"""dialogue_cache.js を再生成するスクリプト
Usage: python tools/path-viewer/update_cache.py
"""
import json, os, glob

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
DIALOGUE_DIR = os.path.join(ROOT, "dialogue")
OUT = os.path.join(os.path.dirname(__file__), "dialogue_cache.js")

cache = {}
for f in sorted(glob.glob(os.path.join(DIALOGUE_DIR, "*.json"))):
    name = os.path.splitext(os.path.basename(f))[0]
    with open(f, "r", encoding="utf-8") as fp:
        cache[name] = json.load(fp)

out = "const DIALOGUE_CACHE = " + json.dumps(cache, ensure_ascii=False, separators=(",", ":")) + ";\n"
with open(OUT, "w", encoding="utf-8") as fp:
    fp.write(out)

print(f"Generated dialogue_cache.js: {len(cache)} files, {len(out)} bytes")
