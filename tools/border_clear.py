# -*- coding: utf-8 -*-
"""清除贴边的细「相框」杂边：把图像最外圈 frac 比例的 alpha 置 0。
用法: python border_clear.py <jobs.json>
[{"path":"...","frac":0.04}, ...]
"""
import json
import os
import sys

import numpy as np
from PIL import Image


def clear(path, frac=0.04):
    im = Image.open(path).convert("RGBA")
    a = np.asarray(im).copy()
    h, w = a.shape[:2]
    kx, ky = max(1, int(w * frac)), max(1, int(h * frac))
    a[:ky, :, 3] = 0
    a[-ky:, :, 3] = 0
    a[:, :kx, 3] = 0
    a[:, -kx:, 3] = 0
    Image.fromarray(a).save(path)
    return float((a[:, :, 3] < 32).mean())


def main():
    jobs = json.load(open(sys.argv[1], encoding="utf-8"))
    log = []
    for j in jobs:
        f = j["path"]
        if not os.path.exists(f):
            log.append("MISSING\t" + f)
            continue
        r = clear(f, float(j.get("frac", 0.04)))
        log.append("OK\t%s\ttransparent %.1f%%" % (os.path.basename(f), r * 100))
    out = os.path.splitext(sys.argv[1])[0] + ".report.txt"
    open(out, "w", encoding="utf-8").write("\n".join(log))
    print("\n".join(log))


if __name__ == "__main__":
    main()
