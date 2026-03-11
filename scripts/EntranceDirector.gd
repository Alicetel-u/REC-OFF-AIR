extends Node

## JSON 駆動のシーケンス演出エンジン
## セリフ・移動・チャット・選択肢分岐をサポート

const DIALOGUE_JSON := "res://dialogue/ch01_entrance.json"
const HorrorChoicePanelScript := preload("res://scripts/HorrorChoicePanel.gd")
const EndingPlayerScript := preload("res://scripts/EndingPlayer.gd")

var player: CharacterBody3D = null
var hud: Control = null

var _walking : bool           = false
var _moving : bool            = false   # 実際に前進するか（walk_setで制御）
var _bob_t : float            = 0.0
var _flash_orig_energy : float = 1.0
var _fade_layer        : CanvasLayer = null
var _fade_rect         : ColorRect = null
var _bg_image_rect     : TextureRect = null
var _bg_vignette       : ColorRect = null
var _bg_walk_active    : bool      = false
var _bg_walk_t         : float     = 0.0
var _bg_walk_speed     : float     = 1.0
var _bg_walk_brightness: float     = 0.3
var _bg_walk_zoom_start: float     = 1.0
var _bg_walk_zoom_end  : float     = 1.4
var _bg_walk_zoom_dur  : float     = 30.0
var _miyuki_instance   : Node3D    = null
var _miyuki_convulsion : float     = 0.0   # 痙攣の強さ (0=無し)
var _miyuki_track      : bool      = false  # プレイヤーの方を向く
var _miyuki_shader_mat : ShaderMaterial = null

# クリックスキップ制御
var _skip_to_next_say : bool = false


func _unhandled_input(_event: InputEvent) -> void:
	pass
	#if event is InputEventMouseButton \
	#		and event.pressed \
	#		and event.button_index == MOUSE_BUTTON_LEFT:
	#	_skip_to_next_say = true
	#	SoundManager.stop_voice()


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if _walking:
		var prev_bob : float = _bob_t
		_bob_t += delta * Player.BOB_FREQ
		var ty : float = abs(sin(_bob_t)) * Player.BOB_AMP
		var tx : float = sin(_bob_t * 2.0) * (Player.BOB_AMP * 0.4)
		player.camera.position.y = lerp(player.camera.position.y, ty, delta * 12.0)
		player.camera.position.x = lerp(player.camera.position.x, tx, delta * 12.0)
		# 足音 — bob_t が π の倍数を通過（着地タイミング）で再生
		if int(_bob_t / PI) != int(prev_bob / PI) and prev_bob > 0.0:
			SoundManager.play_footstep(GameManager.chapter_index, false)
	else:
		if player.camera.position.length_squared() > 0.0001:
			player.camera.position = player.camera.position.lerp(Vector3.ZERO, delta * 5.0)
	# ── 背景画像ウォーク演出 ──
	if _bg_walk_active:
		_bg_walk_t += delta * _bg_walk_speed
		_update_bg_walk()
	# ── みゆきゴースト更新 ──
	_miyuki_update(delta)


# ════════════════════════════════════════════════════════════════════
# クリーンアップ（チャプター遷移前に必ず呼ぶ）
# ════════════════════════════════════════════════════════════════════

func cleanup() -> void:
	_bg_walk_active = false
	# root直下に追加したCanvasLayerを確実に削除
	if is_instance_valid(_fade_layer):
		if _fade_layer.get_parent():
			_fade_layer.get_parent().remove_child(_fade_layer)
		_fade_layer.queue_free()
		_fade_layer = null
		_fade_rect = null
		_bg_image_rect = null
		_bg_vignette = null
	# VHSシェーダーをリセット
	_vhs_reset()


# ════════════════════════════════════════════════════════════════════
# メインシーケンス（JSON 駆動）
# ════════════════════════════════════════════════════════════════════

func run() -> void:
	await run_from_path(DIALOGUE_JSON)


