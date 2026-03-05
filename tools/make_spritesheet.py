"""
bus_frames の連番PNGを1枚のSpriteSheetに変換するツール
- 760x428 → 380x214 に縮小
- 10列 x 5行 = 最大50フレーム分（46フレーム使用）
- 出力: assets/video/bus_spritesheet.png
"""

import os
import sys
from PIL import Image

FRAMES_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "video", "bus_frames")
OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "video", "bus_spritesheet.png")

FRAME_W = 380
FRAME_H = 214
COLS = 10
ROWS = 5

def main():
    # フレーム収集
    frames = []
    idx = 1
    while True:
        path = os.path.join(FRAMES_DIR, f"frame_{idx:03d}.png")
        if not os.path.exists(path):
            break
        frames.append(path)
        idx += 1

    if not frames:
        print("ERROR: フレームが見つかりません")
        sys.exit(1)

    print(f"フレーム数: {len(frames)}")
    print(f"出力サイズ: {COLS * FRAME_W}x{ROWS * FRAME_H} ({COLS}列x{ROWS}行)")
    print(f"フレームサイズ: {FRAME_W}x{FRAME_H}")

    if len(frames) > COLS * ROWS:
        print(f"WARNING: フレーム数({len(frames)})がグリッド容量({COLS * ROWS})を超えています")
        frames = frames[:COLS * ROWS]

    # SpriteSheet生成
    sheet = Image.new("RGB", (COLS * FRAME_W, ROWS * FRAME_H), (0, 0, 0))

    for i, fpath in enumerate(frames):
        col = i % COLS
        row = i // COLS
        img = Image.open(fpath).resize((FRAME_W, FRAME_H), Image.LANCZOS)
        sheet.paste(img, (col * FRAME_W, row * FRAME_H))
        if (i + 1) % 10 == 0:
            print(f"  {i + 1}/{len(frames)} 処理済み")

    sheet.save(OUTPUT_PATH, optimize=True)
    size_kb = os.path.getsize(OUTPUT_PATH) / 1024
    print(f"\n出力: {OUTPUT_PATH}")
    print(f"サイズ: {size_kb:.0f} KB")
    print(f"フレーム数: {len(frames)}")

    # 旧フレームの合計サイズ
    old_total = sum(os.path.getsize(p) for p in frames)
    print(f"旧合計: {old_total / 1024 / 1024:.1f} MB → 新: {size_kb / 1024:.1f} MB")
    print(f"削減率: {(1 - size_kb * 1024 / old_total) * 100:.0f}%")


if __name__ == "__main__":
    main()
