"""
WAV ユーティリティ（共通モジュール）
fix_voice_wait.py / generate_voice_ch01.py / trim_voice_silence.py で共用
"""

import wave
import struct


def get_wav_duration(path: str) -> float:
    """WAVファイルの再生秒数を取得。見つからなければ -1"""
    try:
        with wave.open(path, "rb") as wf:
            return wf.getnframes() / wf.getframerate()
    except Exception:
        return -1.0


def read_wav_samples(path: str) -> dict:
    """WAVファイルを読み込み、サンプルデータと情報を返す。
    16bit以外の場合は error キーを含む。
    """
    with wave.open(path, "rb") as wf:
        n_channels = wf.getnchannels()
        sampwidth = wf.getsampwidth()
        framerate = wf.getframerate()
        n_frames = wf.getnframes()
        raw = wf.readframes(n_frames)

    if sampwidth != 2:
        return {"error": "16bit以外は未対応", "duration": n_frames / framerate}

    fmt = f"<{n_frames * n_channels}h"
    samples = list(struct.unpack(fmt, raw))

    if n_channels == 1:
        mono = [abs(s) for s in samples]
    else:
        mono = [max(abs(samples[i]), abs(samples[i + 1]))
                for i in range(0, len(samples), n_channels)]

    return {
        "n_channels": n_channels,
        "sampwidth": sampwidth,
        "framerate": framerate,
        "n_frames": n_frames,
        "total_sec": n_frames / framerate,
        "samples": samples,
        "mono": mono,
    }


def find_last_sound_frame(mono: list, threshold: int) -> int:
    """末尾から探索して最後に音があるフレームを返す"""
    last = len(mono) - 1
    while last > 0 and mono[last] < threshold:
        last -= 1
    return last


def trim_trailing_silence(wav_path: str, threshold: int = 2000,
                          margin_ms: int = 40) -> float:
    """WAVファイルの末尾の無音を除去し、トリミング後の秒数を返す"""
    info = read_wav_samples(wav_path)
    if "error" in info:
        return info.get("duration", 0.0)

    mono = info["mono"]
    framerate = info["framerate"]
    n_channels = info["n_channels"]
    sampwidth = info["sampwidth"]
    samples = info["samples"]

    last_sound = find_last_sound_frame(mono, threshold)
    margin_frames = int(framerate * margin_ms / 1000)
    cut_frame = min(last_sound + margin_frames, len(mono))

    if cut_frame >= len(mono) - 1:
        return info["total_sec"]

    cut_sample = cut_frame * n_channels
    trimmed = samples[:cut_sample]
    trimmed_raw = struct.pack(f"<{len(trimmed)}h", *trimmed)

    with wave.open(wav_path, "wb") as wf:
        wf.setnchannels(n_channels)
        wf.setsampwidth(sampwidth)
        wf.setframerate(framerate)
        wf.writeframes(trimmed_raw)

    return cut_frame / framerate
