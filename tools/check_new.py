import glob, os, re
import numpy as np
from PIL import Image

ROOT = r"D:\xinxiangmu\youxi\game\art"
files = sorted(glob.glob(os.path.join(ROOT, "crops", "*_s[0-3].png"))) + \
        sorted(glob.glob(os.path.join(ROOT, "ui", "ui_weather_cloudy.png"))) + \
        sorted(glob.glob(os.path.join(ROOT, "ui", "ui_weather_storm.png"))) + \
        sorted(glob.glob(os.path.join(ROOT, "ui", "ui_weather_breeze.png")))
lines = []
for p in files:
    im = Image.open(p)
    a = np.asarray(im.convert("RGBA"))[:, :, 3]
    frac = float((a < 32).mean())
    flag = ""
    if frac < 0.05:
        flag = "  <<< BG-KEPT"
    lines.append(f"{frac*100:5.1f}%\t{os.path.basename(p)}{flag}")
open(r"D:\xinxiangmu\youxi\tools\check_new.out.txt", "w", encoding="utf-8").write("\n".join(lines))
