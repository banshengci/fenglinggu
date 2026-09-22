#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""动画帧条切片器：从「一行 N 个主体帧」的板图切出对齐的帧。

相比 grid_slice（固定等分网格），本工具先做连通域检测拿到每个主体的真实包围盒，
再按「共同基线 + 共同高度 + 共同画幅宽」裁切，保证：
  - 帧与帧之间主体不抖动（动画对齐）；
  - 主体间距不均匀（如逐渐塌缩的 Boss）也能正确切分。

用法: python frame_slice.py <jobs.json>
job:
{
  "source": "...", "out_dir": "...",
  "names": ["enemy_x_00", ...],
  "out_size": 256,
  "tol": 22,             # 背景色差阈值(合成距离 = tol*3)
  "merge_gap": 30,       # 邻近域合并间距(px)，用于把碎屑/光环并入主体
  "min_area_frac": 0.002,# 最小面积占比(占全前景)
  "margin_frac": 0.18    # 画幅外扩
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
        arr[:, :k].reshape(-1, 3), arr[:, -k:].reshape(-1, 3),
    ])
    return np.median(border, axis=0)


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
                                max(a[2], b[2]), max(a[3], b[3]), a[4] + b[4]]
                    del boxes[j]
                    changed = True
                    break
            if changed:
                break
    return boxes


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
    truebg = np.isin(lbl, list(bl))
    alpha = np.where(truebg, 0, 255).astype(np.uint8)
    a_img = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.6))
    out = cell.convert("RGBA")
    out.putalpha(a_img)
    return out


def run_job(job):
    src = os.path.normpath(job["source"])
    out_dir = os.path.normpath(job["out_dir"])
    names = job["names"]
    want = int(job.get("count", len(names)))
    out_size = int(job.get("out_size", 256))
    tol = float(job.get("tol", 22))
    gap = float(job.get("merge_gap", 30))
    min_frac = float(job.get("min_area_frac", 0.002))
    margin = float(job.get("margin_frac", 0.18))

    if not os.path.exists(src):
        return ["MISSING\t%s" % src]

    im = Image.open(src).convert("RGB")
    arr = np.asarray(im).astype(np.int16)
    h, w, _ = arr.shape
    bg = estimate_bg(arr)
    mask = np.abs(arr - bg).sum(axis=2) > tol * 3

    lbl, _ = ndimage.label(mask)
    objs = ndimage.find_objects(lbl)
    boxes = []
    total = int(mask.sum())
    for i, sl in enumerate(objs):
        if sl is None:
            continue
        ys, xs = sl
        area = int((lbl[sl] == (i + 1)).sum())
        if area < total * min_frac:
            continue
        boxes.append([xs.start, ys.start, xs.stop, ys.stop, area])

    boxes = merge_boxes(boxes, gap)
    # 取面积最大的 want 个（剔除碎屑），再按 x 排序
    boxes.sort(key=lambda b: -b[4])
    boxes = boxes[:want]
    boxes.sort(key=lambda b: b[0])

    res = ["COUNT\t%s\tprovided %d / used %d" % (os.path.basename(src), len(names), len(boxes))]
    if not boxes:
        return res

    ymin = min(b[1] for b in boxes)
    ymax = max(b[3] for b in boxes)
    maxw = max(b[2] - b[0] for b in boxes)
    fh = int((ymax - ymin) * (1 + margin))
    fw = int(maxw * (1 + margin))
    y0c = ymin - int(fh * margin / 2.0)

    os.makedirs(out_dir, exist_ok=True)
    for i, b in enumerate(boxes):
        if i >= len(names):
            break
        cx = (b[0] + b[2]) // 2
        x0 = cx - fw // 2
        x1 = x0 + fw
        y0 = y0c
        y1 = y0 + fh
        # clamp to image, then re-pad on a transparent canvas so all frames share size
        sx0, sx1 = max(0, x0), min(w, x1)
        sy0, sy1 = max(0, y0), min(h, y1)
        cell = im.crop((sx0, sy0, sx1, sy1))
        canvas = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
        rgba = alpha_from_bg(cell, tol)
        if rgba is None:
            rgba = cell.convert("RGBA")
        canvas.paste(rgba, (sx0 - x0, sy0 - y0))
        s = max(canvas.size)
        sq = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        sq.paste(canvas, ((s - canvas.width) // 2, (s - canvas.height) // 2))
        sq = sq.resize((out_size, out_size), Image.LANCZOS)
        sq.save(os.path.join(out_dir, "%s.png" % names[i]))
        res.append("OK\t%s\t%dx%d" % (names[i], b[2] - b[0], b[3] - b[1]))
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
