# REC-OFF-AIR プロジェクトルール

## Godot リソースパスのルール（重要）

- **`ProjectSettings.globalize_path()` を使用禁止**
- `FileAccess.open()`, `FileAccess.file_exists()`, `Image.load_from_file()` 等では `res://` パスをそのまま使うこと
- `globalize_path()` はエクスポートビルド（.pck）で動作しない
- 音声・画像・JSON 等すべてのリソース読み込みに適用

## 効果音（SFX）のルール（重要）

- **高音のピコピコ系SFXは使用禁止**
- 禁止カテゴリ: `impactMetal_light_*`, `impactGlass_light_*`, `horror_static/computerNoise_*`
- 代わりに低く重い音を使う: `impactMetal_heavy_*`, `impactMetal_medium_*`, `impactGlass_heavy_*`, `bell/impactBell_heavy_*`, `door/creak*`
- ホラー作品の雰囲気に合う鈍い金属音・軋み音・鐘の音を優先すること

## アセット追加時のルール（重要）

- 音声・画像・モデル等を追加したら、Godotエディタで一度開いて生成される **`.import` ファイルも必ずコミット**すること
- `.import` ファイルがないとCIのWebエクスポートで正しくPCKに含まれない
- 例: `v001.wav` を追加 → `v001.wav.import` も一緒にコミット

## GDScript コーディングルール（重要）

- `var x :=` の型推論は **`abs()`, `sign()`, `clamp()` 等の多態関数と外部 const の掛け算** で失敗する（Godot 4.6）
- 型が曖昧になる式では **明示的に型を書く**: `var x : float = abs(y) * CONST`
- コンパイルエラーはシーン遷移時にフリーズを引き起こすため、`.gd` 変更後は必ず動作確認する

## 対話JSON (`dialogue/*.json`) のルール

- ボイス生成スクリプト (`tools/generate_voice_ch01.py`) は対話JSONを**書き換えない**
- 差分ハッシュは `assets/audio/voice/ch01/.voice_hashes.json` に保存
- 対話JSONのフォーマット・構造を壊すツールを作らない

## ボイス生成

マルチエンジン対応（VOICEVOX / Style-Bert-VITS2）。

### VOICEVOX（デフォルト）
- Speaker ID: 20
- パラメータ: speedScale=1.25, intonationScale=1.5, pitchScale=0.02
- ポーズ短縮: pause_mora.vowel_length max=0.15s, prePhonemeLength=0.05, postPhonemeLength=0.05
- 実行: `python tools/generate_voice_ch01.py`

### Style-Bert-VITS2
- サーバー: `http://127.0.0.1:5000`（起動: `Antigravity_Projects/Style-Bert-VITS2/Server.bat`）
- デフォルトモデル: amitaro / スタイル: Neutral / 話速(length): 0.8
- パラメータ: sdp_ratio=0.2, noise=0.6, noisew=0.8
- 実行: `python tools/generate_voice_ch01.py --engine sbv2`
- モデル指定: `--model jvnv-M1-jp --style Happy`

### 共通設定
- 末尾無音トリミング: threshold=2000, margin=40ms
- セリフ編集後は必ず `python tools/fix_voice_wait.py --validate-only` でバリデーション実行
- 発音修正: TIKTOK→ティックトック / 廃村→はいそん / お札→おふだ
- 出力先: `assets/audio/voice/ch01/v001.wav` 〜

## 自動チェック（pre-commitフック + CI）

漏れ防止のため**2段階の自動チェック**を導入済み。

### pre-commitフック（ローカル）
- **新しいPCでclone後、最初に実行**: `bash tools/setup-hooks.sh`
- **GDScript コンパイルチェック**: `.gd` 変更時に `godot --headless --import` で SCRIPT ERROR を検出 → コミット拒否
- WAV変更時に`.import`がステージされていなければコミット拒否
- dialogue JSON変更時にバリデーション自動実行（CONSECUTIVE_WAIT/LONG_GAP/MISSING_WAVでブロック）
- ボイスツール変更時にCLAUDE.md未更新を警告

### CI（GitHub Actions — 最終防壁）
- PRおよびmaster pushでバリデーション自動実行
- **GDScript コンパイルチェック**: Godot の `--headless --import` で SCRIPT ERROR があればデプロイ停止
- 全WAVに`.import`ファイルがあるか確認
- `fix_voice_wait.py --validate-only` の致命的警告でデプロイ停止

### 手動チェックリスト（フックで防げない項目）
1. **WAV変更時**: `godot.exe --headless --import` で再import → `.import` ファイルに差分があればコミットに含める
2. **設定値変更時**: コードの設定値を変えたら、このCLAUDE.mdの該当セクションも**同じコミット内で**更新する
3. **1コミットで完結**: 関連する変更は全て同じコミットに含める（コード＋ドキュメント＋アセット＋.importファイル）
