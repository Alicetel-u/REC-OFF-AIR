#!/usr/bin/env python3
"""
optimize_timing.py  —  ch01 の say 直後 wait をボイス尺に合わせて最適化

Changes:
  1. say(voice=vXXX) の直後の wait を voice_dur + BEAT に設定
  2. walk_to_arch の dur を voice 尺に合わせて延長
  3. ゲート到着後にゆっくり前進 tween を追加（立ち止まり防止）
"""

import json
import wave
import os
import copy

REPO      = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JSON_PATH = os.path.join(REPO, "dialogue", "ch01_entrance.json")
VOICE_DIR = os.path.join(REPO, "assets", "audio", "voice", "ch01")

BEAT = 0.4   # ボイス終了後の最小待機秒数


def get_dur(voice_name: str) -> float:
    path = os.path.join(VOICE_DIR, voice_name + ".wav")
    with wave.open(path) as w:
        return w.getnframes() / float(w.getframerate())


def main():
    with open(JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)
    events = data["events"]

    # ── 1. say 直後の wait を voice_dur + BEAT に最適化 ──────────────────
    changed = 0
    for i, ev in enumerate(events):
        if ev.get("type") != "say" or not ev.get("voice"):
            continue
        dur = get_dur(ev["voice"])
        new_sec = round(dur + BEAT, 1)

        # _comment を飛ばして直後の wait を探す
        j = i + 1
        while j < len(events) and events[j].get("type") == "_comment":
            j += 1
        if j < len(events) and events[j].get("type") == "wait":
            old = events[j]["sec"]
            if abs(events[j]["sec"] - new_sec) > 0.05:
                events[j]["sec"] = new_sec
                changed += 1

    print(f"[1] wait 最適化: {changed} 件変更")

    # ── 2. walk_to_arch の dur を延長 ────────────────────────────────────
    # section2 の voice 合計 (v009-v018) + chat waits ≒ 55s → dur=50s に設定
    for ev in events:
        if ev.get("type") == "pos_x" and ev.get("id") == "walk_to_arch":
            old_dur = ev["dur"]
            ev["dur"] = 50.0
            print(f"[2] walk_to_arch dur: {old_dur} → {ev['dur']}")
            break

    # ── 3. ゲート到着後にゆっくり前進を追加 ─────────────────────────────
    # pos_x_await walk_to_shop の直後、walk_set: false の前に
    # pos_z(target=-7.0, dur=25.0) を挿入してゲートに向かって歩き続ける
    gate_walk_inserted = False
    for i, ev in enumerate(events):
        if ev.get("type") == "pos_x_await" and ev.get("id") == "walk_to_shop":
            # すでに挿入済みでないか確認
            if i + 1 < len(events) and events[i + 1].get("id") == "gate_creep":
                print("[3] ゲートゆっくり前進: すでに挿入済み")
                gate_walk_inserted = True
                break
            gate_walk = {
                "type": "pos_z",
                "target": -7.0,
                "dur": 25.0,
                "id": "gate_creep"
            }
            events.insert(i + 1, gate_walk)
            gate_walk_inserted = True
            print("[3] ゲートゆっくり前進: pos_z(-7.0, 25s) を挿入")
            break

    if not gate_walk_inserted:
        print("[3] ゲートゆっくり前進: 挿入位置が見つかりませんでした")

    # ── 保存 ──────────────────────────────────────────────────────────────
    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"\n保存完了: {JSON_PATH}")


if __name__ == "__main__":
    main()
