# -*- coding: utf-8 -*-
"""对 33 张「RGB 无 alpha」的建筑/NPC/UI 图批量抠透明底。

策略：
- 逐图估算四边背景色（中位数），抠掉「与边框连通」的背景连通域。
- 自动按图分类容差：建筑/NPC 主体大、背景干净 → tol 可小；
  面板/按钮/拼板类带纸色底 → tol 需大一些以吃透纸底渐变。
- 抠完写 _alpha_report.txt 汇报每张的透明像素占比，便于目检。
"""
import os
import glob
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = r"D:\xinxiangmu\youxi\game\art"
OUT = r"D:\xinxiangmu\youxi\docs\art\_alpha_report.txt"

# 分档容差：文件名前缀 -> tol
GROUPS = [
    ("buildings/", 90),
    ("chars/", 90),
    ("ui/panel_9s", 60),
    ("ui/ui_buttons", 60),
    ("ui/logo_emblem", 75),
    ("ui/app_icon", 75),
    ("tiles/prop_fence_set", 70),
    ("tiles/prop_dock_set", 70),
]


def tol_for(rel):
    for pre, t in GROUPS:
        if rel.replace("\\", "/").startswith(pre):
            return t
    return 80


def bg_median(arr):
    h, w, _ = arr.shape
    k = max(4, min(h, w) // 120)
    border = np.concatenate([
        arr[:k].reshape(-1, 3), arr[-k:].reshape(-1, 3),
        arr[:, :k].reshape(-1, 3), arr[:, -k:].reshape(-1, 3),
    ])
    return np.median(border, axis=0)


def process(path, rel, tol):
    im = Image.open(path)
    if im.mode in ("RGBA", "LA"):
        return "SKIP-already-alpha", 0.0
    im = im.convert("RGB")
    arr = np.asarray(im).astype(np.int16)
    bg = bg_median(arr)
    dist = np.abs(arr - bg).sum(axis=2)
    cand = dist < tol * 3
    lbl, n = ndimage.label(cand)
    if n == 0:
        return "SKIP-no-bg", 0.0
    border_labels = (set(lbl[0, :].tolist()) | set(lbl[-1, :].tolist())
                     | set(lbl[:, 0].tolist()) | set(lbl[:, -1].tolist()))
    border_labels.discard(0)
    if not border_labels:
        return "SKIP-bg-not-connected", 0.0
    truebg = np.isin(lbl, list(border_labels))
    alpha = np.where(truebg, 0, 255).astype(np.uint8)
    a_img = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.8))
    rgba = im.convert("RGBA")
    rgba.putalpha(a_img)
    rgba.save(path)
    transparent = float(truebg.sum()) / float(arr.shape[0] * arr.shape[1])
    return "OK", transparent


def main():
    targets = []
    for d in ["buildings", "chars"]:
        targets += sorted(glob.glob(os.path.join(ROOT, d, "*.png")))
    for name in ["panel_9s", "ui_buttons", "logo_emblem", "app_icon"]:
        targets.append(os.path.join(ROOT, "ui", name + ".png"))
    for name in ["prop_fence_set", "prop_dock_set"]:
        targets.append(os.path.join(ROOT, "tiles", name + ".png"))

    log = []
    for p in targets:
        if not os.path.exists(p):
            log.append("MISSING\t%s" % p)
            continue
        rel = os.path.relpath(p, ROOT).replace("\\", "/")
        try:
            st, tr = process(p, rel, tol_for(rel))
            log.append("%-24s %-8s transparent=%.1f%%" % (rel, st, tr * 100))
        except Exception as ex:  # noqa: BLE001
            log.append("ERR\t%s\t%s" % (rel, ex))
    open(OUT, "w", encoding="utf-8").write("\n".join(log))
    print("done", len(targets))


if __name__ == "__main__":
    main()
