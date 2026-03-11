extends Control

## ─────────────────────────────────────────────────────────
## シネマティック・プロローグ — REC:OFF-AIR
## フルスクリーン映画的演出。スマホUI廃止。
## 静寂と衝撃のコントラスト + RGB分離 + フィルムグレイン。
## 全UI動的生成。Opening.tscn はルートControlのみ。
## ─────────────────────────────────────────────────────────

const EndingPlayerScript := preload("res://scripts/EndingPlayer.gd")

enum Phase { TITLE, VIDEO, PROLOGUE, DONE }

# ── 状態 ──────────────────────────────────────────────────
var _phase       : Phase = Phase.TITLE
var _skipped     : bool  = false
var _title_ready : bool  = false
var _elapsed     : float = 0.0
var _od          : Dictionary = {}

# ── 動的ノード ────────────────────────────────────────────
var _shake_root   : Control
var _title_bg     : TextureRect
var _title_dark   : ColorRect
var _overlay      : ColorRect      # 汎用フラッシュ
var _skip_btn     : Button
var _settings_btn     : Button
var _settings_panel   : Control
var _settings_content : VBoxContainer
var _settings_title   : Label
var _settings_back    : Button

# タイトルHUD
var _prompt_label : Label

# ビデオ
var _video_player  : VideoStreamPlayer
var _video_started : bool  = false
var _video_wait    : float = 0.0

# シェイク
var _shake_intensity : float = 0.0
var _shake_timer     : float = 0.0

# フィルムグレイン
var _grain_mat : ShaderMaterial


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	const _DEBUG_SKIP := false
	if _DEBUG_SKIP:
		_go_to_game()
		return
	_load_data()
	_build_ui()
	_build_settings_button()
	_phase = Phase.TITLE
	_run_title()


func _process(delta: float) -> void:
	_elapsed += delta
	if _shake_timer > 0.0:
		_shake_timer -= delta
		if is_instance_valid(_shake_root):
			_shake_root.position = Vector2(
				randf_range(-_shake_intensity, _shake_intensity),
				randf_range(-_shake_intensity, _shake_intensity))
		if _shake_timer <= 0.0 and is_instance_valid(_shake_root):
			_shake_root.position = Vector2.ZERO
	if _grain_mat:
		_grain_mat.set_shader_parameter("time_val", _elapsed)
	match _phase:
		Phase.TITLE: _update_title_anim()
		Phase.VIDEO: _update_video(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not ((event is InputEventKey and event.pressed and not event.echo) or
			(event is InputEventMouseButton and event.pressed)):
		return
	if _phase == Phase.TITLE and _title_ready and not is_instance_valid(_settings_panel):
		_advance_from_title()


# ════════════════════════════════════════════════════════════
# UI 構築
# ════════════════════════════════════════════════════════════

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.008, 0.005, 0.012, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_shake_root = Control.new()
	_shake_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shake_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shake_root)

	_title_bg = TextureRect.new()
	_title_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var tex := ResourceLoader.load("res://assets/textures/title_bg.jpg", "Texture2D")
	if tex:
		_title_bg.texture = tex as Texture2D
	_title_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_title_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_title_bg.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_title_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_bg.visible = false
	_shake_root.add_child(_title_bg)

	_title_dark = ColorRect.new()
	_title_dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_dark.color = Color(0, 0, 0, 0.0)
	_title_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_dark.visible = false
	_shake_root.add_child(_title_dark)

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# フィルムグレイン・ビネットはタイトルでは無効化
	#_add_film_grain()
	#_add_vignette()


# ════════════════════════════════════════════════════════════
# タイトル画面
# ════════════════════════════════════════════════════════════

func _run_title() -> void:
	SoundManager.play_bgm("res://assets/audio/bgm/山あいのわらべ歌.mp3", -10.0)
	_title_bg.visible = true
	_title_dark.visible = true
	_title_dark.color = Color(0, 0, 0, 0.0)
	_title_bg.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_build_title_hud()
	await get_tree().create_timer(0.3).timeout
	if _skipped: return
	var tw := create_tween()
	tw.tween_property(_title_bg, "modulate:a", 1.0, 1.8)
	await tw.finished
	if _skipped: return
	await get_tree().create_timer(1.2).timeout
	if _skipped: return
	if is_instance_valid(_prompt_label):
		_prompt_label.visible = true
	_title_ready = true


func _build_title_hud() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = "─── 画面をクリック / キーを押して開始 ───"
	_prompt_label.add_theme_font_size_override("font_size", 22)
	_prompt_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.80, 0.85))
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt_label.offset_top = -65
	_prompt_label.offset_bottom = -25
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_label.visible = false
	_shake_root.add_child(_prompt_label)


func _update_title_anim() -> void:
	if is_instance_valid(_prompt_label) and _title_ready:
		_prompt_label.modulate.a = 0.4 + sin(_elapsed * 2.5) * 0.4


func _advance_from_title() -> void:
	_title_ready = false
	_phase = Phase.VIDEO
	SoundManager.stop_bgm(1.1)
	await _fade(_title_bg, 0.0, 1.1)
	_title_bg.visible = false
	_title_dark.visible = false
	if is_instance_valid(_prompt_label):
		_prompt_label.visible = false
	await get_tree().create_timer(0.1).timeout
	if _skipped: return
	_play_video()


# ════════════════════════════════════════════════════════════
# ビデオ再生
# ════════════════════════════════════════════════════════════

func _play_video() -> void:
	const VIDEO_PATH := "res://assets/video/opm.ogv"
	if not ResourceLoader.exists(VIDEO_PATH):
		_phase = Phase.PROLOGUE
		_run_prologue()
		return
	_video_player = VideoStreamPlayer.new()
	_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video_player.expand = true
	_video_player.stream = load(VIDEO_PATH)
	add_child(_video_player)
	_video_player.play()
	_video_started = false
	_video_wait = 0.0
	_create_skip_button()


