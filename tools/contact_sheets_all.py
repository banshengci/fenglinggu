# -*- coding: utf-8 -*-
"""按目录生成联络表（透明底叠加棋盘格，便于查看抠图效果）。"""
import os, glob, sys
from PIL import Image

ROOT = r"D:\xinxiangmu\youxi\game\art"
PREV = r"D:\xinxiangmu\youxi\docs\art\preview"


def checker(w, h, s=12):
    img = Image.new("RGB", (w, h), (235, 235, 235))
    for y in range(0, h, s):
        for x in range(0, w, s):
            if ((x // s) + (y // s)) % 2:
                for yy in range(y, min(y + s, h)):
                    for xx in range(x, min(x + s, w)):
                        img.putpixel((xx, yy), (205, 205, 205))
    return img


def sheet(src_dir, out_path, cols=6, cell=150, prefix=None, ext="*.png"):
    files = sorted(glob.glob(os.path.join(src_dir, ext)))
    files = [f for f in files if not f.endswith(".import")]
    if prefix:
        files = [f for f in files if os.path.basename(f).startswith(prefix)]
    n = len(files)
    if n == 0:
        return "%s n=0" % out_path
    rows = (n + cols - 1) // cols
    pad = 8
    W = cols * (cell + pad) + pad
    H = rows * (cell + pad) + pad
    canvas = checker(W, H).convert("RGBA")
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
    return "%s n=%d %dx%d" % (os.path.basename(out_path), n, W, H)


def sheet_names(src_dir, out_path, names, cols=4, cell=110):
    """按给定顺序拼联络表（行走帧需要「行=方向/角色，列=帧」的语义顺序，glob 排不出来）。"""
    files = [os.path.join(src_dir, n + ".png") for n in names]
    files = [f for f in files if os.path.exists(f)]
    n = len(files)
    if n == 0:
        return "%s n=0" % os.path.basename(out_path)
    rows = (n + cols - 1) // cols
    pad = 8
    W = cols * (cell + pad) + pad
    H = rows * (cell + pad) + pad
    canvas = checker(W, H).convert("RGBA")
    for i, f in enumerate(files):
        try:
            im = Image.open(f).convert("RGBA")
        except Exception:
            continue
        im.thumbnail((cell, cell), Image.LANCZOS)
        r, c = divmod(i, cols)
        x = pad + c * (cell + pad) + (cell - im.width) // 2
        y = pad + r * (cell + pad) + (cell - im.height)
        canvas.alpha_composite(im, (x, y))
    canvas.convert("RGB").save(out_path)
    return "%s n=%d %dx%d" % (os.path.basename(out_path), n, W, H)


WALK_DIR = os.path.join(ROOT, "chars", "walk")
DIRS = ["down", "left", "right", "up"]
NPCS = ["grandpa_lin", "xiaoman", "zhi_tao", "atang", "jiangcheng", "yunzhou", "shijiang", "chapo"]

jobs = [
    ("chars", "v_chars", 5, 200, None),
    ("buildings", "v_buildings", 5, 200, None),
    ("ui", "v_ui_panels", 4, 220, "ui_"),
    ("ui", "v_ui_brand", 4, 220, None),
    ("animals", "v_animals", 6, 150, None),
    ("furniture", "v_furniture", 8, 150, None),
    ("items", "v_items_icons", 8, 130, "icon_"),
    ("tiles", "v_tiles_props", 8, 140, "prop_"),
]
log = []
for d, name, cols, cell, pre in jobs:
    log.append(sheet(os.path.join(ROOT, d), os.path.join(PREV, "_%s.png" % name), cols, cell, pre))

# 行走帧：主角 4 方向 × 4 帧
log.append(sheet_names(
    WALK_DIR, os.path.join(PREV, "_v_walk_player.png"),
    ["player_%s_%02d" % (d, i) for d in DIRS for i in range(4)], 4, 110))
# 行走帧：8 个 NPC × 4 方向（取每方向第 0 帧）
log.append(sheet_names(
    WALK_DIR, os.path.join(PREV, "_v_walk_npcs.png"),
    ["npc_%s_%s_00" % (nid, d) for nid in NPCS for d in DIRS], 4, 110))

open(r"D:\xinxiangmu\youxi\docs\art\_sheets.log", "w", encoding="utf-8").write("\n".join(log))
