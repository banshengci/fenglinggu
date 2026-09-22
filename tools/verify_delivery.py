# -*- coding: utf-8 -*-
"""交付前最终核查：尺寸 / 命名 / 透明通道 / 可加载性 / 空图。"""
import os, json, re
from collections import Counter
from PIL import Image

ROOT = r"D:\xinxiangmu\youxi"
ART = os.path.join(ROOT, "game", "art")
OUT = os.path.join(ROOT, "docs", "art", "_verify.txt")

SKIP = {"_stage", "keys", "sprites"}   # 非运行时
NAME_RE = re.compile(r"^[a-z0-9_]+(_\d{2})?$")

problems = {"bad_name": [], "low_coverage": [], "broken": [], "opaque_small": []}
sizes = Counter()
total = 0
alpha_missing = []

# 递归遍历：chars/walk/ 这类二级目录也要算进来
for dirpath, dirnames, filenames in os.walk(ART):
    rel = os.path.relpath(dirpath, ART).replace("\\", "/")
    if rel == ".":
        continue
    parts = rel.split("/")
    if parts[0] in SKIP:      # _stage / keys / sprites（含其子目录）不算运行时
        continue
    d = rel
    for fn in sorted(filenames):
        if not fn.lower().endswith(".png"):
            continue
        total += 1
        stem = fn[:-4]
        if not NAME_RE.match(stem):
            problems["bad_name"].append("%s/%s" % (d, fn))
        p = os.path.join(dirpath, fn)
        try:
            im = Image.open(p)
            w, h = im.size
        except Exception as e:
            problems["broken"].append("%s/%s (%s)" % (d, fn, e))
            continue
        sizes["%dx%d" % (w, h)] += 1
        rgba = im.convert("RGBA")
        a = rgba.split()[-1]
        # tobytes() 比 getdata() 快且不会被 Pillow 弃用
        opaque = sum(1 for v in a.tobytes() if v > 16)
        cov = opaque / float(w * h)
        # 全幅类资源无透明通道属正常
        full_bleed = stem.startswith(("fx_overlay_", "tile_", "title_bg", "splash",
                                      "capsule_", "library_art", "cutscene_"))
        if not full_bleed and im.mode in ("RGB", "P") and "transparency" not in im.info:
            alpha_missing.append("%s/%s" % (d, fn))
        if cov < 0.02 and os.path.getsize(p) < 30000:
            problems["low_coverage"].append("%s/%s cov=%.3f" % (d, fn, cov))

lines = []
lines.append("== 交付核查（运行时资产，排除 _stage/keys/sprites）==")
lines.append("检查文件数: %d" % total)
lines.append("")
lines.append("1) 命名不规范: %d" % len(problems["bad_name"]))
for x in problems["bad_name"][:20]:
    lines.append("   " + x)
lines.append("")
lines.append("2) 打不开/损坏: %d" % len(problems["broken"]))
for x in problems["broken"][:20]:
    lines.append("   " + x)
lines.append("")
lines.append("3) 疑似空白图: %d" % len(problems["low_coverage"]))
for x in problems["low_coverage"][:40]:
    lines.append("   " + x)
lines.append("")
lines.append("4) 画布尺寸分布:")
for k, v in sizes.most_common():
    lines.append("   %-12s %4d" % (k, v))
lines.append("")
lines.append("5) 应透明但无 alpha 通道: %d" % len(alpha_missing))
for x in alpha_missing[:30]:
    lines.append("   " + x)

open(OUT, "w", encoding="utf-8").write("\n".join(lines))
print("checked", total)