func _update_video(delta: float) -> void:
	if not _video_player or not is_instance_valid(_video_player):
		return
	if not _video_started and _video_player.is_playing():
		_video_started = true
	elif _video_started and not _video_player.is_playing():
		_phase = Phase.PROLOGUE
		_cleanup_video()
		if is_inside_tree():
			await get_tree().create_timer(0.3).timeout
		_run_prologue()
	elif not _video_started:
		_video_wait += delta
		if _video_wait >= 3.0:
			_skip_video()


func _skip_video() -> void:
	if _phase != Phase.VIDEO:
		return
	_phase = Phase.PROLOGUE
	if _video_player and is_instance_valid(_video_player):
		_video_player.stop()
	_cleanup_video()
	_run_prologue()


func _cleanup_video() -> void:
	_remove_skip_button()
	if _video_player and is_instance_valid(_video_player):
		_video_player.queue_free()
	_video_player = null


# ════════════════════════════════════════════════════════════
# プロローグ本編 — シネマティック・ホラー
# ════════════════════════════════════════════════════════════

func _run_prologue() -> void:
	_create_skip_button()
	_play_sfx("ambient_wind/Ambient Wind (1).mp3", -20.0)
	await get_tree().create_timer(1.0).timeout
	if _skipped: return

	await _show_profile()
	if _skipped: return

	await _show_dm()
	if _skipped: return

	await _scare_moment()
	if _skipped: return

	await _show_monologue()
	if _skipped: return

	await _show_caption()
	if _skipped: return

	_go_to_game()


# ── 1. プロフィール（フルスクリーン・タイトルカード）─────

func _show_profile() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shake_root.add_child(root)

	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.15
	vbox.anchor_right = 0.85
	vbox.anchor_top = 0.18
	vbox.anchor_bottom = 0.82
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(vbox)

	# 装飾線
	var deco := Label.new()
	deco.text = "━━━━━━━━━━━━━━━━━━━━━━━"
	deco.add_theme_font_size_override("font_size", 10)
	deco.add_theme_color_override("font_color", Color(0.30, 0.30, 0.35))
	deco.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.modulate.a = 0.0
	vbox.add_child(deco)

	var p : Dictionary = _od.get("profile", {})
	var lines : Array = p.get("lines", [])
	var labels : Array[Label] = []

	for line_data in lines:
		var text : String = line_data.get("text", "")
		var style : String = line_data.get("style", "normal")
		var lbl := Label.new()
		lbl.text = text
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.modulate.a = 0.0
		_apply_profile_style(lbl, style)
		vbox.add_child(lbl)
		labels.append(lbl)

	# 装飾線フェードイン
	var tw0 := create_tween()
	tw0.tween_property(deco, "modulate:a", 1.0, 0.8)
	await tw0.finished
	if _skipped:
		root.queue_free()
		return

	# 各行フェードイン
	for lbl in labels:
		if _skipped: break
		var tw := create_tween()
		tw.tween_property(lbl, "modulate:a", 1.0, 0.6)
		await tw.finished
		if _skipped: break
		var wait : float = maxf(0.25, lbl.text.length() * 0.025)
		await get_tree().create_timer(wait).timeout

	if _skipped:
		root.queue_free()
		return

	await get_tree().create_timer(2.0).timeout
	if _skipped:
		root.queue_free()
		return

	await _fade(root, 0.0, 1.2)
	root.queue_free()
	await get_tree().create_timer(0.5).timeout


func _apply_profile_style(lbl: Label, style: String) -> void:
	match style:
		"name":
			lbl.add_theme_font_size_override("font_size", 32)
			lbl.add_theme_color_override("font_color", Color(0.98, 0.96, 0.93))
		"handle":
			lbl.add_theme_font_size_override("font_size", 15)
			lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
		"bio":
			lbl.add_theme_font_size_override("font_size", 18)
			lbl.add_theme_color_override("font_color", Color(0.75, 0.73, 0.70))
		"stats":
			lbl.add_theme_font_size_override("font_size", 16)
			lbl.add_theme_color_override("font_color", Color(0.62, 0.62, 0.66))
		"video":
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(0.48, 0.48, 0.52))
		"warning":
			lbl.add_theme_font_size_override("font_size", 16)
			lbl.add_theme_color_override("font_color", Color(0.78, 0.20, 0.15))


# ── 2. DM（闇の中に浮かぶメッセージ）────────────────────

