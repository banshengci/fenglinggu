# -*- coding: utf-8 -*-
"""诊断：对某个板图在不同 merge_gap 下报告连通域数量与主要面积，
用于为「N 个主体」选择合适的分割阈值。"""
import os

import numpy as np
from PIL import Image
from scipy import ndimage

def estimate_bg(arr):
    h, w, _ = arr.shape
    k = max(3, min(h, w) // 200)
    border = np.concatenate([
        arr[:k].reshape(-1, 3), arr[-k:].reshape(-1, 3),
        arr[:, :k].reshape(-1, 3), arr[:, -k:].reshape(-1, 3)])
    return np.median(border, axis=0)

def near(a, b, gap):
    return (max(a[0], b[0]) - min(a[2], b[2]) <= gap) and (max(a[1], b[1]) - min(a[3], b[3]) <= gap)

def merge(boxes, gap):
    changed = True
    while changed:
        changed = False
        for i in range(len(boxes)):
            for j in range(i + 1, len(boxes)):
                if near(boxes[i], boxes[j], gap):
                    a, b = boxes[i], boxes[j]
                    boxes[i] = [min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3]), a[4] + b[4]]
                    del boxes[j]; changed = True; break
            if changed:
                break
    return boxes

def analyze(path, tol=22, min_frac=0.002, gaps=(0, 4, 8, 12, 16, 20, 24, 30, 40)):
    im = Image.open(path).convert("RGB")
    arr = np.asarray(im).astype(np.int16)
    bg = estimate_bg(arr)
    mask = np.abs(arr - bg).sum(axis=2) > tol * 3
    lbl, _ = ndimage.label(mask)
    objs = ndimage.find_objects(lbl)
    total = int(mask.sum())
    base = []
    for i, sl in enumerate(objs):
        if sl is None:
            continue
        ys, xs = sl
        area = int((lbl[sl] == (i + 1)).sum())
        if area < total * min_frac:
            continue
        base.append([xs.start, ys.start, xs.stop, ys.stop, area])
    out = ["== %s  W=%d base_cc=%d" % (os.path.basename(path), arr.shape[1], len(base))]
    for g in gaps:
        bs = merge([b[:] for b in base], g)
        bs.sort(key=lambda b: -b[4])
        areas = [b[4] for b in bs[:10]]
        wh = ["%dx%d" % (b[2] - b[0], b[3] - b[1]) for b in bs[:10]]
        out.append("  gap=%-3d n=%-3d top_wh=%s" % (g, len(bs), ",".join(wh)))
    return "\n".join(out)

stage = r"D:\xinxiangmu\youxi\game\art\_stage"
res = []
for f in ["decor7.png", "mistbat.png", "guardian.png", "ore4.png", "slime_walk.png", "slime_hit.png"]:
    p = os.path.join(stage, f)
    if os.path.exists(p):
        res.append(analyze(p))
open(r"D:\xinxiangmu\youxi\_probe2.txt", "w", encoding="utf-8").write("\n".join(res))
