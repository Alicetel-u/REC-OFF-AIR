import os
import re

target_dir = r"C:\Users\【RST-11】リバイブ新所沢\OneDrive\デスクトップ\プロジェクト\REC-OFF-AIR\scenes\KiriharaVillageMap"
new_prefix = "res://scenes/KiriharaVillageMap/"

def fix_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # res:// を res://scenes/KiriharaVillageMap/ に置換。ただし二重にならないよう注意
        new_content = re.sub(r'res://(?!scenes/KiriharaVillageMap/)', new_prefix, content)
        
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed: {filepath}")
    except Exception as e:
        print(f"Error in {filepath}: {e}")

for root, dirs, files in os.walk(target_dir):
    for file in files:
        if file.endswith(('.tscn', '.gd', '.import')):
            fix_file(os.path.join(root, file))
