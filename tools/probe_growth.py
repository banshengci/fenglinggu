import sys, os, glob
sys.path.insert(0, r"D:\xinxiangmu\youxi\tools")
import numpy as np
from PIL import Image
import slice_icons as S

def count(src, tol=25, gap=0, min_frac=0.006):
    im = Image.open(src).convert("RGB")
    arr = np.asarray(im).astype(np.int16)
    bg = S.estimate_bg(arr)
    mask = np.abs(arr - bg).sum(axis=2) > tol * 3
    boxes = S.boxes_from_mask(mask, int(mask.sum() * min_frac))
    boxes = S.merge_boxes(boxes, gap)
    return len(boxes)

plates = sorted(glob.glob(r"D:\xinxiangmu\youxi\game\art\_stage\plate_growth_*_crop.png")) + \
    sorted(glob.glob(r"D:\xinxiangmu\youxi\game\art\_stage\plate_weather3_crop.png"))
lines = []
for p in plates:
    lines.append(f"{os.path.basename(p)}\tdetected {count(p)}")
open(r"D:\xinxiangmu\youxi\tools\probe_growth.out.txt", "w", encoding="utf-8").write("\n".join(lines))
