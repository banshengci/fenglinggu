#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, sys
from PIL import Image
from collections import Counter

names = sys.argv[1:]
base = r"D:\xinxiangmu\youxi\game\art"
lines = []
for n in names:
    p = n
    if not os.path.isabs(p):
        p = os.path.join(base, n) if "/" in n else os.path.join(base, "items", n)
    if not p.lower().endswith(".png"):
        p += ".png"
    if not os.path.exists(p):
        lines.append("MISSING %s" % p)
        continue
    im = Image.open(p).convert("RGBA")
    w, h = im.size
    px = list(im.getdata())
    op = [q for q in px if q[3] > 16]
    cov = len(op) / float(w * h)
    bbox = im.split()[-1].getbbox()
    mid = px[(h // 2) * w + w // 2]
    lines.append("%s %dx%d size=%d cov=%.3f bbox=%s center=%s" % (os.path.basename(p), w, h, os.path.getsize(p), cov, bbox, mid))
    c = Counter([(q[0] // 32 * 32, q[1] // 32 * 32, q[2] // 32 * 32) for q in op])
    lines.append("   top colors: %s" % c.most_common(4))
open(r"D:\xinxiangmu\youxi\docs\art\_audit_one.txt", "w", encoding="utf-8").write("\n".join(lines))
