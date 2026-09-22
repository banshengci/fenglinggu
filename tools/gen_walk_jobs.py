# -*- coding: utf-8 -*-
"""生成行走帧切片作业（主角 1 板 + NPC 8 板，每板 4 行 x 4 列）。
行顺序固定为 down / left / right / up，与 art_pipeline 的方向名一致。
"""
import json
import os

STAGE = r"D:\xinxiangmu\youxi\game\art\_stage"
OUT = r"D:\xinxiangmu\youxi\game\art\chars\walk"
DIRS = ["down", "left", "right", "up"]

# 板图文件名 -> 角色前缀（player 或 npc_<id>）
BOARDS = [
    ("A_sprite_sheet_grid_of_exactly_2026-09-22T10-28-53.png", "player"),
    ("Grandpa_Lin_sprite_sheet__an_e_2026-09-22T10-40-29.png", "npc_grandpa_lin"),
    ("Xiao_Man__a_young_blacksmith_a_2026-09-22T10-34-59.png", "npc_xiaoman"),
    ("Tao_Zhi__a_florist__long_dark__2026-09-22T10-35-20.png", "npc_zhi_tao"),
    ("Shopkeeper_Tang_sprite_sheet___2026-09-22T10-40-53.png", "npc_atang"),
    ("Jiang_Cheng__a_fisherman__a_wi_2026-09-22T10-36-06.png", "npc_jiangcheng"),
    ("Yun_Zhou__a_painter__a_wide_br_2026-09-22T10-36-26.png", "npc_yunzhou"),
    ("Shi_Jiang__an_old_stonemason___2026-09-22T10-36-49.png", "npc_shijiang"),
    ("Cha_Po__an_elderly_tea_master__2026-09-22T10-37-11.png", "npc_chapo"),
]

jobs = []
missing = []
for fn, prefix in BOARDS:
    src = os.path.join(STAGE, fn)
    if not os.path.exists(src):
        # 容错：按前缀模糊匹配
        cands = [f for f in os.listdir(STAGE) if f.startswith(fn.split("__")[0][:12]) and f.endswith(".png")]
        if cands:
            src = os.path.join(STAGE, sorted(cands)[-1])
        else:
            missing.append(fn)
            continue
    names = ["%s_%s_%02d" % (prefix, d, i) for d in DIRS for i in range(4)]
    jobs.append({
        "source": src,
        "out_dir": OUT,
        "names": names,
        "cols": 4,
        "rows": 4,
        "out_w": 192,
        "out_h": 288,
        "tol": 25,
        "fill": 0.92,
        "margin_frac": 0.06,
        "keep_frac": 0.15,
    })

dst = r"D:\xinxiangmu\youxi\tools\art_map_walk.json"
json.dump(jobs, open(dst, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("jobs %d, missing %s" % (len(jobs), missing))
