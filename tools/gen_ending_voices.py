"""
真エンド音声生成スクリプト
e*** / tw*** 音声を VOICEVOX Speaker 14 / intonationScale=0.3 で生成する
（感情なし・ゆっくり読み = ナレーション統一）
"""
import requests
import io
import os
import sys
import json
import wave
import struct

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

VOICEVOX_URL = "http://127.0.0.1:50021"
SPEAKER_ID = 14
SPEED_SCALE = 1.0
INTONATION_SCALE = 0.3
PITCH_SCALE = 0.0

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "voice", "ch02_mura")

SILENCE_THRESHOLD = 2000
TAIL_MARGIN_MS = 40

# NOTE: pause制御（prePhonemeLength/postPhonemeLength短縮・pause_moraクリップ）は
# ch01主人公用の高テンション設定。ナレーションにはVOICEVOXデフォルトのまま使う。

# 発音修正
PRONUNCIATION_FIXES = {
    "廃村": "はいそん",
    "お札": "おふだ",
    "同接": "どうせつ",
    "首": "くび",
}

# text は表示用、reading は実際に読ませるテキスト（Noneなら text を使う）
VOICES = [
    ("e001", "古びた祠の前に、震える手でスマホを置いた。", None),
    ("e002", "画面の端で、数字だけが狂ったように跳ね上がっていく。どうせつ：89,247人。", None),
    ("e008", "彼女の魂は、このはいそんの泥濘に縛りつけられた。", None),
    ("e025", "はいそんの最深部、霧原神社への無数の意識。", None),
    ("e031", "「目」という回路を通って、一気に外界へと氾濫した。", None),
    ("tw001", "視線が呪いを完成させる", None),
    ("tw002", "みんながずっとみていた", None),
]


def fix_pronunciation(text: str) -> str:
    for original, fixed in PRONUNCIATION_FIXES.items():
        text = text.replace(original, fixed)
    return text


def trim_trailing_silence(wav_bytes: bytes, threshold: int = 2000, margin_ms: int = 40) -> bytes:
    buf = io.BytesIO(wav_bytes)
    with wave.open(buf, "rb") as wf:
        nch = wf.getnchannels()
        sw = wf.getsampwidth()
        fr = wf.getframerate()
        frames = wf.readframes(wf.getnframes())
    total_frames = len(frames) // (nch * sw)
    margin_frames = int(fr * margin_ms / 1000)
    last_loud = 0
    for i in range(total_frames):
        offset = i * nch * sw
        sample_sum = 0
        for c in range(nch):
            s_off = offset + c * sw
            if sw == 2:
                s = struct.unpack_from("<h", frames, s_off)[0]
            else:
                s = struct.unpack_from("<b", frames, s_off)[0] * 256
            sample_sum += abs(s)
        if sample_sum // nch >= threshold:
            last_loud = i
    cut = min(last_loud + margin_frames + 1, total_frames)
    trimmed = frames[:cut * nch * sw]
    out = io.BytesIO()
    with wave.open(out, "wb") as wf_out:
        wf_out.setnchannels(nch)
        wf_out.setsampwidth(sw)
        wf_out.setframerate(fr)
        wf_out.writeframes(trimmed)
    return out.getvalue()


def get_wav_duration(wav_bytes: bytes) -> float:
    buf = io.BytesIO(wav_bytes)
    with wave.open(buf, "rb") as wf:
        return wf.getnframes() / wf.getframerate()


def generate(text: str, out_path: str) -> tuple[bool, float]:
    tts_text = fix_pronunciation(text)
    try:
        query_res = requests.post(
            f"{VOICEVOX_URL}/audio_query",
            params={"text": tts_text, "speaker": SPEAKER_ID},
            timeout=30
        )
        query_res.raise_for_status()
        query_data = query_res.json()

        query_data["speedScale"] = SPEED_SCALE
        query_data["intonationScale"] = INTONATION_SCALE
        query_data["pitchScale"] = PITCH_SCALE
        # pause制御はVOICEVOXデフォルトのまま（ナレーションは自然な間を保つ）

        synth_res = requests.post(
            f"{VOICEVOX_URL}/synthesis",
            params={"speaker": SPEAKER_ID},
            json=query_data,
            timeout=60
        )
        synth_res.raise_for_status()
        wav = trim_trailing_silence(synth_res.content, SILENCE_THRESHOLD, TAIL_MARGIN_MS)
        dur = get_wav_duration(wav)
        with open(out_path, "wb") as f:
            f.write(wav)
        return True, dur
    except Exception as e:
        print(f"  ERROR: {e}")
        return False, 0.0


def main():
    print(f"=== 真エンド音声生成 [VOICEVOX Speaker {SPEAKER_ID} / intonation={INTONATION_SCALE}] ===")
    print(f"出力先: {OUTPUT_DIR}")
    print()

    results = {}
    for voice_id, text, reading in VOICES:
        tts_text = reading if reading else text
        out_path = os.path.join(OUTPUT_DIR, f"{voice_id}.wav")
        print(f"[{voice_id}] {text}")
        ok, dur = generate(tts_text, out_path)
        if ok:
            print(f"  -> OK ({dur:.3f}s)")
            results[voice_id] = dur
        else:
            print(f"  -> FAILED")
        print()

    print("=== 完了 ===")
    print("以下の voice_dur を JSON に反映してください：")
    for vid, dur in results.items():
        print(f'  "{vid}": {dur:.3f}')
    print()
    print("その後 godot --headless --import を実行してください。")


if __name__ == "__main__":
    main()
