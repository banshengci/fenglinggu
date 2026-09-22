# -*- coding: utf-8 -*-
"""对剩余 3 张 UI 图（对话条/快捷栏/图标行）抠透明底。"""
import os
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = r"D:\xinxiangmu\youxi\game\art"
OUT = r"D:\xinxiangmu\youxi\docs\art\_alpha_report2.txt"

TARGETS = [
    ("ui/ui_dialog.png", 70),
    ("ui/ui_hotbar.png", 70),
    ("ui/ui_icons_row.png", 85),
]


def bg_median(arr):
    h, w, _ = arr.shape
    k = max(4, min(h, w) // 120)
    border = np.concatenate([
        arr[:k].reshape(-1, 3), arr[-k:].reshape(-1, 3),
        arr[:, :k].reshape(-1, 3), arr[:, -k:].reshape(-1, 3),
    ])
    return np.median(border, axis=0)


log = []
for rel, tol in TARGETS:
    p = os.path.join(ROOT, rel)
    if not os.path.exists(p):
        log.append("MISSING " + rel)
        continue
    im = Image.open(p)
    if im.mode in ("RGBA", "LA"):
        log.append("%s SKIP-already-alpha" % rel)
        continue
    im = im.convert("RGB")
    arr = np.asarray(im).astype(np.int16)
    bg = bg_median(arr)
    dist = np.abs(arr - bg).sum(axis=2)
    cand = dist < tol * 3
    lbl, n = ndimage.label(cand)
    if n == 0:
        log.append("%s SKIP-no-bg" % rel)
        continue
    border = (set(lbl[0, :].tolist()) | set(lbl[-1, :].tolist())
              | set(lbl[:, 0].tolist()) | set(lbl[:, -1].tolist()))
    border.discard(0)
    if not border:
        log.append("%s SKIP-bg-not-connected" % rel)
        continue
    truebg = np.isin(lbl, list(border))
    alpha = np.where(truebg, 0, 255).astype(np.uint8)
    a_img = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.8))
    rgba = im.convert("RGBA")
    rgba.putalpha(a_img)
    rgba.save(p)
    log.append("%-24s OK transparent=%.1f%%" % (rel, 100.0 * truebg.sum() / arr[:, :, 0].size))

open(OUT, "w", encoding="utf-8").write("\n".join(log))
