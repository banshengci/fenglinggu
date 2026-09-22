#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate an ASCII-art preview of an image so it can be verified without a viewer."""
import os, sys
from PIL import Image

CHARS = " .:-=+*#%@"

def preview(path, cols=72):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    rows = max(1, int(cols * h / float(w) * 0.5))
    im2 = im.resize((cols, rows), Image.LANCZOS)
    px = list(im2.getdata())
    out = []
    for r in range(rows):
        line = ""
        for c in range(cols):
            q = px[r * cols + c]
            a = q[3] / 255.0
            lum = (0.299 * q[0] + 0.587 * q[1] + 0.114 * q[2]) / 255.0
            v = (1.0 - lum) * a  # dark ink on transparent
            line += CHARS[min(len(CHARS) - 1, int(v * len(CHARS)))]
        out.append(line)
    return "\n".join(out)

names = sys.argv[2:]
base = sys.argv[1] if len(sys.argv) > 1 else r"D:\xinxiangmu\youxi\game\art\items"
buf = []
for n in names:
    p = os.path.join(base, n if n.endswith(".png") else n + ".png")
    buf.append("=== %s ===" % n)
    if os.path.exists(p):
        buf.append(preview(p))
    else:
        buf.append("MISSING %s" % p)
    buf.append("")
open(r"D:\xinxiangmu\youxi\docs\art\_ascii_preview.txt", "w", encoding="utf-8").write("\n".join(buf))
