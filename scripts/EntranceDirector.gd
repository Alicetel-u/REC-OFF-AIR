extends Node

## JSON 駆動のシーケンス演出エンジン
## セリフ・移動・チャット・選択肢分岐をサポート

const DIALOGUE_JSON := "res://dialogue/ch01_entrance.json"
const HorrorChoicePanelScript := preload("res://scripts/HorrorChoicePanel.gd")

var player: CharacterBody3D = null
var hud: Control = null

var _walking           := false
var _moving            := false   # 実際に前進するか（walk_setで制御）
var _bob_t             := 0.0
var _flash_orig_energy : float = 1.0
var _fade_layer        : CanvasLayer = null
var _fade_rect         : ColorRect = null

# クリックスキップ制御
var _skip_to_next_say  := false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_skip_to_next_say = true
		SoundManager.stop_voice()


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if _walking:
		var prev_bob := _bob_t
		_bob_t += delta * Player.BOB_FREQ
		var ty := abs(sin(_bob_t)) * Player.BOB_AMP
		var tx := sin(_bob_t * 2.0) * Player.BOB_AMP * 0.4
		player.camera.position.y = lerp(player.camera.position.y, ty, delta * 12.0)
		player.camera.position.x = lerp(player.camera.position.x, tx, delta * 12.0)
		# 足音 — bob_t が π の倍数を通過（着地タイミング）で再生
		if int(_bob_t / PI) != int(prev_bob / PI) and prev_bob > 0.0:
			SoundManager.play_footstep(GameManager.chapter_index, false)
	else:
		if player.camera.position.length_squared() > 0.0001:
			player.camera.position = player.camera.position.lerp(Vector3.ZERO, delta * 5.0)


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

	var idx := 0
	while idx < events.size():
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
				await get_tree().create_timer(float(ev.get("sec", 1.0))).timeout

			"wait":
				if not _skip_to_next_say:
					var _sec := float(ev.get("sec", 0.5))
					# play() 直後は playing フラグが立つまで1フレーム掛かる
					await get_tree().process_frame
					# ボイス再生中なら先にボイスを待ち、残り時間のみ追加待機
					if SoundManager.is_voice_playing():
						var _t0 := Time.get_ticks_msec()
						await SoundManager.await_voice()
						if not _skip_to_next_say:
							_sec = max(_sec - (Time.get_ticks_msec() - _t0) / 1000.0, 0.0)
							await _skippable_wait(_sec)
					else:
						await _skippable_wait(_sec)

			"rot_y":
				if not GameManager.debug_free_move:
					_rot_y(float(ev.get("target", 0.0)), float(ev.get("dur", 1.0)))

			"head_x":
				if not GameManager.debug_free_move:
					_head_x(float(ev.get("target", 0.0)), float(ev.get("dur", 1.0)))

			"pos_z":
				if not GameManager.debug_free_move:
					var tw := _pos_z(float(ev.get("target", 0.0)), float(ev.get("dur", 5.0)))
					var tw_id : String = ev.get("id", "")
					if not tw_id.is_empty():
						active_tweens[tw_id] = tw

			"pos_z_await":
				if not GameManager.debug_free_move:
					var tw_id : String = ev.get("id", "")
					if tw_id in active_tweens:
						var tw_ref = active_tweens[tw_id]
						if tw_ref and tw_ref.is_valid():
							await tw_ref.finished
						active_tweens.erase(tw_id)

			"pos_x":
				if not GameManager.debug_free_move:
					var tw := _pos_x(float(ev.get("target", 0.0)), float(ev.get("dur", 5.0)))
					var tw_id : String = ev.get("id", "")
					if not tw_id.is_empty():
						active_tweens[tw_id] = tw

			"pos_x_await":
				if not GameManager.debug_free_move:
					var tw_id : String = ev.get("id", "")
					if tw_id in active_tweens:
						var tw_ref = active_tweens[tw_id]
						if tw_ref and tw_ref.is_valid():
							await tw_ref.finished
						active_tweens.erase(tw_id)

			"set_viewers":
				_set_viewers(int(ev.get("count", 0)))

			"walk_set":
				if not GameManager.debug_free_move:
					_walking = ev.get("on", false)

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

			"superchat":
				_story_superchat(ev.get("name", ""), ev.get("msg", ""), int(ev.get("amount", 500)))

			"flashlight_flicker":
				await _flashlight_flicker()

			"sfx":
				var sound : String = ev.get("sound", "")
				var vol   : float  = float(ev.get("vol", -6.0))
				match sound:
					"ambient_wind":  SoundManager.start_ambient(0)
					"door_creak":    SoundManager.play_door_creak()
					"monster_growl": SoundManager.play_monster_growl(vol)

			"flashlight_off":
				_flashlight_off()

			"fade_black":
				await _fade_black(float(ev.get("dur", 0.8)))

			"fade_clear":
				await _fade_clear(float(ev.get("dur", 0.8)))

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

	panel.show_choice(prompt, choices)

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

