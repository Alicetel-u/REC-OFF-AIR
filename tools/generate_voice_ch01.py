"""
CP1 ボイス生成スクリプト
VOICEVOX API を使って ch01_entrance.json の全 say イベントの音声を生成する
末尾の無音を自動トリミングする
"""

import json
import requests
import sys
import os
import io
import wave
import struct

# Windows コンソールの文字化け対策
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

VOICEVOX_URL = "http://127.0.0.1:50021"
SPEAKER_ID = 20
DIALOGUE_PATH = os.path.join(os.path.dirname(__file__), "..", "dialogue", "ch01_entrance.json")
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "voice", "ch01")

# 音声パラメータ（テンション高め・流暢・早口）
SPEED_SCALE = 1.25         # 速度アップ
INTONATION_SCALE = 1.5     # 抑揚強め（テンション高い感じ）
PITCH_SCALE = 0.02         # ほんの少しピッチ上げ

# 末尾無音トリミング設定
SILENCE_THRESHOLD = 300     # この振幅以下を無音とみなす
TAIL_MARGIN_MS = 80         # トリミング後に残す余白（ミリ秒）

# 発音修正テーブル
PRONUNCIATION_FIXES = {
    "TIKTOK": "ティックトック",
    "TikTok": "ティックトック",
    "tiktok": "ティックトック",
    "廃村": "はいそん",
    "お札": "おふだ",
}


def fix_pronunciation(text: str) -> str:
    """VOICEVOX用にテキストの発音を修正"""
    for original, fixed in PRONUNCIATION_FIXES.items():
        text = text.replace(original, fixed)
    return text


def trim_trailing_silence(wav_path: str) -> float:
    """WAVファイルの末尾の無音を除去し、トリミング後の秒数を返す"""
    with wave.open(wav_path, "rb") as wf:
        n_channels = wf.getnchannels()
        sampwidth = wf.getsampwidth()
        framerate = wf.getframerate()
        n_frames = wf.getnframes()
        raw = wf.readframes(n_frames)

    # サンプルデータに変換
    if sampwidth == 2:
        fmt = f"<{n_frames * n_channels}h"
        samples = list(struct.unpack(fmt, raw))
    else:
        return n_frames / framerate  # 16bit以外は未対応、そのまま返す

    # モノラル化（最大振幅で判定）
    if n_channels == 1:
        mono = [abs(s) for s in samples]
    else:
        mono = [max(abs(samples[i]), abs(samples[i+1])) for i in range(0, len(samples), n_channels)]

    # 末尾から探索して最後に音があるフレームを見つける
    last_sound = len(mono) - 1
    while last_sound > 0 and mono[last_sound] < SILENCE_THRESHOLD:
        last_sound -= 1

    # マージン分を追加
    margin_frames = int(framerate * TAIL_MARGIN_MS / 1000)
    cut_frame = min(last_sound + margin_frames, len(mono))

    if cut_frame >= len(mono) - 1:
        return n_frames / framerate  # トリミング不要

    # トリミングしたデータを書き戻す
    cut_sample = cut_frame * n_channels
    trimmed = samples[:cut_sample]
    trimmed_raw = struct.pack(f"<{len(trimmed)}h", *trimmed)

    with wave.open(wav_path, "wb") as wf:
        wf.setnchannels(n_channels)
        wf.setsampwidth(sampwidth)
        wf.setframerate(framerate)
        wf.writeframes(trimmed_raw)

    return cut_frame / framerate


def generate_voice(text: str, speaker_id: int, output_path: str) -> bool:
    """VOICEVOX APIで音声を生成してWAVファイルに保存（末尾無音トリミング付き）"""
    try:
        tts_text = fix_pronunciation(text)

        # 音声合成用のクエリを作成
        query_res = requests.post(
            f"{VOICEVOX_URL}/audio_query",
            params={"text": tts_text, "speaker": speaker_id},
            timeout=30
        )
        query_res.raise_for_status()
        query_data = query_res.json()

        # パラメータ調整（テンション高め・早口・流暢）
        query_data["speedScale"] = SPEED_SCALE
        query_data["intonationScale"] = INTONATION_SCALE
        query_data["pitchScale"] = PITCH_SCALE

        # 音声合成
        synth_res = requests.post(
            f"{VOICEVOX_URL}/synthesis",
            params={"speaker": speaker_id},
            json=query_data,
            timeout=60
        )
        synth_res.raise_for_status()

        with open(output_path, "wb") as f:
            f.write(synth_res.content)

        # 末尾無音トリミング
        duration = trim_trailing_silence(output_path)

        return True, duration
    except Exception as e:
        print(f"  ERROR: {e}")
        return False, 0.0


def main():
    with open(DIALOGUE_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    events = data.get("events", [])

    voice_events = []
    for ev in events:
        if ev.get("type") == "say" and "voice" in ev:
            voice_events.append(ev)

    print(f"=== CP1 ボイス全再生成 (Speaker ID: {SPEAKER_ID}) ===")
    print(f"対象: {len(voice_events)} 件")
    print(f"speed={SPEED_SCALE} intonation={INTONATION_SCALE} pitch={PITCH_SCALE}")
    print(f"末尾トリミング: threshold={SILENCE_THRESHOLD} margin={TAIL_MARGIN_MS}ms")
    print()

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    success = 0
    fail = 0

    for i, ev in enumerate(voice_events):
        voice_id = ev["voice"]
        text = ev["text"]
        output_path = os.path.join(OUTPUT_DIR, f"{voice_id}.wav")

        print(f"[{i+1}/{len(voice_events)}] {voice_id}")

        ok, duration = generate_voice(text, SPEAKER_ID, output_path)
        if ok:
            size_kb = os.path.getsize(output_path) / 1024
            print(f"  -> OK ({size_kb:.1f} KB, {duration:.2f}s)")
            success += 1
        else:
            fail += 1

    print()
    print(f"=== 完了: 成功 {success} / 失敗 {fail} / 合計 {len(voice_events)} ===")

    if fail > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
