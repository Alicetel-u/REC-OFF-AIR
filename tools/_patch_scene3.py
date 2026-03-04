#!/usr/bin/env python3
"""ch01_entrance.json のシーン3をトイレ演出強化版に置換するパッチスクリプト"""
import json, sys

INPUT  = "dialogue/ch01_entrance.json"
OUTPUT = "dialogue/ch01_entrance.json"

# ─────────────────────────────────────────
#  新しい シーン3 イベント列
# ─────────────────────────────────────────
def C(text): return {"type": "_comment", "_": text}
def say(text, voice): return {"type": "say", "text": text, "voice": voice}
def chat(msg, user, utype=None):
    e = {"type": "chat", "msg": msg, "user": user}
    if utype: e["utype"] = utype
    return e
def wait(sec): return {"type": "wait", "sec": sec}
def sleep(sec): return {"type": "sleep", "sec": sec}
def sfx(sound, vol=None):
    e = {"type": "sfx", "sound": sound}
    if vol is not None: e["vol"] = vol
    return e
def glitch(intensity, count): return {"type": "horror_glitch", "intensity": intensity, "count": count}
def flash(dur): return {"type": "horror_flash", "dur": dur}
def scare(color): return {"type": "scare_flash", "color": color}
def tint(): return {"type": "horror_tint"}
def tint_clear(): return {"type": "horror_tint_clear"}
def rot(target, dur): return {"type": "rot_y", "target": target, "dur": dur}
def head(target, dur): return {"type": "head_x", "target": target, "dur": dur}
def pos_x(target, dur, id=None):
    e = {"type": "pos_x", "target": target, "dur": dur}
    if id: e["id"] = id
    return e
def pos_z(target, dur, id=None):
    e = {"type": "pos_z", "target": target, "dur": dur}
    if id: e["id"] = id
    return e
def pos_z_await(id): return {"type": "pos_z_await", "id": id}
def walk(on): return {"type": "walk_set", "on": on}
def flicker(): return {"type": "flashlight_flicker"}
def flashlight_on(): return {"type": "flashlight_on"}
def set_viewers(n): return {"type": "set_viewers", "count": n}
def fade_black(dur): return {"type": "fade_black", "dur": dur}
def fade_clear(dur): return {"type": "fade_clear", "dur": dur}
def use_ofuda(): return {"type": "use_ofuda"}
def say_clear(): return {"type": "say_clear"}

# ─── 揺れパターン：ドアが閉まる衝撃 ───
def shake_door():
    return [
        head(0.12, 0.06), sleep(0.07),
        head(-0.08, 0.06), sleep(0.07),
        head(0.06, 0.07), sleep(0.07),
        head(-0.04, 0.07), sleep(0.08),
        head(0.02, 0.10), sleep(0.10),
    ]

# ─── 揺れパターン：天井から液体が滴る（微弱） ───
def shake_drip():
    return [
        head(0.05, 0.18), sleep(0.18),
        head(-0.03, 0.18), sleep(0.18),
        head(0.0, 0.20), sleep(0.20),
    ]

# ─── 揺れパターン：みゆき遭遇（天井付近でぶれる） ───
def shake_jumpscare():
    return [
        head(0.75, 0.05), sleep(0.06),
        head(0.50, 0.06), sleep(0.07),
        head(0.68, 0.07), sleep(0.08),
        head(0.55, 0.08), sleep(0.09),
    ]

# ─── 揺れパターン：みゆきが降りてくる（パニック） ───
def shake_panic():
    return [
        head(0.25, 0.06), sleep(0.07),
        head(-0.10, 0.06), sleep(0.07),
        head(0.15, 0.07), sleep(0.08),
        head(0.0, 0.12), sleep(0.12),
    ]

# ─── 揺れパターン：ドアを叩く ───
def shake_punch():
    return [
        head(0.08, 0.08), sleep(0.09),
        head(-0.06, 0.08), sleep(0.09),
        head(0.05, 0.09), sleep(0.10),
        head(0.0, 0.12), sleep(0.12),
    ]

