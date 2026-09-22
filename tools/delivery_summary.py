#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""汇总美术交付：总量 / 规格 / 需求清单完成度。输出汇总 JSON 供 README 渲染。"""
import os, json, re
from collections import OrderedDict, defaultdict

ROOT = r"D:\xinxiangmu\youxi"
ART = os.path.join(ROOT, "game", "art")
OUT = os.path.join(ROOT, "docs", "art", "_summary.json")

# ---------- 1. 文件盘点 ----------
dirs = {}
for d in sorted(os.listdir(ART)):
    dd = os.path.join(ART, d)
    if not os.path.isdir(dd):
        continue
    files = [f for f in sorted(os.listdir(dd)) if f.lower().endswith(".png")]
    size = sum(os.path.getsize(os.path.join(dd, f)) for f in files)
    dirs[d] = {"count": len(files), "bytes": size, "set": set(f[:-4] for f in files)}

runtime_dirs = [d for d in dirs if d not in ("_stage", "keys")]
total_files = sum(dirs[d]["count"] for d in dirs)
runtime_files = sum(dirs[d]["count"] for d in runtime_dirs)
runtime_bytes = sum(dirs[d]["bytes"] for d in runtime_dirs)

# ---------- 2. 需求完成度 ----------
def data(name):
    return json.load(open(os.path.join(ROOT, "game", "data", name), encoding="utf-8"))

crops = data("crops.json")
items = data("items.json")
recipes = data("recipes.json")
fish_ant = data("fish_antiques.json")
npcs = data("npcs.json")
mine = data("mine.json")

def ids(obj):
    if isinstance(obj, dict):
        return list(obj.keys())
    return [x.get("id") for x in obj if isinstance(x, dict) and x.get("id")]

crop_ids = ids(crops)
recipe_ids = ids(recipes)
npc_ids = ids(npcs)

# fish / antiques structure
fa = fish_ant
fish_ids = ids(fa.get("fish", fa.get("fishes", [])))
relic_ids = ids(fa.get("antiques", fa.get("relics", [])))

ITEMS = dirs.get("items", {}).get("set", set())
CROPS = dirs.get("crops", {}).get("set", set())
CHARS = dirs.get("chars", {}).get("set", set())
TILES = dirs.get("tiles", {}).get("set", set())
UI = dirs.get("ui", {}).get("set", set())
FX = dirs.get("fx", {}).get("set", set())
FURN = dirs.get("furniture", {}).get("set", set())
ENEM = dirs.get("enemies", {}).get("set", set())
BUILD = dirs.get("buildings", {}).get("set", set())
ANIM = dirs.get("animals", {}).get("set", set())
CUT = dirs.get("cutscenes", {}).get("set", set())
MKT = dirs.get("marketing", {}).get("set", set())

def coverage(needed, have, prefix=""):
    ok = [i for i in needed if (prefix + i) in have or i in have]
    miss = [i for i in needed if i not in ok]
    return ok, miss

cov = OrderedDict()

# 作物成熟图
ok, miss = coverage(crop_ids, CROPS, "crop_")
cov["作物成熟图"] = {"need": len(crop_ids), "have": len(ok), "miss": miss}
# 作物生长阶段
stage_crops = sorted([c for c in CROPS if re.match(r"^crop_.+_s0$", c)])
cov["作物生长阶段（_s0..s3）"] = {"need": len(crop_ids), "have": len(stage_crops),
                              "miss": [c for c in crop_ids if "crop_%s_s0" % c not in CROPS]}
