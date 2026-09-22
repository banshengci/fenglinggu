#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从「纯色背景 + 多个独立图标」的板图中自动切出独立图标。

流程: 估计背景色 -> 前景掩码 -> 二维连通域 -> 邻近域合并（同一图标的分件）
      -> 过滤噪声 -> 按阅读顺序排列 -> 逐个裁切并缩放。

用法: python slice_icons.py <jobs.json>

job:
{
  "source": "...", "out_dir": "...",
  "names": ["icon_a","icon_b",...],   # 阅读顺序
  "out_size": 256,
  "tol": 22,             # 背景色差阈值
  "margin_frac": 0.12,   # 裁切外扩
  "merge_gap": 30,       # 邻近合并间距(px)
  "min_area_frac": 0.004 # 最小面积占比(占前景)
}
"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage


def estimate_bg(arr):
    h, w, _ = arr.shape
    k = max(3, min(h, w) // 200)
    border = np.concatenate([
        arr[:k].reshape(-1, 3), arr[-k:].reshape(-1, 3),
        arr[:, :k].reshape(-1, 3), arr[:, -k:].reshape(-1, 3),
    ])
    return np.median(border, axis=0)


def boxes_from_mask(mask, min_area):
    lbl, n = ndimage.label(mask)
    objs = ndimage.find_objects(lbl)
    boxes = []
    for i, sl in enumerate(objs):
        if sl is None:
            continue
        ys, xs = sl
        area = int((lbl[sl] == (i + 1)).sum())
        if area < min_area:
            continue
        boxes.append([xs.start, ys.start, xs.stop, ys.stop])
    return boxes


def near(a, b, gap):
    hgap = max(a[0], b[0]) - min(a[2], b[2])
    vgap = max(a[1], b[1]) - min(a[3], b[3])
    return hgap <= gap and vgap <= gap


def merge_boxes(boxes, gap):
    changed = True
    while changed:
        changed = False
        for i in range(len(boxes)):
            for j in range(i + 1, len(boxes)):
                if near(boxes[i], boxes[j], gap):
                    a, b = boxes[i], boxes[j]
                    merged = [min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])]
                    boxes[i] = merged
                    del boxes[j]
                    changed = True
                    break
            if changed:
                break
    return boxes


def order_reading(boxes):
    boxes = sorted(boxes, key=lambda b: b[1])
    heights = [b[3] - b[1] for b in boxes] or [1]
    med = float(np.median(heights))
    rows = []
    for b in boxes:
        yc = (b[1] + b[3]) / 2.0
        for r in rows:
            if abs(r["yc"] - yc) < med * 0.6:
                r["items"].append(b)
                r["yc"] = float(np.mean([(x[1] + x[3]) / 2.0 for x in r["items"]]))
                break
        else:
            rows.append({"yc": yc, "items": [b]})
    rows.sort(key=lambda r: r["yc"])
    out = []
    for r in rows:
        out += sorted(r["items"], key=lambda b: b[0])
    return out


def run_job(job):
    src = os.path.normpath(job["source"])
    out_dir = os.path.normpath(job["out_dir"])
    names = job["names"]
    out_size = job.get("out_size")
    tol = float(job.get("tol", 22))
    margin = float(job.get("margin_frac", 0.12))
    gap = float(job.get("merge_gap", 30))
    min_frac = float(job.get("min_area_frac", 0.004))

    if not os.path.exists(src):
        return [f"MISSING\t{src}"]

    im = Image.open(src).convert("RGB")
    arr = np.asarray(im).astype(np.int16)
    h, w, _ = arr.shape
    bg = estimate_bg(arr)
    mask = np.abs(arr - bg).sum(axis=2) > tol * 3

    boxes = boxes_from_mask(mask, int(mask.sum() * min_frac))
    boxes = merge_boxes(boxes, gap)
    boxes = order_reading(boxes)

    os.makedirs(out_dir, exist_ok=True)
    res = [f"COUNT\t{os.path.basename(src)}\tprovided {len(names)} / detected {len(boxes)}"]
    for i, (x0, y0, x1, y1) in enumerate(boxes):
        if i >= len(names):
            break
        bw, bh = x1 - x0, y1 - y0
        mx, my = int(bw * margin), int(bh * margin)
        X0, Y0 = max(0, x0 - mx), max(0, y0 - my)
        X1, Y1 = min(w, x1 + mx), min(h, y1 + my)
        cell = im.crop((X0, Y0, X1, Y1))
        if out_size:
            cell = cell.resize((int(out_size), int(out_size)), Image.LANCZOS)
        cell.save(os.path.join(out_dir, f"{names[i]}.png"))
        res.append(f"OK\t{names[i]}\t{bw}x{bh}")
    return res


def main():
    jobs = json.load(open(sys.argv[1], encoding="utf-8"))
    lines = []
    for j in jobs:
        lines += run_job(j)
    out = os.path.splitext(sys.argv[1])[0] + ".report.txt"
    open(out, "w", encoding="utf-8").write("\n".join(lines))
    print("\n".join(lines))


if __name__ == "__main__":
    main()