func _show_dm() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shake_root.add_child(root)

	# ヘッダー
	var header := Label.new()
	header.text = "ダイレクトメッセージ"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.50, 0.50, 0.56))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.set_anchors_preset(Control.PRESET_CENTER_TOP)
	header.offset_top = 80
	header.offset_left = -200
	header.offset_right = 200
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.modulate.a = 0.0
	root.add_child(header)

	var sender := Label.new()
	sender.text = "from: [アカウント削除済み]"
	sender.add_theme_font_size_override("font_size", 13)
	sender.add_theme_color_override("font_color", Color(0.72, 0.18, 0.14))
	sender.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sender.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sender.offset_top = 102
	sender.offset_left = -200
	sender.offset_right = 200
	sender.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sender.modulate.a = 0.0
	root.add_child(sender)

	_play_sfx("metal/metalClick.ogg", -6.0)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(header, "modulate:a", 1.0, 0.8)
	tw.tween_property(sender, "modulate:a", 1.0, 0.8).set_delay(0.4)
	await tw.finished
	if _skipped:
		root.queue_free()
		return

	await get_tree().create_timer(0.6).timeout
	if _skipped:
		root.queue_free()
		return

	# メッセージ（中央に1つずつクロスフェード）
	var msg_label := Label.new()
	msg_label.add_theme_font_size_override("font_size", 24)
	msg_label.add_theme_color_override("font_color", Color(0.88, 0.86, 0.84))
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.anchor_left = 0.1
	msg_label.anchor_right = 0.9
	msg_label.anchor_top = 0.3
	msg_label.anchor_bottom = 0.7
	msg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	msg_label.modulate.a = 0.0
	root.add_child(msg_label)

	var messages : Array = _od.get("dm", {}).get("lines", [])
	for idx in range(messages.size()):
		if _skipped: break
		var msg : Dictionary = messages[idx]
		var text : String = msg.get("text", "")
		var style : String = msg.get("style", "normal")
		if style == "alert":
			continue

		# フェードアウト
		if msg_label.modulate.a > 0.0:
			var tw_out := create_tween()
			tw_out.tween_property(msg_label, "modulate:a", 0.0, 0.3)
			await tw_out.finished
			if _skipped: break

		msg_label.text = text
		match style:
			"bold":
				msg_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
				msg_label.add_theme_font_size_override("font_size", 26)
			"creepy":
				msg_label.add_theme_color_override("font_color", Color(0.88, 0.18, 0.14))
				msg_label.add_theme_font_size_override("font_size", 28)
			_:
				msg_label.add_theme_color_override("font_color", Color(0.88, 0.86, 0.84))
				msg_label.add_theme_font_size_override("font_size", 24)

		var tw_in := create_tween()
		tw_in.tween_property(msg_label, "modulate:a", 1.0, 0.5)
		await tw_in.finished
		if _skipped: break

		var hold : float = maxf(1.2, text.length() * 0.07)
		await get_tree().create_timer(hold).timeout
		if _skipped: break

		# 後半: 不穏な赤フリッカー
		if idx >= 5:
			_overlay.color = Color(0.4, 0.0, 0.0, randf_range(0.03, 0.07))
			await get_tree().create_timer(0.06).timeout
			if is_instance_valid(_overlay):
				_overlay.color.a = 0.0

	if _skipped:
		root.queue_free()
		return

	# 最後のメッセージ保持→衝撃
	await get_tree().create_timer(0.6).timeout
	if _skipped:
		root.queue_free()
		return

	_play_sfx("monster/Monster Growl (5).mp3", -4.0)
	await _shake(10.0, 0.5)
	_overlay.color = Color(0.5, 0.0, 0.0, 0.22)
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(_overlay):
		_overlay.color.a = 0.0

	await _fade(root, 0.0, 0.6)
	root.queue_free()
	await get_tree().create_timer(0.8).timeout


# ── 3. 恐怖の瞬間（RGB分離テキスト）─────────────────────

func _scare_moment() -> void:
	var sf : Dictionary = _od.get("scary_flash", {})
	var text : String = sf.get("text", "見 て い る")

	var scare_root := Control.new()
	scare_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	scare_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scare_root.modulate.a = 0.0
	_shake_root.add_child(scare_root)

	# 赤チャネル（左オフセット）
	var scare_r := Label.new()
	scare_r.text = text
	scare_r.add_theme_font_size_override("font_size", 90)
	scare_r.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0, 0.5))
	scare_r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scare_r.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scare_r.set_anchors_preset(Control.PRESET_FULL_RECT)
	scare_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scare_root.add_child(scare_r)

	# メインテキスト
	var scare_main := Label.new()
	scare_main.text = text
	scare_main.add_theme_font_size_override("font_size", 90)
	scare_main.add_theme_color_override("font_color", Color(0.90, 0.04, 0.04, 0.9))
	scare_main.add_theme_color_override("font_shadow_color", Color(0.3, 0, 0, 0.6))
	scare_main.add_theme_constant_override("shadow_offset_x", 3)
	scare_main.add_theme_constant_override("shadow_offset_y", 3)
	scare_main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scare_main.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scare_main.set_anchors_preset(Control.PRESET_FULL_RECT)
	scare_main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scare_root.add_child(scare_main)

	# 青チャネル（右オフセット）
	var scare_b := Label.new()
	scare_b.text = text
	scare_b.add_theme_font_size_override("font_size", 90)
	scare_b.add_theme_color_override("font_color", Color(0.0, 0.15, 1.0, 0.4))
	scare_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scare_b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scare_b.set_anchors_preset(Control.PRESET_FULL_RECT)
	scare_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scare_root.add_child(scare_b)

	# RGB分離フリッカー
	_play_sfx("bell/impactBell_heavy_000.ogg", -6.0)
	for burst in range(5):
		if _skipped: break
		scare_r.position.x = randf_range(-15, -4)
		scare_b.position.x = randf_range(4, 15)
		scare_root.modulate.a = randf_range(0.6, 1.0)
		_overlay.color = Color(0.5, 0.0, 0.0, randf_range(0.08, 0.20))
		await _shake(14.0, 0.07)
		scare_root.modulate.a = 0.0
		if is_instance_valid(_overlay):
			_overlay.color.a = 0.0
		await get_tree().create_timer(randf_range(0.08, 0.18)).timeout

	if _skipped:
		scare_root.queue_free()
		return

	# 最終フラッシュ
	scare_r.position.x = -8
	scare_b.position.x = 8
	scare_root.modulate.a = 0.9
	_overlay.color = Color(0.4, 0.0, 0.0, 0.18)
	_play_sfx("bell/impactBell_heavy_001.ogg", -4.0)
	await _shake(6.0, 0.5)
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(_overlay):
		_overlay.color.a = 0.0

	var tw := create_tween()
	tw.tween_property(scare_root, "modulate:a", 0.0, 0.5)
	await tw.finished
	scare_root.queue_free()
	await get_tree().create_timer(1.0).timeout


# ── 4. 独白（シネマティック字幕）─────────────────────────

