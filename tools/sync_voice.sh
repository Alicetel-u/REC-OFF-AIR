#!/bin/bash
# エディターからダウンロードしたJSONを同期 + 音声差分生成 + 不要ファイル削除
# 使い方: Claude Codeに「音声生成して」と言うだけ

PROJ="$(cd "$(dirname "$0")/.." && pwd)"
DL_DIR="/c/Users/【RST-9】リバイブ新所沢/Downloads"
DIALOGUE="$PROJ/dialogue/ch01_entrance.json"
VOICE_DIR="$PROJ/assets/audio/voice/ch01"

echo "=== REC:OFF:AIR 音声同期 ==="

# 1. ダウンロードフォルダからJSONを取得
DL_FILE="$DL_DIR/ch01_entrance.json"
if [ ! -f "$DL_FILE" ]; then
  echo "ERROR: $DL_FILE が見つかりません"
  exit 1
fi

# 変更前のvoice一覧を取得
OLD_VOICES=$(grep -o '"voice": "v[0-9]*"' "$DIALOGUE" | grep -o 'v[0-9]*' | sort)

# 2. JSONを配置
cp "$DL_FILE" "$DIALOGUE"
echo "[1/3] JSON配置完了"

# 変更後のvoice一覧を取得
NEW_VOICES=$(grep -o '"voice": "v[0-9]*"' "$DIALOGUE" | grep -o 'v[0-9]*' | sort)

# 3. 削除されたvoiceのwavを削除
REMOVED=$(comm -23 <(echo "$OLD_VOICES") <(echo "$NEW_VOICES"))
if [ -n "$REMOVED" ]; then
  echo "[2/3] 不要音声を削除:"
  for v in $REMOVED; do
    WAV="$VOICE_DIR/$v.wav"
    if [ -f "$WAV" ]; then
      rm "$WAV"
      echo "  - $v.wav"
    fi
  done
else
  echo "[2/3] 削除なし"
fi

# 4. 音声差分生成
echo "[3/3] 音声生成..."
python "$PROJ/tools/generate_voice_ch01.py"
