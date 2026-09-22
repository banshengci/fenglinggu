#!/usr/bin/env python3
"""裁掉生成图右下角的水印条，并按美术规范重命名落位。

用法:
    python strip_watermark.py

背景:
    出图模型会在右下角烧入「AI 生成」水印。美术需求清单 §0 禁止水印、
    §14 要求无杂边，因此统一从底部裁掉一条并另存为规范文件名。

默认裁掉底部 max(100, 高度*0.09) 像素（水印位于最底部两行，留足安全边）。
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

from PIL import Image

KEYS_DIR = Path(r"D:\xinxiangmu\youxi\game\art\keys")
STAGE_DIR = Path(r"D:\xinxiangmu\youxi\game\art\_stage")

# (源文件, 目标文件名)
JOBS: list[tuple[Path, str]] = [
    (KEYS_DIR / "Storybook_gouache_illustration_2026-09-22T07-48-41.png", "belltower_plaza.png"),
    (KEYS_DIR / "Storybook_gouache_character_po_2026-09-22T07-48-39.png", "player_portrait.png"),
    (KEYS_DIR / "Storybook_botanical_reference__2026-09-22T07-48-40.png", "crops_plate.png"),
    (KEYS_DIR / "Storybook_gouache_landscape__w_2026-09-22T07-48-39.png", "lake_shore.png"),
    (KEYS_DIR / "Storybook_gouache_landscape__w_2026-09-22T07-48-42.png", "pasture_slope.png"),
    (STAGE_DIR / "Hand_painted_storybook_gouache_2026-09-22T07-49-44.png", "meadow_ridges.png"),
]

STRIP_MIN = 100
STRIP_RATIO = 0.09


def strip_height(height: int) -> int:
    return max(STRIP_MIN, int(round(height * STRIP_RATIO)))


def main() -> int:
    lines: list[str] = []
    failed = 0
    for src, dest_name in JOBS:
        if not src.exists():
            lines.append(f"MISSING  {src}")
            failed += 1
            continue
        dest = KEYS_DIR / dest_name
        with Image.open(src) as im:
            w, h = im.size
            cut = strip_height(h)
            cropped = im.crop((0, 0, w, h - cut))
            cropped.save(dest, "PNG")
            lines.append(f"OK       {dest_name}  {w}x{h} -> {cropped.size[0]}x{cropped.size[1]}")
        # 源文件用规范名落位后即可移除
        if src.parent == KEYS_DIR and src != dest:
            src.unlink()

    report = Path(__file__).with_name("strip_watermark.report.txt")
    report.write_text("\n".join(lines) + f"\nfailed={failed}\n", encoding="utf-8")

    # 清空暂存目录
    if STAGE_DIR.exists():
        shutil.rmtree(STAGE_DIR, ignore_errors=True)

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