func _show_monologue() -> void:
	var lines : Array = _od.get("monologue", {}).get("lines", [])

	for line_data in lines:
		if _skipped: return
		var text : String = line_data.get("text", "")
		var style : String = line_data.get("style", "dialogue")

		var lbl := Label.new()
		lbl.text = text
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.modulate.a = 0.0
		_apply_mono_style(lbl, style)

		if style == "stage_direction":
			lbl.anchor_left = 0.15
			lbl.anchor_right = 0.85
			lbl.anchor_top = 0.32
			lbl.anchor_bottom = 0.48
		elif style == "final":
			lbl.anchor_left = 0.1
			lbl.anchor_right = 0.9
			lbl.anchor_top = 0.38
			lbl.anchor_bottom = 0.62
		else:
			lbl.anchor_left = 0.1
			lbl.anchor_right = 0.9
			lbl.anchor_top = 0.40
			lbl.anchor_bottom = 0.60

		_shake_root.add_child(lbl)

		var tw_in := create_tween()
		tw_in.tween_property(lbl, "modulate:a", 1.0, 0.6)
		await tw_in.finished
		if _skipped:
			lbl.queue_free()
			return

		var wait : float = maxf(1.0, text.length() * 0.05)
		await get_tree().create_timer(wait).timeout
		if _skipped:
			lbl.queue_free()
			return

		if style == "final":
			await get_tree().create_timer(0.8).timeout
			if _skipped:
				lbl.queue_free()
				return

		var tw_out := create_tween()
		tw_out.tween_property(lbl, "modulate:a", 0.0, 0.5)
		await tw_out.finished
		lbl.queue_free()
		await get_tree().create_timer(0.3).timeout

	await get_tree().create_timer(0.5).timeout


func _apply_mono_style(lbl: Label, style: String) -> void:
	match style:
		"stage_direction":
			lbl.add_theme_font_size_override("font_size", 17)
			lbl.add_theme_color_override("font_color", Color(0.52, 0.50, 0.48, 0.85))
		"dialogue_strong":
			lbl.add_theme_font_size_override("font_size", 28)
			lbl.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
		"dialogue":
			lbl.add_theme_font_size_override("font_size", 24)
			lbl.add_theme_color_override("font_color", Color(0.85, 0.83, 0.80))
		"dialogue_dim":
			lbl.add_theme_font_size_override("font_size", 22)
			lbl.add_theme_color_override("font_color", Color(0.68, 0.65, 0.62))
		"dialogue_faint":
			lbl.add_theme_font_size_override("font_size", 22)
			lbl.add_theme_color_override("font_color", Color(0.58, 0.55, 0.52))
		"final":
			lbl.add_theme_font_size_override("font_size", 36)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.98, 0.95))
			lbl.add_theme_color_override("font_shadow_color", Color(0.5, 0.08, 0.08, 0.5))
			lbl.add_theme_constant_override("shadow_offset_x", 2)
			lbl.add_theme_constant_override("shadow_offset_y", 2)


# ── 5. ロケーション テロップ ─────────────────────────────

func _show_caption() -> void:
	var cap_label := Label.new()
	cap_label.text = ""
	cap_label.add_theme_font_size_override("font_size", 56)
	cap_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.82))
	cap_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	cap_label.add_theme_constant_override("shadow_offset_x", 3)
	cap_label.add_theme_constant_override("shadow_offset_y", 3)
	cap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap_label.anchor_left  = 0.1
	cap_label.anchor_right = 0.9
	cap_label.anchor_top   = 0.28
	cap_label.anchor_bottom = 0.72
	cap_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap_label.modulate.a = 0.0
	_shake_root.add_child(cap_label)

	var tw := create_tween()
	tw.tween_property(cap_label, "modulate:a", 1.0, 1.0)
	await tw.finished
	if _skipped:
		cap_label.queue_free()
		return

	var c : Dictionary = _od.get("caption", {})
	var cap_lines : Array = c.get("lines", ["霧 原 村", "", "深 夜   0 : 0 0"])
	for line in cap_lines:
		if _skipped: break
		if str(line) == "":
			cap_label.text += "\n"
			await get_tree().create_timer(0.6).timeout
		else:
			for ch in str(line):
				if _skipped: break
				cap_label.text += ch
				await get_tree().create_timer(c.get("char_speed", 0.08)).timeout
			cap_label.text += "\n"
			await get_tree().create_timer(c.get("line_wait", 0.4)).timeout
	if _skipped:
		cap_label.queue_free()
		return

	await get_tree().create_timer(c.get("display_wait", 2.5)).timeout
	if _skipped:
		cap_label.queue_free()
		return

	await _caption_warning(cap_label, c)
	if _skipped:
		cap_label.queue_free()
		return

	await get_tree().create_timer(1.0).timeout
	if _skipped:
		cap_label.queue_free()
		return
	await _fade(cap_label, 0.0, 0.8)
	cap_label.queue_free()
	await get_tree().create_timer(0.5).timeout


func _caption_warning(cap_label: Label, c: Dictionary) -> void:
	var orig_text := cap_label.text
	cap_label.text = c.get("warning_text", "  立 入 禁 止  ")
	cap_label.add_theme_color_override("font_color", Color(1.0, 0.06, 0.06))
	cap_label.add_theme_font_size_override("font_size", 58)
	_play_sfx("bell/impactBell_heavy_001.ogg", -4.0)
	await _shake(5.0, 0.15)
	_overlay.color = Color(0.4, 0.0, 0.0, 0.18)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(_overlay):
		_overlay.color.a = 0.0
	await get_tree().create_timer(0.06).timeout
	_overlay.color = Color(0.4, 0.0, 0.0, 0.12)
	await get_tree().create_timer(0.1).timeout
	cap_label.text = orig_text
	cap_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.82))
	cap_label.add_theme_font_size_override("font_size", 56)
	if is_instance_valid(_overlay):
		_overlay.color.a = 0.0


# ════════════════════════════════════════════════════════════
# エフェクト
# ════════════════════════════════════════════════════════════

func _shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_timer = duration
	await get_tree().create_timer(duration).timeout


func _fade(node: CanvasItem, to: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", to, duration)
	await tw.finished


# ════════════════════════════════════════════════════════════
# シェーダー
# ════════════════════════════════════════════════════════════

func _add_film_grain() -> void:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float grain : hint_range(0.0, 0.3) = 0.03;\nuniform float time_val = 0.0;\nvoid fragment() {\n\tfloat n = fract(sin(dot(FRAGCOORD.xy + vec2(time_val * 137.3), vec2(12.9898, 78.233))) * 43758.5453);\n\tCOLOR = vec4(vec3(n), grain);\n}"
	_grain_mat = ShaderMaterial.new()
	_grain_mat.shader = shader
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.material = _grain_mat
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)


