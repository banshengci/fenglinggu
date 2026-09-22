# -*- coding: utf-8 -*-
"""把某目录下的 PNG 拼成一张联络表(contact sheet)，便于一次性目检。"""
import glob
import os
import sys

from PIL import Image

def sheet(src_dir, out_path, cols=6, cell=140, bg=(245, 240, 232, 255), prefix=""):
    files = sorted(glob.glob(os.path.join(src_dir, "*.png")))
    files = [f for f in files if not f.endswith(".import")]
    if prefix:
        files = [f for f in files if os.path.basename(f).startswith(prefix)]
    n = len(files)
    rows = (n + cols - 1) // cols
    pad = 8
    W = cols * (cell + pad) + pad
    H = rows * (cell + pad) + pad
    canvas = Image.new("RGBA", (W, H), bg)
    for i, f in enumerate(files):
        try:
            im = Image.open(f).convert("RGBA")
        except Exception:
            continue
        im.thumbnail((cell, cell), Image.LANCZOS)
        r, c = divmod(i, cols)
        x = pad + c * (cell + pad) + (cell - im.width) // 2
        y = pad + r * (cell + pad) + (cell - im.height) // 2
        canvas.alpha_composite(im, (x, y))
    canvas.convert("RGB").save(out_path)
    return "%s  n=%d  %dx%d" % (out_path, n, W, H)

if __name__ == "__main__":
    args = sys.argv[1:]
    log = []
    log.append(sheet(args[0], args[1], int(args[2]) if len(args) > 2 else 6,
                     prefix=args[3] if len(args) > 3 else ""))
    open(r"D:\xinxiangmu\youxi\_sheet.txt", "w", encoding="utf-8").write("\n".join(log))
