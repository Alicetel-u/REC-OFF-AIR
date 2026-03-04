#!/usr/bin/env python3
"""
gen_voice_ch01.py  —  VOICEVOX で ch01_entrance.json の say イベントに音声を生成する

Usage:
    python tools/gen_voice_ch01.py          # 全 say を生成
    python tools/gen_voice_ch01.py --dry    # 生成プレビューのみ（ファイル不生成）
    python tools/gen_voice_ch01.py --force  # 既存ファイルも上書き再生成

Requirements:
    VOICEVOX engine が localhost:50021 で起動済みであること
"""

import json
import os
import sys
import urllib.request
import urllib.parse

# ─────────────────── 設定 ───────────────────
VOICEVOX_URL = "http://localhost:50021"
SPEAKER_ID   = 20       # もち子さん
SPEED_SCALE  = 1.08     # 少し速め
PITCH_SCALE  = 0.0      # 変更なし

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT    = os.path.dirname(SCRIPT_DIR)
JSON_PATH    = os.path.join(REPO_ROOT, "dialogue", "ch01_entrance.json")
OUTPUT_DIR   = os.path.join(REPO_ROOT, "assets", "audio", "voice", "ch01")
# ────────────────────────────────────────────


def preprocess_text(text: str) -> str:
    """VOICEVOX に渡す前に読み方を修正する"""
    replacements = {
        "TIKTOK":  "ティクトック",
        "TikTok":  "ティクトック",
        "お札":    "おふだ",
        "廃村":    "はいそん",
    }
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text


def audio_query(text: str, speaker_id: int) -> dict:
    params = urllib.parse.urlencode({"text": text, "speaker": speaker_id})
    req = urllib.request.Request(
        f"{VOICEVOX_URL}/audio_query?{params}", method="POST"
    )
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=30) as res:
        return json.loads(res.read())


def synthesis(query: dict, speaker_id: int) -> bytes:
    params = urllib.parse.urlencode({"speaker": speaker_id})
    body   = json.dumps(query).encode("utf-8")
    req = urllib.request.Request(
        f"{VOICEVOX_URL}/synthesis?{params}", data=body, method="POST"
    )
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=60) as res:
        return res.read()


def main():
    dry_run = "--dry" in sys.argv
    force   = "--force" in sys.argv

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    with open(JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)

    events = data.get("events", [])

    # say イベントを収集（順番に v001, v002, ... を割り当て）
    say_events = [(i, ev) for i, ev in enumerate(events) if ev.get("type") == "say"]
    print(f"say イベント数: {len(say_events)}")
    if dry_run:
        print("\n[DRY RUN] 以下のファイルが生成されます:\n")
        for n, (_, ev) in enumerate(say_events, 1):
            print(f"  v{n:03d}.wav  {ev.get('text','')[:50]}")
        return

    ok_count   = 0
    skip_count = 0
    err_count  = 0

    for n, (ev_idx, ev) in enumerate(say_events, 1):
        voice_name = f"v{n:03d}"
        wav_path   = os.path.join(OUTPUT_DIR, voice_name + ".wav")
        text       = ev.get("text", "").strip()

        if not text:
            ev["voice"] = voice_name
            continue

        # 既存ファイルはスキップ（--force で上書き）
        if os.path.exists(wav_path) and not force:
            print(f"[SKIP] {voice_name}")
            ev["voice"] = voice_name
            skip_count += 1
            continue

        preview = text[:55].encode("ascii", errors="replace").decode("ascii")
        print(f"[GEN]  {voice_name}: {preview}", end="", flush=True)
        try:
            query = audio_query(preprocess_text(text), SPEAKER_ID)
            query["speedScale"] = SPEED_SCALE
            query["pitchScale"] = PITCH_SCALE
            wav_data = synthesis(query, SPEAKER_ID)

            with open(wav_path, "wb") as f:
                f.write(wav_data)

            ev["voice"] = voice_name
            print(f"  [{len(wav_data)//1024} KB]")
            ok_count += 1

        except Exception as e:
            print(f"  ERROR: {e}")
            err_count += 1

    # JSON 更新（voice フィールド付き）
    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\n完了: 生成={ok_count}件 / スキップ={skip_count}件 / エラー={err_count}件")
    print(f"JSON 更新: {JSON_PATH}")


if __name__ == "__main__":
    main()
