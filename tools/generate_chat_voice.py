"""
チャットコメント用ボイス生成スクリプト（VOICEVOX）
- dialogue JSON の chat イベントから特定ユーザーのコメントを抽出
- ユーザーごとに異なるVOICEVOX話者IDで音声生成
- 差分ハッシュで変更分のみ再生成
- JSONのchatイベントに "voice": "c001" を自動挿入

使い方:
  python tools/generate_chat_voice.py --dialogue dialogue/ch01_entrance.json --output-dir assets/audio/voice/ch01_chat
  python tools/generate_chat_voice.py --dialogue dialogue/ch02_mura_tansaku_exit.json --output-dir assets/audio/voice/ch02_mura_chat
  python tools/generate_chat_voice.py --force  # 全再生成
"""

import json
import hashlib
import requests
import sys
import os
import io
import argparse
from wav_utils import trim_trailing_silence as _trim_wav

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

# ═══════════════════════════════════════════════════
# VOICEVOX 設定
# ═══════════════════════════════════════════════════
VOICEVOX_URL = "http://127.0.0.1:50021"

# チャットボイス用パラメータ（早口・軽い感じ）
SPEED_SCALE = 1.4
INTONATION_SCALE = 1.2
PITCH_SCALE = 0.0

# ポーズ制御
MAX_PAUSE_LENGTH = 0.10
PRE_PHONEME_LENGTH = 0.03
POST_PHONEME_LENGTH = 0.03

# 末尾無音トリミング
SILENCE_THRESHOLD = 2000
TAIL_MARGIN_MS = 30

# ═══════════════════════════════════════════════════
# ユーザー → 話者ID マッピング
# ═══════════════════════════════════════════════════
USER_SPEAKER_MAP = {
    "視聴者A":       3,   # ずんだもん（高め・元気）
    "配信民99":      2,   # 四国めたん ノーマル（落ち着いた）
    "ゆきんこ77":    0,   # 四国めたん あまあま（柔らかい）
    "まっちゃん":    8,   # 春日部つむぎ（カジュアル）
    "K":            14,   # 冥鳴ひまり（不気味）
    "名無しさん":   10,   # ナースロボ＿タイプＴ
    "ホラー好き太郎": 11,  # 玄野武宏
    "深夜組":        9,   # 雀松朱司
    "ガクブル太郎":  13,  # 青山龍星
    "幽霊ガチ勢":    1,   # 四国めたん ツンツン
    "おばけ見たい":  21,  # もち子さん
    "はじめまして民": 3,  # ずんだもん（視聴者Aと同じ）
    "深夜のツッコミ担当": 2,  # 四国めたん ノーマル
    "塩ラーメン":    9,   # 雀松朱司
    "暗闇ウォッチャー": 11, # 玄野武宏
    "オカルト研究部": 10,  # ナースロボ＿タイプＴ
    "地蔵キッズ":   13,   # 青山龍星
}

# 繰り返しスキップ: 同じユーザーの同じメッセージが連続する場合、最初の1回だけ生成
SKIP_DUPLICATE = True

# Kの特殊パラメータ（不気味さを出す）
K_PARAMS = {
    "speedScale": 0.9,
    "intonationScale": 0.6,
    "pitchScale": -0.08,
}


def compute_hash(text: str, speaker_id: int) -> str:
    h = hashlib.md5(f"{text}|{speaker_id}".encode("utf-8")).hexdigest()[:12]
    return h


def generate_voicevox(text: str, speaker_id: int, user: str = "") -> bytes:
    """VOICEVOX APIで音声合成"""
    # audio_query
    resp = requests.post(
        f"{VOICEVOX_URL}/audio_query",
        params={"text": text, "speaker": speaker_id},
        timeout=30,
    )
    resp.raise_for_status()
    query = resp.json()

    # パラメータ調整
    if user == "K":
        query["speedScale"] = K_PARAMS["speedScale"]
        query["intonationScale"] = K_PARAMS["intonationScale"]
        query["pitchScale"] = K_PARAMS["pitchScale"]
    else:
        query["speedScale"] = SPEED_SCALE
        query["intonationScale"] = INTONATION_SCALE
        query["pitchScale"] = PITCH_SCALE

    query["prePhonemeLength"] = PRE_PHONEME_LENGTH
    query["postPhonemeLength"] = POST_PHONEME_LENGTH

    # ポーズ短縮
    if "accent_phrases" in query:
        for phrase in query["accent_phrases"]:
            if "pause_mora" in phrase and phrase["pause_mora"]:
                vl = phrase["pause_mora"].get("vowel_length", 0)
                if vl > MAX_PAUSE_LENGTH:
                    phrase["pause_mora"]["vowel_length"] = MAX_PAUSE_LENGTH

    # synthesis
    resp2 = requests.post(
        f"{VOICEVOX_URL}/synthesis",
        params={"speaker": speaker_id},
        json=query,
        timeout=60,
    )
    resp2.raise_for_status()
    return resp2.content