func _add_vignette() -> void:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec2 uv = UV - 0.5;\n\tfloat v = dot(uv, uv);\n\tCOLOR = vec4(0.0, 0.0, 0.0, smoothstep(0.25, 0.65, v));\n}"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.material = mat
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)


# ════════════════════════════════════════════════════════════
# ヘルパー
# ════════════════════════════════════════════════════════════

func _go_to_game() -> void:
	_phase = Phase.DONE
	_remove_skip_button()
	_remove_settings()
	GameManager.load_chapter(0)
	SoundManager.stop_bgm(0.0)
	LoadingScreen.show_loading()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _go_to_chapter(index: int) -> void:
	_phase = Phase.DONE
	_skipped = true
	_remove_skip_button()
	_remove_settings()
	GameManager.load_chapter(index)
	SoundManager.stop_bgm(0.0)
	LoadingScreen.show_loading()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _skip_to_game() -> void:
	_skipped = true
	_remove_skip_button()
	if is_instance_valid(_overlay):
		_overlay.color = Color(0, 0, 0, 0)
	_go_to_game()


func _create_skip_button() -> void:
	_remove_skip_button()
	_skip_btn = Button.new()
	_skip_btn.text = "SKIP ▸▸"
	_skip_btn.add_theme_font_size_override("font_size", 18)
	_skip_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	_skip_btn.flat = true
	_skip_btn.anchor_left  = 1.0
	_skip_btn.anchor_top   = 0.0
	_skip_btn.anchor_right = 1.0
	_skip_btn.anchor_bottom = 0.0
	_skip_btn.offset_left   = -150
	_skip_btn.offset_top    = 14
	_skip_btn.offset_right  = -14
	_skip_btn.offset_bottom = 50
	_skip_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	if _phase == Phase.VIDEO:
		_skip_btn.pressed.connect(_skip_video)
	else:
		_skip_btn.pressed.connect(_skip_to_game)
	add_child(_skip_btn)


func _remove_skip_button() -> void:
	if _skip_btn and is_instance_valid(_skip_btn):
		_skip_btn.queue_free()
	_skip_btn = null


func _play_sfx(rel_path: String, vol_db: float = -6.0) -> void:
	var path := "res://assets/audio/sfx/" + rel_path
	var stream: AudioStream = null
	if path.ends_with(".ogg"):
		stream = load(path) as AudioStream
	else:
		var f := FileAccess.open(path, FileAccess.READ)
		if not f:
			return
		var s := AudioStreamMP3.new()
		s.data = f.get_buffer(f.get_length())
		stream = s
	if not stream:
		return
	var asp := AudioStreamPlayer.new()
	asp.stream = stream
	asp.volume_db = vol_db
	add_child(asp)
	asp.play()
	asp.finished.connect(asp.queue_free)


# ════════════════════════════════════════════════════════════
# 設定パネル（歯車アイコン → ステージ選択ウィンドウ）
# ════════════════════════════════════════════════════════════

const _PANEL_W := 480
const _PANEL_H := 420
const _PANEL_RADIUS := 18
const _PANEL_BG := Color(0.06, 0.06, 0.08, 0.96)
const _PANEL_BORDER := Color(0.35, 0.12, 0.12, 0.8)
const _PANEL_ACCENT := Color(0.85, 0.10, 0.10, 1.0)
const _BTN_BG := Color(0.10, 0.10, 0.12, 1.0)
const _BTN_BG_HOVER := Color(0.18, 0.08, 0.08, 1.0)
const _BTN_BORDER := Color(0.30, 0.12, 0.12, 0.6)

const CHAPTER_INFO : Array[Dictionary] = [
	{"name": "CP1  廃村入口", "sub": "公衆トイレの首無し少女", "icon": "🏚", "sections": [
		{"name": "CP1-1  廃村入口", "sub": "配信開始〜村門", "section": 0},
		{"name": "CP1-2  商店街", "sub": "懐中電灯で探索", "section": 1},
		{"name": "CP1-3  公衆トイレ", "sub": "みゆき遭遇〜脱出", "section": 2},
		{"name": "CP1-4  逃走と反転", "sub": "バス停へ逃走→村の奥へ", "section": 3},
	]},
	{"name": "CP2  村長の屋敷", "sub": "Kの日記と鏡の向こう", "icon": "🏛"},
	{"name": "CP3  廃倉庫", "sub": "VHSテープ回収", "icon": "📼"},
	{"name": "CP4  桐原神社", "sub": "白い木箱の秘密", "icon": "⛩"},
	{"name": "CP5  脱出", "sub": "最終分岐・3エンディング", "icon": "🚌"},
]


func _build_settings_button() -> void:
	_settings_btn = Button.new()
	_settings_btn.text = "⚙"
	_settings_btn.add_theme_font_size_override("font_size", 28)
	_settings_btn.add_theme_color_override("font_color", Color(0.65, 0.60, 0.55, 0.7))
	_settings_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.3, 0.2, 1.0))
	_settings_btn.flat = true
	_settings_btn.anchor_left   = 0.0
	_settings_btn.anchor_top    = 1.0
	_settings_btn.anchor_right  = 0.0
	_settings_btn.anchor_bottom = 1.0
	_settings_btn.offset_left   = 14
	_settings_btn.offset_top    = -60
	_settings_btn.offset_right  = 60
	_settings_btn.offset_bottom = -14
	_settings_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_btn.pressed.connect(_toggle_settings)
	add_child(_settings_btn)


func _toggle_settings() -> void:
	if is_instance_valid(_settings_panel):
		_close_settings()
	else:
		_open_settings()


