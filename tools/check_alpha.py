import glob, os
import numpy as np
from PIL import Image

ROOT = r"D:\xinxiangmu\youxi\game\art"
dirs = ["crops", "items", "enemies", "furniture", "fx", "ui"]
lines = []
for d in dirs:
    for p in sorted(glob.glob(os.path.join(ROOT, d, "*.png"))):
        im = Image.open(p)
        if im.mode != "RGBA":
            lines.append(f"NOALPHA\t{d}/{os.path.basename(p)}\tmode={im.mode}")
            continue
        a = np.asarray(im)[:, :, 3]
        frac = float((a < 32).mean())
        flag = ""
        if frac > 0.85:
            flag = "  <<< TOO-TRANSPARENT"
        elif frac < 0.02:
            flag = "  <<< NOT-REMOVED"
        lines.append(f"{frac*100:5.1f}%\t{d}/{os.path.basename(p)}{flag}")
open(r"D:\xinxiangmu\youxi\tools\check_alpha.out.txt", "w", encoding="utf-8").write("\n".join(lines))
