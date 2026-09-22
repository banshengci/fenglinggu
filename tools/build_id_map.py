# -*- coding: utf-8 -*-
"""生成「数据 id → 美术文件」映射表（JSON + CSV），供 MiMo 侧直接消费。"""
import json, os, csv

ROOT = r"D:\xinxiangmu\youxi"
ART = os.path.join(ROOT, "game", "art")
DATA = os.path.join(ROOT, "game", "data")
OUT_JSON = os.path.join(ROOT, "docs", "art", "art_id_map.json")
OUT_CSV = os.path.join(ROOT, "docs", "art", "art_id_map.csv")

def load(n):
    return json.load(open(os.path.join(DATA, n), encoding="utf-8"))

items = load("items.json")
crops = load("crops.json")
recipes = load("recipes.json")
fa = load("fish_antiques.json")
mine = load("mine.json")

def names(d):
    return set(f[:-4] for f in os.listdir(d) if f.endswith(".png"))

A = {
    "items": names(os.path.join(ART, "items")),
    "crops": names(os.path.join(ART, "crops")),
    "furniture": names(os.path.join(ART, "furniture")),
    "chars": names(os.path.join(ART, "chars")),
    "enemies": names(os.path.join(ART, "enemies")),
    "ui": names(os.path.join(ART, "ui")),
    "tiles": names(os.path.join(ART, "tiles")),
    "fx": names(os.path.join(ART, "fx")),
}
A["seed_ids"] = set(f[len("seed_"):] for f in A["items"] if f.startswith("seed_"))
A["icon_ids"] = set(f[len("icon_"):] for f in A["items"] if f.startswith("icon_"))
A["dish_ids"] = set(f[len("dish_"):] for f in A["items"] if f.startswith("dish_"))
A["fish_ids"] = set(f[len("fish_"):] for f in A["items"] if f.startswith("fish_"))
A["relic_ids"] = set(f[len("relic_"):] for f in A["items"] if f.startswith("relic_"))
A["furn_ids"] = set(f[len("furniture_"):] for f in A["furniture"] if f.startswith("furniture_"))

