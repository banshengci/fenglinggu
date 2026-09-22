# -*- coding: utf-8 -*-
"""报告若干 PNG 的透明像素占比，用于判断背景是否成功抠除。"""
import sys

import numpy as np
from PIL import Image

targets = sys.argv[1:]
out = []
for p in targets:
    try:
        im = Image.open(p).convert("RGBA")
        a = np.asarray(im)[:, :, 3]
        frac = float((a < 32).mean())
        out.append("%-22s %5.1f%% transparent  %s" % (p.split("\\")[-1], frac * 100,
                                                      "OK" if 0.05 < frac < 0.95 else "SUSPECT"))
    except Exception as e:
        out.append("%-22s ERR %s" % (p.split("\\")[-1], e))
open(r"D:\xinxiangmu\youxi\_alpha_check.txt", "w", encoding="utf-8").write("\n".join(out))
