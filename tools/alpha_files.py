#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""对指定文件列表做「边框连通背景抠除 -> 透明底」（与 make_alpha 同算法）。

用于只对 slice_icons 产出的（RGB）图标补 alpha，避免整目录批处理误伤
已带 alpha（黑/纸色填充）的 grid_slice / frame_slice 产物。

用法: python alpha_files.py <list.json>       # ["path1","path2",...]
可选: 列表元素为 {"path": "...", "inset": 0.10}
"""
import json
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage


def bg_median(arr):
    h, w, _ = arr.shape
    k = max(3, min(h, w) // 200)
    border = np.concatenate([
        arr[:k].reshape(-1, 3), arr[-k:].reshape(-1, 3),
        arr[:, :k].reshape(-1, 3), arr[:, -k:].reshape(-1, 3),
    ])
    return np.median(border, axis=0)


def process(path, inset=0.0, tol=55):
    im = Image.open(path).convert("RGB")
    if inset > 0:
        w, h = im.size
        ix, iy = int(w * inset), int(h * inset)
        im = im.crop((ix, iy, w - ix, h - iy))
    arr = np.asarray(im).astype(np.int16)
    bg = bg_median(arr)
    dist = np.abs(arr - bg).sum(axis=2)
    cand = dist < tol
    lbl, n = ndimage.label(cand)
    if n == 0:
        return "SKIP-no-bg"
    bl = set(lbl[0, :].tolist()) | set(lbl[-1, :].tolist()) \
        | set(lbl[:, 0].tolist()) | set(lbl[:, -1].tolist())
    bl.discard(0)
    if not bl:
        return "SKIP-bg-not-connected"
    truebg = np.isin(lbl, list(bl))
    alpha = np.where(truebg, 0, 255).astype(np.uint8)
    a_img = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.6))
    rgba = im.convert("RGBA")
    rgba.putalpha(a_img)
    rgba.save(path)
    frac = 1.0 - (alpha > 32).mean()
    return "OK\ttransparent=%.0f%%" % (frac * 100)


def main():
    items = json.load(open(sys.argv[1], encoding="utf-8"))
    log = []
    for it in items:
        p = it["path"] if isinstance(it, dict) else it
        inset = float(it.get("inset", 0.0)) if isinstance(it, dict) else 0.0
        try:
            log.append("%s\t%s" % (process(p, inset), p))
        except Exception as ex:  # noqa: BLE001
            log.append("ERR\t%s\t%s" % (p, ex))
    out = sys.argv[1].rsplit(".", 1)[0] + ".report.txt"
    open(out, "w", encoding="utf-8").write("\n".join(log))
    print("\n".join(log))


if __name__ == "__main__":
    main()
