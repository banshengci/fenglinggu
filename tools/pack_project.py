# -*- coding: utf-8 -*-
"""把整个项目打包成一个 zip（下班带走 / 交给别人时一键归档）。

用法:
    python tools/pack_project.py                 # 默认输出 ../youxi_<日期>.zip
    python tools/pack_project.py --out X:\a.zip  # 指定输出路径
    python tools/pack_project.py --exclude _stage,keys   # 排除子目录（逗号分隔，相对项目根）

要点:
  - 输出路径必须在项目目录之外，否则会把压缩包自己打包进去（脚本已强制校验）。
  - PNG/JPG/WEBP/ZIP 本身已是压缩格式，用 ZIP_STORED 直接存，省 CPU 且体积几乎不变；
    其余（代码 / 文档 / 数据）用 deflate，体积能压到 1/4 左右。
"""
import os
import sys
import time
import zipfile

ROOT = r"D:\xinxiangmu\youxi"

# 已是压缩格式 -> 直接存，不二次 deflate
STORE_EXT = {".png", ".jpg", ".jpeg", ".webp", ".zip", ".7z", ".gz", ".rar", ".mp4", ".mp3", ".ogg"}

DEFAULT_EXCLUDE_DIRS = [".git", "__pycache__", ".import"]


def parse_args(argv):
    out = None
    exclude = []
    i = 1
    while i < len(argv):
        a = argv[i]
        if a == "--out" and i + 1 < len(argv):
            out = argv[i + 1]
            i += 2
        elif a == "--exclude" and i + 1 < len(argv):
            exclude = [x.strip() for x in argv[i + 1].split(",") if x.strip()]
            i += 2
        else:
            i += 1
    return out, exclude


def main():
    out, exclude = parse_args(sys.argv)
    if out is None:
        out = os.path.join(os.path.dirname(ROOT), "youxi_%s.zip" % time.strftime("%Y%m%d-%H%M"))

    out = os.path.abspath(out)
    root = os.path.abspath(ROOT)
    # 输出必须落在项目外，避免自包含
    if out.lower().startswith(root.lower() + os.sep):
        print("ERROR: 输出路径不能在项目目录内 ->", out)
        return 1
    os.makedirs(os.path.dirname(out), exist_ok=True)

    skip_dirs = set(DEFAULT_EXCLUDE_DIRS) | set(exclude)
    skip_prefix = [os.path.join(root, d).lower() for d in skip_dirs]

    n = 0
    raw = 0
    t0 = time.time()
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for dirpath, dirnames, filenames in os.walk(root):
            dp = dirpath.lower()
            if any(dp == p or dp.startswith(p + os.sep) for p in skip_prefix):
                dirnames[:] = []
                continue
            dirnames[:] = [d for d in dirnames
                           if not any(os.path.join(dirpath, d).lower() == p or
                                      os.path.join(dirpath, d).lower().startswith(p + os.sep)
                                      for p in skip_prefix)]
            for fn in filenames:
                if fn == os.path.basename(out):
                    continue
                p = os.path.join(dirpath, fn)
                try:
                    sz = os.path.getsize(p)
                except OSError:
                    continue
                arc = os.path.relpath(p, os.path.dirname(root))
                ext = os.path.splitext(fn)[1].lower()
                zi = zipfile.ZipInfo.from_file(p, arc)
                zi.compress_type = zipfile.ZIP_STORED if ext in STORE_EXT else zipfile.ZIP_DEFLATED
                with open(p, "rb") as fh:
                    z.writestr(zi, fh.read())
                n += 1
                raw += sz
                if n % 200 == 0:
                    print("  ...%d files" % n)

    dt = time.time() - t0
    zsz = os.path.getsize(out)
    print("packed %d files, %.1f MB -> %s (%.1f MB) in %.0fs"
          % (n, raw / 1048576.0, out, zsz / 1048576.0, dt))
    return 0


if __name__ == "__main__":
    sys.exit(main())
