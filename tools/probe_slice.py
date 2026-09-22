#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""探针：扫描 tol / merge_gap，观察连通域数量，帮助选参数。"""
import numpy as np
from PIL import Image
from scipy import ndimage

FILES = {
    "tools": ("D:/xinxiangmu/youxi/game/art/items/icon_tools_row.png", 5),
    "resources": ("D:/xinxiangmu/youxi/game/art/items/icon_resources_grid.png", 9),
    "crops": ("D:/xinxiangmu/youxi/game/art/keys/crops_plate.png", 12),
}


def est_bg(arr):
    h, w, _ = arr.shape
    k = max(3, min(h, w) // 200)
    b = np.concatenate([arr[:k].reshape(-1, 3), arr[-k:].reshape(-1, 3),
                        arr[:, :k].reshape(-1, 3), arr[:, -k:].reshape(-1, 3)])
    return np.median(b, axis=0)


def near(a, b, g):
    return (max(a[0], b[0]) - min(a[2], b[2]) <= g) and (max(a[1], b[1]) - min(a[3], b[3]) <= g)


def merge(boxes, g):
    ch = True
    while ch:
        ch = False
        for i in range(len(boxes)):
            for j in range(i + 1, len(boxes)):
                if near(boxes[i], boxes[j], g):
                    a, b = boxes[i], boxes[j]
                    boxes[i] = [min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])]
                    del boxes[j]
                    ch = True
                    break
            if ch:
                break
    return boxes


for name, (path, expect) in FILES.items():
    arr = np.asarray(Image.open(path).convert("RGB")).astype(np.int16)
    bg = est_bg(arr)
    dist = np.abs(arr - bg).sum(axis=2)
    print(f"== {name} (expect {expect}) bg={bg.astype(int).tolist()} distmax={int(dist.max())}")
    for tol in (20, 30, 40, 50, 60, 80):
        m = dist > tol * 3
        lbl, n = ndimage.label(m)
        sizes = ndimage.sum(np.ones_like(lbl), lbl, range(1, n + 1))
        keep = [i + 1 for i, s in enumerate(sizes) if s > m.sum() * 0.006]
        objs = ndimage.find_objects(lbl)
        boxes = [[objs[i - 1][1].start, objs[i - 1][0].start, objs[i - 1][1].stop, objs[i - 1][0].stop] for i in keep]
        for g in (10, 20, 30):
            mb = merge([b[:] for b in boxes], g)
            print(f"   tol={tol:>3} gap={g:>2} raw={len(boxes):>2} merged={len(mb):>2}")