func _open_settings() -> void:
	if is_instance_valid(_settings_panel):
		return

	_settings_panel = Control.new()
	_settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_settings_panel)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.6)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	var close_bg := Button.new()
	close_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	close_bg.flat = true
	close_bg.modulate.a = 0.0
	close_bg.pressed.connect(_close_settings)
	_settings_panel.add_child(dimmer)
	_settings_panel.add_child(close_bg)

	var panel := PanelContainer.new()
	panel.anchor_left  = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top   = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left   = -_PANEL_W / 2.0
	panel.offset_right  = _PANEL_W / 2.0
	panel.offset_top    = -_PANEL_H / 2.0
	panel.offset_bottom = _PANEL_H / 2.0

	var sb := StyleBoxFlat.new()
	sb.bg_color = _PANEL_BG
	sb.border_color = _PANEL_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(_PANEL_RADIUS)
	sb.shadow_color = Color(0.4, 0.0, 0.0, 0.3)
	sb.shadow_size = 20
	sb.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", sb)
	panel.clip_contents = true
	_settings_panel.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	var header_ctrl := _settings_header()
	vbox.add_child(header_ctrl)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = _PANEL_BORDER
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)

	_settings_content = VBoxContainer.new()
	_settings_content.add_theme_constant_override("separation", 0)
	_settings_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_settings_content)

	_show_settings_top()

	panel.scale = Vector2(0.85, 0.85)
	panel.pivot_offset = Vector2(_PANEL_W / 2.0, _PANEL_H / 2.0)
	panel.modulate.a = 0.0
	dimmer.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.2)
	tw.tween_property(dimmer, "modulate:a", 1.0, 0.2)


func _clear_settings_content() -> void:
	if not is_instance_valid(_settings_content):
		return
	for child in _settings_content.get_children():
		child.queue_free()


func _show_settings_top() -> void:
	_clear_settings_content()
	if is_instance_valid(_settings_title):
		_settings_title.text = "SETTINGS"
	if is_instance_valid(_settings_back):
		_settings_back.visible = false

	var section := _settings_section_label("メニュー")
	_settings_content.add_child(section)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_settings_content.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var top_pad := Control.new()
	top_pad.custom_minimum_size = Vector2(0, 4)
	list.add_child(top_pad)

	var menu_items : Array[Dictionary] = [
		{"name": "ステージ選択", "sub": "チャプターを選んでプレイ", "icon": "🎮", "action": "_show_stage_select"},
		{"name": "エンディング集", "sub": "解放したエンディングを閲覧", "icon": "📖", "action": "_show_ending_gallery"},
		{"name": "サウンド", "sub": "BGM・SE音量調整", "icon": "🔊", "action": ""},
		{"name": "グラフィック", "sub": "画質・エフェクト設定", "icon": "🖥", "action": ""},
	]

	for item in menu_items:
		var card := _menu_card(item["name"], item["sub"], item["icon"], item["action"])
		list.add_child(card)

	var bot_pad := Control.new()
	bot_pad.custom_minimum_size = Vector2(0, 8)
	list.add_child(bot_pad)


func _show_ending_gallery() -> void:
	_clear_settings_content()
	if is_instance_valid(_settings_title):
		_settings_title.text = "ENDING GALLERY"
	if is_instance_valid(_settings_back):
		_settings_back.visible = true

	var section := _settings_section_label("エンディング集")
	_settings_content.add_child(section)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_settings_content.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	# エンディング定義（追加する度にここに足す）
	var endings : Array[Dictionary] = [
		{"id": "bad_hikikomori", "name": "ひきこもり", "chapter": "CP1", "type": "BAD END",
		 "desc": "恐怖に負けて逃げ出した配信者の末路",
		 "source_json": "res://dialogue/ch01_entrance.json"},
	]

	for ed in endings:
		var unlocked : bool = true  # TODO: デバッグ用。リリース時は GameManager.is_ending_unlocked(ed["id"]) に戻す
		var card := _ending_card(ed, unlocked)
		list.add_child(card)
		if unlocked:
			card.gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_play_ending_from_gallery(ed)
			)

	# 未解放カウント
	var total : int = endings.size()
	var unlocked_count : int = 0
	for ed in endings:
		if GameManager.is_ending_unlocked(ed["id"]):
			unlocked_count += 1

	var footer := Label.new()
	footer.text = "解放済み: %d / %d" % [unlocked_count, total]
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.45, 0.4, 0.38))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(footer)


func _ending_card(ed: Dictionary, unlocked: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if unlocked:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	if unlocked:
		sb.bg_color = Color(0.12, 0.05, 0.05, 0.9)
		sb.border_color = Color(0.5, 0.12, 0.12, 0.6)
	else:
		sb.bg_color = Color(0.06, 0.06, 0.06, 0.7)
		sb.border_color = Color(0.2, 0.2, 0.2, 0.4)
	sb.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var type_lbl := Label.new()
	type_lbl.text = ed.get("type", "END") if unlocked else "???"
	type_lbl.add_theme_font_size_override("font_size", 11)
	type_lbl.add_theme_color_override("font_color", Color(0.9, 0.2, 0.15) if unlocked else Color(0.4, 0.4, 0.4))
	header.add_child(type_lbl)

	var chapter_lbl := Label.new()
	chapter_lbl.text = ed.get("chapter", "") if unlocked else ""
	chapter_lbl.add_theme_font_size_override("font_size", 11)
	chapter_lbl.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
	header.add_child(chapter_lbl)

	var name_lbl := Label.new()
	name_lbl.text = ed.get("name", "") if unlocked else "????????"
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8) if unlocked else Color(0.3, 0.3, 0.3))
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = ed.get("desc", "") if unlocked else "このエンディングはまだ解放されていません"
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45) if unlocked else Color(0.3, 0.28, 0.25))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	return panel


