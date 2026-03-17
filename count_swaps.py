
import json

path = r'c:\Users\【RST-11】リバイブ新所沢\OneDrive\デスクトップ\プロジェクト\REC-OFF-AIR\dialogue\ch01_entrance.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

events = data.get('events', [])
count = 0
for i, ev in enumerate(events):
    if ev.get('type') == 'stage_swap':
        count += 1
        print(f"Index {i}: count={count}, scene={ev.get('scene')}")
