import zipfile
import os
import shutil

zip_path = r'C:\Users\【RST-11】リバイブ新所沢\OneDrive\デスクトップ\プロジェクト\BGM\越前さん.zip'
target_project_path = r'assets/audio/bgm/toilet_bgm.mp3'
extract_dir = 'tmp_extract'

try:
    if not os.path.exists(extract_dir):
        os.makedirs(extract_dir)

    with zipfile.ZipFile(zip_path, 'r') as z:
        # ZIP内のファイルリストを表示して探し出す
        found_file = None
        for name in z.namelist():
            # 文字化け対策のため、エンコードを考慮しつつ「静寂」や「mp3」を含むファイルを探す
            try:
                # cp932 (Japanese Windows) でリネームされている可能性が高い
                decoded_name = name.encode('cp437').decode('cp932')
            except:
                decoded_name = name
            
            if '静寂' in decoded_name and decoded_name.endswith('.mp3'):
                found_file = name
                print(f"Found target BGM in ZIP: {decoded_name}")
                break
        
        if found_file:
            z.extract(found_file, extract_dir)
            source_path = os.path.join(extract_dir, found_file)
            shutil.copy2(source_path, target_project_path)
            print(f"Successfully updated {target_project_path} from ZIP.")
        else:
            print("Target file '静寂ノ境界.mp3' not found in the ZIP.")

except Exception as e:
    print(f"Error: {e}")
finally:
    if os.path.exists(extract_dir):
        shutil.rmtree(extract_dir)