func run_from_path(json_path: String) -> void:
	if not is_instance_valid(player):
		return

	_flash_orig_energy = player.flashlight.light_energy

	# JSON 読み込み（res:// パスのまま — エクスポートビルドでも動作する）
	if not FileAccess.file_exists(json_path):
		push_error("EntranceDirector: dialogue JSON not found: " + json_path)
		return

	var text := FileAccess.get_file_as_string(json_path)
	var json  := JSON.new()
	if json.parse(text) != OK:
		push_error("EntranceDirector: JSON parse error — " + json.get_error_message())
		return

	var data   : Dictionary = json.get_data()
	var events : Array      = data.get("events", [])

	# ラベル → インデックスのマップを事前構築
	var label_map : Dictionary = {}
	for i in range(events.size()):
		var ev_check : Dictionary = events[i]
		if ev_check.get("type", "") == "label":
			label_map[ev_check.get("name", "")] = i

	# 並行 Tween を id で管理（pos_z の非同期歩行用）
	var active_tweens : Dictionary = {}

	# セクションスキップ: start_section 回目の stage_swap まで飛ばす
	var skip_section : int = GameManager.start_section
	GameManager.start_section = 0  # リセット（先にクリアして再リロード時のループ防止）
	print("EntranceDirector: skip_section=%d, events=%d" % [skip_section, events.size()])
	if skip_section > 0 and is_inside_tree():
		var swap_count := 0
		var skip_idx := 0
		while skip_idx < events.size():
			var skip_ev : Dictionary = events[skip_idx]
			if skip_ev.get("type", "") == "stage_swap":
				swap_count += 1
				print("EntranceDirector: found stage_swap #%d at idx=%d scene=%s" % [swap_count, skip_idx, skip_ev.get("scene", "")])
				if swap_count >= skip_section:
					# この stage_swap を実行してから、次のイベントから開始
					if is_inside_tree():
						await _stage_swap(
							skip_ev.get("scene", ""),
							skip_ev.get("spawn", [0, 1, 0]))
					# 懐中電灯ON（スキップ先でも見えるように）
					if is_instance_valid(player):
						player.flashlight.visible = true
						player.flashlight_on = true
						player.flashlight.light_energy = _flash_orig_energy
					# 商店街セクション（bg_imageパート）は暗転状態で始まる
					if swap_count == 1 and is_inside_tree():
						_ensure_fade_layer()
						_fade_rect.color = Color(0, 0, 0, 1)
					break
			skip_idx += 1
		# stage_swap の次から再開（見つからなかった場合は最初から）
		if swap_count >= skip_section:
			events = events.slice(skip_idx + 1)
			# ラベルマップを再構築
			label_map.clear()
			for i2 in range(events.size()):
				var ev2 : Dictionary = events[i2]
				if ev2.get("type", "") == "label":
					label_map[ev2.get("name", "")] = i2

	var idx := 0
	while idx < events.size():
		if not is_inside_tree():
			return
		var ev : Dictionary = events[idx]
		var t : String = ev.get("type", "")
		match t:

			"say":
				# 新しいセリフが来たらスキップフラグをリセット
				_skip_to_next_say = false
				_say(ev.get("text", ""))
				var _vname : String = ev.get("voice", "")
				if not _vname.is_empty():
					SoundManager.play_voice(
						"res://assets/audio/voice/ch01/" + _vname + ".wav")
				# ボイス再生はノンブロッキング → wait イベント側で吸収

			"say_clear":
				_say_clear()
				SoundManager.stop_voice()

			"chat":
				# スキップ中はチャット追加をスキップ
				if not _skip_to_next_say:
					_chat(ev.get("msg", ""), ev.get("user", ""), ev.get("utype", ""))

			"sleep":
				## スキップ・ボイス待機を無視する固定待機（横見演出など）
				if is_inside_tree():
					var _sleep_sec : float = float(ev.get("sec", 1.0)) / GameManager.playback_speed
					await get_tree().create_timer(_sleep_sec).timeout

			"wait":
				if not _skip_to_next_say:
					var _sec := float(ev.get("sec", 0.5))
					# play() 直後は playing フラグが立つまで1フレーム掛かる
					if not is_inside_tree():
						continue
					await get_tree().process_frame
					# ボイス再生中なら先にボイスを待ち、残り時間のみ追加待機
					if SoundManager.is_voice_playing():
						var _t0 := Time.get_ticks_msec()
						await SoundManager.await_voice(_sec + 5.0)
						if not _skip_to_next_say:
							_sec = max(_sec - (Time.get_ticks_msec() - _t0) / 1000.0, 0.0)
							await _skippable_wait(_sec)  # playback_speed は _skippable_wait 内で適用
					else:
						await _skippable_wait(_sec)  # playback_speed は _skippable_wait 内で適用

			"rot_y":
				if not GameManager.debug_free_move:
					_rot_y(float(ev.get("target", 0.0)), float(ev.get("dur", 1.0)))

			"head_x":
				if not GameManager.debug_free_move:
					_head_x(float(ev.get("target", 0.0)), float(ev.get("dur", 1.0)))

			"motion":
				if not GameManager.debug_free_move:
					await _motion(ev.get("name", "look_around"), float(ev.get("dur", 2.0)))

			"pos_z":
				if not GameManager.debug_free_move:
					var tw := _pos_z(float(ev.get("target", 0.0)), float(ev.get("dur", 0.0)))
					var tw_id : String = ev.get("id", "")
					if not tw_id.is_empty():
						active_tweens[tw_id] = tw

			"pos_z_await":
				if not GameManager.debug_free_move:
					var tw_id : String = ev.get("id", "")
					if tw_id in active_tweens:
						var tw_ref = active_tweens[tw_id]
						if tw_ref and tw_ref.is_valid():
							await _await_tween_safe(tw_ref, 60.0)
						active_tweens.erase(tw_id)

			"pos_x":
				if not GameManager.debug_free_move:
					var tw := _pos_x(float(ev.get("target", 0.0)), float(ev.get("dur", 0.0)))
					var tw_id : String = ev.get("id", "")
					if not tw_id.is_empty():
						active_tweens[tw_id] = tw

			"pos_x_await":
				if not GameManager.debug_free_move:
					var tw_id : String = ev.get("id", "")
					if tw_id in active_tweens:
						var tw_ref = active_tweens[tw_id]
						if tw_ref and tw_ref.is_valid():
							await _await_tween_safe(tw_ref, 60.0)
						active_tweens.erase(tw_id)

			"pos_y":
				if not GameManager.debug_free_move:
					var tw := _pos_y(float(ev.get("target", 1.0)), float(ev.get("dur", 2.0)))
					var tw_id : String = ev.get("id", "")
					if not tw_id.is_empty():
						active_tweens[tw_id] = tw

			"pos_y_await":
				if not GameManager.debug_free_move:
					var tw_id : String = ev.get("id", "")
					if tw_id in active_tweens:
						var tw_ref = active_tweens[tw_id]
						if tw_ref and tw_ref.is_valid():
							await _await_tween_safe(tw_ref, 60.0)
						active_tweens.erase(tw_id)

			"set_viewers":
				_set_viewers(int(ev.get("count", 0)))

			"walk_set":
				if not GameManager.debug_free_move:
					_walking = ev.get("on", false)
					player.forced_moving = _walking

			"flashlight_on":
				await _flashlight_on()

			"polaroid_video":
				await _polaroid_video(ev.get("path", ""))

			# ── 分岐システム ──

			"label":
				pass  # ラベルは通過するだけ（事前にマップ構築済み）

			"goto":
				var target_label : String = ev.get("label", "")
				if target_label in label_map:
					idx = label_map[target_label]
					continue  # idx++ をスキップ

			"goto_route":
				# ending_route に応じて異なるラベルにジャンプ
				var routes : Dictionary = ev.get("routes", {})
				var route_key := str(GameManager.ending_route)
				if route_key in routes:
					var target_label : String = routes[route_key]
					if target_label in label_map:
						idx = label_map[target_label]
						continue

			"use_ofuda":
				# お札を1枚消費
				GameManager.ofuda_count = max(0, GameManager.ofuda_count - 1)

			"set_route":
				# ending_route を設定
				GameManager.ending_route = int(ev.get("route", -1))

			"choice":
				# ホラー選択肢パネルを表示し、結果に応じて分岐
				var choice_result := await _show_horror_choice(ev)
				# 結果に応じたラベルにジャンプ
				var targets : Array = ev.get("targets", [])
				if choice_result < targets.size():
					var target_label : String = targets[choice_result]
					if target_label in label_map:
						idx = label_map[target_label]
						continue

			# ── ホラー演出イベント ──

			"horror_flash":
				_horror_flash(float(ev.get("dur", 0.3)))

			"horror_glitch":
				_horror_glitch(float(ev.get("intensity", 8.0)), int(ev.get("count", 3)))

			"horror_tint":
				_horror_tint()

			"horror_tint_clear":
				_horror_tint_clear()

			"scare_flash":
				var sf_str : String = ev.get("color", "white")
				var sf_col := Color.WHITE if sf_str == "white" else Color(0.9, 0.0, 0.0)
				if is_instance_valid(hud):
					hud._do_scare_flash(sf_col)

			"horror_red":
				if is_instance_valid(hud):
					hud.start_horror_red(float(ev.get("dur", 8.0)))

			"horror_red_clear":
				if is_instance_valid(hud):
					hud.stop_horror_red()

			"chat_horror_mode":
				var chrome := _get_chrome()
				if chrome and chrome.has_method("chat_horror_mode"):
					chrome.chat_horror_mode(float(ev.get("dur", 10.0)))

			"chat_horror_clear":
				var chrome := _get_chrome()
				if chrome and chrome.has_method("chat_horror_clear"):
					chrome.chat_horror_clear()

			"superchat":
				_story_superchat(ev.get("name", ""), ev.get("msg", ""), int(ev.get("amount", 500)))

			"flashlight_flicker":
				await _flashlight_flicker()

			"sfx":
				var sound : String = ev.get("sound", "")
				var sfile : String = ev.get("file", "")
				var vol   : float  = float(ev.get("vol", -6.0))
				if not sfile.is_empty():
					SoundManager.play_sfx_file(sfile, vol)
				else:
					match sound:
						"ambient_wind":  SoundManager.start_ambient(0)
						"door_creak":    SoundManager.play_door_creak()
						"monster_growl": SoundManager.play_monster_growl(vol)
						"wooden_floor":  SoundManager.play_footstep(GameManager.chapter_index, false)

			"flashlight_off":
				_flashlight_off()

			"bg_image":
				await _bg_image_show(
					ev.get("file", ""),
					float(ev.get("dur", 1.0)),
					float(ev.get("brightness", 0.35)),
					float(ev.get("radius", 0.38)),
					float(ev.get("softness", 0.45)),
					ev.get("center", [0.5, 0.5]))

			"bg_image_clear":
				await _bg_image_clear(float(ev.get("dur", 1.0)))

			"bg_image_flicker":
				_bg_image_flicker(
					float(ev.get("dur", 3.0)),
					float(ev.get("brightness", 0.3)))

			"bg_walk_start":
				_bg_walk_start(
					float(ev.get("speed", 1.0)),
					float(ev.get("zoom_end", 1.4)),
					float(ev.get("zoom_dur", 30.0)),
					float(ev.get("radius", 0.22)),
					float(ev.get("softness", 0.35)))

			"bg_walk_stop":
				_bg_walk_stop()

			"fade_black":
				await _fade_black(float(ev.get("dur", 0.8)), float(ev.get("target", 1.0)))

			"fade_clear":
				await _fade_clear(float(ev.get("dur", 0.8)), float(ev.get("target", 0.0)))

			"play_ending":
				await _play_ending(ev)

			"bad_end":
				await _bad_end(
					ev.get("title", "BAD END"),
					ev.get("return_label", ""),
					float(ev.get("fade_dur", 1.5)),
					float(ev.get("display_dur", 4.0)),
					ev.get("image", ""))
				# 「選択肢に戻る」を選んだ場合、ラベルにジャンプ
				if _bad_end_return_label != "" and _bad_end_return_label in label_map:
					idx = label_map[_bad_end_return_label]
					_bad_end_return_label = ""
					continue

			"stage_swap":
				await _stage_swap(ev.get("scene", ""), ev.get("spawn", [0, 1, 0]))

			# ── 新ホラー演出コマンド ──

			"camera_shake":
				if is_instance_valid(player):
					player.start_camera_shake(
						float(ev.get("intensity", 0.05)),
						float(ev.get("dur", 0.5)))

			"vhs_glitch":
				await _vhs_glitch(
					float(ev.get("intensity", 0.8)),
					float(ev.get("dur", 1.0)))

			"vhs_reset":
				_vhs_reset()

			"fisheye":
				_fisheye_on(
					float(ev.get("distortion", 0.5)),
					float(ev.get("breath", 0.08)),
					float(ev.get("dur", 1.5)))

			"fisheye_off":
				_fisheye_off(float(ev.get("dur", 1.0)))

			"light_flicker":
				await _light_flicker(
					int(ev.get("count", 5)),
					float(ev.get("dur", 1.5)))

			"desaturate":
				_desaturate(
					float(ev.get("amount", 0.8)),
					float(ev.get("dur", 0.5)))

			"slow_motion":
				await _slow_motion(
					float(ev.get("scale", 0.3)),
					float(ev.get("dur", 2.0)))

			"fog_change":
				_fog_change(ev)

			"distortion":
				_distortion(
					float(ev.get("amount", 0.03)),
					float(ev.get("dur", 1.0)))

			"vignette":
				_vignette(
					float(ev.get("amount", 0.3)),
					float(ev.get("dur", 0.5)))

			"garbled_text":
				_garbled_text(
					ev.get("text", ""),
					float(ev.get("dur", 0.3)))

			"set_fps":
				# Engine.max_fps を変更してカクツキ演出（0 = 制限なし＝通常）
				var target_fps : int = int(ev.get("fps", 0))
				Engine.max_fps = target_fps

			"chat_flood":
				# チャット欄を特定メッセージで埋め尽くす
				await _chat_flood(
					ev.get("msg", "藁"),
					int(ev.get("count", 10)),
					float(ev.get("interval", 0.1)),
					ev.get("color", ""))

			"miyuki_spawn":
				_miyuki_spawn(ev)

			"miyuki_move":
				_miyuki_move(ev)

			"miyuki_despawn":
				_miyuki_despawn()

			_:
				pass  # 未知タイプは無視

		idx += 1

	_walking = false
	if is_instance_valid(hud):
		hud.hide_monologue()