func _play_ending_from_gallery(ed: Dictionary) -> void:
	# ダイアログJSONからplay_endingセクションを取得
	var source : String = ed.get("source_json", "")
	var ending_id : String = ed.get("id", "")
	if source == "" or ending_id == "":
		return

	var f := FileAccess.open(source, FileAccess.READ)
	if not f:
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		return
	var data : Array = json.data if json.data is Array else json.data.get("events", [])

	var sections : Array = []
	var ending_title : String = ""
	for ev in data:
		if ev is Dictionary and ev.get("type", "") == "play_ending" and ev.get("id", "") == ending_id:
			sections = ev.get("sections", [])
			ending_title = ev.get("ending_title", "")
			break

	if sections.is_empty():
		return

	# タイトルBGMを止める
	SoundManager.stop_bgm(1.5)

	# タイトル画面全体を非表示にする
	visible = false

	# EndingPlayerで再生（ルートに追加してレイヤー順を保証）
	var player := CanvasLayer.new()
	player.set_script(EndingPlayerScript)
	get_tree().root.add_child(player)
	await player.play(sections, ending_title)

	# EndingPlayer をフェードアウト
	await player.fade_out(1.5)

	# タイトル画面を復帰 + BGM再開
	visible = true
	if is_instance_valid(_settings_panel):
		_settings_panel.visible = true
	SoundManager.play_bgm("res://assets/audio/bgm/山あいのわらべ歌.mp3", -10.0)


func _show_stage_select() -> void:
	_clear_settings_content()
	if is_instance_valid(_settings_title):
		_settings_title.text = "STAGE SELECT"
	if is_instance_valid(_settings_back):
		_settings_back.visible = true

	var section := _settings_section_label("チャプター")
	_settings_content.add_child(section)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_settings_content.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var top_pad := Control.new()
	top_pad.custom_minimum_size = Vector2(0, 4)
	list.add_child(top_pad)

	for i in range(CHAPTER_INFO.size()):
		var card := _chapter_card(i)
		list.add_child(card)
		# CP1のサブセクションカードを直下に追加
		if CHAPTER_INFO[i].has("sections"):
			for sec_info in CHAPTER_INFO[i]["sections"]:
				var sec_card := _section_card(i, sec_info)
				list.add_child(sec_card)

	var bot_pad := Control.new()
	bot_pad.custom_minimum_size = Vector2(0, 8)
	list.add_child(bot_pad)


func _menu_card(title: String, sub: String, icon: String, action: String) -> Control:
	var btn := Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(0, 60)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = _BTN_BG
	normal_sb.border_color = _BTN_BORDER
	normal_sb.set_border_width_all(1)
	normal_sb.set_corner_radius_all(12)
	normal_sb.content_margin_left = 14
	normal_sb.content_margin_right = 14
	normal_sb.content_margin_top = 8
	normal_sb.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal_sb)

	var hover_sb : StyleBoxFlat = normal_sb.duplicate()
	hover_sb.bg_color = _BTN_BG_HOVER
	hover_sb.border_color = _PANEL_ACCENT.darkened(0.2)
	btn.add_theme_stylebox_override("hover", hover_sb)

	var pressed_sb : StyleBoxFlat = normal_sb.duplicate()
	pressed_sb.bg_color = Color(0.25, 0.05, 0.05, 1.0)
	pressed_sb.border_color = _PANEL_ACCENT
	btn.add_theme_stylebox_override("pressed", pressed_sb)

	var is_disabled := action.is_empty()
	if is_disabled:
		btn.disabled = true
		var disabled_sb : StyleBoxFlat = normal_sb.duplicate()
		disabled_sb.bg_color = Color(0.07, 0.07, 0.08, 0.6)
		disabled_sb.border_color = Color(0.15, 0.15, 0.15, 0.4)
		btn.add_theme_stylebox_override("disabled", disabled_sb)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 14)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	var pad_l := Control.new()
	pad_l.custom_minimum_size = Vector2(4, 0)
	hbox.add_child(pad_l)

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 26)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_disabled:
		icon_lbl.modulate.a = 0.35
	hbox.add_child(icon_lbl)

	var text_vbox := VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.text = title
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.88) if not is_disabled else Color(0.40, 0.38, 0.35))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(name_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = sub + ("" if not is_disabled else "  (coming soon)")
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.50, 0.45, 0.42) if not is_disabled else Color(0.30, 0.28, 0.25))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(sub_lbl)

	var arrow := Label.new()
	arrow.text = "▶"
	arrow.add_theme_font_size_override("font_size", 14)
	arrow.add_theme_color_override("font_color", Color(0.45, 0.35, 0.30) if not is_disabled else Color(0.20, 0.18, 0.15))
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(arrow)

	var pad_r := Control.new()
	pad_r.custom_minimum_size = Vector2(4, 0)
	hbox.add_child(pad_r)

	var wrapper := MarginContainer.new()
	wrapper.add_theme_constant_override("margin_left", 12)
	wrapper.add_theme_constant_override("margin_right", 12)
	wrapper.add_child(btn)

	if not is_disabled:
		btn.pressed.connect(Callable(self, action))

	return wrapper


func _close_settings() -> void:
	if not is_instance_valid(_settings_panel):
		return
	var tw := create_tween()
	tw.tween_property(_settings_panel, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_settings_panel):
			_settings_panel.queue_free()
			_settings_panel = null
	)


func _remove_settings() -> void:
	if is_instance_valid(_settings_panel):
		_settings_panel.queue_free()
		_settings_panel = null


func _settings_header() -> Control:
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 52)
	hbox.add_theme_constant_override("separation", 0)

	_settings_back = Button.new()
	_settings_back.text = "◀"
	_settings_back.flat = true
	_settings_back.add_theme_font_size_override("font_size", 18)
	_settings_back.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	_settings_back.add_theme_color_override("font_hover_color", Color(1.0, 0.3, 0.2))
	_settings_back.custom_minimum_size = Vector2(44, 0)
	_settings_back.visible = false
	_settings_back.pressed.connect(_show_settings_top)
	hbox.add_child(_settings_back)

	var pad_l := Control.new()
	pad_l.custom_minimum_size = Vector2(8, 0)
	hbox.add_child(pad_l)

	var icon := Label.new()
	icon.text = "⚙"
	icon.add_theme_font_size_override("font_size", 22)
	icon.add_theme_color_override("font_color", _PANEL_ACCENT)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	var pad_m := Control.new()
	pad_m.custom_minimum_size = Vector2(10, 0)
	hbox.add_child(pad_m)

	_settings_title = Label.new()
	_settings_title.text = "SETTINGS"
	_settings_title.add_theme_font_size_override("font_size", 20)
	_settings_title.add_theme_color_override("font_color", Color(0.92, 0.88, 0.84))
	_settings_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_settings_title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var close := Button.new()
	close.text = "✕"
	close.flat = true
	close.add_theme_font_size_override("font_size", 20)
	close.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	close.add_theme_color_override("font_hover_color", Color(1.0, 0.3, 0.2))
	close.custom_minimum_size = Vector2(44, 0)
	close.pressed.connect(_close_settings)
	hbox.add_child(close)

	return hbox