def main():
    parser = argparse.ArgumentParser(description="チャットコメント用ボイス生成")
    parser.add_argument("--dialogue", required=True, help="対話JSONファイルパス")
    parser.add_argument("--output-dir", required=True, help="WAV出力ディレクトリ")
    parser.add_argument("--force", action="store_true", help="全再生成")
    parser.add_argument("--dry-run", action="store_true", help="生成せず対象を表示")
    args = parser.parse_args()

    dialogue_path = os.path.normpath(args.dialogue)
    output_dir = os.path.normpath(args.output_dir)

    if not os.path.exists(dialogue_path):
        print(f"ERROR: {dialogue_path} が見つかりません")
        sys.exit(1)

    os.makedirs(output_dir, exist_ok=True)

    # JSON読み込み
    with open(dialogue_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    events = data.get("events", [])

    # ハッシュ読み込み
    hash_path = os.path.join(output_dir, ".voice_hashes.json")
    hashes = {}
    if os.path.exists(hash_path):
        with open(hash_path, "r", encoding="utf-8") as f:
            hashes = json.load(f)

    # chatイベントを抽出（対象ユーザーのみ、繰り返しスキップ）
    chat_events = []
    seen_msgs = set()  # (user, msg) の重複検出
    prev_msg = ""
    for i, ev in enumerate(events):
        if ev.get("type") != "chat":
            continue
        user = ev.get("user", "")
        if user not in USER_SPEAKER_MAP:
            continue
        msg = ev.get("msg", "")
        # 繰り返しスキップ: 同一ユーザーの同一メッセージ or 直前と同じメッセージ
        if SKIP_DUPLICATE:
            key = (user, msg)
            if key in seen_msgs:
                continue
            seen_msgs.add(key)
        chat_events.append((i, ev))
        prev_msg = msg

    print(f"=== チャットボイス生成 ===")
    print(f"  対話JSON: {dialogue_path}")
    print(f"  出力先: {output_dir}")
    print(f"  対象コメント: {len(chat_events)} 件")
    print()

    # 連番割り当て
    success = 0
    skipped = 0
    errors = 0

    for seq, (ev_idx, ev) in enumerate(chat_events):
        voice_id = f"c{seq + 1:03d}"
        user = ev["user"]
        msg = ev["msg"]
        speaker_id = USER_SPEAKER_MAP[user]

        new_hash = compute_hash(msg, speaker_id)
        old_hash = hashes.get(voice_id, "")
        out_path = os.path.join(output_dir, f"{voice_id}.wav")

        if not args.force and new_hash == old_hash and os.path.exists(out_path):
            skipped += 1
            # voice フィールドが未設定なら追加
            if "voice" not in ev:
                events[ev_idx]["voice"] = voice_id
            continue

        if args.dry_run:
            print(f"  [DRY] {voice_id} [{user}] (speaker={speaker_id}): {msg}")
            events[ev_idx]["voice"] = voice_id
            continue

        try:
            print(f"  生成中: {voice_id} [{user}] (speaker={speaker_id}): {msg[:30]}...")
            wav_data = generate_voicevox(msg, speaker_id, user)

            with open(out_path, "wb") as wf:
                wf.write(wav_data)

            # 末尾無音トリミング
            _trim_wav(out_path, threshold=SILENCE_THRESHOLD, margin_ms=TAIL_MARGIN_MS)

            hashes[voice_id] = new_hash
            events[ev_idx]["voice"] = voice_id
            success += 1

        except Exception as e:
            print(f"  ERROR: {voice_id} [{user}]: {e}")
            errors += 1

    print()
    print(f"=== 結果: 生成={success}, スキップ={skipped}, エラー={errors} ===")

    # ハッシュ保存
    if success > 0 or args.dry_run:
        with open(hash_path, "w", encoding="utf-8") as f:
            json.dump(hashes, f, indent=2, ensure_ascii=False)

    # JSONにvoiceフィールドを書き戻し
    modified = False
    for seq, (ev_idx, ev) in enumerate(chat_events):
        voice_id = f"c{seq + 1:03d}"
        if events[ev_idx].get("voice") != voice_id:
            events[ev_idx]["voice"] = voice_id
            modified = True

    if modified or success > 0:
        data["events"] = events
        # chat_voice_dir を設定
        rel_dir = output_dir.replace("\\", "/")
        if not rel_dir.startswith("res://"):
            # プロジェクトルートからの相対パスを res:// に変換
            if "assets/" in rel_dir:
                rel_dir = "res://" + rel_dir[rel_dir.index("assets/"):]
            else:
                rel_dir = "res://" + rel_dir
        if not rel_dir.endswith("/"):
            rel_dir += "/"
        data["chat_voice_dir"] = rel_dir

        with open(dialogue_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4, ensure_ascii=False)
        print(f"  → {dialogue_path} を更新しました（voiceフィールド + chat_voice_dir）")

    if success > 0:
        print()
        print("⚠ Godotで .import ファイルを生成してください:")
        print('  godot.exe --headless --import --quit')


if __name__ == "__main__":
    main()