# ════════════════════════════════════════════════════════════════════
# ホラー選択肢パネル
# ════════════════════════════════════════════════════════════════════

func _show_horror_choice(ev: Dictionary) -> int:
	var panel : Node = HorrorChoicePanelScript.new()
	get_tree().root.add_child(panel)

	var prompt : String = ev.get("prompt", "")
	var choices : Array = ev.get("choices", [])
	var title_text : String = ev.get("title", "")
	var danger : bool = ev.get("danger", false)

	panel.show_choice(prompt, choices, title_text, danger)

	var result : int = await panel.choice_selected
	panel.queue_free()
	return result


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

## Tweenの完了をタイムアウト付きで待機（Web環境でのフリーズ防止）
func _await_tween_safe(tw: Tween, max_sec: float) -> void:
	var elapsed := 0.0
	while tw and tw.is_valid() and tw.is_running():
		if not is_inside_tree():
			return
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if elapsed >= max_sec:
			push_warning("EntranceDirector: tween await timed out after %.0fs" % max_sec)
			tw.kill()
			break


## クリックでキャンセル可能な待機（playback_speed で短縮）
func _skippable_wait(sec: float) -> void:
	if sec <= 0.0 or _skip_to_next_say:
		return
	var actual_sec : float = sec / GameManager.playback_speed
	var t_end := Time.get_ticks_msec() + int(actual_sec * 1000)
	while Time.get_ticks_msec() < t_end and not _skip_to_next_say:
		if not is_inside_tree():
			return
		await get_tree().process_frame


func _say(text: String) -> void:
	if is_instance_valid(hud):
		hud.show_monologue(text)


func _say_clear() -> void:
	if is_instance_valid(hud):
		hud.hide_monologue()


func _chat(msg: String, user: String = "", utype: String = "") -> void:
	if is_instance_valid(hud):
		hud.add_chat(msg, user, utype)


func _rot_y(target: float, dur: float) -> Tween:
	var tw := create_tween()
	var actual_dur : float = dur / GameManager.playback_speed
	tw.tween_property(player, "rotation:y", target, actual_dur).set_trans(Tween.TRANS_SINE)
	return tw


func _head_x(target: float, dur: float) -> Tween:
	var tw := create_tween()
	var actual_dur : float = dur / GameManager.playback_speed
	tw.tween_property(player.head, "rotation:x", target, actual_dur).set_trans(Tween.TRANS_SINE)
	return tw


func _motion(motion_name: String, dur: float) -> void:
	if not is_inside_tree():
		return
	var base_y : float = player.rotation.y
	var base_x : float = player.head.rotation.x
	var step : float = dur / 4.0  # 各ステップの基本時間
	match motion_name:
		"look_around":
			# 左→右→正面
			await _rot_y(base_y - 0.8, step).finished
			await _rot_y(base_y + 0.8, step * 2.0).finished
			_rot_y(base_y, step)
		"nod":
			# 下→上→正面
			await _head_x(base_x + 0.25, step * 0.5).finished
			await _head_x(base_x - 0.1, step * 0.5).finished
			_head_x(base_x, step * 0.3)
		"shake_head":
			# 左→右→左→正面
			var s : float = dur / 5.0
			await _rot_y(base_y - 0.4, s).finished
			await _rot_y(base_y + 0.4, s).finished
			await _rot_y(base_y - 0.3, s).finished
			await _rot_y(base_y + 0.2, s).finished
			_rot_y(base_y, s)
		"look_behind_slow":
			# ゆっくり真後ろ→戻る
			await _rot_y(base_y + 3.14, dur * 0.6).finished
			await get_tree().create_timer(dur * 0.1 / GameManager.playback_speed).timeout
			_rot_y(base_y, dur * 0.3)
		"startle_up":
			# びくっと上→戻る
			await _head_x(base_x - 0.6, step * 0.3).finished
			await get_tree().create_timer(step * 0.5 / GameManager.playback_speed).timeout
			_head_x(base_x, step * 0.5)
		"peek_left":
			# 少し左→戻る
			await _rot_y(base_y - 0.5, step * 0.7).finished
			await get_tree().create_timer(step * 0.5 / GameManager.playback_speed).timeout
			_rot_y(base_y, step * 0.5)
		"peek_right":
			# 少し右→戻る
			await _rot_y(base_y + 0.5, step * 0.7).finished
			await get_tree().create_timer(step * 0.5 / GameManager.playback_speed).timeout
			_rot_y(base_y, step * 0.5)
		"look_down_up":
			# 下→上→正面
			await _head_x(base_x + 0.5, step).finished
			await get_tree().create_timer(step * 0.3 / GameManager.playback_speed).timeout
			await _head_x(base_x - 0.4, step).finished
			_head_x(base_x, step * 0.5)
		"tremble":
			# 小刻みに震える
			var s : float = dur / 8.0
			for i in range(4):
				if not is_inside_tree():
					return
				var off_y : float = randf_range(-0.08, 0.08)
				var off_x : float = randf_range(-0.05, 0.05)
				_rot_y(base_y + off_y, s)
				await _head_x(base_x + off_x, s).finished
			_rot_y(base_y, s)
			_head_x(base_x, s)


var _tw_pos_z : Tween = null
var _tw_pos_x : Tween = null
var _tw_pos_y : Tween = null
const _WALK_SPEED := 1.8  # 自動演出の歩行速度 (units/s)

func _pos_z(target_z: float, dur: float) -> Tween:
	if _tw_pos_z and _tw_pos_z.is_valid():
		_tw_pos_z.kill()
	# dur <= 0 なら距離と一定速度から自動算出
	var dist : float = abs(target_z - player.position.z)
	var base_dur : float = dur if dur > 0.0 else max(dist / _WALK_SPEED, 0.1)
	var actual_dur : float = base_dur / GameManager.playback_speed
	_tw_pos_z = create_tween()
	_tw_pos_z.tween_property(player, "position:z", target_z, actual_dur) \
			.set_trans(Tween.TRANS_LINEAR)
	return _tw_pos_z


