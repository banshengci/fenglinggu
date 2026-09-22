import glob, os
import numpy as np
from PIL import Image

ROOT = r"D:\xinxiangmu\youxi\game\art\tiles"
pats = ["tree_*.png", "flower_*.png",
        "prop_bush.png", "prop_grass_tuft.png", "prop_small_flower.png",
        "prop_reed.png", "prop_bamboo.png", "prop_stump.png",
        "prop_stone_cluster.png", "prop_rock_pile.png",
        "prop_fence_corner.png", "prop_footprints.png"]
files = []
for p in pats:
    files += glob.glob(os.path.join(ROOT, p))
lines = []
for p in sorted(files):
    a = np.asarray(Image.open(p).convert("RGBA"))[:, :, 3]
    frac = float((a < 32).mean())
    flag = "  <<< BG-KEPT" if frac < 0.05 else ""
    lines.append(f"{frac*100:5.1f}%\t{os.path.basename(p)}{flag}")
open(r"D:\xinxiangmu\youxi\tools\check_veg.out.txt", "w", encoding="utf-8").write("\n".join(lines))
