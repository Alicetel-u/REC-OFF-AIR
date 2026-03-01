extends Node

## 廃村入口チャプター専用: バス降車〜村の門くぐりまでの自動演出
## 主人公セリフ: 下部メッセージウィンドウ (_say)
## 視聴者コメント: チャット欄 (_chat)

var player: CharacterBody3D = null
var hud: Control = null

var _walking        := false
var _bob_t          := 0.0
var _flash_orig_energy : float = 1.0   # 懐中電灯の元の明るさ


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if _walking:
		_bob_t += delta * 4.8
		var ty := sin(_bob_t) * 0.05
		var tx := sin(_bob_t * 0.5) * 0.025
		player.camera.position.y = lerp(player.camera.position.y, ty, delta * 8.0)
		player.camera.position.x = lerp(player.camera.position.x, tx, delta * 8.0)
	else:
		player.camera.position = player.camera.position.lerp(Vector3.ZERO, delta * 5.0)


# ════════════════════════════════════════════════════════════════
# メインシーケンス
# ════════════════════════════════════════════════════════════════

func run() -> void:
	if not is_instance_valid(player):
		return

	_flash_orig_energy = player.flashlight.light_energy

	# ──────────────────────────────────────────────
	# 0. 開幕: バス停前・暗闇
	# ──────────────────────────────────────────────
	_chat("配信始まったー！")
	await _w(0.5)
	_chat("あれ？真っ暗……", "ゆきんこ77")
	await _w(0.4)
	_chat("何も見えないんだけどｗ", "配信民99")
	await _w(0.4)
	_chat("え、本当に来たの？", "幽霊ガチ勢")
	await _w(0.6)

	_say("来た来た…霧原村。バス降りたら…なにこの霧")
	await _w(1.4)
	_chat("懐中電灯！！", "ホラー好き太郎")
	await _w(0.4)
	_chat("真っ暗すぎるｗｗ")
	await _w(0.5)

	_say("ホラー好き太郎さん、懐中電灯ね、今出す今出す！ちょっと待って")
	await _w(1.7)
	_chat("はよはよｗ", "配信民99")
	await _w(0.4)
	_chat("バス停しか見えないじゃん", "視聴者A")
	await _w(0.6)

	_say("霧やばくない？バス停しか見えない…")
	await _w(1.3)
	_chat("霧やばすぎｗ", "幽霊ガチ勢")
	await _w(0.5)
	_chat("深夜0時に一人でここ来るとか", "ゆきんこ77")
	await _w(1.0)

	# ──────────────────────────────────────────────
	# 1. 正面に向き直す → 懐中電灯を点灯
	# ──────────────────────────────────────────────
	_say_clear()
	_rot_y(0.0, 1.6)
	_head_x(0.0, 0.8)
	await _w(0.9)

	_say("よし、ライトつけよう")
	await _w(0.6)
	await _flashlight_on()

	_say_clear()
	_chat("きたーーー！！！", "ホラー好き太郎")
	await _w(0.3)
	_chat("明るくなったｗ", "配信民99")
	await _w(0.4)
	_chat("よかったぁ…", "ゆきんこ77")
	await _w(0.8)

	_say("怖そうって言ってる人いるけど、怖いわ実際。でもほら、霧の中に道がある")
	await _w(1.8)
	_chat("うわぁ…道がある", "視聴者A")
	await _w(0.5)
	_chat("引き返せ引き返せｗｗｗ", "ゆきんこ77")
	await _w(0.5)
	_chat("絶対ヤバいって", "幽霊ガチ勢")
	await _w(0.8)

	# ──────────────────────────────────────────────
	# 2. コメント読み上げ・状況説明
	# ──────────────────────────────────────────────
	_say("ゆきんこ77さん、引き返せって？ざんね～んもうここまで来たら引き返せないよ")
	await _w(2.0)
	_chat("ｗｗｗｗ", "配信民99")
	await _w(0.4)
	_chat("覚悟完了してて草", "幽霊ガチ勢")
	await _w(0.7)

	_say("奥の倉庫にVHSテープが隠されてるって情報があってさ")
	await _w(1.5)
	_chat("VHSって何？", "視聴者A")
	await _w(0.5)
	_chat("証拠映像的なやつ？", "配信民99")
	await _w(0.7)

	_say("そう、証拠の映像テープ。持ち帰れたら完璧なんだよね")
	await _w(1.5)
	_chat("ガチ勢すぎるｗ", "ホラー好き太郎")
	await _w(0.4)
	_chat("応援してるよ！！", "ゆきんこ77")
	await _w(0.7)

	_head_x(-0.05, 0.3)
	await _w(0.4)
	_head_x(0.0, 0.3)
	await _w(0.3)

	_say("よし、行くよ。みんなついてきて")
	await _w(1.2)
	_chat("ついてく！！", "ゆきんこ77")
	await _w(0.4)
	_chat("やめろやめろｗ", "配信民99")
	await _w(0.7)

	# ──────────────────────────────────────────────
	# 3. 歩き始める（Z=15 → Z=-1）
	# ──────────────────────────────────────────────
	_say_clear()
	_walking = true
	_chat("行くな行くな", "ホラー好き太郎")
	await _w(0.5)
	_chat("絶対ヤバいって", "配信民99")
	var walk1 := _pos_z(-1.0, 10.0)

	await _w(2.5)
	_rot_y(-0.55, 1.0)
	await _w(0.7)
	_say("畑か…もう誰も手入れしてないんだな")
	await _w(1.2)
	_chat("廃村感えぐい", "幽霊ガチ勢")
	await _w(0.5)
	_chat("本当に誰もいないんだ…", "視聴者A")
	await _w(0.8)

	_say_clear()
	_rot_y(0.45, 0.9)
	await _w(0.9)
	_chat("こっちも同じだ", "ゆきんこ77")
	await _w(0.5)
	_chat("足元気をつけて", "配信民99")
	await _w(0.5)
	_say("本当に人の気配が全くない。廃村ってこういうことか")
	await _w(1.2)
	_rot_y(0.0, 0.8)
	await walk1.finished

	# ──────────────────────────────────────────────
	# 4. 門へ近づく（Z=-1 → Z=-12）
	# ──────────────────────────────────────────────
	_say_clear()
	_say("あれ…あれが村の門か")
	await _w(0.9)
	_chat("でかいな！！", "ホラー好き太郎")
	await _w(0.5)
	_chat("立入禁止じゃない？ｗ", "ゆきんこ77")
	await _w(0.6)
	_say("ゆきんこ77さん立入禁止じゃないかって…うん、まあたぶんそう（笑）")
	await _w(1.6)
	_chat("開き直ってて草ｗ", "配信民99")
	await _w(0.4)
	_chat("霧の中に浮かんでてこわ…", "幽霊ガチ勢")
	var walk2 := _pos_z(-12.0, 5.0)

	await _w(2.0)
	_say_clear()
	_chat("霧が濃くなってる…", "視聴者A")
	await _w(0.5)
	_chat("なんか雰囲気やばすぎ", "ゆきんこ77")
	await walk2.finished

	# ──────────────────────────────────────────────
	# 5. 門の前で立ち止まり、看板を見上げる
	# ──────────────────────────────────────────────
	_walking = false
	await _w(0.5)

	_say("あ、看板がある。なんて書いてある？")
	await _w(0.9)
	_head_x(1.0, 1.0)
	await _w(0.5)
	_chat("読める？", "配信民99")
	await _w(0.4)
	_chat("霧原村って書いてある！", "視聴者A")
	await _w(0.5)
	_chat("不吉すぎるｗ", "幽霊ガチ勢")
	await _w(0.5)

	_say("霧原村…か。")
	await _w(1.0)
	_chat("引き返してーー！！", "ホラー好き太郎")
	await _w(0.4)
	_chat("ひぃぃ…", "ゆきんこ77")
	await _w(0.8)

	# ──────────────────────────────────────────────
	# 6. 正面に向き直して門をくぐる
	# ──────────────────────────────────────────────
	_head_x(0.0, 0.6)
	await _w(0.5)
	_say("行くよ。絶対配信事故にしてみせる")
	await _w(1.0)
	_chat("行くな！！", "ホラー好き太郎")
	await _w(0.3)
	_chat("配信事故って言い方ｗ", "配信民99")
	await _w(0.4)
	_chat("ついてく…ついてくよ…", "ゆきんこ77")
	await _w(0.5)

	_say_clear()
	_walking = true
	await _w(0.2)
	_chat("入ったｗｗ", "視聴者A")
	await _w(0.3)
	_chat("もう戻れないｗ", "配信民99")
	await _pos_z(-21.0, 5.0).finished
	_walking = false
	if is_instance_valid(hud):
		hud.hide_monologue()