func _pos_y(target_y: float, dur: float) -> Tween:
	if _tw_pos_y and _tw_pos_y.is_valid():
		_tw_pos_y.kill()
	var base_dur : float = dur if dur > 0.0 else 2.0
	var actual_dur : float = base_dur / GameManager.playback_speed
	_tw_pos_y = create_tween()
	_tw_pos_y.tween_property(player, "position:y", target_y, actual_dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return _tw_pos_y


func _pos_x(target_x: float, dur: float) -> Tween:
	if _tw_pos_x and _tw_pos_x.is_valid():
		_tw_pos_x.kill()
	# dur <= 0 なら距離と一定速度から自動算出
	var dist : float = abs(target_x - player.position.x)
	var base_dur : float = dur if dur > 0.0 else max(dist / _WALK_SPEED, 0.1)
	var actual_dur : float = base_dur / GameManager.playback_speed
	_tw_pos_x = create_tween()
	_tw_pos_x.tween_property(player, "position:x", target_x, actual_dur) \
			.set_trans(Tween.TRANS_LINEAR)
	return _tw_pos_x


func _set_viewers(count: int) -> void:
	if not is_inside_tree():
		return
	var chrome := get_tree().get_first_node_in_group("youtube_chrome")
	if not is_instance_valid(chrome):
		return
	chrome._view_count = count
	if is_instance_valid(chrome._view_label):
		chrome._view_label.text = "%s 人が視聴中" % chrome._fmt_count(count)


# ════════════════════════════════════════════════════════════════════
# ポラロイド風動画表示
# ════════════════════════════════════════════════════════════════════

func _polaroid_video(_video_path: String) -> void:
	# SpriteSheet方式: 1枚のPNGに全フレームを格納（10列×5行、380×214/フレーム）
	const SHEET_PATH := "res://assets/video/bus_spritesheet.png"
	if not ResourceLoader.exists(SHEET_PATH):
		push_warning("EntranceDirector: polaroid_video — spritesheet not found")
		return

	const FPS        := 25.0
	const TOTAL_FRAMES := 46
	const SHEET_COLS := 10
	const CELL_W    := 380    # SpriteSheet上の1フレーム幅
	const CELL_H    := 214    # SpriteSheet上の1フレーム高さ

	# YouTubeChrome 映像エリア座標系: (0,48)〜(940,612) = 940×564
	const VIDEO_AREA_X := 0
	const VIDEO_AREA_Y := 48
	const VIDEO_AREA_W := 940
	const VIDEO_AREA_H := 564  # 612 - 48

	# ポラロイド寸法
	const PHOTO_W := 380      # 写真部分の幅
	const PHOTO_H := 254      # 写真部分の高さ (3:2比率)
	const BORDER_SIDE := 14   # 左右・上の白枠
	const BORDER_BOT  := 44   # 下の白枠（ポラロイド特有の広い下余白）
	const FRAME_W := PHOTO_W + BORDER_SIDE * 2   # 408
	const FRAME_H := PHOTO_H + BORDER_SIDE + BORDER_BOT  # 312

	# SpriteSheetを1回だけロード
	var sheet_tex := ResourceLoader.load(SHEET_PATH, "Texture2D") as Texture2D
	if not sheet_tex:
		push_warning("EntranceDirector: polaroid_video — failed to load spritesheet")
		return

	# 中央位置
	var cx := VIDEO_AREA_X + (VIDEO_AREA_W - FRAME_W) / 2
	var cy := VIDEO_AREA_Y + (VIDEO_AREA_H - FRAME_H) / 2

	# ── CanvasLayer (layer=18: HUD(2)より上、YouTubeChrome(20)より下) ──
	var canvas := CanvasLayer.new()
	canvas.layer = 18
	get_tree().root.add_child(canvas)

	# ── コンテナ（回転・移動のルート） ──
	var container := Control.new()
	container.position = Vector2(cx + FRAME_W / 2, cy + FRAME_H / 2)
	container.pivot_offset = Vector2.ZERO
	container.rotation = deg_to_rad(-2.5)
	canvas.add_child(container)

	# ── ドロップシャドウ ──
	var shadow := PanelContainer.new()
	shadow.position = Vector2(-FRAME_W / 2 + 6, -FRAME_H / 2 + 6)
	shadow.size = Vector2(FRAME_W, FRAME_H)
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.0, 0.0, 0.0, 0.45)
	shadow_style.set_corner_radius_all(2)
	shadow.add_theme_stylebox_override("panel", shadow_style)
	container.add_child(shadow)

	# ── 白いポラロイドフレーム ──
	var frame := PanelContainer.new()
	frame.position = Vector2(-FRAME_W / 2, -FRAME_H / 2)
	frame.size = Vector2(FRAME_W, FRAME_H)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.96, 0.94, 0.92, 1.0)
	frame_style.set_corner_radius_all(2)
	frame.add_theme_stylebox_override("panel", frame_style)
	container.add_child(frame)

	# ── フレーム表示用 TextureRect（AtlasTexture で領域切り替え） ──
	var tex_rect := TextureRect.new()
	tex_rect.position = Vector2(-FRAME_W / 2 + BORDER_SIDE, -FRAME_H / 2 + BORDER_SIDE)
	tex_rect.size = Vector2(PHOTO_W, PHOTO_H)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	container.add_child(tex_rect)

	# AtlasTexture を1つ作り、region を切り替えて再生
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet_tex
	atlas.region = Rect2(0, 0, CELL_W, CELL_H)
	tex_rect.texture = atlas

	# ── 下部テキスト（手書き風メモ） ──
	var memo := Label.new()
	memo.text = "2026.02.24  霧原村"
	memo.add_theme_font_size_override("font_size", 13)
	memo.add_theme_color_override("font_color", Color(0.35, 0.30, 0.28, 0.85))
	memo.position = Vector2(-FRAME_W / 2 + BORDER_SIDE + 8, -FRAME_H / 2 + BORDER_SIDE + PHOTO_H + 8)
	memo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	container.add_child(memo)

	# ── スライドインアニメーション ──
	var start_y := container.position.y
	container.position.y = 720 + FRAME_H
	container.modulate.a = 0.0

	var tw_in := create_tween()
	tw_in.set_parallel(true)
	tw_in.tween_property(container, "position:y", start_y, 0.6) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(container, "modulate:a", 1.0, 0.3)
	await tw_in.finished

	# ── SpriteSheetアニメーション再生（AtlasTexture.region を切り替えるだけ） ──
	var frame_dur := 1.0 / FPS
	for i in TOTAL_FRAMES:
		var col := i % SHEET_COLS
		var row := i / SHEET_COLS
		atlas.region = Rect2(col * CELL_W, row * CELL_H, CELL_W, CELL_H)
		await get_tree().create_timer(frame_dur).timeout

	# 少し余韻
	await get_tree().create_timer(0.5).timeout

	# ── フェードアウト ──
	var tw_out := create_tween()
	tw_out.set_parallel(true)
	tw_out.tween_property(container, "modulate:a", 0.0, 0.8)
	tw_out.tween_property(container, "position:y", start_y - 30, 0.8) \
			.set_trans(Tween.TRANS_SINE)
	await tw_out.finished

	# クリーンアップ
	canvas.queue_free()


# ════════════════════════════════════════════════════════════════════
# ホラー演出ヘルパー
# ════════════════════════════════════════════════════════════════════

func _get_chrome() -> Node:
	return get_tree().get_first_node_in_group("youtube_chrome")


func _horror_flash(dur: float = 0.3) -> void:
	var chrome := _get_chrome()
	if chrome and chrome.has_method("horror_flash"):
		chrome.horror_flash(dur)


func _horror_glitch(intensity: float = 8.0, count: int = 3) -> void:
	var chrome := _get_chrome()
	if chrome and chrome.has_method("horror_glitch"):
		chrome.horror_glitch(intensity, count)


