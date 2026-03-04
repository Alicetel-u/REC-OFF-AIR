# REC-OFF-AIR プロジェクトルール

## Godot リソースパスのルール（重要）

- **`ProjectSettings.globalize_path()` を使用禁止**
- `FileAccess.open()`, `FileAccess.file_exists()`, `Image.load_from_file()` 等では `res://` パスをそのまま使うこと
- `globalize_path()` はエクスポートビルド（.pck）で動作しない
- 音声・画像・JSON 等すべてのリソース読み込みに適用

## アセット追加時のルール（重要）

- 音声・画像・モデル等を追加したら、Godotエディタで一度開いて生成される **`.import` ファイルも必ずコミット**すること
- `.import` ファイルがないとCIのWebエクスポートで正しくPCKに含まれない
- 例: `v001.wav` を追加 → `v001.wav.import` も一緒にコミット

## 対話JSON (`dialogue/*.json`) のルール

- ボイス生成スクリプト (`tools/generate_voice_ch01.py`) は対話JSONを**書き換えない**
- 差分ハッシュは `assets/audio/voice/ch01/.voice_hashes.json` に保存
- 対話JSONのフォーマット・構造を壊すツールを作らない

## ボイス生成

- VOICEVOX Speaker ID: 20
- パラメータ: speedScale=1.25, intonationScale=1.5, pitchScale=0.02
- 末尾無音トリミング: threshold=2000, margin=40ms
- ポーズ短縮: pause_mora.vowel_length max=0.15s, prePhonemeLength=0.05, postPhonemeLength=0.05
- セリフ編集後は必ず `python tools/fix_voice_wait.py --validate-only` でバリデーション実行
- 発音修正: TIKTOK→ティックトック / 廃村→はいそん / お札→おふだ
- 出力先: `assets/audio/voice/ch01/v001.wav` 〜

## コミット・デプロイ前チェックリスト（重要・必ず守る）

コミットやプッシュを実行する前に、以下を**全て**確認すること。漏れがあると他PCでビルドが壊れる。

1. **WAV変更時**: `godot.exe --headless --import` で再import → `.godot/imported/` に新しい `.sample` が生成されたことを確認 → `.import` ファイルに差分があればコミットに含める
2. **設定値変更時**: コードの設定値を変えたら、このCLAUDE.mdの該当セクションも**同じコミット内で**更新する
3. **バリデーション**: `python tools/fix_voice_wait.py --validate-only` を実行し、致命的な警告がないことを確認
4. **1コミットで完結**: 関連する変更は全て同じコミットに含める（コード＋ドキュメント＋アセット＋.importファイル）。後から「忘れてた」で追加コミットしない
5. **git status最終確認**: 未追跡・未ステージのファイルに漏れがないか確認してからコミット
