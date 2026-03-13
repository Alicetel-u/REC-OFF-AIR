import json
import os

def update_cache():
    cache_path = 'tools/path-viewer/dialogue_cache.js'
    dialogue_dir = 'dialogue'
    cache = {}
    
    files = [
        'ch01_entrance.json',
        'ch01_haison_souko.json',
        'ch01_haison_souko_found.json',
        'ch02_haison_naibu.json',
        'ch02_yashiki.json',
        'ch03_minka.json',
        'ch04_jinja.json',
        'opening.json'
    ]
    
    for f in files:
        path = os.path.join(dialogue_dir, f)
        if os.path.exists(path):
            print(f"Loading {f}...")
            with open(path, 'r', encoding='utf-8') as jf:
                data = json.load(jf)
                chapter_id = data.get('chapter', f.replace('.json', ''))
                cache[chapter_id] = data
        else:
            print(f"Warning: {f} not found.")
            
    content = 'const DIALOGUE_CACHE = ' + json.dumps(cache, ensure_ascii=False, indent=2) + ';'
    with open(cache_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Successfully updated dialogue_cache.js")

if __name__ == "__main__":
    update_cache()
