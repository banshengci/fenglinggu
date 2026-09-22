#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
《风铃谷》美术后处理：裁掉右下角 AI 水印 + 规范命名 + 归入正确目录。

用法:
    python art_postprocess.py <map.json>

map.json 格式:
[
  {"source": "D:/.../raw_gen.png", "target": "D:/.../building_cabin.png"},
  ...
]

行为:
    - 打开 source，裁掉底部 bottom_frac（默认 10%）的水印带，保存为 target。
    - 若 source 与 target 不同路径，删除 source 原始文件。
    - 生成同目录 <map>.report.txt 汇报结果。
"""
import json
import os
import sys

from PIL import Image


def crop_bottom(src: str, dst: str, bottom_frac: float = 0.10):
    im = Image.open(src)
    w, h = im.size
    keep = int(round(h * (1.0 - bottom_frac)))
    mode = im.mode
    im2 = im.crop((0, 0, w, keep))
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    im2.save(dst)
    return w, keep, mode


def main():
    if len(sys.argv) < 2:
        print("usage: python art_postprocess.py <map.json>")
        sys.exit(1)

    map_path = sys.argv[1]
    with open(map_path, "r", encoding="utf-8") as f:
        entries = json.load(f)

    report = []
    for e in entries:
        src = os.path.normpath(e["source"])
        dst = os.path.normpath(e["target"])
        frac = float(e.get("bottom_frac", 0.10))
        if not os.path.exists(src):
            report.append(f"MISSING\t{src}")
            continue
        try:
            w, h, mode = crop_bottom(src, dst, frac)
            report.append(f"OK\t{os.path.basename(dst)}\t{w}x{h}\t{mode}")
            if os.path.abspath(src) != os.path.abspath(dst):
                os.remove(src)
        except Exception as ex:  # noqa: BLE001
            report.append(f"ERR\t{src}\t{ex}")

    out = os.path.splitext(map_path)[0] + ".report.txt"
    with open(out, "w", encoding="utf-8") as f:
        f.write("\n".join(report))
    print("\n".join(report))


if __name__ == "__main__":
    main()
