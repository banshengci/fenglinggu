#!/usr/bin/env python
"""导出美术对照 CSV 与 asset manifest，供 workbuddy 勾选交付。"""
from __future__ import annotations

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "game" / "data"
OUT = ROOT / "docs" / "art"
OUT.mkdir(parents=True, exist_ok=True)


def load(name: str):
    return json.loads((DATA / name).read_text(encoding="utf-8"))


def main() -> None:
    items = load("items.json")
    crops = load("crops.json")
    fa = load("fish_antiques.json")

    rows = []
    for cid, c in crops.items():
        batch = "A" if cid in {
            "turnip", "potato", "tomato", "berry", "corn", "pumpkin",
            "grape", "rice", "tea", "sunflower", "mushroom", "apple",
        } else "C"
        rows.append({
            "batch": batch,
            "kind": "crop",
            "id": cid,
            "name": c.get("name", cid),
            "files": f"crop_{cid}.png 或 crop_{cid}_s0..s3.png",
            "size": "32x32",
            "status": "",
        })
    for iid, it in items.items():
        t = it.get("type", "misc")
        if t == "seed":
            batch = "C"
        elif iid in {"hoe", "watering_can", "wood_axe", "stone_pick", "wood", "stone", "fiber", "wind_shard"}:
            batch = "A"
        elif t in {"tool", "furniture", "resource"}:
            batch = "B"
        else:
            batch = "C"
        rows.append({
            "batch": batch,
            "kind": "icon_" + t,
            "id": iid,
            "name": it.get("name", iid),
            "files": f"icon_{iid}.png",
            "size": "32x32",
            "status": "",
        })
    for f in fa.get("fish", []):
        rows.append({"batch": "C", "kind": "fish", "id": f["id"], "name": f.get("name", ""), "files": f"icon_{f['id']}.png", "size": "32x32", "status": ""})
    for a in fa.get("antiques", []):
        rows.append({"batch": "C", "kind": "antique", "id": a["id"], "name": a.get("name", ""), "files": f"icon_{a['id']}.png", "size": "32x32", "status": ""})

    csv_path = OUT / "asset_checklist.csv"
    with csv_path.open("w", encoding="utf-8-sig", newline="") as fp:
        w = csv.DictWriter(fp, fieldnames=["batch", "kind", "id", "name", "files", "size", "status"])
        w.writeheader()
        w.writerows(rows)

    manifest = {
        "style_anchor": [
            "game/art/keys/town_square.png",
            "game/art/keys/garden_dusk.png",
            "game/art/keys/mine_crystal.png",
        ],
        "naming_doc": "docs/art/美术需求清单.md",
        "counts": {
            "crops": len(crops),
            "items": len(items),
            "fish": len(fa.get("fish", [])),
            "antiques": len(fa.get("antiques", [])),
            "checklist_rows": len(rows),
        },
        "drop_into": "game/art/{chars,crops,tiles,buildings,items,enemies,ui,fx}",
    }
    (OUT / "asset_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print("wrote", csv_path, "rows", len(rows))
    print("wrote", OUT / "asset_manifest.json")


if __name__ == "__main__":
    main()