# ════════════════════════════════════════════════════════════════
# 懐中電灯フリッカー点灯
# ════════════════════════════════════════════════════════════════

func _flashlight_on() -> void:
	player.flashlight.light_energy = 0.0
	player.flashlight.visible = true
	player.flashlight_on = true

	# チラつき → 安定のフリッカー演出
	var tw := create_tween()
	tw.tween_property(player.flashlight, "light_energy", 0.6,                 0.04)  # ぱっと
	tw.tween_property(player.flashlight, "light_energy", 0.0,                 0.06)  # 消える
	tw.tween_property(player.flashlight, "light_energy", _flash_orig_energy,  0.05)  # 再点灯
	tw.tween_property(player.flashlight, "light_energy", 0.2,                 0.08)  # ちらつき
	tw.tween_property(player.flashlight, "light_energy", _flash_orig_energy,  0.20)  # 安定
	await tw.finished


# ════════════════════════════════════════════════════════════════
# プライベートヘルパー
# ════════════════════════════════════════════════════════════════

func _say(text: String) -> void:
	if is_instance_valid(hud):
		hud.show_monologue(text)


func _say_clear() -> void:
	if is_instance_valid(hud):
		hud.hide_monologue()


func _chat(msg: String, user: String = "", utype: String = "") -> void:
	if is_instance_valid(hud):
		hud.add_chat(msg, user, utype)


func _w(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _rot_y(target: float, dur: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(player, "rotation:y", target, dur).set_trans(Tween.TRANS_SINE)
	return tw


func _head_x(target: float, dur: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(player.head, "rotation:x", target, dur).set_trans(Tween.TRANS_SINE)
	return tw


func _pos_z(target_z: float, dur: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(player, "position:z", target_z, dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw
