import os

scene_path = r'scenes/PublicToiletStage.tscn'
temp_path = r'scenes/PublicToiletStage.tscn.tmp'

target_res = 'res://assets/audio/bgm/静寂ノ境界.mp3'
target_node = '[node name="BGM"'

try:
    with open(scene_path, 'r', encoding='utf-8') as f_in, open(temp_path, 'w', encoding='utf-8') as f_out:
        skip = False
        for line in f_in:
            if target_res in line:
                continue
            if target_node in line:
                skip = True
                continue
            if skip and (line.startswith('stream =') or line.startswith('autoplay =') or line.startswith('bus =')):
                continue
            if skip and line.strip() == "":
                skip = False
                continue
            if skip and line.startswith('['): # 次のノードが始まったらスキップ終了
                skip = False
            
            if not skip:
                f_out.write(line)

    os.replace(temp_path, scene_path)
    print("Redundant BGM node removed from scene.")
except Exception as e:
    print(f"Error: {e}")