## クリックでキャンセル可能な待機
func _skippable_wait(sec: float) -> void:
	if sec <= 0.0 or _skip_to_next_say:
		return
	var t_end := Time.get_ticks_msec() + int(sec * 1000)
	while Time.get_ticks_msec() < t_end and not _skip_to_next_say:
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


func _pos_x(target_x: float, dur: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(player, "position:x", target_x, dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw


func _set_viewers(count: int) -> void:
	var chrome := get_tree().get_first_node_in_group("youtube_chrome")
	if not is_instance_valid(chrome):
		return
	chrome._view_count = count
	if is_instance_valid(chrome._view_label):
		chrome._view_label.text = "%s 人が視聴中" % chrome._fmt_count(count)


# ════════════════════════════════════════════════════════════════════
# ポラロイド風動画表示
# ════════════════════════════════════════════════════════════════════

func _polaroid_video(video_path: String) -> void:
	# video_path はフレームディレクトリ (例: "res://assets/video/bus_frames")
	# または旧OGVパス → フレームディレクトリに自動変換
	var frames_dir := video_path
	if frames_dir.ends_with(".ogv") or frames_dir.ends_with(".webm"):
		frames_dir = frames_dir.get_base_dir() + "/bus_frames"

	# フレームが存在するか確認（1枚目のみチェック・全枚プリロードを回避）
	if not ResourceLoader.exists("%s/frame_001.png" % frames_dir):
		push_warning("EntranceDirector: polaroid_video — no frames in: " + frames_dir)
		return

	const FPS := 25.0
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
	frame_style.bg_color = Color(0.96, 0.94, 0.92, 1.0)  # やや温かみのある白
	frame_style.set_corner_radius_all(2)
	frame.add_theme_stylebox_override("panel", frame_style)
	container.add_child(frame)

	# ── フレーム表示用 TextureRect ──
	var tex_rect := TextureRect.new()
	tex_rect.position = Vector2(-FRAME_W / 2 + BORDER_SIDE, -FRAME_H / 2 + BORDER_SIDE)
	tex_rect.size = Vector2(PHOTO_W, PHOTO_H)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.texture = null  # ストリーミング再生で上書きするため初期値は空
	container.add_child(tex_rect)

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

	# ── フレームアニメーション再生（ストリーミング: 1枚ずつロード・即解放） ──
	var frame_dur := 1.0 / FPS
	var stream_idx := 1
	while true:
		var path := "%s/frame_%03d.png" % [frames_dir, stream_idx]
		if not ResourceLoader.exists(path):
			break
		tex_rect.texture = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		await get_tree().create_timer(frame_dur).timeout
		stream_idx += 1

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
# 画面フェード（暗転 / 明転）
# ════════════════════════════════════════════════════════════════════

func _ensure_fade_layer() -> void:
	if is_instance_valid(_fade_layer):
		return
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 19  # YouTubeChrome(20) の直下、ポラロイド(18) より上
	get_tree().root.add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.anchor_right  = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func _fade_black(dur: float = 0.8) -> void:
	_ensure_fade_layer()
	_fade_rect.color = Color(0, 0, 0, 0)
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, dur)
	await tw.finished


func _fade_clear(dur: float = 0.8) -> void:
	_ensure_fade_layer()
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 0.0, dur)
	await tw.finished
