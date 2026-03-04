"""
セリフ後の wait 時間を WAV 実尺 + コンテキスト対応余白に一括修正するツール

■ EntranceDirector の wait 処理ロジック:
  1. say イベントで voice 再生開始（ノンブロッキング、即座に次イベントへ）
  2. wait イベント到達時:
     - voice再生中 → voice完了まで await → 残り時間 = max(sec - elapsed, 0)
     - voice完了済 → sec 秒待機
  つまり wait.sec ≧ voice_duration なら「voice完了後 (sec - dur) 秒の余白」
       wait.sec < voice_duration なら「voice完了後 0 秒の余白」

■ 修正方針:
  wait.sec = voice_duration + context_pad
  context_pad はセリフ内容によって自動調整

使い方:
  python tools/fix_voice_wait.py                    # 確認のみ (dry-run)
  python tools/fix_voice_wait.py --apply            # 実際にJSONを書き換え
  python tools/fix_voice_wait.py --apply --backup   # バックアップ後に書き換え
  python tools/fix_voice_wait.py --pad-base 0.3     # ベース余白を変更 (default: 0.3)
"""

import json
import os
import sys
import io
import wave
import shutil
import argparse
import re
from datetime import datetime

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

BASE_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
DIALOGUE_PATH = os.path.join(BASE_DIR, "dialogue", "ch01_entrance.json")
VOICE_DIR = os.path.join(BASE_DIR, "assets", "audio", "voice", "ch01")

# ── コンテキスト別パディング設定 ──
PAD_BASE     = 0.3   # 通常セリフのベース余白
PAD_DRAMATIC = 0.6   # 余韻が必要なセリフ（三点リーダ/ダッシュで終わる）
PAD_TENSE    = 0.15  # 緊迫シーン（叫び・連続セリフ）
PAD_QUESTION = 0.5   # 問いかけ（視聴者チャットとの間を取る）


def get_wav_duration(voice_id: str) -> float:
    """WAVファイルの再生秒数を取得。見つからなければ -1"""
    path = os.path.join(VOICE_DIR, f"{voice_id}.wav")
    if not os.path.exists(path):
        return -1.0
    with wave.open(path, "rb") as wf:
        return wf.getnframes() / wf.getframerate()


def classify_padding(text: str, pad_base: float) -> tuple:
    """セリフ内容からコンテキストに応じたパディングを決定
    Returns: (pad_seconds, reason_label)
    """
    text = text.strip()

    # 緊迫・叫び系 → 間を詰める
    if re.search(r'[！!]{2,}|イヤァ|きゃあ|ヒッ|くそ|開かない|降りて|掴まれ', text):
        return pad_base * 0.5, "緊迫"

    # 余韻系（三点リーダ/ダッシュで終わる、恐怖の静寂）
    if re.search(r'[……—–]{2,}$|\.{3,}$', text):
        return pad_base * 2.0, "余韻"

    # 問いかけ系（チャット反応を待つ）
    if re.search(r'[？?]$|みんな.*[？?]|どうする', text):
        return pad_base * 1.7, "問いかけ"

    # 通常
    return pad_base, "通常"


def validate_json(events: list, voice_dir: str) -> list:
    """JSONの整合性を検証し、問題をリストで返す"""
    issues = []

    voice_ids_in_json = set()
    for ev in events:
        if ev.get("type") == "say" and "voice" in ev:
            vid = ev["voice"]
            voice_ids_in_json.add(vid)
            wav_path = os.path.join(voice_dir, f"{vid}.wav")
            if not os.path.exists(wav_path):
                issues.append(f"MISSING_WAV: {vid}.wav が存在しません")

    # ディスク上の WAV で JSON に参照されていないもの
    if os.path.isdir(voice_dir):
        for f in os.listdir(voice_dir):
            if f.endswith(".wav"):
                vid = f[:-4]
                if vid not in voice_ids_in_json:
                    issues.append(f"ORPHAN_WAV: {vid}.wav はJSONで参照されていません")

    # wait sec の異常値チェック
    for i, ev in enumerate(events):
        if ev.get("type") == "wait":
            sec = ev.get("sec", 0.5)
            if isinstance(sec, (int, float)) and sec > 20:
                issues.append(f"LONG_WAIT: index {i} の wait sec={sec}s が異常に長い")
            if isinstance(sec, (int, float)) and sec < 0:
                issues.append(f"NEGATIVE_WAIT: index {i} の wait sec={sec}s が負の値")

    return issues


