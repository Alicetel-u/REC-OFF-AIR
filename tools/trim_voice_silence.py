"""
ボイスWAV末尾の無音を一括トリミングするツール

使い方:
  python tools/trim_voice_silence.py                    # ch01 をトリミング（デフォルト）
  python tools/trim_voice_silence.py --dir assets/audio/voice/ch02  # 任意ディレクトリ
  python tools/trim_voice_silence.py --dry-run           # 実際には書き換えない（確認のみ）
  python tools/trim_voice_silence.py --threshold 200     # 無音判定の閾値を変更
  python tools/trim_voice_silence.py --margin 100        # 末尾余白を100msに変更
"""

import os
import sys
import io
import wave
import struct
import argparse

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

DEFAULT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "voice", "ch01")
DEFAULT_THRESHOLD = 300   # この振幅以下を無音とみなす
DEFAULT_MARGIN_MS = 80    # トリミング後に残す余白（ミリ秒）


def analyze_wav(wav_path: str, threshold: int) -> dict:
    """WAVファイルの末尾無音を解析"""
    with wave.open(wav_path, "rb") as wf:
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

    # 末尾から探索
    last_sound = len(mono) - 1
    while last_sound > 0 and mono[last_sound] < threshold:
        last_sound -= 1

    total_sec = n_frames / framerate
    sound_end_sec = (last_sound + 1) / framerate
    silence_sec = total_sec - sound_end_sec

    return {
        "n_channels": n_channels,
        "sampwidth": sampwidth,
        "framerate": framerate,
        "n_frames": n_frames,
        "total_sec": total_sec,
        "sound_end_sec": sound_end_sec,
        "silence_sec": silence_sec,
        "last_sound_frame": last_sound,
        "samples": samples,
        "mono": mono,
    }


def trim_wav(wav_path: str, info: dict, margin_ms: int) -> float:
    """WAVファイルの末尾無音をトリミングして書き戻す。新しい秒数を返す"""
    framerate = info["framerate"]
    n_channels = info["n_channels"]
    sampwidth = info["sampwidth"]
    samples = info["samples"]
    last_sound = info["last_sound_frame"]

    margin_frames = int(framerate * margin_ms / 1000)
    cut_frame = min(last_sound + margin_frames, len(info["mono"]))

    cut_sample = cut_frame * n_channels
    trimmed = samples[:cut_sample]
    trimmed_raw = struct.pack(f"<{len(trimmed)}h", *trimmed)

    with wave.open(wav_path, "wb") as wf:
        wf.setnchannels(n_channels)
        wf.setsampwidth(sampwidth)
        wf.setframerate(framerate)
        wf.writeframes(trimmed_raw)

    return cut_frame / framerate


def main():
    parser = argparse.ArgumentParser(description="WAV末尾の無音を一括トリミング")
    parser.add_argument("--dir", default=DEFAULT_DIR, help="対象ディレクトリ")
    parser.add_argument("--threshold", type=int, default=DEFAULT_THRESHOLD,
                        help=f"無音判定の振幅閾値 (default: {DEFAULT_THRESHOLD})")
    parser.add_argument("--margin", type=int, default=DEFAULT_MARGIN_MS,
                        help=f"末尾に残す余白ms (default: {DEFAULT_MARGIN_MS})")
    parser.add_argument("--dry-run", action="store_true",
                        help="実際にはファイルを変更しない（解析のみ）")
    parser.add_argument("--min-silence", type=float, default=0.15,
                        help="この秒数以上の末尾無音だけトリミング (default: 0.15)")
    args = parser.parse_args()

    target_dir = os.path.normpath(args.dir)
    if not os.path.isdir(target_dir):
        print(f"ERROR: ディレクトリが見つかりません: {target_dir}")
        sys.exit(1)

    wav_files = sorted([f for f in os.listdir(target_dir) if f.endswith(".wav")])
    if not wav_files:
        print(f"WAVファイルが見つかりません: {target_dir}")
        sys.exit(1)

    mode = "DRY-RUN（確認のみ）" if args.dry_run else "トリミング実行"
    print(f"=== 末尾無音トリミング [{mode}] ===")
    print(f"対象: {target_dir} ({len(wav_files)} files)")
    print(f"閾値: {args.threshold} / 余白: {args.margin}ms / 最小無音: {args.min_silence}s")
    print()

    trimmed_count = 0
    skipped_count = 0
    total_saved_sec = 0.0

    for fname in wav_files:
        fpath = os.path.join(target_dir, fname)
        info = analyze_wav(fpath, args.threshold)

        if "error" in info:
            print(f"  {fname}: SKIP ({info['error']})")
            skipped_count += 1
            continue

        silence = info["silence_sec"]
        total = info["total_sec"]

        if silence < args.min_silence:
            print(f"  {fname}: {total:.2f}s (末尾無音 {silence:.3f}s) -- OK")
            skipped_count += 1
            continue

        if args.dry_run:
            print(f"  {fname}: {total:.2f}s (末尾無音 {silence:.3f}s) -- トリミング対象")
            trimmed_count += 1
            total_saved_sec += silence
        else:
            new_dur = trim_wav(fpath, info, args.margin)
            saved = total - new_dur
            print(f"  {fname}: {total:.2f}s -> {new_dur:.2f}s (削除 {saved:.3f}s)")
            trimmed_count += 1
            total_saved_sec += saved

    print()
    print(f"=== 完了: トリミング {trimmed_count} / スキップ {skipped_count} / 合計 {len(wav_files)} ===")
    if total_saved_sec > 0:
        print(f"合計削減: {total_saved_sec:.2f}s")


if __name__ == "__main__":
    main()
