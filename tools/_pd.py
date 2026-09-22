import os
from PIL import Image

gi = r"D:\xinxiangmu\youxi\generated-images"
out = []
for f in sorted(os.listdir(gi)):
    if f.lower().endswith(".png"):
        try:
            im = Image.open(os.path.join(gi, f))
            out.append("%s\t%dx%d\tmode=%s" % (f, im.size[0], im.size[1], im.mode))
        except Exception as e:
            out.append("%s\tERR\t%s" % (f, e))
open(r"D:\xinxiangmu\youxi\_dims.txt", "w", encoding="utf-8").write("\n".join(out))
