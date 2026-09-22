# -*- coding: utf-8 -*-
"""重定框：先按 inset 内裁（跳过板图内侧的装饰相框/暗角），
再按不透明内容紧裁，最后居中放到统一正方形画布。
用法: python reframe.py <jobs.json>
[{"path":"...","inset":0.11,"out_size":256,"margin":0.12}, ...]
"""
import json
import os
import sys

import numpy as np
from PIL import Image


def run(path, inset=0.0, out_size=256, margin=0.12):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    if inset > 0:
        ix, iy = int(w * inset), int(h * inset)
        im = im.crop((ix, iy, w - ix, h - iy))
    a = np.asarray(im)[:, :, 3]
    ys, xs = np.where(a > 32)
    if len(xs) == 0:
        return None
    x0, x1, y0, y1 = int(xs.min()), int(xs.max()) + 1, int(ys.min()), int(ys.max()) + 1
    sub = im.crop((x0, y0, x1, y1))
    bw, bh = sub.size
    s = int(max(bw, bh) * (1 + margin * 2))
    canvas = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    canvas.paste(sub, ((s - bw) // 2, (s - bh) // 2))
    if out_size:
        canvas = canvas.resize((out_size, out_size), Image.LANCZOS)
    canvas.save(path)
    return float((np.asarray(canvas)[:, :, 3] < 32).mean())


def main():
    jobs = json.load(open(sys.argv[1], encoding="utf-8"))
    log = []
    for j in jobs:
        f = j["path"]
        if not os.path.exists(f):
            log.append("MISSING\t" + f)
            continue
        r = run(f, float(j.get("inset", 0.0)), int(j.get("out_size", 256)),
                float(j.get("margin", 0.12)))
        log.append("OK\t%s\ttransparent %.1f%%" % (os.path.basename(f), (r or 0) * 100))
    out = os.path.splitext(sys.argv[1])[0] + ".report.txt"
    open(out, "w", encoding="utf-8").write("\n".join(log))
    print("\n".join(log))


if __name__ == "__main__":
    main()