func _settings_section_label(text: String) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 4)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.45, 0.40))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(lbl)
	return margin


func _chapter_card(index: int) -> Control:
	var info : Dictionary = CHAPTER_INFO[index]

	var btn := Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(0, 56)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = _BTN_BG
	normal_sb.border_color = _BTN_BORDER
	normal_sb.set_border_width_all(1)
	normal_sb.set_corner_radius_all(12)
	normal_sb.content_margin_left = 14
	normal_sb.content_margin_right = 14
	normal_sb.content_margin_top = 6
	normal_sb.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", normal_sb)

	var hover_sb : StyleBoxFlat = normal_sb.duplicate()
	hover_sb.bg_color = _BTN_BG_HOVER
	hover_sb.border_color = _PANEL_ACCENT.darkened(0.2)
	btn.add_theme_stylebox_override("hover", hover_sb)

	var pressed_sb : StyleBoxFlat = normal_sb.duplicate()
	pressed_sb.bg_color = Color(0.25, 0.05, 0.05, 1.0)
	pressed_sb.border_color = _PANEL_ACCENT
	btn.add_theme_stylebox_override("pressed", pressed_sb)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	var pad_l := Control.new()
	pad_l.custom_minimum_size = Vector2(4, 0)
	hbox.add_child(pad_l)

	var icon_lbl := Label.new()
	icon_lbl.text = info["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 24)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon_lbl)

	var text_vbox := VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.text = info["name"]
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.88))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(name_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = info["sub"]
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.50, 0.45, 0.42))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(sub_lbl)

	var arrow := Label.new()
	arrow.text = "▶"
	arrow.add_theme_font_size_override("font_size", 14)
	arrow.add_theme_color_override("font_color", Color(0.45, 0.35, 0.30))
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(arrow)

	var pad_r := Control.new()
	pad_r.custom_minimum_size = Vector2(4, 0)
	hbox.add_child(pad_r)

	var wrapper := MarginContainer.new()
	wrapper.add_theme_constant_override("margin_left", 12)
	wrapper.add_theme_constant_override("margin_right", 12)
	wrapper.add_child(btn)

	if not info.has("sections"):
		btn.pressed.connect(func() -> void: _go_to_chapter(index))
	else:
		# サブセクションがある場合はボタン無効化（親は見出し扱い）
		btn.disabled = true
		var disabled_sb : StyleBoxFlat = normal_sb.duplicate()
		disabled_sb.bg_color = Color(0.12, 0.08, 0.06, 0.9)
		disabled_sb.border_color = _PANEL_ACCENT.darkened(0.4)
		btn.add_theme_stylebox_override("disabled", disabled_sb)
		arrow.text = "▼"

	return wrapper


func _section_card(chapter_index: int, sec_info: Dictionary) -> Control:
	var btn := Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(0, 48)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = Color(0.08, 0.06, 0.05, 0.8)
	normal_sb.border_color = Color(0.25, 0.18, 0.14, 0.5)
	normal_sb.set_border_width_all(1)
	normal_sb.set_corner_radius_all(8)
	normal_sb.content_margin_left = 14
	normal_sb.content_margin_right = 14
	normal_sb.content_margin_top = 4
	normal_sb.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", normal_sb)

	var hover_sb : StyleBoxFlat = normal_sb.duplicate()
	hover_sb.bg_color = Color(0.18, 0.08, 0.06, 0.9)
	hover_sb.border_color = _PANEL_ACCENT.darkened(0.2)
	btn.add_theme_stylebox_override("hover", hover_sb)

	var pressed_sb : StyleBoxFlat = normal_sb.duplicate()
	pressed_sb.bg_color = Color(0.25, 0.05, 0.05, 1.0)
	pressed_sb.border_color = _PANEL_ACCENT
	btn.add_theme_stylebox_override("pressed", pressed_sb)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	var indent := Control.new()
	indent.custom_minimum_size = Vector2(24, 0)
	hbox.add_child(indent)

	var dot := Label.new()
	dot.text = "┗"
	dot.add_theme_font_size_override("font_size", 14)
	dot.add_theme_color_override("font_color", Color(0.40, 0.30, 0.25))
	dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(dot)

	var text_vbox := VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 1)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.text = sec_info["name"]
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.80, 0.75))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(name_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = sec_info["sub"]
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", Color(0.45, 0.40, 0.38))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(sub_lbl)

	var arrow := Label.new()
	arrow.text = "▶"
	arrow.add_theme_font_size_override("font_size", 12)
	arrow.add_theme_color_override("font_color", Color(0.40, 0.30, 0.25))
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(arrow)

	var pad_r := Control.new()
	pad_r.custom_minimum_size = Vector2(4, 0)
	hbox.add_child(pad_r)

	var wrapper := MarginContainer.new()
	wrapper.add_theme_constant_override("margin_left", 24)
	wrapper.add_theme_constant_override("margin_right", 12)
	wrapper.add_child(btn)

	var sec_idx : int = sec_info["section"]
	btn.pressed.connect(func() -> void:
		GameManager.start_section = sec_idx
		_go_to_chapter(chapter_index)
	)

	return wrapper


# ════════════════════════════════════════════════════════════
# データ読み込み
# ════════════════════════════════════════════════════════════

func _load_data() -> void:
	var f := FileAccess.open("res://dialogue/opening.json", FileAccess.READ)
	if f:
		_od = JSON.parse_string(f.get_as_text())
	if _od == null:
		_od = {}
