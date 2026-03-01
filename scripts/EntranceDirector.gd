extends Node

## 廃村入口チャプター専用: バス降車〜村の門くぐりまでの自動演出
## セリフデータは res://dialogue/ch01_entrance.json から読み込む

const DIALOGUE_JSON := "res://dialogue/ch01_entrance.json"

var player: CharacterBody3D = null
var hud: Control = null

var _walking           := false
var _bob_t             := 0.0
var _flash_orig_energy : float = 1.0


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


# ════════════════════════════════════════════════════════════════════
# メインシーケンス（JSON 駆動）
# ════════════════════════════════════════════════════════════════════

func run() -> void:
	if not is_instance_valid(player):
		return

	_flash_orig_energy = player.flashlight.light_energy

	# JSON 読み込み
	var abs_path := ProjectSettings.globalize_path(DIALOGUE_JSON)
	if not FileAccess.file_exists(abs_path):
		push_error("EntranceDirector: dialogue JSON not found: " + DIALOGUE_JSON)
		return

	var text := FileAccess.get_file_as_string(abs_path)
	var json  := JSON.new()
	if json.parse(text) != OK:
		push_error("EntranceDirector: JSON parse error — " + json.get_error_message())
		return

	var data   : Dictionary = json.get_data()
	var events : Array      = data.get("events", [])

	# 並行 Tween を id で管理（pos_z の非同期歩行用）
	var active_tweens : Dictionary = {}

	for ev: Dictionary in events:
		var t : String = ev.get("type", "")
		match t:

			"say":
				_say(ev.get("text", ""))

			"say_clear":
				_say_clear()

			"chat":
				_chat(ev.get("msg", ""), ev.get("user", ""), ev.get("utype", ""))

			"wait":
				await get_tree().create_timer(float(ev.get("sec", 0.5))).timeout

			"rot_y":
				_rot_y(float(ev.get("target", 0.0)), float(ev.get("dur", 1.0)))

			"head_x":
				_head_x(float(ev.get("target", 0.0)), float(ev.get("dur", 1.0)))

			"pos_z":
				var tw := _pos_z(float(ev.get("target", 0.0)), float(ev.get("dur", 5.0)))
				var id : String = ev.get("id", "")
				if not id.is_empty():
					active_tweens[id] = tw

			"pos_z_await":
				var id : String = ev.get("id", "")
				if id in active_tweens and is_instance_valid(active_tweens[id]):
					await active_tweens[id].finished
					active_tweens.erase(id)

			"walk_set":
				_walking = ev.get("on", false)

			"flashlight_on":
				await _flashlight_on()

			_:
				pass  # 未知タイプは無視

	_walking = false
	if is_instance_valid(hud):
		hud.hide_monologue()


# ════════════════════════════════════════════════════════════════════
# 懐中電灯フリッカー点灯
# ════════════════════════════════════════════════════════════════════

func _flashlight_on() -> void:
	player.flashlight.light_energy = 0.0
	player.flashlight.visible = true
	player.flashlight_on = true

	var tw := create_tween()
	tw.tween_property(player.flashlight, "light_energy", 0.6,                 0.04)  # ぱっと
	tw.tween_property(player.flashlight, "light_energy", 0.0,                 0.06)  # 消える
	tw.tween_property(player.flashlight, "light_energy", _flash_orig_energy,  0.05)  # 再点灯
	tw.tween_property(player.flashlight, "light_energy", 0.2,                 0.08)  # ちらつき
	tw.tween_property(player.flashlight, "light_energy", _flash_orig_energy,  0.20)  # 安定
	await tw.finished


# ════════════════════════════════════════════════════════════════════
# プライベートヘルパー
# ════════════════════════════════════════════════════════════════════

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
