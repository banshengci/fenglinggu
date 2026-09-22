# -*- coding: utf-8 -*-
"""行走帧质量审计：检查每个角色每个方向的 4 帧是否「同大小、同脚底线」。

判定口径：
  1) 帧覆盖率过低（< 8%）→ 疑似空帧
  2) 同一方向 4 帧的高度极差 > 18% → 帧间抖动/残帧混入
  3) 同一角色 4 个方向的平均高度极差 > 25% → 板图某行画错/被切
  4) 脚底未落在画布底边（底部 6px 内无前景）→ 锚点漂移
"""
import os
import re

import numpy as np
from PIL import Image

WALK = r"D:\xinxiangmu\youxi\game\art\chars\walk"
DIRS = ["down", "left", "right", "up"]

pat = re.compile(r"^(?P<char>.+?)_(?P<dir>down|left|right|up)_(?P<i>\d{2})$")


def stats(path):
    im = Image.open(path).convert("RGBA")
    a = np.asarray(im)
    alpha = a[..., 3]
    cov = float((alpha > 32).mean())
    ys, xs = np.where(alpha > 32)
    if len(ys) == 0:
        return cov, 0, 0, im.height
    h = int(ys.max() - ys.min() + 1)
    w = int(xs.max() - xs.min() + 1)
    foot = int(ys.max())                     # 前景最低行
    return cov, w, h, foot


def main():
    files = sorted(f for f in os.listdir(WALK) if f.endswith(".png"))
    chars = {}
    for f in files:
        m = pat.match(f[:-4])
        if not m:
            continue
        chars.setdefault(m.group("char"), {}).setdefault(m.group("dir"), []).append(f)

    out = ["=== 行走帧审计  (%d 个文件) ===" % len(files), ""]
    problems = []
    for ch in sorted(chars):
        out.append("--- %s ---" % ch)
        dir_h = {}
        for d in DIRS:
            fs = sorted(chars[ch].get(d, []))
            if not fs:
                out.append("  %-6s MISSING" % d)
                problems.append("%s %s 缺帧" % (ch, d))
                continue
            rows = []
            for f in fs:
                cov, w, h, foot = stats(os.path.join(WALK, f))
                rows.append((f, cov, w, h, foot))
            hs = np.array([r[3] for r in rows], dtype=float)
            fs_ = np.array([r[4] for r in rows], dtype=float)
            rng = (hs.max() - hs.min()) / max(1.0, hs.mean())
            foot_rng = fs_.max() - fs_.min()
            flag = ""
            if rng > 0.18:
                flag += " [高度抖动 %.0f%%]" % (rng * 100)
                problems.append("%s %s 帧高极差 %.0f%%" % (ch, d, rng * 100))
            if foot_rng > 6:
                flag += " [脚底漂移 %.0fpx]" % foot_rng
                problems.append("%s %s 脚底漂移 %.0fpx" % (ch, d, foot_rng))
            for f, cov, w, h, foot in rows:
                mark = ""
                if cov < 0.08:
                    mark = "  <== 疑似空帧 cov=%.3f" % cov
                    problems.append("%s 疑似空帧 cov=%.3f" % (f, cov))
                out.append("    %-32s cov=%.3f %3dx%3d foot=%3d%s" % (f, cov, w, h, foot, mark))
            out.append("    %-32s 高度极差 %.0f%%  脚底极差 %.0fpx%s"
                       % ("[%s 小计]" % d, rng * 100, foot_rng, flag))
            dir_h[d] = float(hs.mean())
        if len(dir_h) == 4:
            v = np.array(list(dir_h.values()))
            r = (v.max() - v.min()) / max(1.0, v.mean())
            flag = ""
            if r > 0.25:
                flag = "  <== 方向间高度差 %.0f%%，可能某行画错" % (r * 100)
                problems.append("%s 方向间高度极差 %.0f%%" % (ch, r * 100))
            out.append("    [方向均值] " + " ".join("%s=%.0f" % (d, dir_h[d]) for d in DIRS if d in dir_h) + flag)
        out.append("")

    out.append("=== 问题汇总 (%d) ===" % len(problems))
    for p in problems:
        out.append("  - " + p)
    if not problems:
        out.append("  无")
    txt = "\n".join(out)
    open(r"D:\xinxiangmu\youxi\docs\art\_walk_audit.txt", "w", encoding="utf-8").write(txt)
    print("problems %d" % len(problems))


if __name__ == "__main__":
    main()
