import zipfile
import os
import shutil

zip_path = r'C:\Users\【RST-11】リバイブ新所沢\OneDrive\デスクトップ\プロジェクト\BGM\越前さん.zip'
# 日本語ファイル名で直接保存
target_name = "静寂ノ境界.mp3"
target_dir = r"assets/audio/bgm/"
target_path = os.path.join(target_dir, target_name)
extract_dir = 'tmp_extract_final'

try:
    if not os.path.exists(extract_dir): os.makedirs(extract_dir)
    
    # 既存の toilet_bgm.mp3 などを掃除
    old_file = os.path.join(target_dir, "toilet_bgm.mp3")
    if os.path.exists(old_file): os.remove(old_file)

    with zipfile.ZipFile(zip_path, 'r') as z:
        found_file = None
        for name in z.namelist():
            try:
                decoded_name = name.encode('cp437').decode('cp932')
            except:
                decoded_name = name
            
            if "静寂ノ境界" in decoded_name and decoded_name.endswith(".mp3"):
                found_file = name
                print(f"Extracting: {decoded_name}")
                break
        
        if found_file:
            # 抽出
            data = z.read(found_file)
            with open(target_path, "wb") as f:
                f.write(data)
            print(f"Perfectly extracted to {target_path}")
        else:
            print("Not found in ZIP.")

except Exception as e:
    print(f"Error: {e}")
finally:
    if os.path.exists(extract_dir): shutil.rmtree(extract_dir)