func _horror_tint() -> void:
	var chrome := _get_chrome()
	if chrome and chrome.has_method("horror_tint"):
		chrome.horror_tint()


func _horror_tint_clear() -> void:
	var chrome := _get_chrome()
	if chrome and chrome.has_method("horror_tint_clear"):
		chrome.horror_tint_clear()


func _story_superchat(sc_name: String, sc_msg: String, amount: int) -> void:
	var chrome := _get_chrome()
	if chrome and chrome.has_method("spawn_story_superchat"):
		chrome.spawn_story_superchat(sc_name, sc_msg, amount)


func _flashlight_flicker() -> void:
	if not is_instance_valid(player) or not player.flashlight:
		return
	var orig : float = player.flashlight.light_energy
	var tw := create_tween()
	for i in 4:
		tw.tween_property(player.flashlight, "light_energy", 0.0, 0.05)
		tw.tween_property(player.flashlight, "light_energy", orig * 0.3, 0.03)
		tw.tween_property(player.flashlight, "light_energy", 0.0, 0.08)
		tw.tween_property(player.flashlight, "light_energy", orig, 0.06)
	await tw.finished


func _flashlight_off() -> void:
	if is_instance_valid(player):
		player.flashlight.visible = false
		player.flashlight_on = false


# ════════════════════════════════════════════════════════════════════
# 背景画像表示（紙芝居風 — 暗転レイヤー上に画像を重ねる）
# ════════════════════════════════════════════════════════════════════

func _bg_image_show(file: String, dur: float = 1.0, brightness: float = 0.35,
		vignette_radius: float = 0.38, vignette_softness: float = 0.45,
		vignette_center: Array = [0.5, 0.5]) -> void:
	_ensure_fade_layer()
	# ── 画像テクスチャ（load失敗時はImage.load_from_fileでフォールバック） ──
	var path := "res://assets/textures/" + file if not file.begins_with("res://") else file
	var tex : Texture2D = load(path) as Texture2D
	if not tex:
		var img := Image.new()
		if img.load(path) == OK:
			tex = ImageTexture.create_from_image(img)
	if not tex:
		push_warning("EntranceDirector: bg_image — texture not found: " + path)
		return
	if not is_instance_valid(_bg_image_rect):
		_bg_image_rect = TextureRect.new()
		_bg_image_rect.anchor_right = 1.0
		_bg_image_rect.anchor_bottom = 1.0
		_bg_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_bg_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bg_image_rect.modulate = Color(brightness, brightness, brightness, 0.0)
		_fade_layer.add_child(_bg_image_rect)
	_bg_image_rect.texture = tex
	_bg_image_rect.modulate = Color(brightness, brightness, brightness, 0.0)
	_bg_image_rect.show()
	# ── 円形ビネット（懐中電灯風 — center移動対応） ──
	if not is_instance_valid(_bg_vignette):
		_bg_vignette = ColorRect.new()
		_bg_vignette.anchor_right = 1.0
		_bg_vignette.anchor_bottom = 1.0
		_bg_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shd := Shader.new()
		shd.code = """
shader_type canvas_item;
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius : hint_range(0.0, 1.0) = 0.38;
uniform float softness : hint_range(0.0, 1.0) = 0.45;
void fragment() {
	vec2 uv = UV - center;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	uv.x *= aspect;
	float d = length(uv);
	float v = smoothstep(radius, radius + softness, d);
	COLOR = vec4(0.0, 0.0, 0.0, v);
}
"""
		var mat := ShaderMaterial.new()
		mat.shader = shd
		mat.set_shader_parameter("center", Vector2(0.5, 0.5))
		mat.set_shader_parameter("radius", 0.38)
		mat.set_shader_parameter("softness", 0.45)
		_bg_vignette.material = mat
		_bg_vignette.modulate.a = 0.0
		_fade_layer.add_child(_bg_vignette)
	# パラメータを毎回反映（既存ビネットにも適用）
	var vig_mat := _bg_vignette.material as ShaderMaterial
	if vig_mat:
		var cx : float = float(vignette_center[0]) if vignette_center.size() > 0 else 0.5
		var cy : float = float(vignette_center[1]) if vignette_center.size() > 1 else 0.5
		vig_mat.set_shader_parameter("center", Vector2(cx, cy))
		vig_mat.set_shader_parameter("radius", vignette_radius)
		vig_mat.set_shader_parameter("softness", vignette_softness)
	_bg_vignette.show()
	# フェードイン
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_bg_image_rect, "modulate:a", 1.0, dur / GameManager.playback_speed)
	tw.tween_property(_bg_vignette, "modulate:a", 1.0, dur / GameManager.playback_speed)
	await tw.finished


func _bg_image_clear(dur: float = 1.0) -> void:
	if _bg_walk_active:
		_bg_walk_stop()
	var tw := create_tween()
	tw.set_parallel(true)
	if is_instance_valid(_bg_image_rect):
		tw.tween_property(_bg_image_rect, "modulate:a", 0.0, dur / GameManager.playback_speed)
	if is_instance_valid(_bg_vignette):
		tw.tween_property(_bg_vignette, "modulate:a", 0.0, dur / GameManager.playback_speed)
	await tw.finished
	if is_instance_valid(_bg_image_rect):
		_bg_image_rect.hide()
	if is_instance_valid(_bg_vignette):
		_bg_vignette.hide()


## 背景画像チカチカ（懐中電灯の接触不良風 — awaitしない、裏で勝手に走る）
func _bg_image_flicker(dur: float = 3.0, brightness: float = 0.3) -> void:
	if not is_instance_valid(_bg_image_rect):
		return
	var base_b : float = brightness
	var tw := create_tween()
	tw.set_loops(0)  # 無限ループ
	# 暗→明→暗→明 の不規則パターン
	tw.tween_property(_bg_image_rect, "modulate",
		Color(base_b * 0.1, base_b * 0.1, base_b * 0.1, 1.0), 0.05)
	tw.tween_property(_bg_image_rect, "modulate",
		Color(base_b * 0.6, base_b * 0.6, base_b * 0.6, 1.0), 0.03)
	tw.tween_property(_bg_image_rect, "modulate",
		Color(base_b * 0.0, base_b * 0.0, base_b * 0.0, 1.0), 0.08)
	tw.tween_property(_bg_image_rect, "modulate",
		Color(base_b, base_b, base_b, 1.0), 0.06)
	tw.tween_property(_bg_image_rect, "modulate",
		Color(base_b * 0.3, base_b * 0.3, base_b * 0.3, 1.0), 0.04)
	tw.tween_property(_bg_image_rect, "modulate",
		Color(base_b * 0.8, base_b * 0.8, base_b * 0.8, 1.0), 0.12)
	tw.tween_property(_bg_image_rect, "modulate",
		Color(base_b * 0.05, base_b * 0.05, base_b * 0.05, 1.0), 0.06)
	tw.tween_property(_bg_image_rect, "modulate",
		Color(base_b, base_b, base_b, 1.0), 0.15)
	# dur秒後に停止して元の明るさに戻す
	await get_tree().create_timer(dur / GameManager.playback_speed).timeout
	tw.kill()
	if is_instance_valid(_bg_image_rect):
		_bg_image_rect.modulate = Color(base_b, base_b, base_b, 1.0)


## 背景画像ウォーク（奥に歩く + 懐中電灯サーチ）
func _bg_walk_start(speed: float = 1.0, zoom_end: float = 1.4,
		zoom_dur: float = 30.0, radius: float = 0.22, softness: float = 0.35) -> void:
	_bg_walk_t = 0.0
	_bg_walk_speed = speed
	_bg_walk_zoom_start = 1.0
	_bg_walk_zoom_end = zoom_end
	_bg_walk_zoom_dur = zoom_dur
	# 懐中電灯の範囲を狭くする
	if is_instance_valid(_bg_vignette):
		var mat := _bg_vignette.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("radius", radius)
			mat.set_shader_parameter("softness", softness)
	# 画像の pivot を中央に設定
	if is_instance_valid(_bg_image_rect):
		_bg_image_rect.pivot_offset = _bg_image_rect.size / 2.0
	_bg_walk_active = true


