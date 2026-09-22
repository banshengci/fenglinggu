#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build a machine-readable manifest of game/art assets (path, size, px, alpha)."""
import os, json
from collections import OrderedDict

ROOT = r"D:\xinxiangmu\youxi"
ART = os.path.join(ROOT, "game", "art")
OUT = os.path.join(ROOT, "docs", "art", "_manifest_raw.json")

try:
    from PIL import Image
    HAS_PIL = True
except Exception:
    HAS_PIL = False

# directory -> (role, description)
ROLES = {
    "crops":     ("sprite", "作物成熟图 / 生长阶段图（_s0.._s3）"),
    "items":     ("icon",   "物品图标：食材 dish_*、鱼 fish_*、古物 relic_*、种子 seed_*、工具/资源 icon_*"),
    "tiles":     ("tile",   "地皮 tile_*、装饰 prop_*、树 tree_*、花 flower_*"),
    "ui":        ("ui",     "UI 元素：面板/按钮/图标行/天气与季节标记/技能与提示图标"),
    "furniture": ("sprite", "家具与室内外摆件"),
    "enemies":   ("sprite", "敌人与宝箱，含动画帧 *_walk_00.. / *_hit_00.. / *_fall_00.."),
    "fx":        ("fx",     "特效与天气，fx_overlay_* 为全屏天气遮罩"),
    "buildings": ("sprite", "建筑与设施"),
    "chars":     ("sprite", "主角参考图与 NPC 立绘"),
    "animals":   ("sprite", "动物"),
    "cutscenes": ("art",    "章节过场插画"),
    "marketing": ("art",    "商店/营销图：胶囊主图、库图、海报、Splash"),
    "keys":      ("reference", "风格锚点参考图（非运行时资产，仅用于后续生成对齐）"),
    "sprites":   ("legacy", "早期占位小图"),
    "_stage":    ("source", "拼板源图（切片前的中间产物，非运行时资产）"),
}

data = OrderedDict()
counts = OrderedDict()

dirs = sorted([d for d in os.listdir(ART) if os.path.isdir(os.path.join(ART, d))])
for d in dirs:
    role, desc = ROLES.get(d, ("sprite", ""))
    entries = []
    for fn in sorted(os.listdir(os.path.join(ART, d))):
        if not fn.lower().endswith(".png"):
            continue
        p = os.path.join(ART, d, fn)
        w = h = None
        alpha = None
        if HAS_PIL:
            try:
                im = Image.open(p)
                w, h = im.size
                alpha = im.mode in ("RGBA", "LA") or (im.mode == "P" and "transparency" in im.info)
            except Exception:
                pass
        entries.append({
            "file": "game/art/%s/%s" % (d, fn),
            "id": os.path.splitext(fn)[0],
            "w": w, "h": h, "alpha": alpha,
            "bytes": os.path.getsize(p),
        })
    data[d] = {"role": role, "desc": desc, "count": len(entries), "items": entries}
    counts[d] = len(entries)

with open(OUT, "w", encoding="utf-8") as fh:
    json.dump({"dirs": data, "counts": counts}, fh, ensure_ascii=False, indent=1)

print("dirs:", json.dumps(counts, ensure_ascii=False))
