# -*- coding: utf-8 -*-
import os, json
from PIL import Image
Image.MAX_IMAGE_PIXELS = None

ROOT = r"D:\xinxiangmu\youxi\game\art"
EXTRA = "_stage"   # 暂存区，不算运行时资产

rows = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    rel = os.path.relpath(dirpath, ROOT).replace("\\", "/")
    if rel == ".":
        rel = "(root)"
    n = 0
    b = 0
    for f in filenames:
        if not f.lower().endswith((".png", ".jpg", ".webp")):
            continue
        n += 1
        b += os.path.getsize(os.path.join(dirpath, f))
    if n:
        rows.append((rel, n, b))

rows.sort(key=lambda r: -r[1])
total_n = sum(r[1] for r in rows)
total_b = sum(r[2] for r in rows)
run_n = sum(r[1] for r in rows if r[0] != EXTRA and not r[0].startswith(EXTRA + "/"))
run_b = sum(r[2] for r in rows if r[0] != EXTRA and not r[0].startswith(EXTRA + "/"))
stage_n = sum(r[1] for r in rows if r[0] == EXTRA or r[0].startswith(EXTRA + "/"))
stage_b = sum(r[2] for r in rows if r[0] == EXTRA or r[0].startswith(EXTRA + "/"))

out = []
out.append("=== game/art 资产最终清点 ===")
out.append("")
out.append("%-40s %6s %10s" % ("目录", "张数", "体积(MB)"))
out.append("-" * 60)
for rel, n, b in rows:
    mark = "  [暂存]" if (rel == EXTRA or rel.startswith(EXTRA + "/")) else ""
    out.append("%-40s %6d %10.2f%s" % (rel, n, b / 1048576.0, mark))
out.append("-" * 60)
out.append("%-40s %6d %10.2f" % ("运行时资产合计(排除_stage)", run_n, run_b / 1048576.0))
out.append("%-40s %6d %10.2f" % ("_stage 暂存", stage_n, stage_b / 1048576.0))
out.append("%-40s %6d %10.2f" % ("总计", total_n, total_b / 1048576.0))

txt = "\n".join(out)
with open(r"D:\xinxiangmu\youxi\docs\art\_final_count.txt", "w", encoding="utf-8") as f:
    f.write(txt)

data = {"runtime": {"count": run_n, "mb": round(run_b / 1048576.0, 2)},
        "stage": {"count": stage_n, "mb": round(stage_b / 1048576.0, 2)},
        "total": {"count": total_n, "mb": round(total_b / 1048576.0, 2)},
        "dirs": [{"dir": r[0], "count": r[1], "mb": round(r[2] / 1048576.0, 2)} for r in rows]}
with open(r"D:\xinxiangmu\youxi\docs\art\_final_count.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print("done", total_n, run_n)
