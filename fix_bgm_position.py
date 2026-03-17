import os

scene_path = r'scenes/PublicToiletStage.tscn'
temp_path = r'scenes/PublicToiletStage.tscn.tmp'

target_res = 'res://assets/audio/bgm/静寂ノ境界.mp3'
bgm_res_line = f'[ext_resource type="AudioStream" path="{target_res}" id="10_bgm"]\n'
bgm_node_lines = [
    '\n[node name="BGM" type="AudioStreamPlayer" parent="."]\n',
    'stream = ExtResource("10_bgm")\n',
    'autoplay = true\n',
    'bus = &"BGM"\n'  # BGMバスが設定されている場合を想定（なければデフォルトへ）
]

try:
    with open(scene_path, 'r', encoding='utf-8') as f_in:
        lines = f_in.readlines()

    # 既存のBGM関連をすべてクリア
    cleaned_lines = []
    for line in lines:
        if target_res in line: continue
        if '[node name="BGM"' in line: continue
        if 'stream = ExtResource("10_bgm")' in line: continue
        # 末尾に追加したautoplay等も、BGMノード特定は難しいため
        # 一旦そのままにして、ノード本体を前に持ってくることで上書き的に処理
        cleaned_lines.append(line)

    final_lines = []
    res_inserted = False
    node_inserted = False

    for line in cleaned_lines:
        final_lines.append(line)
        
        # 1. リソース定義の挿入 (Texture2D id="9_g1jtn" の後ろ)
        if 'id="9_g1jtn"' in line and not res_inserted:
            final_lines.append(bgm_res_line)
            res_inserted = True
            
        # 2. ノードの挿入 (ルートノード ToiletWalls の後ろ)
        if '[node name="ToiletWalls"' in line and not node_inserted:
            final_lines.extend(bgm_node_lines)
            node_inserted = True

    with open(temp_path, 'w', encoding='utf-8') as f_out:
        for line in final_lines:
            f_out.write(line)

    os.replace(temp_path, scene_path)
    print("BGM node moved to root sub-level successfully.")

except Exception as e:
    print(f"Error: {e}")
    if os.path.exists(temp_path):
        os.remove(temp_path)
