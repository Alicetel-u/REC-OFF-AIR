"""
真エンド音声生成スクリプト
e*** / tw*** 音声を VOICEVOX 冥鳴ひまり（Speaker 14）で生成する
静かなダウナーホラー語り手 / intonation=0.6, speed=0.95, pitch=-0.02
"""

import io
import os
import struct
import sys
import wave

import requests

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

VOICEVOX_URL = "http://127.0.0.1:50021"
SPEAKER_ID = 14
SPEED_SCALE = 0.95
INTONATION_SCALE = 0.6
PITCH_SCALE = -0.02

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "voice", "ch02_mura")

SILENCE_THRESHOLD = 2000
TAIL_MARGIN_MS = 40

PRONUNCIATION_FIXES = {
    "廃村": "はいそん",
    "お札": "おふだ",
    "同接": "どうせつ",
    "首": "くび",
    "蠢": "うごめ",
    "彷徨い": "さまよい",
}

# (voice_id, display_text, reading_override)
# reading_override が None の場合は display_text をそのまま読み上げる
VOICES = [
    ("e001", "古びた祠の前に、震える手でスマホを置いた。", None),
    ("e002", "画面の端で、数字だけが狂ったように跳ね上がっていく。どうせつ：89,247人。", None),
    ("e003", "早くここから離れなければ——本能がそう叫び、闇の中を走り出した。", None),
    ("e004", "だが、逃げ切れないことは分かっていた。", None),
    ("e005", "この配信は、もう誰にも止められない。", None),
    ("e006", "霧原みゆき。享年17歳。", None),
    ("e007", "儀式は無惨な失敗に終わった。", None),
    ("e008", "彼女の魂は、このはいそんの泥濘に縛りつけられた。", None),
    ("e009", "解放の条件は、ただひとつ。", None),
    ("e010", "誰かが、彼女の代わりに儀式を完遂すること。", None),
    ("e011", "そして今、その「器」がようやく目の前に現れた。", None),
    ("e012", "霧原の呪いは——「視線」を喰らって増殖する。", None),
    ("e013", "絶命の瞬間。", None),
    ("e014", "万を超える視線が注がれたとき、呪いは真の姿を現す。", None),
    ("e015", "あの夜、瞳が足りなかった。", None),
    ("e016", "だから彼女は、首のない霊として永い時を彷徨い続けた。", None),
    ("e017", "次の「万の目」が訪れる、その瞬間を待ちわびて。", None),
    ("e018", "暗闇の至る所で、不気味に蠢（うごめ）く無数の赤い光。", "暗闇の至る所で、不気味にうごめく無数の赤い光。"),
    ("e019", "それは村人の霊なんかじゃない。", None),
    ("e020", "液晶の向こう側にいる、視聴者たちの飢えた目だ。", None),
    ("e022", "その全員が、神社の闇を一睡もせず凝視していた。", None),
    ("e023", "みゆきに欠けていた最後のピースを——", None),
    ("e024", "「しゅっち」が、最悪の形で揃えてしまった。", None),
    ("e025", "はいそんの最深部、霧原神社への無数の意識。", None),
    ("e027", "みゆきが、数年の孤独の中で待ち続けた「条件」が——", None),
    ("e028", "たった一晩の「生中継」によって、無慈悲に達成された。", None),
    ("e029", "霧原みゆきは、ついに解き放たれた。", None),
    ("e030", "村に淀んでいた呪いは——", None),
    ("e031", "「目」という回路を通って、一気に外界へと氾濫した。", None),
    ("e032", "数週間後、世界各地で原因不明の集団症例が報告され始める。", None),
    ("e033", "発症者たちは、怯えた声で同じ証言を繰り返した。", None),
    ("e034", "「暗闇の中に、こちらを覗き込む無数の赤い目が見える」と。", None),
    ("e035", "感染経路も、治療法も、いまだ解明されていない。", None),
    ("e036", "そして、あの夜から「しゅっち」の行方は分かっていない。", None),
    ("tw001", "視線が呪いを完成させる", None),
    ("tw002", "みんながずっとみていた", None),
]


def normalize_wav(wav_bytes: bytes, target_peak: float = 0.92) -> bytes:
    """ピーク正規化: 最大振幅を target_peak (0.0〜1.0) に合わせる"""
    buf = io.BytesIO(wav_bytes)
    with wave.open(buf, "rb") as wf:
        nch = wf.getnchannels()
        sw = wf.getsampwidth()
        fr = wf.getframerate()
        frames = wf.readframes(wf.getnframes())

    if sw != 2:
        return wav_bytes  # 16bit以外は非対応

    samples = list(struct.unpack_from(f"<{len(frames) // 2}h", frames))
    peak = max(abs(s) for s in samples) if samples else 0
    if peak == 0:
        return wav_bytes

    gain = (32767 * target_peak) / peak
    samples = [max(-32768, min(32767, int(s * gain))) for s in samples]
    new_frames = struct.pack(f"<{len(samples)}h", *samples)

    out = io.BytesIO()
    with wave.open(out, "wb") as wf_out:
        wf_out.setnchannels(nch)
        wf_out.setsampwidth(sw)
        wf_out.setframerate(fr)
        wf_out.writeframes(new_frames)
    return out.getvalue()


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
                sample = struct.unpack_from("<h", frames, s_off)[0]
            else:
                sample = struct.unpack_from("<b", frames, s_off)[0] * 256
            sample_sum += abs(sample)
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
            timeout=30,
        )
        query_res.raise_for_status()
        query_data = query_res.json()

        query_data["speedScale"] = SPEED_SCALE
        query_data["intonationScale"] = INTONATION_SCALE
        query_data["pitchScale"] = PITCH_SCALE

        synth_res = requests.post(
            f"{VOICEVOX_URL}/synthesis",
            params={"speaker": SPEAKER_ID},
            json=query_data,
            timeout=60,
        )
        synth_res.raise_for_status()

        wav = trim_trailing_silence(synth_res.content, SILENCE_THRESHOLD, TAIL_MARGIN_MS)
        wav = normalize_wav(wav)
        dur = get_wav_duration(wav)
        with open(out_path, "wb") as f:
            f.write(wav)
        return True, dur
    except Exception as e:
        print(f"  ERROR: {e}")
        return False, 0.0


def main() -> None:
    print(f"=== 真エンド音声生成 [VOICEVOX Speaker {SPEAKER_ID} / intonation={INTONATION_SCALE} / speed={SPEED_SCALE} / pitch={PITCH_SCALE}] ===")
    print(f"出力先: {OUTPUT_DIR}")
    print()

    results: dict[str, float] = {}
    for voice_id, text, reading in VOICES:
        tts_text = reading if reading else text
        out_path = os.path.join(OUTPUT_DIR, f"{voice_id}.wav")
        print(f"[{voice_id}] {text}")
        ok, dur = generate(tts_text, out_path)
        if ok:
            print(f"  -> OK ({dur:.3f}s)")
            results[voice_id] = dur
        else:
            print("  -> FAILED")
        print()

    print("=== 完了 ===")
    print("以下の voice_dur を JSON に反映してください：")
    for vid, dur in results.items():
        print(f'  "{vid}": {dur:.3f}')


if __name__ == "__main__":
    main()
