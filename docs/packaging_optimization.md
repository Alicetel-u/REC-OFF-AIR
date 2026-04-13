# パッケージ化前の軽量化・最適化チェックリスト

調査日: 2026-04-14

## プロジェクトのサイズ内訳（調査時点）

| カテゴリ | サイズ |
|---|---|
| 3Dモデル（assets/models + Interaction + Inventory） | 354MB |
| 音声（voice 163MB / sfx 55MB / bgm 49MB） | 265MB |
| テクスチャ（assets/textures） | 118MB |
| 動画（OGV 5本） | 44MB |
| フォント（NotoSansCJK-Regular.ttc） | 14MB |
| **未使用確認済みファイル** | **~88MB** |

---

## A. 即効（`deploy.yml` の exclude_filter に追加するだけ）

### 未使用テクスチャ（-16MB）
以下を `exclude_filter` に追加（`_fixed.png` が使用されており、元ファイルは不要）:
- `assets/textures/title_bg.png`（`title_bg.jpg` が使用中）
- `assets/textures/true_bad_miyuki_face.png`（`_fixed.png` が使用中）
- `assets/textures/_2K_202604071403.png`（`_fixed.png` が使用中）
- `assets/textures/_2K_202604071523.png`（`_fixed.png` が使用中）

### 未使用動画（-24MB）
- `assets/video/opm-5.ogv`（20MB）→ 未参照（`opm-5_godot.ogv` が使用中）
- `assets/video/opm-5_godot_silent.ogv`（4MB）→ 未参照

### 未使用BGM（-10MB）
- `assets/audio/bgm/BGM1.mp3`（4.8MB）→ スクリプト・JSON 参照なし
- `assets/audio/bgm/BGM2.mp3`（5.0MB）→ スクリプト・JSON 参照なし
- ⚠️ EntranceDirector が BGM をファイル名文字列で動的ロードするため、除外後は一度フルプレイ確認すること

### 孤立 import ファイル（軽微）
- `assets/audio/bgm/toilet_bgm.mp3.import` → 実ファイルが存在しない孤立 import、削除でOK

---

## B. 短期作業（1〜2時間）

### Main_Restored.tscn 削除（-38MB、リポジトリ削減）
- `scenes/Main_Restored.tscn`（38MB）→ 旧バックアップシーン・未参照
- Git から削除して `.gitignore` に追加するか、`exclude_filter` に追加

### WAV リサンプリング（-46MB ソースサイズ）
- `ch01/` の152本と `ch02/` の116本が **44100Hz** で録音されている（合計268本）
- 他のディレクトリは 24000Hz 済み
- `ffmpeg -ar 24000 -c:a pcm_s16le in.wav out.wav` で一括変換
- AI 音声合成の標準は 24KHz なので品質劣化はほぼなし
- ツール候補: `tools/wav_utils.py` が既存

### Inventory/addons GLB 重複整理（要 md5 確認、潜在 -43MB）
- `Inventory/` と `addons/` に同名・同サイズの GLB が存在する疑惑:
  - `便器.glb`(11MB) / `トイレドアノブl.glb`(11MB) / `トイレットペーパー.glb`(11MB) / `蛍光灯glb.glb`(9.4MB)
- `md5sum` で一致確認後、`Inventory/` 側を削除して `addons/` に統一

---

## C. 検討が必要（品質トレードオフあり）

### テクスチャ圧縮設定変更
- 現状: 全テクスチャが `compress/mode=0`（Lossless）
- 変更候補: UI画像を `compress/mode=2`（VRAM）または Lossy に変更
- GL Compatibility での WebGL2 サポートが限定的なため、必ず動作確認
- 演出用の立ち絵・紙芝居画像はロッシーで劣化が目立ちやすいので注意

### フォントの Git 管理除外（-14MB リポジトリ）
- `NotoSansCJK-Regular.ttc` は CI で `sudo apt-get install fonts-noto-cjk` → コピーしている
- Git から削除し CI に任せれば -14MB だが、ローカル開発者への周知が必要

---

## D. やらなくていいこと

| 作業 | 理由 |
|---|---|
| GDScript コメント削除 | PCK にはバイトコードのみ、コメントはサイズに無関係 |
| WAV → OGG 全変換 | IMA ADPCM で既に4:1圧縮済み・797ファイルの変換コストが高い |
| `.bak` ファイル削除 | Godot は `.bak` を PCK に含めない |
| NotoSansCJK サブセット化 | 使用漢字の完全なリストアップが必要で文字化けリスクあり |

---

## CI 除外フィルターの場所

`.github/workflows/deploy.yml` の `exclude_filter` に追加する。

現在すでに除外済み（PCKに含まれない）:
- `killers/` フォルダ全体（FBX+GLB）
- 未使用 female FBX 多数（Character_Female_*.fbx 等）
- `bus_arrival.ogv` / `bus_arrival.webm` / `bus_arrival_audio.ogg`

## 優先度別ロードマップ

```
即効 (deploy.yml修正のみ・リスクゼロ):
  未使用テクスチャ4本を exclude_filter  → -16MB
  opm-5.ogv / opm-5_godot_silent.ogv   → -24MB
  BGM1.mp3 / BGM2.mp3                  → -10MB
  小計: -50MB

短期 (1〜2時間):
  Main_Restored.tscn 削除              → -38MB (リポジトリ)
  44100Hz WAV 268本を 24000Hz に変換   → -46MB (ソース)
  Inventory/addons 重複整理 (要確認)   → 最大 -43MB

中期 (品質確認必要):
  テクスチャ圧縮設定変更               → 変動
  フォントの Git 管理除外              → -14MB (リポジトリ)
```
