# -*- coding: utf-8 -*-
import sys
from PIL import Image
paths = [
    r"game/art/buildings/building_cabin.png",
    r"game/art/chars/npc_lin.png",
    r"game/art/ui/panel_9s.png",
    r"game/art/tiles/prop_fence_set.png",
    r"game/art/ui/ui_buttons.png",
    r"game/art/ui/logo_emblem.png",
    r"game/art/ui/app_icon.png",
    r"game/art/furniture/furniture_field_marker.png",
    r"game/art/items/seed_mushroom.png",
    r"game/art/chars/npc_grandpa_lin.png",
]
import os
base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = []
for p in paths:
    fp = os.path.join(base, p)
    if not os.path.exists(fp):
        out.append("MISSING " + p); continue
    im = Image.open(fp)
    out.append("%-40s mode=%-6s size=%s" % (os.path.basename(p), im.mode, im.size))
out_path = os.path.join(base, "docs", "art", "_modes.txt")
os.makedirs(os.path.dirname(out_path), exist_ok=True)
open(out_path, "w", encoding="utf-8").write("\n".join(out))
