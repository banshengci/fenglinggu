#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""行走帧板图切片器：规则网格切格 + **统一缩放** + **脚底对齐**。

与 grid_slice.py 的区别（关键）：
  grid_slice 每格各自 fit 到正方形，帧与帧缩放不同 → 播放时会「呼吸抖动」，
  且角色高 > 宽时正方形裁切会丢掉脚底基准线。
  本脚本改为：
    1) 按 cols x rows 规则网格切格；
    2) 每格求前景 bbox；
    3) 用**同一张板全部格子的最大 bbox** 算一个统一 scale；
    4) 输出固定画布 out_w x out_h，每帧按 **底边对齐 + 水平居中** 放置。
  → 同一角色的 16 帧大小一致、脚在同一条线上，可直接做帧动画。

用法: python slice_walk.py <jobs.json>
job:
{
  "source": "...", "out_dir": "...",
  "names": ["player_down_00", ...],   # 行优先（先第 1 行 4 个，再第 2 行...）
  "cols": 4, "rows": 4,
  "out_w": 192, "out_h": 288,
  "tol": 25, "fill": 0.92, "margin_frac": 0.06
}
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage


def border_bg(arr):
    h, w, _ = arr.shape
    k = max(3, min(h, w) // 200)
    border = np.concatenate([
        arr[:k].reshape(-1, 3), arr[-k:].reshape(-1, 3),
        arr[:, :k].reshape(-1, 3), arr[:, -k:].reshape(-1, 3),
    ])
    return np.median(border, axis=0)


def fg_bbox(cell_rgb, tol, keep_frac=0.15):
    """返回格内**主体**的 bbox (x0,y0,x1,y1)，全背景返回 None。

    两个反向的坑，都要避：
      A) 网格切格时相邻行角色的顶部/底部会溢进本格，成为与主体不相连的小碎片
         —— 用整格前景会把 bbox 撑大，并把残片一起裁进输出帧。
      B) 但角色自身也可能被背景近似色（浅色衣物贴纸奶油底）断成上下两半，
         只取「最大连通域」会丢掉头或腿（down 行实测就是这样）。
    折中：先求最大域面积 A，再把所有面积 >= A*keep_frac 的域合并成一个 bbox。
    实测 keep_frac=0.15 能同时避开 A（溢入残片约为主体 0.5%）和 B（断裂的
    上半身约为主体 73%）。
    """
    arr = np.asarray(cell_rgb).astype(np.int16)
    bg = border_bg(arr)
    dist = np.abs(arr - bg).sum(axis=2)
    mask = dist > tol * 3
    mask = ndimage.binary_opening(mask, np.ones((3, 3)))
    lbl, n = ndimage.label(mask)
    if n == 0:
        return None
    objs = ndimage.find_objects(lbl)
    doms = []
    for i, sl in enumerate(objs):
        if sl is None:
            continue
        doms.append((int((lbl[sl] == (i + 1)).sum()), sl))
    if not doms:
        return None
    max_a = max(a for a, _ in doms)
    keep = [sl for a, sl in doms if a >= max_a * keep_frac]
    x0 = min(sl[1].start for sl in keep)
    x1 = max(sl[1].stop for sl in keep)
    y0 = min(sl[0].start for sl in keep)
    y1 = max(sl[0].stop for sl in keep)
    return int(x0), int(y0), int(x1), int(y1)


def alpha_from_bg(cell, tol):
    arr = np.asarray(cell.convert("RGB")).astype(np.int16)
    bg = border_bg(arr)
    cand = np.abs(arr - bg).sum(axis=2) < tol * 3
    lbl, n = ndimage.label(cand)
    if n == 0:
        return None
    bl = set(lbl[0, :].tolist()) | set(lbl[-1, :].tolist()) \
        | set(lbl[:, 0].tolist()) | set(lbl[:, -1].tolist())
    bl.discard(0)
    if not bl:
        return None
    alpha = np.where(np.isin(lbl, list(bl)), 0, 255).astype(np.uint8)
    a_img = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.6))
    out = cell.convert("RGBA")
    out.putalpha(a_img)
    return out