func _bg_walk_stop() -> void:
	_bg_walk_active = false
	# ビネットを中央・デフォルトサイズに戻す
	if is_instance_valid(_bg_vignette):
		var mat := _bg_vignette.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("center", Vector2(0.5, 0.5))
			mat.set_shader_parameter("radius", 0.38)
			mat.set_shader_parameter("softness", 0.45)
	# 画像スケール・位置をリセット
	if is_instance_valid(_bg_image_rect):
		_bg_image_rect.scale = Vector2.ONE
		_bg_image_rect.position = Vector2.ZERO


func _update_bg_walk() -> void:
	var t : float = _bg_walk_t
	# ── ズーム（奥に歩く感じ） ──
	if is_instance_valid(_bg_image_rect):
		var progress : float = clampf(t / _bg_walk_zoom_dur, 0.0, 1.0)
		var zoom_val : float = lerpf(_bg_walk_zoom_start, _bg_walk_zoom_end, progress)
		_bg_image_rect.pivot_offset = _bg_image_rect.size / 2.0
		_bg_image_rect.scale = Vector2(zoom_val, zoom_val)
		# 歩行ボブ（上下の揺れ）
		var bob_y : float = sin(t * 5.5) * 4.0
		var bob_x : float = sin(t * 2.8) * 2.0
		_bg_image_rect.position = Vector2(bob_x, bob_y)
	# ── 懐中電灯サーチ（ビネット中心がゆらゆら動く） ──
	if is_instance_valid(_bg_vignette):
		var mat := _bg_vignette.material as ShaderMaterial
		if mat:
			# 複数のsin波を重ねて不規則な動きを演出
			var cx : float = 0.4 + sin(t * 0.7) * 0.12 + sin(t * 1.9) * 0.06 + sin(t * 3.3) * 0.03
			var cy : float = 0.5 + cos(t * 0.5) * 0.08 + sin(t * 1.3) * 0.05 + cos(t * 2.7) * 0.02
			mat.set_shader_parameter("center", Vector2(cx, cy))


# ════════════════════════════════════════════════════════════════════
# 画面フェード（暗転 / 明転）
# ════════════════════════════════════════════════════════════════════

func _ensure_fade_layer() -> void:
	if is_instance_valid(_fade_layer):
		return
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 1  # HUD(2)・YouTubeChrome(20) より下 → 暗転中もセリフ・チャット表示
	get_tree().root.add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.anchor_right  = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func _fade_black(dur: float = 0.8, target: float = 1.0) -> void:
	_ensure_fade_layer()
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", target, dur / GameManager.playback_speed)
	await tw.finished


func _fade_clear(dur: float = 0.8, target: float = 0.0) -> void:
	_ensure_fade_layer()
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", target, dur / GameManager.playback_speed)
	await tw.finished


## エンディング専用演出を再生（YouTubeChrome非表示 → EndingPlayer → 復帰）
func _play_ending(ev: Dictionary) -> void:
	var ending_id : String = ev.get("id", "")
	var sections : Array = ev.get("sections", [])
	var ending_title : String = ev.get("ending_title", "")

	# エンディング開放を記録
	if ending_id != "":
		GameManager.unlock_ending(ending_id)

	# YouTubeChrome を非表示
	var chrome = hud.get_node_or_null("YouTubeChrome") if hud else null
	if chrome:
		chrome.visible = false

	# 暗転
	await _fade_black(1.5, 1.0)

	# EndingPlayer を生成して再生
	var ep := CanvasLayer.new()
	ep.set_script(EndingPlayerScript)
	get_tree().root.add_child(ep)
	await ep.play(sections, ending_title)

	# EndingPlayer をフェードアウト
	await ep.fade_out(1.5)


## バッドエンド演出：暗転 → 画像+タイトル表示 → 「選択肢に戻る？」→ タイトルへ or 分岐戻り
func _bad_end(title_text: String, return_label: String, fade_dur: float, display_dur: float, image_path: String = "") -> void:
	# 暗転
	await _fade_black(fade_dur, 1.0)
	await get_tree().create_timer(0.5).timeout

	# バッドエンド画面用CanvasLayer
	var canvas := CanvasLayer.new()
	canvas.layer = 200
	get_tree().root.add_child(canvas)

	# コンテナ（全画面、黒背景）
	var container := Control.new()
	container.anchors_preset = Control.PRESET_FULL_RECT
	container.modulate.a = 0.0
	canvas.add_child(container)

	# 背景画像（あれば）
	if image_path != "":
		var tex := load(image_path) as Texture2D
		if tex:
			var img_rect := TextureRect.new()
			img_rect.texture = tex
			img_rect.anchors_preset = Control.PRESET_FULL_RECT
			img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			img_rect.modulate = Color(0.6, 0.6, 0.65, 1.0)  # やや暗く青みがかった色調
			container.add_child(img_rect)

	# バッドエンドタイトル（画像の上に重ねる）
	var lbl := Label.new()
	lbl.text = title_text
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.15, 0.1))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.anchors_preset = Control.PRESET_FULL_RECT
	container.add_child(lbl)

	# フェードイン
	var tw_in := create_tween()
	tw_in.tween_property(container, "modulate:a", 1.0, 1.5)
	await tw_in.finished

	await get_tree().create_timer(display_dur).timeout

	# 「選択肢の直前に戻りますか？」選択
	var retry_ev := {
		"prompt": "",
		"choices": [{"text": "選択肢の直前に戻る", "sub": ""}, {"text": "タイトルに戻る", "sub": ""}]
	}
	var result := await _show_horror_choice(retry_ev)

	# フェードアウト
	var tw_out := create_tween()
	tw_out.tween_property(container, "modulate:a", 0.0, 0.5)
	await tw_out.finished
	canvas.queue_free()

	if result == 0 and return_label != "":
		# 選択肢の直前に戻る — フェードクリアしてラベルにジャンプ
		await _fade_clear(0.8, 0.0)
		_bad_end_return_label = return_label
	else:
		# タイトルに戻る
		get_tree().change_scene_to_file("res://scenes/Opening.tscn")

## _bad_end から戻るためのラベル（空なら戻らない）
var _bad_end_return_label : String = ""


# ════════════════════════════════════════════════════════════════════
# ステージ差し替え（暗転中に呼ぶ想定）
# ════════════════════════════════════════════════════════════════════

func _stage_swap(scene_path: String, spawn: Array) -> void:
	if not is_inside_tree():
		return
	var main := get_tree().current_scene
	if not main:
		return

	# 現在のステージ系ノードを削除（Player/HUD/UI/カメラ等は残す）
	var keep_names : Array = ["Player", "HUD", "WorldEnvironment",
		"DirectionalLight3D", "OverlayLayer", "YouTubeChrome",
		"ScenarioUI", "InventoryUI"]
	for child in main.get_children():
		if child == player:
			continue
		if child is CanvasLayer:
			continue
		if child.name in keep_names:
			continue
		if child is Node3D:
			child.queue_free()
	await get_tree().process_frame

	# 新シーン読み込み
	var packed := load(scene_path) as PackedScene
	var stage : Node = null
	if packed:
		stage = packed.instantiate()
		main.add_child(stage)
	else:
		push_warning("EntranceDirector: stage_swap — シーンが読み込めません: " + scene_path)

	# トイレ用の地面（暗い環境）
	var ground_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(60, 0.2, 60)
	ground_mesh.mesh = plane
	ground_mesh.position = Vector3(0, -0.1, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.10)
	ground_mesh.material_override = mat
	main.add_child(ground_mesh)

	# WorldEnvironment の ambient_light を抑える（白飛びの主因）
	var we := main.get_node_or_null("WorldEnvironment")
	if we and we is WorldEnvironment and we.environment:
		var env : Environment = we.environment
		env.ambient_light_energy = 0.02
		env.ambient_light_color = Color(0.3, 0.35, 0.45)
	# DirectionalLight3D も大幅減光
	var dl := main.get_node_or_null("DirectionalLight3D")
	if dl and dl is DirectionalLight3D:
		dl.light_energy = 0.0

	# 蛍光灯っぽい環境光（トイレをほんのり照らす程度）
	var env_light := OmniLight3D.new()
	env_light.position = Vector3(0, 3.5, 0)
	env_light.light_color = Color(0.7, 0.75, 0.85)
	env_light.light_energy = 0.15
	env_light.omni_range = 8.0
	main.add_child(env_light)

	# GLB蛍光灯ライトを適度に減光（白飛び防止）
	if stage:
		_dim_lights_recursive(stage, 0.08)

	# トイレでは懐中電灯を控えめに（蛍光灯がメイン光源）
	if is_instance_valid(player):
		if "Toilet" in scene_path or "toilet" in scene_path:
			player.flashlight.light_energy = _flash_orig_energy * 0.25
			player.flashlight.spot_range = 20.0
		else:
			player.flashlight.light_energy = _flash_orig_energy
			player.flashlight.spot_range = 80.0

	# プレイヤー位置設定
	var sx : float = float(spawn[0]) if spawn.size() > 0 else 0.0
	var sy : float = float(spawn[1]) if spawn.size() > 1 else 1.0
	var sz : float = float(spawn[2]) if spawn.size() > 2 else 0.0
	player.position = Vector3(sx, sy, sz)


