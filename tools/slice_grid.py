#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""按网格把图标板切成独立图标。用法: python slice_grid.py <jobs.json>

jobs.json 为数组，每个 job:
{
  "source": "D:/.../icon_tools_row.png",
  "out_dir": "D:/.../items",
  "cols": 5, "rows": 1,
  "names": ["icon_hoe","icon_watering_can",...],
  "out_size": 256,          # 可选，统一尺寸
  "pad_frac": 0.05          # 可选，每格四周内缩比例
}
"""
import json
import os
import sys

from PIL import Image


def run_job(job):
    src = os.path.normpath(job["source"])
    out_dir = os.path.normpath(job["out_dir"])
    cols = int(job["cols"])
    rows = int(job["rows"])
    names = job["names"]
    out_size = job.get("out_size")
    pad = float(job.get("pad_frac", 0.05))

    if not os.path.exists(src):
        return [f"MISSING\t{src}"]

    im = Image.open(src).convert("RGB")
    w, h = im.size
    cw, ch = w / float(cols), h / float(rows)
    os.makedirs(out_dir, exist_ok=True)
    res = []
    for r in range(rows):
        for c in range(cols):
            i = r * cols + c
            if i >= len(names):
                break
            left = int(c * cw + cw * pad)
            top = int(r * ch + ch * pad)
            right = int((c + 1) * cw - cw * pad)
            bottom = int((r + 1) * ch - ch * pad)
            cell = im.crop((left, top, right, bottom))
            if out_size:
                cell = cell.resize((int(out_size), int(out_size)), Image.LANCZOS)
            dst = os.path.join(out_dir, f"{names[i]}.png")
            cell.save(dst)
            res.append(f"OK\t{names[i]}\t{cell.size[0]}x{cell.size[1]}")
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
