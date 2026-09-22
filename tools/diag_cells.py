# -*- coding: utf-8 -*-
"""诊断板图每格的连通域分布，判断 slice_walk 该取哪些域。"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage


def border_bg(arr):
    h, w, _ = arr.shape
    k = max(3, min(h, w) // 200)
    border = np.concatenate([
        arr[:k].reshape(-1, 3), arr[-k:].reshape(-1, 3),
        arr[:, :k].reshape(-1, 3), arr[:, -k:].reshape(-1, 3)])
    return np.median(border, axis=0)


def main():
    src = sys.argv[1]
    cols = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    rows = int(sys.argv[3]) if len(sys.argv) > 3 else 4
    tol = float(sys.argv[4]) if len(sys.argv) > 4 else 25
    im = Image.open(src).convert("RGB")
    W, H = im.size
    out = ["BOARD %dx%d grid %dx%d tol=%s" % (W, H, cols, rows, tol)]
    for r in range(rows):
        y0, y1 = H * r // rows, H * (r + 1) // rows
        for c in range(cols):
            x0, x1 = W * c // cols, W * (c + 1) // cols
            cell = im.crop((x0, y0, x1, y1))
            arr = np.asarray(cell).astype(np.int16)
            bg = border_bg(arr)
            mask = np.abs(arr - bg).sum(axis=2) > tol * 3
            mask = ndimage.binary_opening(mask, np.ones((3, 3)))
            lbl, n = ndimage.label(mask)
            objs = ndimage.find_objects(lbl)
            info = []
            for i, sl in enumerate(objs):
                if sl is None:
                    continue
                area = int((lbl[sl] == (i + 1)).sum())
                ys, xs = sl
                info.append((area, xs.start, ys.start, xs.stop, ys.stop))
            info.sort(key=lambda t: -t[0])
            desc = " | ".join("a=%d y(%d-%d) x(%d-%d)" % (a, y0b, y1b, x0b, x1b)
                              for a, x0b, y0b, x1b, y1b in info[:4])
            out.append("r%d c%d  cell=%dx%d  n=%d  %s" % (r, c, cell.width, cell.height, n, desc))
    p = os.path.splitext(src)[0] + ".diag.txt"
    open(r"D:\xinxiangmu\youxi\docs\art\_raw_scratch\_diag.txt", "w", encoding="utf-8").write("\n".join(out))
    print("\n".join(out))


if __name__ == "__main__":
    main()