## ステージ内の全Light3Dのenergyにscaleを掛ける（GLBライト減光用）
func _dim_lights_recursive(node: Node, scale: float) -> void:
	if node is Light3D:
		node.light_energy *= scale
	for child in node.get_children():
		_dim_lights_recursive(child, scale)


# ════════════════════════════════════════════════════════════════════
# 新ホラー演出ヘルパー
# ════════════════════════════════════════════════════════════════════

func _get_main() -> Node:
	return get_tree().current_scene


## VHSグリッチ一時強化 — ノイズ・色収差・グリッチバーを一時的に上げて戻す
func _vhs_glitch(intensity: float, dur: float) -> void:
	var main := _get_main()
	if not main or not main.has_method("set_vhs_param"):
		return
	main.set_vhs_param("glitch_strength", intensity)
	main.set_vhs_param("chroma_boost", intensity * 0.03)
	main.set_vhs_param("noise_intensity", 0.08 + intensity * 0.3)
	main.set_vhs_param("shake_intensity", 0.005 + intensity * 0.02)
	if is_inside_tree():
		await get_tree().create_timer(dur / GameManager.playback_speed).timeout
	# 元に戻す（Tweenで滑らかに）
	if main.has_method("tween_vhs_param"):
		main.tween_vhs_param("glitch_strength", 0.0, 0.3)
		main.tween_vhs_param("chroma_boost", 0.0, 0.3)
		main.tween_vhs_param("noise_intensity", 0.08, 0.3)
		main.tween_vhs_param("shake_intensity", 0.005, 0.3)


## VHSパラメータを即座にデフォルトへリセット
func _vhs_reset() -> void:
	var main := _get_main()
	if not main or not main.has_method("set_vhs_param"):
		return
	main.set_vhs_param("glitch_strength", 0.0)
	main.set_vhs_param("chroma_boost", 0.0)
	main.set_vhs_param("noise_intensity", 0.08)
	main.set_vhs_param("shake_intensity", 0.005)


## 魚眼レンズON — distortionとbreathをTweenで立ち上げ
func _fisheye_on(distortion: float, breath: float, dur: float) -> void:
	var main := _get_main()
	if not main or not main.has_method("set_fisheye_param"):
		return
	main.set_fisheye_param("distortion", 0.0)
	main.set_fisheye_param("breath", 0.0)
	main.set_fisheye_param("chromatic", 0.003)
	main.set_fisheye_param("vignette_strength", 0.8)
	main.set_fisheye_param("grain", 0.04)
	if main.has_method("tween_fisheye_param"):
		main.tween_fisheye_param("distortion", distortion, dur)
		main.tween_fisheye_param("breath", breath, dur * 0.8)
		main.tween_fisheye_param("vignette_strength", 1.2, dur)
		main.tween_fisheye_param("chromatic", 0.006, dur)


## 魚眼レンズOFF — 全パラメータを0へTween→オーバーレイ除去
func _fisheye_off(dur: float) -> void:
	var main := _get_main()
	if not main or not main.has_method("tween_fisheye_param"):
		return
	main.tween_fisheye_param("distortion", 0.0, dur)
	main.tween_fisheye_param("breath", 0.0, dur)
	main.tween_fisheye_param("vignette_strength", 0.0, dur)
	main.tween_fisheye_param("chromatic", 0.0, dur)
	main.tween_fisheye_param("grain", 0.0, dur)
	if is_inside_tree():
		await get_tree().create_timer(dur + 0.1).timeout
	if main.has_method("remove_fisheye_overlay"):
		main.remove_fisheye_overlay()


## シーン内の全ライトをフリッカー
func _light_flicker(count: int, dur: float) -> void:
	var main := _get_main()
	if not main:
		return
	# シーン内の全ライトを収集
	var lights : Array[Light3D] = []
	_collect_lights(main, lights)
	if lights.is_empty():
		return

	# 元のエネルギーを保存
	var orig_energies : Array[float] = []
	for light in lights:
		orig_energies.append(light.light_energy)

	var interval : float = dur / max(count * 2, 1) / GameManager.playback_speed
	for i in count:
		if not is_inside_tree():
			break
		# 消灯
		for light in lights:
			if is_instance_valid(light):
				light.light_energy = 0.0
		await get_tree().create_timer(interval * randf_range(0.3, 0.8)).timeout
		# 点灯
		for j in lights.size():
			if is_instance_valid(lights[j]):
				lights[j].light_energy = orig_energies[j] * randf_range(0.4, 1.2)
		await get_tree().create_timer(interval * randf_range(0.5, 1.0)).timeout

	# 元に戻す
	for j in lights.size():
		if is_instance_valid(lights[j]):
			lights[j].light_energy = orig_energies[j]


func _collect_lights(node: Node, result: Array[Light3D]) -> void:
	if node is Light3D and node != player.flashlight:
		result.append(node as Light3D)
	for child in node.get_children():
		_collect_lights(child, result)


## 彩度変化（amount=0で通常、1でモノクロ）
func _desaturate(amount: float, dur: float) -> void:
	var main := _get_main()
	if main and main.has_method("tween_vhs_param"):
		main.tween_vhs_param("desaturation", amount, dur)


## スローモーション
func _slow_motion(scale: float, dur: float) -> void:
	var orig_scale := Engine.time_scale
	Engine.time_scale = scale
	if is_inside_tree():
		# 実時間で待機（time_scaleの影響を受けないように）
		await get_tree().create_timer(dur * scale / GameManager.playback_speed).timeout
	Engine.time_scale = orig_scale


## フォグ動的変化
func _fog_change(ev: Dictionary) -> void:
	var main := _get_main()
	if not main or not main.has_method("tween_fog"):
		return
	var density : float = float(ev.get("density", 0.05))
	var dur     : float = float(ev.get("dur", 2.0))
	var col_arr : Array = ev.get("color", [])
	var col := Color(-1, 0, 0)  # -1 = 色変更なし
	if col_arr.size() >= 3:
		col = Color(float(col_arr[0]), float(col_arr[1]), float(col_arr[2]))
	main.tween_fog(density, dur, col)


## 画面歪み（水波エフェクト）
func _distortion(amount: float, dur: float) -> void:
	var main := _get_main()
	if main and main.has_method("tween_vhs_param"):
		main.tween_vhs_param("distortion", amount, dur)


## ビネット強化（画面端を暗く）
func _vignette(amount: float, dur: float) -> void:
	var main := _get_main()
	if main and main.has_method("tween_vhs_param"):
		main.tween_vhs_param("vignette_boost", amount, dur)


