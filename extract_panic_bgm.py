import zipfile
import os
import shutil

zip_path = r'C:\Users\【RST-11】リバイブ新所沢\OneDrive\デスクトップ\プロジェクト\BGM\越前さん.zip'
target_name = "panic_bgm.mp3"
target_dir = r"assets/audio/bgm/"
target_path = os.path.join(target_dir, target_name)
extract_dir = 'tmp_extract_bgm2'

try:
    if not os.path.exists(target_dir): os.makedirs(target_dir)
    if not os.path.exists(extract_dir): os.makedirs(extract_dir)

    with zipfile.ZipFile(zip_path, 'r') as z:
        found_file = None
        for name in z.namelist():
            try:
                # Assuming the ZIP uses SJIS for Japanese filenames
                decoded_name = name.encode('cp437').decode('cp932')
            except:
                decoded_name = name
            
            if "BGM2 (1).mp3" in decoded_name:
                found_file = name
                print(f"Extracting: {decoded_name}")
                break
        
        if found_file:
            data = z.read(found_file)
            with open(target_path, "wb") as f:
                f.write(data)
            print(f"Successfully extracted to {target_path}")
        else:
            print("BGM2 (1).mp3 not found in ZIP.")

except Exception as e:
    print(f"Error: {e}")
finally:
    if os.path.exists(extract_dir): shutil.rmtree(extract_dir)