def run_job(job):
    src = os.path.normpath(job["source"])
    out_dir = os.path.normpath(job["out_dir"])
    names = job["names"]
    cols = int(job.get("cols", 4))
    rows = int(job.get("rows", 4))
    out_w = int(job.get("out_w", 192))
    out_h = int(job.get("out_h", 288))
    tol = float(job.get("tol", 25))
    fill = float(job.get("fill", 0.92))
    margin = float(job.get("margin_frac", 0.06))
    keep_frac = float(job.get("keep_frac", 0.15))

    if not os.path.exists(src):
        return ["MISSING\t%s" % src]
    im = Image.open(src).convert("RGB")
    W, H = im.size
    os.makedirs(out_dir, exist_ok=True)

    # ---- 1) 切格 + 求 bbox ----
    cells = []          # (name, PIL crop, bbox or None)
    idx = 0
    for r in range(rows):
        y0, y1 = H * r // rows, H * (r + 1) // rows
        for c in range(cols):
            x0, x1 = W * c // cols, W * (c + 1) // cols
            if idx >= len(names):
                break
            cell = im.crop((x0, y0, x1, y1))
            bb = fg_bbox(cell, tol, keep_frac)
            cells.append((names[idx], cell, bb))
            idx += 1

    res = ["BOARD\t%s\t%dx%d\tgrid %dx%d\tdetected %d/%d"
           % (os.path.basename(src), W, H, cols, rows,
              sum(1 for _, _, bb in cells if bb), len(cells))]

    good = [(n, c, bb) for n, c, bb in cells if bb is not None]
    if not good:
        return res + ["FATAL\tno foreground found"]

    # ---- 2) 统一 scale：用全部格子的最大 bbox（取 90 分位抗异常格） ----
    ws = np.array([bb[2] - bb[0] for _, _, bb in good], dtype=float)
    hs = np.array([bb[3] - bb[1] for _, _, bb in good], dtype=float)
    max_w = float(np.percentile(ws, 90))
    max_h = float(np.percentile(hs, 90))
    # 关键：实际缩放的是加了 margin 的 sub，不是裸 bbox。若按裸 bbox 算 scale，
    # 再加 margin 裁切，最大那帧就会撑破画布（实测 grandpa_lin 有帧超出 15px）。
    eff_w = max_w * (1.0 + 2.0 * margin)
    eff_h = max_h * (1.0 + 2.0 * margin)
    scale = min(out_w * fill / eff_w, out_h * fill / eff_h)
    res.append("SCALE\tmaxW=%.0f maxH=%.0f eff=%.0fx%.0f scale=%.4f"
               % (max_w, max_h, eff_w, eff_h, scale))

    # ---- 3) 逐帧输出：统一缩放 + 底边对齐 + 水平居中 ----
    for name, cell, bb in cells:
        if bb is None:
            res.append("EMPTY\t%s" % name)
            continue
        mx = int((bb[2] - bb[0]) * margin)
        my = int((bb[3] - bb[1]) * margin)
        sub = cell.crop((max(0, bb[0] - mx), max(0, bb[1] - my),
                         min(cell.width, bb[2] + mx), min(cell.height, bb[3] + my)))
        rgba = alpha_from_bg(sub, tol)
        if rgba is None:
            rgba = sub.convert("RGBA")
        nw = max(1, int(round(rgba.width * scale)))
        nh = max(1, int(round(rgba.height * scale)))
        rgba = rgba.resize((nw, nh), Image.LANCZOS)

        canvas = Image.new("RGBA", (out_w, out_h), (0, 0, 0, 0))
        # 底边对齐：让**角色 bbox 的底边**（脚下沿）落在画布底边，而不是让含 margin
        # 的 sub 底边落地。margin 是 bbox 高度的固定比例，各帧 bbox 高不同时 margin
        # 像素数也不同，按 sub 落地会让脚底上下漂 7~10px（实测 chapo / xiaoman）。
        mb = my * scale                       # 底部 margin 缩放后的像素数
        px = max(0, int(round((out_w - nw) / 2.0)))
        py = int(round(out_h - 1 - nh + mb))
        if py < 0:                            # 兜底：仍超出画布则贴顶居中
            nw = min(nw, out_w)
            nh = min(nh, out_h)
            rgba = rgba.resize((nw, nh), Image.LANCZOS)
            px = max(0, (out_w - nw) // 2)
            py = max(0, (out_h - nh) // 2)
        canvas.paste(rgba, (px, py), rgba)
        canvas.save(os.path.join(out_dir, "%s.png" % name))
        res.append("OK\t%s\t%dx%d -> %dx%d @(%d,%d)" % (name, sub.width, sub.height, nw, nh, px, py))

    return res


def main():
    jobs = json.load(open(sys.argv[1], encoding="utf-8"))
    lines = []
    for j in jobs:
        lines += run_job(j)
    out = os.path.splitext(sys.argv[1])[0] + ".report.txt"
    open(out, "w", encoding="utf-8").write("\n".join(lines))
    print("\n".join(lines))


if __name__ == "__main__":
    main()