# ─── 揺れパターン：お札効果（最大） ───
def shake_ofuda():
    return [
        head(0.25, 0.05), sleep(0.06),
        head(-0.18, 0.06), sleep(0.07),
        head(0.14, 0.07), sleep(0.08),
        head(-0.09, 0.08), sleep(0.09),
        head(0.05, 0.10), sleep(0.10),
        head(0.0, 0.15), sleep(0.15),
    ]


new_scene3 = [
    # ════ ヘッダー ════
    C("════════════════════════════════════════════"),
    C("【シーン3：公衆トイレの首無し少女】画面暗転→トイレ演出"),
    C("════════════════════════════════════════════"),

    # ─── フェーズ1: 到着・入場 ───
    C("── フェーズ1: トイレ前に到着・入場 ──"),
    set_viewers(38),
    flicker(),
    sfx("door_creak"),
    glitch(2, 1),
    wait(0.3),
    say("……着いた。ここだ。", "v024"),
    wait(1.64),

    # 建物を見渡す（左→右→正面）
    rot(-0.8, 1.0),
    wait(0.8),
    rot(-2.1, 1.2),
    wait(0.8),
    rot(-1.57, 0.8),
    wait(0.5),

    walk(True),
    pos_z(15, 8, "walk_inside"),
    wait(1.0),
    say("うわっ……カビ臭ぇ……最悪。制服汚れたら最悪なんですけど", "v025"),
    wait(4.84),
    chat("JKの感想がそれかよｗ", "配信民99", "member"),
    wait(1.0),
    chat("うわ汚そう", "ゆきんこ77", "moderator"),
    wait(0.3),
    chat("怖い…", "視聴者A"),
    wait(1.5),
    pos_z_await("walk_inside"),
    walk(False),

    # 個室を探す視線演出
    rot(-0.5, 0.7),
    wait(0.6),
    rot(-1.57, 0.7),
    wait(0.4),
    say("……えーと、奥から１、２……これか。奥から２つ目。", "v026"),
    wait(4.44),

    flicker(),
    wait(0.5),
    say("みんなどうする？開けるよ？……せーのっ！", "v027"),
    wait(3.39),
    sfx("door_creak"),
    glitch(1, 1),

    # ─── フェーズ2: 偽りの安心 ───
    C("── フェーズ2: 何もない（偽りの安心） ──"),
    say("……なんだよ、何もないじゃん。", "v028"),
    wait(2.02),
    say("おいおい、ビビらせやがって。やっぱりヤラセっていうか、ただの汚いトイレじゃん。萎えー", "v029"),
    wait(6.52),
    chat("よかったー", "視聴者A"),
    wait(0.3),
    chat("ほらね、何もないって", "名無しさん"),
    wait(0.4),
    chat("まあそんなもんよなｗ", "配信民99", "member"),
    wait(0.4),
    chat("準備してくれてありがとｗ", "深夜組"),
    # 安心の余韻 → 長い静寂
    wait(1.8),

    # ─── フェーズ3: 異変の始まり ───
    C("── フェーズ3: 異変の始まり ──"),
    say("……ん？なんか急に……寒くない？", "v030"),
    wait(3.25),
    glitch(2, 1),
    flicker(),
    wait(0.5),
    say("え、息……白い？……さっきまでこんなに寒かった？", "v031"),
    wait(4.78),
    chat("なんか画面おかしくない？", "深夜組"),
    wait(0.3),
    chat("ノイズ入ってるんだけど", "ガクブル太郎"),
    wait(0.3),
    chat("懐中電灯点滅してない？", "ホラー好き太郎", "member"),
    wait(1.2),

    # ─── フェーズ4: 「うしろ」flood ───
    C("── フェーズ4: 「うしろ」flood ──"),
    sfx("monster_growl", -22),   # 遠くから微かに
    tint(),
    flicker(),
    wait(0.3),
    chat("うしろ", "K", "horror"),
    wait(0.15),
    chat("くる", "K", "horror"),
    wait(0.15),
    chat("うしろ", "K", "horror"),
    wait(0.12),
    glitch(2, 1),
    chat("逃げて", "K", "horror"),
    wait(0.12),
    chat("うしろ", "K", "horror"),
    wait(0.10),
    chat("くる", "K", "horror"),
    wait(0.10),
    chat("うしろ", "K", "horror"),
    wait(0.10),
    chat("うしろ", "K", "horror"),
    wait(0.10),
    chat("うしろ", "K", "horror"),
    wait(0.5),
    say("え？……うしろ？", "v032"),
    wait(2.15),

    # ─── フェーズ5: ドアが閉まる + カメラシェイク ───
    C("── フェーズ5: ドアが閉まる + シェイク ──"),
    sfx("door_creak"),
    glitch(8, 2),
    *shake_door(),
    scare("white"),
    tint(),
    wait(0.5),
    set_viewers(502),
    say("ッ！？——ドアが——！", "v033"),
    wait(1.37),
    chat("上を見るな", "K", "horror"),
    wait(0.2),
    chat("上を見るな", "K", "horror"),
    wait(0.15),
    chat("来るぞ", "K", "horror"),
    wait(0.15),
    chat("みゆきさんが来る", "K", "horror"),
    wait(0.15),
    chat("上を見るな", "K", "horror"),
    wait(1.0),
    say("きゃあっ！？な、なに！？ドアが開かない！！ちょ、開けてよ！！", "v034"),
    wait(4.87),

    # ─── フェーズ6: 天井から赤い液体 ───
    C("── フェーズ6: 天井から赤い液体 ──"),
    flicker(),
    wait(0.5),
    *shake_drip(),
    say("……なに、これ……天井から何か……落ちてきて……", "v035"),
    wait(3.92),
    glitch(5, 2),
    flicker(),
    say("赤い……血？……嘘でしょ……", "v036"),
    wait(2.96),
    chat("天井見るな！！！", "幽霊ガチ勢", "member"),
    wait(0.3),
    chat("やばいやばいやばい", "ガクブル太郎"),
    wait(0.3),
    chat("逃げてっ！！", "ゆきんこ77", "moderator"),
    wait(0.7),

    # ─── フェーズ7: 段階的に天井を見上げる ───
    C("── フェーズ7: 段階的に天井を見上げる ──"),
    say("……は……？天井……？", "v037"),
    wait(1.79),

    head(0.20, 1.3),        # 少し見上げ始める
    wait(1.3),
    glitch(3, 1),
    wait(0.3),

    head(0.42, 1.4),        # さらに上
    wait(1.4),
    glitch(4, 1),
    flicker(),
    wait(0.3),

    head(0.65, 1.5),        # 完全に天井を見る
    wait(1.5),
    tint(),
    wait(0.9),              # 一瞬の静寂

    # ─── フェーズ8: みゆき遭遇・最強演出 ───
    C("── フェーズ8: みゆき遭遇・最強演出 ──"),
    sfx("monster_growl", 2),    # 最大音量
    scare("white"),
    flash(0.5),
    glitch(15, 6),
    *shake_jumpscare(),
    wait(0.5),
    say("ヒッ——！！ウソでしょ！？イヤァァァァ！！開けて！！開いてよ！！", "v038"),
    wait(4.5),
    chat("ぎゃああああ！！", "ゆきんこ77", "moderator"),
    wait(0.2),
    chat("なにあれなにあれなにあれ！！", "ガクブル太郎"),
    wait(0.2),
    chat("首がない！！！！", "ホラー好き太郎", "member"),
    wait(1.5),
    chat("見えてる", "K", "horror"),
    wait(0.3),
    chat("ずっと待ってた", "K", "horror"),
    wait(1.5),

    # ─── フェーズ9: みゆきが降りてくる ───
    C("── フェーズ9: みゆきが降りてくる ──"),
    sfx("monster_growl", -8),
    glitch(8, 3),
    say("降りてくる——降りて——", "v039"),
    wait(1.62),
    scare("red"),
    glitch(12, 5),
    *shake_panic(),
    wait(0.3),
    chat("画面真っ暗！！", "視聴者A"),
    wait(0.2),
    chat("逃げてーーー！！！", "幽霊ガチ勢", "member"),
    wait(0.2),
    chat("ドア開けろ！！！", "ガクブル太郎"),
    wait(0.3),
    chat("逃げられない", "K", "horror"),
    wait(1.5),

    head(0.0, 0.5),
    say("ドアが——開かない！！", "v040"),
    wait(2.0),
    sfx("door_creak"),
    flash(0.4),
    *shake_punch(),
    say("くそ！開かないっ！！", "v041"),
    wait(2.1),
    glitch(6, 2),
    say("足首を掴まれてる——冷たい——", "v042"),
    wait(2.8),
    chat("やばいやばいやばい", "名無しさん"),
    wait(0.3),
    chat("お札！！お札使え！！", "ゆきんこ77", "moderator"),
    wait(0.3),
    chat("さっきのお札！！", "幽霊ガチ勢", "member"),
    wait(1.5),

    # ─── フェーズ10: お札使用・脱出 ───
    C("── フェーズ10: お札使用・脱出 ──"),
    sfx("monster_growl", 3),
    glitch(4, 2),
    say("……お札。さっきの——", "v043"),
    wait(2.1),
    say("ポケットのお札。これしかない", "v044"),
    wait(2.7),
    chat("貼れ！！ドアに貼れ！！", "ホラー好き太郎", "member"),
    wait(0.3),
    chat("早く！！！", "視聴者A"),
    wait(1.5),
    say("ドアに——貼る！！", "v045"),
    wait(1.8),
    use_ofuda(),
    wait(0.8),
    scare("red"),
    flash(0.6),
    glitch(20, 8),
    *shake_ofuda(),
    wait(0.3),
    scare("white"),
    wait(0.5),
    say("——叫んだ。あいつが——叫んでる——", "v046"),
    wait(3.2),

    # ─── 暗転で場面転換 ───
    C("── 暗転で場面転換：トイレ→道路（門付近）へ ──"),
    fade_black(0.5),
    wait(1.5),
    pos_x(25, 0.01),
    pos_z(4, 0.01),
    rot(-1.57, 0.01),
    tint_clear(),
    wait(0.5),
    fade_clear(1.5),
    flashlight_on(),
    sfx("ambient_wind"),
    wait(0.5),
    say("……消えた。もういない……", "v047"),
    wait(2.0),
    chat("生きてる！！？", "視聴者A"),
    wait(0.2),
    chat("走れ！！！", "ホラー好き太郎", "member"),
    wait(0.2),
    chat("出ろおおお！！", "ゆきんこ77", "moderator"),
    wait(1.0),
    say("……外だ。戻ってきた……門の前……", "v048"),
    wait(3.0),
    say_clear(),
]

# ─────────────────────────────────────────
#  JSON を書き換える
# ─────────────────────────────────────────
with open(INPUT, encoding="utf-8") as f:
    data = json.load(f)

events = data["events"]

# シーン3の範囲を検出
s3_start = None
s4_start = None
for i, ev in enumerate(events):
    t = ev.get("type","")
    v = ev.get("_","")
    if t == "_comment" and "シーン3" in v and s3_start is None:
        s3_start = i - 1   # ═══ の行
    if t == "_comment" and "シーン4" in v and s4_start is None:
        s4_start = i - 1   # ═══ の行

# シーン3の末尾 = シーン4の═══ の直前のsay_clear
s3_end = s4_start          # s4_start の直前まで（そのインデックスは含まない）

print(f"シーン3 range: [{s3_start}, {s3_end}) → {s3_end - s3_start} events")
print(f"new_scene3: {len(new_scene3)} events")

# 置換
data["events"] = events[:s3_start] + new_scene3 + events[s3_end:]

with open(OUTPUT, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent="\t")

print("Done!")
