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

			"polaroid_video":
				await _polaroid_video(ev.get("path", ""))

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


# ════════════════════════════════════════════════════════════════════
# ポラロイド風動画表示
# ════════════════════════════════════════════════════════════════════

func _polaroid_video(video_path: String) -> void:
	# video_path はフレームディレクトリ (例: "res://assets/video/bus_frames")
	# または旧OGVパス → フレームディレクトリに自動変換
	var frames_dir := video_path
	if frames_dir.ends_with(".ogv") or frames_dir.ends_with(".webm"):
		frames_dir = frames_dir.get_base_dir() + "/bus_frames"

	# フレーム画像をプリロード
	var frames: Array[Texture2D] = []
	var idx := 1
	while true:
		var path := "%s/frame_%03d.png" % [frames_dir, idx]
		if not ResourceLoader.exists(path):
			break
		frames.append(load(path))
		idx += 1

	if frames.is_empty():
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
	tex_rect.texture = frames[0]
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

	# ── フレームアニメーション再生（PNG連番 → 劣化なし） ──
	var frame_dur := 1.0 / FPS
	for i in range(frames.size()):
		tex_rect.texture = frames[i]
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
