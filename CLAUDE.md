# REC-OFF-AIR プロジェクトルール

## Godot リソースパスのルール（重要）

- **`ProjectSettings.globalize_path()` を使用禁止**
- `FileAccess.open()`, `FileAccess.file_exists()`, `Image.load_from_file()` 等では `res://` パスをそのまま使うこと
- `globalize_path()` はエクスポートビルド（.pck）で動作しない
- 音声・画像・JSON 等すべてのリソース読み込みに適用

## 対話JSON (`dialogue/*.json`) のルール

- ボイス生成スクリプト (`tools/generate_voice_ch01.py`) は対話JSONを**書き換えない**
- 差分ハッシュは `assets/audio/voice/ch01/.voice_hashes.json` に保存
- 対話JSONのフォーマット・構造を壊すツールを作らない

## ボイス生成

- VOICEVOX Speaker ID: 20
- パラメータ: speedScale=1.25, intonationScale=1.5, pitchScale=0.02
- 末尾無音トリミング: threshold=300, margin=80ms
- 発音修正: TIKTOK→ティックトック / 廃村→はいそん / お札→おふだ
- 出力先: `assets/audio/voice/ch01/v001.wav` 〜
