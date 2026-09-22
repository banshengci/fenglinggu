#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Scan game/art and emit an inventory report (txt + json) for delivery packaging."""
import os, json, hashlib
from collections import defaultdict

ROOT = r"D:\xinxiangmu\youxi"
ART = os.path.join(ROOT, "game", "art")
OUT_TXT = os.path.join(ROOT, "docs", "art", "_scan_report.txt")
OUT_JSON = os.path.join(ROOT, "docs", "art", "_scan_inventory.json")

EXT_OK = {".png", ".webp", ".jpg", ".jpeg"}

stat = defaultdict(lambda: {"count": 0, "bytes": 0, "files": []})
total = {"count": 0, "bytes": 0}

for dirpath, dirnames, filenames in os.walk(ART):
    rel = os.path.relpath(dirpath, ART).replace("\\", "/")
    if rel == ".":
        rel = "(root)"
    for fn in sorted(filenames):
        ext = os.path.splitext(fn)[1].lower()
        if ext not in EXT_OK:
            continue
        p = os.path.join(dirpath, fn)
        size = os.path.getsize(p)
        stat[rel]["count"] += 1
        stat[rel]["bytes"] += size
        stat[rel]["files"].append({
            "name": fn,
            "path": os.path.relpath(p, ROOT).replace("\\", "/"),
            "bytes": size,
        })
        total["count"] += 1
        total["bytes"] += size

lines = []
lines.append("=== game/art inventory ===")
lines.append("total files: %d   total size: %.2f MB" % (total["count"], total["bytes"] / 1048576))
lines.append("")
for k in sorted(stat.keys()):
    v = stat[k]
    lines.append("%-16s %4d files  %8.2f MB" % (k, v["count"], v["bytes"] / 1048576))
lines.append("")
lines.append("=== per-directory file list ===")
for k in sorted(stat.keys()):
    lines.append("")
    lines.append("--- %s (%d) ---" % (k, stat[k]["count"]))
    for f in stat[k]["files"]:
        lines.append("  %s  (%d B)" % (f["name"], f["bytes"]))

with open(OUT_TXT, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines))

with open(OUT_JSON, "w", encoding="utf-8") as fh:
    json.dump({"total": total, "dirs": {k: {"count": v["count"], "bytes": v["bytes"], "files": [f["path"] for f in v["files"]]} for k, v in stat.items()}}, fh, ensure_ascii=False, indent=1)

print("done", total["count"])
