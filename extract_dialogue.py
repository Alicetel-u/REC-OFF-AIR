import json
import os

dialogue_dir = r"c:\Users\【RST-11】リバイブ新所沢\OneDrive\デスクトップ\プロジェクト\REC-OFF-AIR\dialogue"
output_file = r"c:\Users\【RST-11】リバイブ新所沢\OneDrive\デスクトップ\プロジェクト\REC-OFF-AIR\dialogue_list.md"

files = [
    "opening.json",
    "ch01_entrance.json",
    "ch02_haison_souko.json",
    "ch02_haison_souko_found.json",
    "ch02_haison_souko_free.json",
    "ch02_haison_souko_exit.json",
    "ch02_mura_tansaku_start.json",
    "ch02_mura_tansaku.json",
    "ch02_mura_item_a.json",
    "ch02_mura_item_b.json",
    "ch02_mura_item_c.json",
    "ch02_mura_tansaku_exit.json",
    "ch02_mura_bad_voices.json",
    "bad_eien.json"
]

with open(output_file, 'w', encoding='utf-8') as out:
    out.write("# REC-OFF-AIR 全台本（セリフ一覧）\n\n")
    
    for filename in files:
        path = os.path.join(dialogue_dir, filename)
        if not os.path.exists(path):
            continue
            
        out.write(f"## ファイル: {filename}\n\n")
        
        try:
            with open(path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                events = data.get("events", [])
                
                count = 0
                for ev in events:
                    if ev.get("type") == "say":
                        text = ev.get("text", "").replace("\n", " ").strip()
                        voice = ev.get("voice", "-")
                        if text:
                            out.write(f"- **{voice}**: {text}\n")
                            count += 1
                
                if count == 0:
                    out.write("*（セリフなし）*\n")
        except Exception as e:
            out.write(f"エラー: {str(e)}\n")
            
        out.write("\n---\n\n")

print(f"Exported to {output_file}")
