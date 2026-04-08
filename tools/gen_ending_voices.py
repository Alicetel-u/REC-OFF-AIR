"""
真エンド音声生成スクリプト
変更・新規のeおよびtw音声をSBV2で一括生成する
"""
import requests
import io
import os
import sys
import wave
import struct

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

SBV2_URL = "http://127.0.0.1:5000"
SBV2_MODEL = "jvnv-F2-jp"
SBV2_STYLE = "Fear"
SBV2_LENGTH = 0.8
SBV2_SDP_RATIO = 0.2
SBV2_NOISE = 0.6
SBV2_NOISEW = 0.8

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "voice", "ch02_mura")

SILENCE_THRESHOLD = 2000
TAIL_MARGIN_MS = 40

VOICES = [
    ("e001", "古びた祠の前に、震える手でスマホを置いた。"),
    ("e002", "画面の端で、数字だけが狂ったように跳ね上がっていく。どうせつ：89,247人。"),
    ("e008", "彼女の魂は、このはいそんの泥濘に縛りつけられた。"),
    ("e025", "はいそんの最深部、霧原神社への無数の意識。"),
    ("e031", "「目」という回路を通って、一気に外界へと氾濫した。"),
    ("tw001", "視線が呪いを完成させる"),
    ("tw002", "みんながずっとみていた"),
]


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
    params = {
        "text": text,
        "model_name": SBV2_MODEL,
        "style": SBV2_STYLE,
        "length": SBV2_LENGTH,
        "sdp_ratio": SBV2_SDP_RATIO,
        "noise": SBV2_NOISE,
        "noisew": SBV2_NOISEW,
        "language": "JP",
    }
    try:
        r = requests.get(f"{SBV2_URL}/voice", params=params, timeout=60)
        if r.status_code != 200:
            print(f"  ERROR: HTTP {r.status_code}")
            return False, 0.0
        wav = trim_trailing_silence(r.content, SILENCE_THRESHOLD, TAIL_MARGIN_MS)
        dur = get_wav_duration(wav)
        with open(out_path, "wb") as f:
            f.write(wav)
        return True, dur
    except Exception as e:
        print(f"  ERROR: {e}")
        return False, 0.0


def main():
    print(f"=== 真エンド音声生成 [{SBV2_MODEL} / {SBV2_STYLE}] ===")
    print(f"出力先: {OUTPUT_DIR}")
    print()
    for voice_id, text in VOICES:
        out_path = os.path.join(OUTPUT_DIR, f"{voice_id}.wav")
        print(f"[{voice_id}] {text}")
        ok, dur = generate(text, out_path)
        if ok:
            print(f"  -> OK ({dur:.3f}s)  ← voice_dur に設定してください")
        else:
            print(f"  -> FAILED")
        print()
    print("完了。生成されたファイルのvoice_durをJSONに反映し、")
    print("Godotエディタで --headless --import を実行してください。")


if __name__ == "__main__":
    main()