# 种子
ok, miss = coverage(crop_ids, ITEMS, "seed_")
cov["种子图标"] = {"need": len(crop_ids), "have": len(ok), "miss": miss}
# 料理
ok, miss = coverage(recipe_ids, ITEMS, "dish_")
cov["料理图标"] = {"need": len(recipe_ids), "have": len(ok), "miss": miss}
# 鱼
ok, miss = coverage(fish_ids, ITEMS, "fish_")
cov["鱼类图标"] = {"need": len(fish_ids), "have": len(ok), "miss": miss}
# 古物
ok, miss = coverage(relic_ids, ITEMS, "relic_")
cov["古物图标"] = {"need": len(relic_ids), "have": len(ok), "miss": miss}
# NPC
ok, miss = coverage(npc_ids, CHARS, "npc_")
cov["NPC 立绘"] = {"need": len(npc_ids), "have": len(ok), "miss": miss}

# 敌人帧
enemy_frames = {
    "晶蚀史莱姆 · 走": ("enemy_slime_walk_%02d", 4),
    "晶蚀史莱姆 · 受击": ("enemy_slime_hit_%02d", 4),
    "雾蝠 · 飞": ("enemy_mist_bat_fly_%02d", 4),
    "岩心守卫 · 倒下": ("enemy_stone_guardian_fall_%02d", 6),
}
ef = {}
for k, (pat, n) in enemy_frames.items():
    got = sum(1 for i in range(n) if pat % i in ENEM)
    ef[k] = "%d/%d" % (got, n)
cov["敌人帧序列"] = {"need": sum(n for _, n in enemy_frames.values()),
                 "have": sum(int(v.split("/")[0]) for v in ef.values()), "detail": ef,
                 "miss": []}

# 矿岩（4 皮 + 3 缺）
ore_all = sorted({k for fl in mine["floors"] for k in fl.get("ore_weights", {})})
ore_have = sorted([e for e in ENEM if e.startswith("enemy_ore_rock_")])
cov["矿岩（按矿石 id）"] = {"need": len(ore_all), "have": len(ore_have),
                        "miss": ["silver_ore", "gold_ore", "mythril_shard"], "detail": ore_have}

# 天气 / 季节
cov["天气图标"] = {"need": 7, "have": len([u for u in UI if u.startswith("ui_weather_")]), "miss": []}
cov["季节图标"] = {"need": 4, "have": len([u for u in UI if u.startswith("ui_season_")]), "miss": []}
cov["天气全屏遮罩"] = {"need": 4, "have": len([f for f in FX if f.startswith("fx_overlay_")]), "miss": []}

# 树木
seasons = ["spring", "summer", "autumn", "winter"]
kinds = ["broadleaf", "conifer", "fruit"]
tree_ok = sum(1 for s in seasons for k in kinds if "tree_%s_%s" % (s, k) in TILES)
cov["树木（四季×三类）"] = {"need": 12, "have": tree_ok, "miss": []}

summary = {
    "total_files": total_files,
    "runtime_files": runtime_files,
    "runtime_mb": round(runtime_bytes / 1048576.0, 1),
    "all_mb": round(sum(dirs[d]["bytes"] for d in dirs) / 1048576.0, 1),
    "dirs": {d: {"count": dirs[d]["count"], "mb": round(dirs[d]["bytes"] / 1048576.0, 2)}
             for d in sorted(dirs, key=lambda x: -dirs[x]["count"])},
    "coverage": cov,
    "counts": {
        "crops": len(crop_ids), "recipes": len(recipe_ids), "fish": len(fish_ids),
        "relics": len(relic_ids), "npcs": len(npc_ids), "items": len(items),
        "mine_floors": len(mine["floors"]), "ores": ore_all,
    },
}
with open(OUT, "w", encoding="utf-8") as fh:
    json.dump(summary, fh, ensure_ascii=False, indent=1)

lines = ["total=%d runtime=%d (%.1f MB) all=%.1f MB" % (total_files, runtime_files,
                                                       summary["runtime_mb"], summary["all_mb"]), ""]
for k, v in cov.items():
    lines.append("%-22s %s/%s  %s" % (k, v["have"], v["need"], v.get("miss") or ""))
open(os.path.join(ROOT, "docs", "art", "_summary.txt"), "w", encoding="utf-8").write("\n".join(lines))
print("ok")
