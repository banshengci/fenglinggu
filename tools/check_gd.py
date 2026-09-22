# -*- coding: utf-8 -*-
import os
base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DST = os.path.join(base, "game", "scripts", "autoload", "art_id_map.gd")
s = open(DST, encoding="utf-8").read()
lines = s.splitlines()
bad = [l for l in lines if l.count(chr(34)) != 4 or chr(92) in l]
out = []
out.append("entries: %d" % s.count(': "'))
out.append("bad lines: %d" % len(bad))
for l in bad[:5]:
    out.append("  " + l)
out.append("size KB: %.1f" % (len(s.encode()) / 1024.0))
out_path = os.path.join(base, "docs", "art", "_gdcheck.txt")
os.makedirs(os.path.dirname(out_path), exist_ok=True)
open(out_path, "w", encoding="utf-8").write("\n".join(out))
print("\n".join(out))
