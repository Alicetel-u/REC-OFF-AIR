import json
import os

# パスの設定
base_dir = r"c:\Users\【RST-11】リバイブ新所沢\OneDrive\デスクトップ\プロジェクト\REC-OFF-AIR"
scenario_path = os.path.join(base_dir, "dialogue", "ch01_entrance.json")
sfx_dir = os.path.join(base_dir, "assets", "audio", "sfx")
output_path = os.path.join(base_dir, "tools", "sound-dashboard", "data.js")

print(f"Reading scenario: {scenario_path}")

# シナリオの読み込み (5000行すべて)
with open(scenario_path, 'r', encoding='utf-8') as f:
    scenario = json.load(f)

print(f"Scanning SFX directory: {sfx_dir}")

# SFXファイルのスキャン
sfx_data = {}
# カテゴリリスト（フォルダ直下のディレクトリ）
categories = [d for d in os.listdir(sfx_dir) if os.path.isdir(os.path.join(sfx_dir, d))]

for cat in categories:
    cat_path = os.path.join(sfx_dir, cat)
    sfx_data[cat] = []
    for root, _, files in os.walk(cat_path):
        for file in files:
            if file.endswith(('.mp3', '.wav', '.ogg')):
                # カテゴリ以下の相対パスを取得
                rel = os.path.relpath(os.path.join(root, file), cat_path).replace("\\", "/")
                sfx_data[cat].append(rel)

# JSファイルの生成
with open(output_path, 'w', encoding='utf-8') as f:
    f.write("// 自動生成されたデータファイル (全5000行超)\n")
    f.write("const SCENARIO_DATA = ")
    json.dump(scenario, f, ensure_ascii=False, indent=2)
    f.write(";\n\n")
    
    # カテゴリマッピングも自動生成
    cat_map = {cat: f"res://assets/audio/sfx/{cat}" for cat in categories}
    f.write("const SOUND_CATEGORIES = ")
    json.dump(cat_map, f, ensure_ascii=False, indent=2)
    f.write(";\n\n")
    
    f.write("const SOUND_FILES = ")
    json.dump(sfx_data, f, ensure_ascii=False, indent=2)
    f.write(";\n")

print(f"Successfully generated {output_path}")
print(f"Total events loaded: {len(scenario['events'])}")
