#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""投影谷分割器：切「N 个主体挨在一起」的帧条。

当主体彼此相接/包围盒重叠时（连通域法失效），改用竖直投影：
对每个名义分界 x≈W*i/N 在邻域内寻找前景密度最低的列作为真实分界，
从而沿背景缝隙把 N 个主体分开。再逐帧紧裁 + 共同画幅（水平居中、底对齐）+ 透明底。

用法: python strip_split.py <jobs.json>
job:
{
  "source": "...", "out_dir": "...", "names": [...],
  "count": 4, "out_size": 256,
  "tol": 22, "margin_frac": 0.16, "search_frac": 0.42, "min_frac": 0.001
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


def smooth1d(p, k):
    if k <= 1:
        return p
    ker = np.ones(k) / k
    return np.convolve(p, ker, mode="same")


def run_job(job):
    src = os.path.normpath(job["source"])
    out_dir = os.path.normpath(job["out_dir"])
    names = job["names"]
    n = int(job.get("count", len(names)))
    out_size = int(job.get("out_size", 256))
    tol = float(job.get("tol", 22))
    margin = float(job.get("margin_frac", 0.16))
    search = float(job.get("search_frac", 0.42))
    min_frac = float(job.get("min_frac", 0.001))

    if not os.path.exists(src):
        return ["MISSING\t%s" % src]
    im = Image.open(src).convert("RGB")
    arr = np.asarray(im).astype(np.int16)
    H, W, _ = arr.shape
    bg = estimate_bg(arr)
    mask = np.abs(arr - bg).sum(axis=2) > tol * 3
    proj = smooth1d(mask.sum(axis=0).astype(float), max(3, W // 220))

    # 名义分界 -> 邻域投影谷
    bounds = [0]
    r = int((W / n) * search)
    for i in range(1, n):
        nom = int(round(W * i / n))
        lo, hi = max(1, nom - r), min(W - 2, nom + r)
        if hi <= lo:
            b = nom
        else:
            b = lo + int(np.argmin(proj[lo:hi + 1]))
        if b <= bounds[-1]:
            b = bounds[-1] + 1
        bounds.append(b)
    bounds.append(W)

    res = ["SPLIT\t%s\tW=%d n=%d bounds=%s" % (os.path.basename(src), W, n, bounds)]
    bboxes = []
    for i in range(n):
        x0, x1 = bounds[i], bounds[i + 1]
        sub = mask[:, x0:x1]
        cols = np.where(sub.any(axis=0))[0]
        rows = np.where(sub.any(axis=1))[0]
        if len(cols) == 0 or len(rows) == 0:
            bboxes.append(None)
            continue
        bboxes.append((x0 + int(cols.min()), int(rows.min()),
                       x0 + int(cols.max()) + 1, int(rows.max()) + 1))

    valid = [b for b in bboxes if b]
    if not valid:
        return res
    maxw = max(b[2] - b[0] for b in valid)
    maxh = max(b[3] - b[1] for b in valid)
    cw = int(maxw * (1 + margin * 2))
    ch = int(maxh * (1 + margin * 2))
    os.makedirs(out_dir, exist_ok=True)
    s = max(cw, ch)
    for i, b in enumerate(bboxes):
        if i >= len(names):
            break
        if b is None:
            res.append("EMPTY\t%s" % names[i])
            continue
        x0, y0, x1, y1 = b
        bw, bh = x1 - x0, y1 - y0
        mx, my = int(bw * margin), int(bh * margin)
        cx0, cx1 = max(0, x0 - mx), min(W, x1 + mx)
        cy0, cy1 = max(0, y0 - my), min(H, y1 + my)
        cell = im.crop((cx0, cy0, cx1, cy1))
        rgba = alpha_from_bg(cell, tol)
        if rgba is None:
            rgba = cell.convert("RGBA")
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        px = (cw - cell.width) // 2
        py = ch - cell.height  # 底对齐
        canvas.paste(rgba, (max(0, px), max(0, py)))
        sq = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        sq.paste(canvas, ((s - cw) // 2, (s - ch) // 2))
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