## チャットフラッド — 特定メッセージでチャット欄を埋め尽くす
func _chat_flood(msg: String, count: int, interval: float, color_name: String) -> void:
	if not is_instance_valid(hud):
		return
	var usernames : Array[String] = [
		"???", "視聴者", "名無し", "■■■", "▓▓▓",
		"░░░", "呪い", "案山子", "藁人形", "霧原村民"
	]
	var utype : String = ""
	if color_name == "red":
		utype = "owner"  # 赤色表示
	for i in count:
		if not is_inside_tree():
			return
		var uname : String = usernames[randi() % usernames.size()]
		_chat(msg, uname, utype)
		if interval > 0.0 and i < count - 1:
			await get_tree().create_timer(interval / GameManager.playback_speed).timeout


## 文字化けテキスト — セリフを一瞬壊してから正しく表示
const GARBLE_CHARS := "ア̷̢イ̶ウ̸エ̴オ̷カ̸キ̶ク̴ケ̷コ̸■▓░█▒▌▐◈◆●◼ᚠᛗᛁᚾᛟᚳ"

func _garbled_text(text: String, dur: float) -> void:
	if not is_instance_valid(hud) or text.is_empty():
		return
	# まず文字化け版を表示
	var garbled := ""
	for i in text.length():
		if randf() < 0.7:
			garbled += GARBLE_CHARS[randi() % GARBLE_CHARS.length()]
		else:
			garbled += text[i]
	hud.show_monologue(garbled)

	# 短い間隔で数回文字化けを変えてから正しいテキストに
	var steps := 3
	var step_dur : float = dur / (steps + 1) / GameManager.playback_speed
	for _s in steps:
		if not is_inside_tree():
			return
		await get_tree().create_timer(step_dur).timeout
		garbled = ""
		var correct_ratio : float = float(_s + 1) / float(steps + 1)
		for i in text.length():
			if randf() < correct_ratio:
				garbled += text[i]
			else:
				garbled += GARBLE_CHARS[randi() % GARBLE_CHARS.length()]
		hud.show_monologue(garbled)

	if is_inside_tree():
		await get_tree().create_timer(step_dur).timeout
	hud.show_monologue(text)


# ════════════════════════════════════════════════════════════════════
# みゆきゴースト — 動的スポーン・移動・消去
# ════════════════════════════════════════════════════════════════════

func _miyuki_spawn(ev: Dictionary) -> void:
	# 既存インスタンスがあれば消す
	_miyuki_despawn()

	var glb : PackedScene = load("res://assets/models/characters/Miyuki.glb") as PackedScene
	if not glb:
		push_warning("EntranceDirector: Miyuki.glb が見つかりません")
		return

	_miyuki_instance = Node3D.new()
	_miyuki_instance.name = "MiyukiGhost"

	# GLBモデルをインスタンス化して子に追加
	var model := glb.instantiate()
	model.name = "ModelInstance"
	var s : float = float(ev.get("scale", 10.0))
	model.scale = Vector3(s, s, s)
	_miyuki_instance.add_child(model)

	# 位置
	var pos_arr : Array = ev.get("pos", [0, 3.8, -1])
	_miyuki_instance.global_position = Vector3(
		float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))

	# 逆さま
	if ev.get("upside_down", false):
		_miyuki_instance.rotation.x = PI

	# 不気味な青白い照明（脈動は _miyuki_update で処理）
	var light := OmniLight3D.new()
	light.name = "GhostLight"
	light.light_color = Color(0.4, 0.5, 0.9)
	light.light_energy = float(ev.get("light_energy", 6.0))
	light.omni_range = float(ev.get("light_range", 12.0))
	_miyuki_instance.add_child(light)

	# 初期状態
	_miyuki_instance.visible = ev.get("visible", true)
	_miyuki_convulsion = float(ev.get("convulsion_intensity", 0.0))
	_miyuki_track = ev.get("track_player", false)

	# シーンツリーに追加
	get_tree().current_scene.add_child(_miyuki_instance)


## モデルの全 MeshInstance3D に ghost shader を再帰的に適用
func _apply_ghost_shader(node: Node, mat: ShaderMaterial) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for surf_idx in mi.get_surface_override_material_count():
			var orig := mi.mesh.surface_get_material(surf_idx)
			# 元テクスチャがあればシェーダーに渡す
			if orig is StandardMaterial3D:
				var std := orig as StandardMaterial3D
				if std.albedo_texture:
					mat.set_shader_parameter("ghost_texture", std.albedo_texture)
			mi.set_surface_override_material(surf_idx, mat)
	for child in node.get_children():
		_apply_ghost_shader(child, mat)


func _miyuki_move(ev: Dictionary) -> void:
	if not is_instance_valid(_miyuki_instance):
		return

	# 位置
	if ev.has("pos"):
		var pos_arr : Array = ev.get("pos", [0, 0, 0])
		_miyuki_instance.global_position = Vector3(
			float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))

	# 逆さま切替
	if ev.has("upside_down"):
		if ev.get("upside_down", false):
			_miyuki_instance.rotation.x = PI
		else:
			_miyuki_instance.rotation.x = 0.0

	# 表示/非表示
	if ev.has("visible"):
		_miyuki_instance.visible = ev.get("visible", true)

	# ライトの強さ変更
	if ev.has("light_energy"):
		var light := _miyuki_instance.get_node_or_null("GhostLight") as OmniLight3D
		if light:
			light.light_energy = float(ev.get("light_energy", 6.0))

	# 痙攣の強さ
	if ev.has("convulsion_intensity"):
		_miyuki_convulsion = float(ev.get("convulsion_intensity", 0.0))

	# プレイヤー追跡
	if ev.has("track_player"):
		_miyuki_track = ev.get("track_player", false)

	# rage（シェーダー — 赤く激しくなる）
	if ev.has("rage") and _miyuki_shader_mat:
		_miyuki_shader_mat.set_shader_parameter("rage", float(ev.get("rage", 0.0)))


## 毎フレーム更新: ライト脈動・痙攣・プレイヤー追跡
func _miyuki_update(delta: float) -> void:
	if not is_instance_valid(_miyuki_instance):
		return

	var t : float = Time.get_ticks_msec() / 1000.0

	# ── ライト脈動（sin で明滅） ──
	var light := _miyuki_instance.get_node_or_null("GhostLight") as OmniLight3D
	if light:
		var base_energy : float = light.light_energy
		# ±30% の脈動（不規則にするため2波合成）
		var pulse : float = sin(t * 1.8) * 0.2 + sin(t * 4.3) * 0.1
		light.light_energy = base_energy + pulse

	# ── 痙攣（微細な回転ノイズ） ──
	if _miyuki_convulsion > 0.0:
		var model := _miyuki_instance.get_node_or_null("ModelInstance")
		if model:
			var ci : float = _miyuki_convulsion
			var rx : float = sin(t * 17.3 + 0.5) * 0.05 * ci
			var ry : float = cos(t * 13.7 + 1.2) * 0.03 * ci
			var rz : float = sin(t * 21.1 + 2.8) * 0.04 * ci
			model.rotation = Vector3(rx, ry, rz)
			# 位置のブレ（小さく震える）
			var px : float = sin(t * 23.0) * 0.02 * ci
			var pz : float = cos(t * 19.0) * 0.02 * ci
			model.position = Vector3(px, 0.0, pz)

	# ── プレイヤーの方を向く ──
	if _miyuki_track and is_instance_valid(player):
		var target_pos := player.global_position
		var my_pos := _miyuki_instance.global_position
		# Y軸だけで回転（逆さでも自然に見える）
		var dir := (target_pos - my_pos)
		dir.y = 0.0
		if dir.length_squared() > 0.01:
			var target_angle : float = atan2(dir.x, dir.z)
			# 逆さの場合は反転
			var is_upside : bool = absf(_miyuki_instance.rotation.x - PI) < 0.1
			if is_upside:
				target_angle += PI
			_miyuki_instance.rotation.y = lerp_angle(
				_miyuki_instance.rotation.y, target_angle, delta * 2.0)


func _miyuki_despawn() -> void:
	if is_instance_valid(_miyuki_instance):
		if _miyuki_instance.get_parent():
			_miyuki_instance.get_parent().remove_child(_miyuki_instance)
		_miyuki_instance.queue_free()
		_miyuki_instance = null
	_miyuki_convulsion = 0.0
	_miyuki_track = false
	_miyuki_shader_mat = null