def main():
    parser = argparse.ArgumentParser(
        description="セリフ後のwait時間をWAV実尺+コンテキスト余白に自動調整")
    parser.add_argument("--apply", action="store_true",
                        help="実際にJSONを書き換える")
    parser.add_argument("--backup", action="store_true",
                        help="書き換え前にバックアップを作成")
    parser.add_argument("--pad-base", type=float, default=PAD_BASE,
                        help=f"ベース余白秒 (default: {PAD_BASE})")
    parser.add_argument("--validate-only", action="store_true",
                        help="バリデーションのみ実行")
    args = parser.parse_args()

    with open(DIALOGUE_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    events = data.get("events", [])

    # ── バリデーション ──
    print("=== バリデーション ===")
    issues = validate_json(events, VOICE_DIR)
    if issues:
        for iss in issues:
            print(f"  [WARN] {iss}")
    else:
        print("  問題なし")
    print()

    if args.validate_only:
        return

    # ── メイン処理 ──
    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"=== セリフ後 wait 自動調整 [{mode}] ===")
    print(f"パディング: base={args.pad_base}s  "
          f"(緊迫={args.pad_base*0.5:.2f}s / 余韻={args.pad_base*2.0:.2f}s / "
          f"問いかけ={args.pad_base*1.7:.2f}s)")
    print()

    changes = 0
    total_shortened = 0.0
    total_lengthened = 0.0
    details = []

    i = 0
    while i < len(events):
        ev = events[i]

        if ev.get("type") == "say" and "voice" in ev:
            voice_id = ev["voice"]
            text = ev.get("text", "")
            wav_dur = get_wav_duration(voice_id)

            if wav_dur < 0:
                print(f"  {voice_id}: WAVが見つかりません -- スキップ")
                i += 1
                continue

            # 直後の最初の wait を探す（chat/_comment 等は飛ばす、sleep/sayで打ち切り）
            wait_idx = None
            for j in range(i + 1, min(i + 15, len(events))):
                t = events[j].get("type", "")
                if t in ("say", "sleep"):
                    break  # voice-sync でない wait 構造
                if t == "wait":
                    wait_idx = j
                    break

            if wait_idx is None:
                i += 1
                continue

            old_sec = float(events[wait_idx].get("sec", 0.5))
            pad, reason = classify_padding(text, args.pad_base)
            new_sec = round(wav_dur + pad, 2)

            delta = old_sec - new_sec

            if abs(delta) < 0.05:
                i = wait_idx + 1
                continue

            direction = "短縮" if delta > 0 else "延長"
            silence_before = max(old_sec - wav_dur, 0)
            silence_after = pad

            line = (f"  {voice_id}: wav={wav_dur:.2f}s  "
                    f"wait {old_sec:.1f}s -> {new_sec:.1f}s  "
                    f"(無音 {silence_before:.1f}s -> {silence_after:.2f}s [{reason}])  "
                    f"\"{text[:35]}\"")
            print(line)
            details.append({
                "voice": voice_id, "wav_dur": wav_dur,
                "old_sec": old_sec, "new_sec": new_sec,
                "reason": reason, "delta": delta
            })

            if args.apply:
                events[wait_idx]["sec"] = new_sec

            changes += 1
            if delta > 0:
                total_shortened += delta
            else:
                total_lengthened += abs(delta)
            i = wait_idx + 1
        else:
            i += 1

    # ── サマリー ──
    print()
    print("=" * 60)
    print(f"変更対象: {changes} 件")
    print(f"合計短縮: {total_shortened:.1f}s / 合計延長: {total_lengthened:.1f}s")
    print(f"ネット効果: {total_shortened - total_lengthened:.1f}s 短縮")

    # コンテキスト別内訳
    from collections import Counter
    reason_counts = Counter(d["reason"] for d in details)
    if reason_counts:
        print(f"内訳: {dict(reason_counts)}")

    # ── 適用 ──
    if args.apply and changes > 0:
        if args.backup:
            ts = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_path = DIALOGUE_PATH + f".bak_{ts}"
            shutil.copy2(DIALOGUE_PATH, backup_path)
            print(f"バックアップ: {backup_path}")

        with open(DIALOGUE_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"JSON保存: {DIALOGUE_PATH}")

        # 適用後バリデーション
        print()
        print("=== 適用後バリデーション ===")
        post_issues = validate_json(events, VOICE_DIR)
        if post_issues:
            for iss in post_issues:
                print(f"  [WARN] {iss}")
        else:
            print("  問題なし")
    elif not args.apply and changes > 0:
        print()
        print("実際に反映するには --apply を付けて再実行してください")
        print("  python tools/fix_voice_wait.py --apply --backup")


if __name__ == "__main__":
    main()
