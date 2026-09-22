# -*- coding: utf-8 -*-
"""把 docs/art/art_id_map.json 固化为 GDScript 常量字典。

生成 game/scripts/autoload/art_id_map.gd（纯数据，无依赖）：
  const FILE_OF := { "crop:apple": "crops/crop_apple.png", ... }
key 统一为 "<kind>:<id>"，value 为相对 res://art/ 的路径。
"""
import json
import os

SRC = r"D:\xinxiangmu\youxi\docs\art\art_id_map.json"
DST = r"D:\xinxiangmu\youxi\game\scripts\autoload\art_id_map.gd"

with open(SRC, "r", encoding="utf-8") as f:
    data = json.load(f)

if isinstance(data, list):
    entries = data
elif isinstance(data, dict):
    entries = data.get("map") or data.get("mappings") or data.get("items") or []
    if isinstance(entries, dict):
        entries = [{"kind": k, "id": v["id"] if isinstance(v, dict) else "",
                    "file": v["file"] if isinstance(v, dict) else v} for k, v in entries.items()]
else:
    entries = []

lines = []
seen = {}
for e in entries:
    kind = str(e.get("kind", "")).strip()
    iid = str(e.get("id", "")).strip()
    fp = str(e.get("file", "")).strip().replace("\\", "/")
    if not kind or not iid or not fp:
        continue
    for pre in ("res://art/", "game/art/", "art/"):
        if fp.startswith(pre):
            fp = fp[len(pre):]
            break
    seen["%s:%s" % (kind, iid)] = fp

keys = sorted(seen.keys())

out = []
out.append("extends RefCounted")
out.append("## 美术 id -> 文件 映射表（由 tools/gen_art_map_gd.py 从 docs/art/art_id_map.json 生成，请勿手改）")
out.append("## key 格式 \"<kind>:<id>\"，value 为相对 res://art/ 的相对路径。")
out.append("## 共 %d 条。" % len(keys))
out.append("")
out.append("const FILE_OF := {")
for k in keys:
    out.append('\t"%s": "%s",' % (k, seen[k]))
out.append("}")
out.append("")
out.append("")
out.append("static func path_of(kind: String, id: String) -> String:")
out.append('\treturn FILE_OF.get("%s:%s" % [kind, id], "")')
out.append("")

os.makedirs(os.path.dirname(DST), exist_ok=True)
with open(DST, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(out))

print("written", DST, len(keys))
