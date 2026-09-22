#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""修正版透明底抠图：先向内裁掉水彩暗角(vignette)，再按边框连通域抠背景。
用法: python fix_alpha.py <jobs.json>
[{"path":"...", "inset":0.08, "tol":55}, ...]
"""
import json
import os
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
    w, h = im.size
    if inset > 0:
        ix, iy = int(w * inset), int(h * inset)
        im = im.crop((ix, iy, w - ix, h - iy))
    arr = np.asarray(im).astype(np.int16)
    bg = bg_median(arr)
    dist = np.abs(arr - bg).sum(axis=2)
    cand = dist < tol
    lbl, n = ndimage.label(cand)
    border = set(lbl[0, :].tolist()) | set(lbl[-1, :].tolist()) \
        | set(lbl[:, 0].tolist()) | set(lbl[:, -1].tolist())
    border.discard(0)
    truebg = np.isin(lbl, list(border)) if border else np.zeros(cand.shape, bool)
    alpha = np.where(truebg, 0, 255).astype(np.uint8)
    a_img = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.6))
    rgba = im.convert("RGBA")
    rgba.putalpha(a_img)
    rgba.save(path)
    return float((alpha < 32).mean())


def main():
    jobs = json.load(open(sys.argv[1], encoding="utf-8"))
    log = []
    for j in jobs:
        f = j["path"]
        if not os.path.exists(f):
            log.append("MISSING\t" + f)
            continue
        r = process(f, float(j.get("inset", 0.0)), float(j.get("tol", 55)))
        log.append(f"OK\t{os.path.basename(f)}\ttransparent {r*100:.1f}%")
    out = os.path.splitext(sys.argv[1])[0] + ".report.txt"
    open(out, "w", encoding="utf-8").write("\n".join(log))
    print("\n".join(log))


if __name__ == "__main__":
    main()
