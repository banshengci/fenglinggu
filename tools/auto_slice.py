#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""布局无关切片器：连通域检测 + 阅读顺序 + 透明底 + 逐件正方形画布。

适合「多物件板图但列/行数不确定或不等距」的情况（生成模型常在同一批里
给出 5x2 / 2x5 / 6x2 等不同排布）。等价于 slice_icons + make_alpha 的合体。

用法: python auto_slice.py <jobs.json>
job:
{
  "source": "...", "out_dir": "...", "names": [...],
  "out_size": 256, "tol": 22, "merge_gap": 30,
  "min_area_frac": 0.004, "margin_frac": 0.14
}
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage


def estimate_bg(arr):
    h, w, _ = arr.shape
    k = max(3, min(h, w) // 200)
    border = np.concatenate([
        arr[:k].reshape(-1, 3), arr[-k:].reshape(-1, 3),
        arr[:, :k].reshape(-1, 3), arr[:, -k:].reshape(-1, 3)])
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
                    boxes[i] = [min(a[0], b[0]), min(a[1], b[1]),
                                max(a[2], b[2]), max(a[3], b[3])]
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


def alpha_from_bg(cell, tol):
    arr = np.asarray(cell.convert("RGB")).astype(np.int16)
    bg = estimate_bg(arr)
    cand = np.abs(arr - bg).sum(axis=2) < tol * 3
    lbl, n = ndimage.label(cand)
    if n == 0:
        return None
    bl = set(lbl[0, :].tolist()) | set(lbl[-1, :].tolist()) \
        | set(lbl[:, 0].tolist()) | set(lbl[:, -1].tolist())
    bl.discard(0)
    if not bl:
        return None
    alpha = np.where(np.isin(lbl, list(bl)), 0, 255).astype(np.uint8)
    a_img = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.6))
    out = cell.convert("RGBA")
    out.putalpha(a_img)
    return out


def run_job(job):
    src = os.path.normpath(job["source"])
    out_dir = os.path.normpath(job["out_dir"])
    names = job["names"]
    out_size = int(job.get("out_size", 256))
    tol = float(job.get("tol", 22))
    gap = float(job.get("merge_gap", 30))
    min_frac = float(job.get("min_area_frac", 0.004))
    margin = float(job.get("margin_frac", 0.14))

    if not os.path.exists(src):
        return ["MISSING\t%s" % src]
    im = Image.open(src).convert("RGB")
    arr = np.asarray(im).astype(np.int16)
    h, w, _ = arr.shape
    bg = estimate_bg(arr)
    mask = np.abs(arr - bg).sum(axis=2) > tol * 3
    boxes = boxes_from_mask(mask, int(mask.sum() * min_frac))
    if gap > 0:
        boxes = merge_boxes(boxes, gap)
    if len(boxes) > len(names):
        boxes = sorted(boxes, key=lambda b: -((b[2] - b[0]) * (b[3] - b[1])))[:len(names)]
    boxes = order_reading(boxes)

    res = ["COUNT\t%s\tprovided %d / detected %d" % (os.path.basename(src), len(names), len(boxes))]
    os.makedirs(out_dir, exist_ok=True)
    for i, (x0, y0, x1, y1) in enumerate(boxes):
        if i >= len(names):
            break
        bw, bh = x1 - x0, y1 - y0
        mx, my = int(bw * margin), int(bh * margin)
        X0, Y0 = max(0, x0 - mx), max(0, y0 - my)
        X1, Y1 = min(w, x1 + mx), min(h, y1 + my)
        cell = im.crop((X0, Y0, X1, Y1))
        rgba = alpha_from_bg(cell, tol)
        if rgba is None:
            rgba = cell.convert("RGBA")
        s = max(rgba.size)
        sq = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        sq.paste(rgba, ((s - rgba.width) // 2, (s - rgba.height) // 2))
        sq = sq.resize((out_size, out_size), Image.LANCZOS)
        sq.save(os.path.join(out_dir, "%s.png" % names[i]))
        res.append("OK\t%s\t%dx%d" % (names[i], bw, bh))
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