# ---- 人工语义映射（美术命名 ↔ 数据命名 不同名时的桥接）----
FISH_ALIAS = {
    "carp_spring": "brook_carp", "crucian": "crucian", "loach": "loach", "dace": "medaka",
    "bluegill": "mandarin", "bass": "river_perch", "catfish": "catfish", "puffer": "stone_grouper",
    "mackerel": "silver_crucian", "salmon": "rainbow_trout", "carp_mirror": "grass_carp",
    "night_eel": "eel", "eel": "eel", "gudgeon": "sweetfish", "ice_trout": "crystal_fish",
    "whitefish": "moonfish", "smelt": "lanternfish", "pike": "snakehead", "moon_koi": "koi",
    "ghost_fish": "mist_fish", "crystal_shrimp": "star_bass", "stone_loach": "lake_sturgeon",
    "pond_turtle": "bronze_carp", "legend_fish": "legendary",
}
RELIC_ALIAS = {
    "clay_bell": "clay_bell_shard", "glass_marble": "mist_marble", "old_letter": "old_letter",
    "gear_toy": "gear_toy", "porcelain_shard": "celadon_shard", "bronze_coin": "bronze_coin",
    "wooden_comb": "wood_mask", "stone_bead": "stone_tablet", "glass_bottle": "clay_jug",
    "iron_key": "compass", "bone_flake": "ring_fragment", "pocket_watch": "star_map",
}
COOK_ALIAS = {
    "turnip_cake": "turnip_cake", "berry_jam": "berry_jam", "salad": "salad",
    "apple_pie": "apple_pie", "honey_toast": "honey_toast", "hot_cocoa": "hot_cocoa",
    "dumpling": "dumpling", "cheese": "cheese", "cake": "cake", "pudding": "pudding",
    "ginger_tea": "ginger_tea", "tomato_soup": "veg_soup", "potato_stew": "veg_stew",
    "veggie_skewer": "mixed_plate", "fish_grill": "grilled_fish", "fish_stew": "fish_soup",
    "berry_pie": "pumpkin_pie", "corn_bread": "bread", "pumpkin_soup": "corn_soup",
    "mushroom_risotto": "mushroom_pot", "tea_set": "tea", "coffee": "hot_cocoa",
    "wine_grape": "grape_wine", "sushi": "rice_ball", "rice_bowl": "fried_rice",
    "noodle": "noodles", "hotpot": "mushroom_pot", "butter_toast": "honey_toast",
    "jam_toast": "jam_bun", "pickles": "pickle", "kimchi": "pickle",
    "smoked_eel": "grilled_fish", "honey": "honey_cake", "candy": "cookie",
    "chocolate": "cake", "ice": "ice_cream", "sun_cake": "pancake",
    "herb_salt": "herbal_soup", "mixed_juice": "mixed_plate", "legend_feast": "feast",
}
ICON_ALIAS = {
    "wood_axe": "axe", "stone_pick": "pickaxe", "copper_ore": "copper", "iron_ore": "iron",
    "silver_ore": "silver", "gold_ore": "gold", "mythril_shard": "star_crystal",
    "wind_shard": "windchime_shard",
}
FURN_ALIAS = {
    "wood_fence": "fence", "stone_path": "stone_tile", "flower_pot": "pot",
    "sign_post": "sign", "painting_hills": "painting_valley", "painting_lake": "painting_lake",
    "painting_mine": "painting_cave", "bell_mobile": "bell_hanging",
    "festival_banner": "banner", "photo_frame": "frame", "hanging_bells": "eave_chime",
    "picnic_set": "picnic_basket", "tiny_bell": "wind_chime", "trophy_cup": "frame",
}

rows = []

def add(kind, data_id, file_path, note=""):
    rows.append({"kind": kind, "id": data_id, "file": file_path, "note": note})

# 作物
for cid in crops:
    p = "game/art/crops/crop_%s.png" % cid
    add("crop", cid, p if ("crop_" + cid) in A["crops"] else "", "成熟图")
    for s in range(4):
        k = "crop_%s_s%d" % (cid, s)
        if k in A["crops"]:
            add("crop_stage", "%s:s%d" % (cid, s), "game/art/crops/%s.png" % k)

# 种子
for iid, v in items.items():
    if v.get("type") != "seed":
        continue
    cand = iid[len("seed_"):] if iid.startswith("seed_") else iid.replace("_seed", "")
    add("seed", iid, "game/art/items/seed_%s.png" % cand if cand in A["seed_ids"] else "",
        "" if cand in A["seed_ids"] else "缺图：美术侧无对应种子")

# 料理
for rid in recipes:
    if recipes[rid].get("station") != "kitchen":
        continue
    art = COOK_ALIAS.get(rid, rid)
    ok = art in A["dish_ids"]
    add("dish", rid, "game/art/items/dish_%s.png" % art if ok else "",
        "" if art == rid else ("语义近似：%s" % art))

# 鱼
for f in fa["fish"]:
    fid = f["id"]
    art = FISH_ALIAS.get(fid, fid)
    ok = art in A["fish_ids"]
    add("fish", fid, "game/art/items/fish_%s.png" % art if ok else "",
        f["name"] + ("" if art == fid else "（近似：%s）" % art))

# 古物
for a in fa["antiques"]:
    aid = a["id"]
    art = RELIC_ALIAS.get(aid, aid)
    ok = art in A["relic_ids"]
    add("antique", aid, "game/art/items/relic_%s.png" % art if ok else "",
        a["name"] + ("" if art == aid else "（近似：%s）" % art))

