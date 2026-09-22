#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Audit: list assets that are suspiciously small / low ink coverage (possible failed slices)."""
import os, json
from PIL import Image

ROOT = r"D:\xinxiangmu\youxi"
ART = os.path.join(ROOT, "game", "art")
OUT = os.path.join(ROOT, "docs", "art", "_audit_small.txt")

rows = []
for d in sorted(os.listdir(ART)):
    dd = os.path.join(ART, d)
    if not os.path.isdir(dd) or d in ("_stage", "keys"):
        continue
    for fn in sorted(os.listdir(dd)):
        if not fn.lower().endswith(".png"):
            continue
        p = os.path.join(dd, fn)
        b = os.path.getsize(p)
        if b > 12000:
            continue
        try:
            im = Image.open(p).convert("RGBA")
            w, h = im.size
            a = im.split()[-1]
            opaque = sum(1 for v in a.getdata() if v > 16)
            cov = opaque / float(w * h)
        except Exception as e:
            w = h = -1
            cov = -1
        rows.append((b, d, fn, w, h, cov))

rows.sort()
lines = ["bytes  dir        file                                w    h    coverage"]
for b, d, fn, w, h, cov in rows:
    lines.append("%6d  %-10s %-34s %4d %4d  %.3f" % (b, d, fn, w, h, cov))
lines.append("")
lines.append("suspicious (bytes<12000 and coverage<0.05): %d" % sum(1 for r in rows if r[5] >= 0 and r[5] < 0.05))

with open(OUT, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines))
print("rows", len(rows))
