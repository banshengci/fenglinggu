#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把「纯色纸底 + 单个主体」的图标转成透明底 RGBA（只抠掉与边框连通的背景，
保留主体内部的浅色填充，避免把纸张/高光误删）。

用法: python make_alpha.py
"""
import glob
import os

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = r"D:\xinxiangmu\youxi\game\art"


def bg_median(arr):
    h, w, _ = arr.shape
    k = max(3, min(h, w) // 200)
    border = np.concatenate([
        arr[:k].reshape(-1, 3), arr[-k:].reshape(-1, 3),
        arr[:, :k].reshape(-1, 3), arr[:, -k:].reshape(-1, 3),
    ])
    return np.median(border, axis=0)


def process(path, tol=55):
    im = Image.open(path).convert("RGB")
    arr = np.asarray(im).astype(np.int16)
    bg = bg_median(arr)
    dist = np.abs(arr - bg).sum(axis=2)
    cand = dist < tol
    lbl, n = ndimage.label(cand)
    if n == 0:
        return "SKIP-no-bg"
    border_labels = set(lbl[0, :].tolist()) | set(lbl[-1, :].tolist()) \
        | set(lbl[:, 0].tolist()) | set(lbl[:, -1].tolist())
    border_labels.discard(0)
    if not border_labels:
        return "SKIP-bg-not-connected"
    truebg = np.isin(lbl, list(border_labels))
    alpha = np.where(truebg, 0, 255).astype(np.uint8)
    a_img = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.6))
    rgba = im.convert("RGBA")
    rgba.putalpha(a_img)
    rgba.save(path)
    return "OK"


def main():
    targets = []
    for d in ["crops", "items", "enemies", "furniture", "fx"]:
        targets += sorted(glob.glob(os.path.join(ROOT, d, "*.png")))
    ui_keep = ("ui_prompt_", "ui_skill_", "ui_season_", "ui_weather_",
               "ui_hp_", "ui_coin", "ui_achievement", "ui_camera")
    for p in sorted(glob.glob(os.path.join(ROOT, "ui", "*.png"))):
        if os.path.basename(p).startswith(ui_keep):
            targets.append(p)

    log = []
    for p in targets:
        try:
            st = process(p)
            log.append(f"{st}\t{os.path.basename(p)}")
        except Exception as ex:  # noqa: BLE001
            log.append(f"ERR\t{os.path.basename(p)}\t{ex}")
    open(r"D:\xinxiangmu\youxi\tools\make_alpha.report.txt", "w", encoding="utf-8").write("\n".join(log))
    print(f"processed {len(targets)}")


if __name__ == "__main__":
    main()