# 工具/资源/任务
for iid, v in items.items():
    t = v.get("type")
    if t not in ("tool", "resource", "quest"):
        continue
    art = ICON_ALIAS.get(iid, iid)
    ok = art in A["icon_ids"]
    add("item_icon", iid, "game/art/items/icon_%s.png" % art if ok else "",
        "" if art == iid else "别名：%s" % art)

# 家具
for iid, v in items.items():
    if v.get("type") != "furniture":
        continue
    art = iid if iid in A["furn_ids"] else FURN_ALIAS.get(iid)
    ok = art in A["furn_ids"]
    add("furniture", iid, "game/art/furniture/furniture_%s.png" % art if ok else "",
        "" if art == iid else ("别名：%s" % art))

# NPC
for nid in load("npcs.json"):
    add("npc", nid, "game/art/chars/npc_%s.png" % nid if ("npc_" + nid) in A["chars"] else "")

# 矿岩
ores = sorted({k for fl in mine["floors"] for k in fl.get("ore_weights", {})})
ORE_ART = {"stone": "stone", "copper_ore": "copper", "iron_ore": "iron", "wind_shard": "crystal",
           "silver_ore": "stone", "gold_ore": "stone", "mythril_shard": "crystal"}
ORE_TINT = {"silver_ore": "#D9E0F0", "gold_ore": "#E8C87A", "mythril_shard": "#8FD8E8"}
for o in ores:
    a = ORE_ART[o]
    add("ore_rock", o, "game/art/enemies/enemy_ore_rock_%s.png" % a,
        "原图" if a == o else ("复用 %s + 色相 %s" % (a, ORE_TINT.get(o, ""))))

# 敌人动画
ANIM = {
    "slime": ("enemy_slime", "walk", 4),
    "bat": ("enemy_mist_bat", "fly", 4),
    "slime_king": ("enemy_stone_guardian", "fall", 6),
}
for tid, (pre, act, n) in ANIM.items():
    for i in range(n):
        k = "%s_%s_%02d" % (pre, act, i)
        add("enemy_frame", "%s:%s:%02d" % (tid, act, i),
            "game/art/enemies/%s.png" % k if k in A["enemies"] else "")

# 行走帧（主角 + NPC）：直接扫描 game/art/chars/walk/ 的实际落盘文件
WALK_DIR = os.path.join(ROOT, "game", "art", "chars", "walk")
WALK_DIRS = ["down", "left", "right", "up"]
walk_files = set()
if os.path.isdir(WALK_DIR):
    walk_files = {f[:-4] for f in os.listdir(WALK_DIR) if f.endswith(".png")}

for _d in WALK_DIRS:
    for _i in range(4):
        _k = "player_%s_%02d" % (_d, _i)
        add("player_walk", "%s:%02d" % (_d, _i),
            "game/art/chars/walk/%s.png" % _k if _k in walk_files else "")

for _nid in load("npcs.json"):
    for _d in WALK_DIRS:
        for _i in range(4):
            _k = "npc_%s_%s_%02d" % (_nid, _d, _i)
            add("npc_walk", "%s:%s:%02d" % (_nid, _d, _i),
                "game/art/chars/walk/%s.png" % _k if _k in walk_files else "")

missing = [r for r in rows if not r["file"]]
json.dump({
    "generated_from": ["game/data/items.json", "game/data/crops.json", "game/data/recipes.json",
                       "game/data/fish_antiques.json", "game/data/mine.json", "game/data/npcs.json",
                       "game/art/chars/walk/ (行走帧，按实际落盘文件扫描)"],
    "total": len(rows), "mapped": len(rows) - len(missing), "missing": len(missing),
    "map": rows,
    "missing_list": missing,
}, open(OUT_JSON, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

with open(OUT_CSV, "w", encoding="utf-8-sig", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["kind", "id", "file", "note"])
    w.writeheader()
    w.writerows(rows)

print("total %d  mapped %d  missing %d" % (len(rows), len(rows) - len(missing), len(missing)))
print("missing:", [r["kind"] + ":" + r["id"] for r in missing])
