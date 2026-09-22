#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""规则网格切片 + 逐格紧裁 + 透明底。

适合「N 个主体等距排成一行/若干行」的板图（生长阶段条、天气图标等）。

用法: python grid_slice.py <jobs.json>
job:
{
  "source": "...", "out_dir": "...",
  "names": ["crop_turnip_s0", ...],
  "cols": 4, "rows": 1,
  "out_size": 128,
  "tol": 25,        # 背景色差(合成距离阈值 = tol*3)
  "margin_frac": 0.12
}
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage


def border_bg(arr):
    h, w, _ = arr.shape
    k = max(3, min(h, w) // 200)
    border = np.concatenate([
        arr[:k].reshape(-1, 3), arr[-k:].reshape(-1, 3),
        arr[:, :k].reshape(-1, 3), arr[:, -k:].reshape(-1, 3),
    ])
    return np.median(border, axis=0)


def alpha_from_bg(cell, tol):
    arr = np.asarray(cell.convert("RGB")).astype(np.int16)
    bg = border_bg(arr)
    dist = np.abs(arr - bg).sum(axis=2)
    cand = dist < tol * 3
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
    cols = int(job.get("cols", 4))
    rows = int(job.get("rows", 1))
    out_size = int(job.get("out_size", 128))
    tol = float(job.get("tol", 25))
    margin = float(job.get("margin_frac", 0.12))

    if not os.path.exists(src):
        return [f"MISSING\t{src}"]
    im = Image.open(src).convert("RGB")
    W, H = im.size
    os.makedirs(out_dir, exist_ok=True)
    res = [f"OK\t{os.path.basename(src)}\t{W}x{H}\t{cols}x{rows}"]
    idx = 0
    for r in range(rows):
        y0, y1 = H * r // rows, H * (r + 1) // rows
        for c in range(cols):
            x0, x1 = W * c // cols, W * (c + 1) // cols
            if idx >= len(names):
                break
            cell = im.crop((x0, y0, x1, y1))
            ca = np.asarray(cell).astype(np.int16)
            bg = border_bg(ca)
            dist = np.abs(ca - bg).sum(axis=2)
            mask = dist > tol * 3
            ys, xs = np.where(mask)
            if len(xs) == 0:
                res.append(f"EMPTY\t{names[idx]}")
                idx += 1
                continue
            bx0, bx1, by0, by1 = int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max())
            mw, mh = int((bx1 - bx0) * margin), int((by1 - by0) * margin)
            X0, Y0 = max(0, bx0 - mw), max(0, by0 - mh)
            X1, Y1 = min(cell.width, bx1 + mw + 1), min(cell.height, by1 + mh + 1)
            sub = cell.crop((X0, Y0, X1, Y1))
            w, h = sub.size
            s = max(w, h)
            canvas = Image.new("RGBA", (s, s), (0, 0, 0, 0))
            rgba = alpha_from_bg(sub, tol)
            if rgba is None:
                rgba = sub.convert("RGBA")
            canvas.paste(rgba, ((s - w) // 2, (s - h) // 2))
            canvas = canvas.resize((out_size, out_size), Image.LANCZOS)
            canvas.save(os.path.join(out_dir, f"{names[idx]}.png"))
            res.append(f"OK\t{names[idx]}\t{w}x{h}")
            idx += 1
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
