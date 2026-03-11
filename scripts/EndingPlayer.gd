extends CanvasLayer

## ─────────────────────────────────────────────────────────
## エンディング専用シネマティック演出プレイヤー（超リッチ版）
## 画像なしでも文字・色・エフェクトだけで圧倒する
## mood: "dark"=恐怖/闇, "cold"=寂しさ/後悔, "warm"=切なさ, "fear"=直接的恐怖
## ─────────────────────────────────────────────────────────

signal ending_finished

# ── UI要素 ──
var _container     : Control
var _bg_color      : ColorRect       # 動的背景色
var _bg_rect       : TextureRect     # 背景画像A
var _bg_rect2      : TextureRect     # 背景画像B（クロスフェード）
var _vignette      : ColorRect
var _grain_overlay : ColorRect
var _scan_line     : ColorRect       # 走査線
var _fog_layer     : Control         # 霧/靄レイヤー
var _section_lbl   : Label
var _text_label    : RichTextLabel
var _center_big    : Label           # 画面中央の巨大テキスト（強調用）
var _divider       : ColorRect
var _heartbeat_overlay : ColorRect   # 心拍フラッシュ
var _top_bar       : ColorRect
var _bot_bar       : ColorRect

# ── 状態 ──
var _is_playing    : bool = false
var _time          : float = 0.0
var _zoom_tween    : Tween = null
var _particles     : Array[ColorRect] = []
var _rain_drops    : Array[ColorRect] = []
var _fog_rects     : Array[ColorRect] = []
var _current_mood  : String = ""
var _shake_amount  : float = 0.0
var _base_pos      : Vector2 = Vector2.ZERO
var _section_idx   : int = 0
var _current_audio : AudioStreamPlayer = null


func _ready() -> void:
	layer = 150
	_build_ui()
	visible = false


func _process(delta: float) -> void:
	if not _is_playing:
		return
	_time += delta

	# フィルムグレイン — ちらつき
	if is_instance_valid(_grain_overlay):
		_grain_overlay.color.a = 0.015 + sin(_time * 11.3) * 0.008 + sin(_time * 23.7) * 0.005

	# 走査線ゆっくり移動
	if is_instance_valid(_scan_line):
		_scan_line.position.y = fmod(_time * 40.0, 780.0) - 30.0
		_scan_line.color.a = 0.03 + sin(_time * 3.0) * 0.015

	# ビネット呼吸 — moodで強度変化
	if is_instance_valid(_vignette):
		var base_a : float = 0.6 if _current_mood == "dark" else (0.7 if _current_mood == "fear" else 0.5)
		_vignette.color.a = base_a + sin(_time * 0.6) * 0.08

	# 浮遊パーティクル
	for p in _particles:
		if is_instance_valid(p):
			var spd : float = p.get_meta("speed", 12.0)
			var freq : float = p.get_meta("freq", 1.0)
			var phase : float = p.get_meta("phase", 0.0)
			p.position.y -= delta * spd
			p.position.x += sin(_time * freq + phase) * delta * 10.0
			p.color.a = (sin(_time * 0.4 + phase) * 0.5 + 0.5) * 0.18
			if p.position.y < -20:
				p.position.y = 760
				p.position.x = randf_range(0, 1280)

	# 雨パーティクル（cold mood）
	for r in _rain_drops:
		if is_instance_valid(r):
			var spd : float = r.get_meta("speed", 300.0)
			r.position.y += delta * spd
			r.position.x -= delta * spd * 0.15
			if r.position.y > 740:
				r.position.y = randf_range(-100, -10)
				r.position.x = randf_range(0, 1400)

	# 霧の揺らぎ
	for f in _fog_rects:
		if is_instance_valid(f):
			var phase : float = f.get_meta("phase", 0.0)
			var spd : float = f.get_meta("drift", 8.0)
			f.position.x += delta * spd
			f.color.a = (sin(_time * 0.3 + phase) * 0.5 + 0.5) * 0.06
			if f.position.x > 1400:
				f.position.x = -200

	# シェイク
	if _shake_amount > 0.001 and is_instance_valid(_container):
		_container.position = _base_pos + Vector2(
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount)
		)
		_shake_amount *= 0.95

	# 心拍フラッシュ（dark/fear mood）
	if is_instance_valid(_heartbeat_overlay) and _current_mood in ["dark", "fear"]:
		var beat : float = fmod(_time, 3.0)
		if beat < 0.08:
			_heartbeat_overlay.color.a = 0.06
		elif beat < 0.2:
			_heartbeat_overlay.color.a = 0.0
		elif beat < 0.28:
			_heartbeat_overlay.color.a = 0.04
		else:
			_heartbeat_overlay.color.a = 0.0


func _build_ui() -> void:
	var vp_size := Vector2(1280, 720)

	_container = Control.new()
	_container.size = vp_size
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)
	_base_pos = _container.position

	# 動的背景色（黒→mood色にゆっくり変化）
	_bg_color = ColorRect.new()
	_bg_color.color = Color(0, 0, 0, 1)
	_bg_color.size = vp_size
	_bg_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_bg_color)

	# 背景画像A
	_bg_rect = TextureRect.new()
	_bg_rect.size = vp_size
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.modulate = Color(1, 1, 1, 0.0)
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_rect.pivot_offset = Vector2(640, 360)
	_container.add_child(_bg_rect)

	# 背景画像B
	_bg_rect2 = TextureRect.new()
	_bg_rect2.size = vp_size
	_bg_rect2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect2.modulate = Color(1, 1, 1, 0.0)
	_bg_rect2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_rect2.pivot_offset = Vector2(640, 360)
	_container.add_child(_bg_rect2)

	# 霧/靄レイヤー
	_fog_layer = Control.new()
	_fog_layer.size = vp_size
	_fog_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_fog_layer)
	for i in range(6):
		var fog := ColorRect.new()
		fog.size = Vector2(randf_range(200, 500), randf_range(80, 200))
		fog.position = Vector2(randf_range(-100, 1200), randf_range(100, 600))
		fog.color = Color(0.3, 0.25, 0.35, 0.0)
		fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fog.set_meta("phase", randf_range(0, TAU))
		fog.set_meta("drift", randf_range(3, 12))
		_fog_layer.add_child(fog)
		_fog_rects.append(fog)

	# ビネット
	_vignette = ColorRect.new()
	_vignette.color = Color(0, 0, 0, 0.6)
	_vignette.size = vp_size
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_vignette)

	# 心拍フラッシュオーバーレイ
	_heartbeat_overlay = ColorRect.new()
	_heartbeat_overlay.color = Color(0.4, 0.0, 0.0, 0.0)
	_heartbeat_overlay.size = vp_size
	_heartbeat_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_heartbeat_overlay)

	# フィルムグレイン
	_grain_overlay = ColorRect.new()
	_grain_overlay.color = Color(1, 1, 1, 0.015)
	_grain_overlay.size = vp_size
	_grain_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_grain_overlay)

	# 走査線
	_scan_line = ColorRect.new()
	_scan_line.color = Color(1, 1, 1, 0.03)
	_scan_line.size = Vector2(1280, 2)
	_scan_line.position = Vector2(0, -30)
	_scan_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_scan_line)

	# 浮遊パーティクル（塵）
	for i in range(30):
		var p := ColorRect.new()
		p.size = Vector2(randf_range(1, 4), randf_range(1, 4))
		p.color = Color(0.7, 0.6, 0.55, 0.0)
		p.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.set_meta("speed", randf_range(5, 20))
		p.set_meta("freq", randf_range(0.3, 1.5))
		p.set_meta("phase", randf_range(0, TAU))
		_container.add_child(p)
		_particles.append(p)

	# シネマスコープ（上下の黒帯）
	var bar_h : float = 55.0
	_top_bar = ColorRect.new()
	_top_bar.color = Color(0, 0, 0, 1)
	_top_bar.position = Vector2(0, 0)
	_top_bar.size = Vector2(1280, bar_h)
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_top_bar)

	_bot_bar = ColorRect.new()
	_bot_bar.color = Color(0, 0, 0, 1)
	_bot_bar.position = Vector2(0, 720 - bar_h)
	_bot_bar.size = Vector2(1280, bar_h)
	_bot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_bot_bar)

	# セクションタイトル
	_section_lbl = Label.new()
	_section_lbl.add_theme_font_size_override("font_size", 14)
	_section_lbl.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3, 0.0))
	_section_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_section_lbl.add_theme_constant_override("shadow_offset_x", 1)
	_section_lbl.add_theme_constant_override("shadow_offset_y", 1)
	_section_lbl.position = Vector2(80, bar_h + 14)
	_section_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_section_lbl)

	# 区切り線
	_divider = ColorRect.new()
	_divider.color = Color(0.5, 0.1, 0.1, 0.0)
	_divider.size = Vector2(0, 1)
	_divider.position = Vector2(640, 365)
	_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_divider)

	# 画面中央の巨大テキスト（emphasis用）
	_center_big = Label.new()
	_center_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_big.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center_big.position = Vector2(0, 0)
	_center_big.size = vp_size
	_center_big.add_theme_font_size_override("font_size", 36)
	_center_big.add_theme_color_override("font_color", Color(0.95, 0.7, 0.6, 0.0))
	_center_big.add_theme_color_override("font_shadow_color", Color(0.3, 0.0, 0.0, 0.8))
	_center_big.add_theme_constant_override("shadow_offset_x", 2)
	_center_big.add_theme_constant_override("shadow_offset_y", 2)
	_center_big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_center_big)

	# メインテキスト（画面中央、大きめ）
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.scroll_active = false
	_text_label.fit_content = false
	_text_label.position = Vector2(vp_size.x * 0.08, vp_size.y * 0.38)
	_text_label.size = Vector2(vp_size.x * 0.84, vp_size.y * 0.40)
	_text_label.add_theme_font_size_override("normal_font_size", 24)
	_text_label.add_theme_color_override("default_color", Color(0.92, 0.88, 0.82, 1.0))
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_text_label)


## ──────────────────────────────────────────────────────
## 再生メイン
## ──────────────────────────────────────────────────────
func play(sections: Array, ending_title: String = "") -> void:
	visible = true
	_is_playing = true
	_container.modulate.a = 0.0

	# エンディング専用アンビエント（静かな風の音）
	var ambient := AudioStreamPlayer.new()
	var amb_stream := load("res://assets/audio/sfx/ambient_wind/Ambient Wind (3).mp3")
	if amb_stream:
		ambient.stream = amb_stream
		ambient.volume_db = -18.0
		ambient.bus = "Master"
		add_child(ambient)
		ambient.play()

	# じわっと暗闇から始まる
	var tw_in := create_tween()
	tw_in.tween_property(_container, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	await tw_in.finished

	await get_tree().create_timer(1.0).timeout

	for i in range(sections.size()):
		_section_idx = i
		await _play_section(sections[i], i)

	# ── バッドエンドタイトル表示 ──
	if ending_title != "":
		await _show_ending_title(ending_title)

	_is_playing = false
	ending_finished.emit()


## ──────────────────────────────────────────────────────
## セクション再生
## ──────────────────────────────────────────────────────
func _play_section(section: Dictionary, idx: int) -> void:
	var section_title : String = section.get("title", "")
	var lines : Array = section.get("lines", [])
	var image_path : String = section.get("image", "")
	var post_wait : float = section.get("wait", 2.0)
	var mood : String = section.get("mood", "dark")
	_current_mood = mood

	# ── mood別の背景色変化 ──
	var target_bg : Color
	match mood:
		"dark":  target_bg = Color(0.03, 0.02, 0.04, 1.0)
		"cold":  target_bg = Color(0.04, 0.05, 0.08, 1.0)
		"warm":  target_bg = Color(0.06, 0.04, 0.03, 1.0)
		"fear":  target_bg = Color(0.06, 0.01, 0.01, 1.0)
		_:       target_bg = Color(0.03, 0.03, 0.03, 1.0)

	var tw_bg := create_tween()
	tw_bg.tween_property(_bg_color, "color", target_bg, 2.0)

	# ── mood別エフェクト ──
	_apply_mood_effects(mood)

	# ── 背景画像（あれば） ──
	if image_path != "":
		var tex := load(image_path) as Texture2D
		if tex:
			var tint_a : float = 0.7 if mood == "dark" else 0.8
			_bg_rect2.texture = tex
			_bg_rect2.modulate = Color(0.85, 0.8, 0.85, 0.0)
			_bg_rect2.scale = Vector2(1.0, 1.0)

			var tw_cross := create_tween().set_parallel(true)
			tw_cross.tween_property(_bg_rect, "modulate:a", 0.0, 2.5)
			tw_cross.tween_property(_bg_rect2, "modulate:a", tint_a, 3.0).set_trans(Tween.TRANS_SINE)
			await tw_cross.finished

			_bg_rect.texture = tex
			_bg_rect.modulate = _bg_rect2.modulate
			_bg_rect.scale = Vector2(1.0, 1.0)
			_bg_rect2.modulate.a = 0.0

			if _zoom_tween and _zoom_tween.is_valid():
				_zoom_tween.kill()
			_zoom_tween = create_tween()
			_zoom_tween.tween_property(_bg_rect, "scale", Vector2(1.06, 1.06), 25.0)

	# ── セクションタイトル ──
	if section_title != "":
		_section_lbl.text = "— %s —" % section_title
		_section_lbl.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3, 0.0))

		_divider.position.x = 640
		_divider.size.x = 0
		_divider.color.a = 0.0

		var tw_s := create_tween().set_parallel(true)
		tw_s.tween_property(_section_lbl, "theme_override_colors/font_color:a", 0.8, 1.5).set_trans(Tween.TRANS_SINE)
		tw_s.tween_property(_divider, "color:a", 0.5, 1.2)
		tw_s.tween_property(_divider, "size:x", 500.0, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw_s.tween_property(_divider, "position:x", 390.0, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await tw_s.finished

		await get_tree().create_timer(0.5).timeout
	else:
		_section_lbl.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3, 0.0))

	# ── 各行を表示 ──
	for line_idx in range(lines.size()):
		await _show_line(lines[line_idx], line_idx, lines.size())

	# ── セクション終了の余韻 ──
	await get_tree().create_timer(post_wait).timeout

	# ── フェードアウト ──
	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(_text_label, "modulate:a", 0.0, 1.2)
	tw_out.tween_property(_center_big, "theme_override_colors/font_color:a", 0.0, 1.2)
	tw_out.tween_property(_section_lbl, "theme_override_colors/font_color:a", 0.0, 1.0)
	tw_out.tween_property(_divider, "color:a", 0.0, 1.0)
	await tw_out.finished
	_text_label.text = ""
	_text_label.modulate.a = 1.0
	_center_big.text = ""

	# セクション間の暗転余韻
	await get_tree().create_timer(0.8).timeout


## ──────────────────────────────────────────────────────
## mood別エフェクト適用
## ──────────────────────────────────────────────────────
func _apply_mood_effects(mood: String) -> void:
	# 雨パーティクル（cold mood で生成）
	if mood == "cold" and _rain_drops.is_empty():
		for i in range(40):
			var r := ColorRect.new()
			r.size = Vector2(1, randf_range(8, 20))
			r.color = Color(0.5, 0.55, 0.7, 0.12)
			r.position = Vector2(randf_range(0, 1400), randf_range(-200, 720))
			r.rotation = -0.15
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			r.set_meta("speed", randf_range(250, 450))
			_container.add_child(r)
			# シネマバーの下に移動
			_container.move_child(r, _container.get_child_count() - 10)
			_rain_drops.append(r)
	elif mood != "cold":
		# 雨を消す
		for r in _rain_drops:
			if is_instance_valid(r):
				var tw := create_tween()
				tw.tween_property(r, "color:a", 0.0, 1.0)
				tw.tween_callback(r.queue_free)
		_rain_drops.clear()

	# 霧の色をmoodで変える
	var fog_color : Color
	match mood:
		"dark":  fog_color = Color(0.15, 0.08, 0.15, 0.0)
		"cold":  fog_color = Color(0.15, 0.18, 0.25, 0.0)
		"warm":  fog_color = Color(0.25, 0.18, 0.12, 0.0)
		"fear":  fog_color = Color(0.25, 0.05, 0.05, 0.0)
		_:       fog_color = Color(0.15, 0.15, 0.15, 0.0)
	for f in _fog_rects:
		if is_instance_valid(f):
			f.color = fog_color

	# ビネット色をmoodで変える
	if is_instance_valid(_vignette):
		var v_color : Color
		match mood:
			"dark":  v_color = Color(0, 0, 0, 0.65)
			"cold":  v_color = Color(0.0, 0.02, 0.08, 0.6)
			"warm":  v_color = Color(0.05, 0.02, 0.0, 0.5)
			"fear":  v_color = Color(0.1, 0.0, 0.0, 0.7)
			_:       v_color = Color(0, 0, 0, 0.55)
		var tw := create_tween()
		tw.tween_property(_vignette, "color", v_color, 1.5)

	# 心拍オーバーレイ色
	if is_instance_valid(_heartbeat_overlay):
		match mood:
			"fear": _heartbeat_overlay.color = Color(0.5, 0.0, 0.0, 0.0)
			"dark": _heartbeat_overlay.color = Color(0.3, 0.0, 0.05, 0.0)
			_:      _heartbeat_overlay.color = Color(0.0, 0.0, 0.0, 0.0)


## ──────────────────────────────────────────────────────
## 1行表示（超リッチ版）
## ──────────────────────────────────────────────────────
func _show_line(line, line_idx: int, total_lines: int) -> void:
	var text : String = ""
	var voice_path : String = ""
	var pause_after : float = 1.5
	var emphasis : bool = false

	var voice_dur : float = 0.0

	if line is Dictionary:
		text = line.get("text", "")
		voice_path = line.get("voice", "")
		pause_after = float(line.get("pause", 1.5))
		emphasis = line.get("emphasis", false)
		voice_dur = float(line.get("voice_dur", 0.0))
	else:
		text = str(line)

	# ── 前の音声を停止 ──
	if is_instance_valid(_current_audio) and _current_audio.playing:
		_current_audio.stop()
		_current_audio.queue_free()
		_current_audio = null

	# ── 音声再生 ──
	if voice_path != "":
		var voice_stream : AudioStream = load(voice_path)
		if voice_stream:
			if voice_dur < 0.1:
				voice_dur = voice_stream.get_length()
			var audio := AudioStreamPlayer.new()
			audio.stream = voice_stream
			audio.volume_db = -2.0
			add_child(audio)
			audio.play()
			_current_audio = audio
			audio.finished.connect(func() -> void:
				if _current_audio == audio:
					_current_audio = null
				audio.queue_free()
			)

	# ── emphasis: 画面中央に巨大テキスト + 特殊演出 ──
	if emphasis:
		await _show_emphasis_line(text, pause_after, voice_dur)
		return

	# ── 通常テキスト ──
	var fmt_text : String = "[center]%s[/center]" % text
	_text_label.text = fmt_text
	_text_label.modulate.a = 0.0
	_text_label.visible_ratio = 0.0

	# フェードイン（0.4秒で出す）
	var tw_fade := create_tween()
	tw_fade.tween_property(_text_label, "modulate:a", 1.0, 0.4)

	# タイプライター — 音声長ぴったりに合わせる
	var type_dur : float = voice_dur if voice_dur > 0.1 else float(text.length()) * 0.045
	var tw_type := create_tween()
	tw_type.tween_property(_text_label, "visible_ratio", 1.0, type_dur)

	# 音声が終わるまで待つ（テキストと音声の長い方）
	if is_instance_valid(_current_audio):
		await _current_audio.finished
	else:
		await tw_type.finished

	# 余韻（pause = voice_dur + margin なので、voice_dur分は既に経過）
	var remaining_pause : float = pause_after - voice_dur
	if remaining_pause > 0.1:
		await get_tree().create_timer(remaining_pause).timeout

	# フェードアウト
	var tw_out := create_tween()
	tw_out.tween_property(_text_label, "modulate:a", 0.0, 0.5)
	await tw_out.finished


## ──────────────────────────────────────────────────────
## emphasis行: 画面中央に巨大文字 + 震え + 色変化 + シェイク
## ──────────────────────────────────────────────────────
func _show_emphasis_line(text: String, pause_after: float, voice_dur: float = 0.0) -> void:
	# 通常テキストを消す
	_text_label.modulate.a = 0.0

	_center_big.text = ""
	_center_big.add_theme_color_override("font_color", Color(0.95, 0.7, 0.6, 0.0))
	_center_big.pivot_offset = Vector2(640, 360)
	_center_big.scale = Vector2(1.0, 1.0)

	# 1文字ずつ出現 — 音声があれば音声長に合わせる
	var char_count : int = text.length()
	var per_char : float
	if voice_dur > 0.1:
		per_char = (voice_dur * 0.85) / maxf(float(char_count), 1.0)
		per_char = clampf(per_char, 0.04, 0.2)
	else:
		per_char = 0.07
	var pause_char : float = per_char * 2.5  # 句読点は長め

	var revealed : String = ""
	for i in range(char_count):
		var ch : String = text[i]
		revealed += ch
		_center_big.text = revealed

		# 文字が出るたびに微震
		_shake_amount = 1.5

		# 徐々にフェードイン
		var alpha : float = clampf(float(i) / max(float(char_count) * 0.3, 1.0), 0.0, 1.0)
		_center_big.add_theme_color_override("font_color", Color(0.95, 0.7, 0.6, alpha))

		if ch == "\n" or ch == "。" or ch == "、":
			await get_tree().create_timer(pause_char).timeout
		else:
			await get_tree().create_timer(per_char).timeout

	# 全文字出た後の演出
	# 色が赤みを帯びながら完全表示
	var tw_glow := create_tween().set_parallel(true)
	tw_glow.tween_property(_center_big, "theme_override_colors/font_color",
		Color(1.0, 0.75, 0.65, 1.0), 0.8).set_trans(Tween.TRANS_SINE)
	# 微妙にスケールアップ
	tw_glow.tween_property(_center_big, "scale", Vector2(1.02, 1.02), 1.5).set_trans(Tween.TRANS_SINE)

	# 心拍フラッシュを強める
	if is_instance_valid(_heartbeat_overlay):
		var tw_hb := create_tween()
		tw_hb.tween_property(_heartbeat_overlay, "color:a", 0.1, 0.1)
		tw_hb.tween_property(_heartbeat_overlay, "color:a", 0.0, 0.3)

	# シェイク
	_shake_amount = 4.0

	# 音声が終わるまで待つ
	if is_instance_valid(_current_audio) and _current_audio.playing:
		await _current_audio.finished

	# 余韻（pause = voice_dur + margin なので、voice_dur分は経過済み）
	var remaining : float = pause_after - voice_dur
	if remaining > 0.1:
		await get_tree().create_timer(remaining).timeout

	# フェードアウト + 縮小
	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(_center_big, "theme_override_colors/font_color:a", 0.0, 1.0)
	tw_out.tween_property(_center_big, "scale", Vector2(0.98, 0.98), 1.0)
	await tw_out.finished
	_center_big.text = ""
	_center_big.scale = Vector2(1.0, 1.0)


## ──────────────────────────────────────────────────────
## グリッチ演出（セクション間に挿入可能）
## ──────────────────────────────────────────────────────
func _glitch_burst(intensity: float = 8.0, count: int = 3) -> void:
	for i in range(count):
		_shake_amount = intensity
		if is_instance_valid(_grain_overlay):
			_grain_overlay.color.a = 0.15
		if is_instance_valid(_heartbeat_overlay):
			_heartbeat_overlay.color.a = 0.15
		await get_tree().create_timer(0.05).timeout
		if is_instance_valid(_grain_overlay):
			_grain_overlay.color.a = 0.02
		if is_instance_valid(_heartbeat_overlay):
			_heartbeat_overlay.color.a = 0.0
		await get_tree().create_timer(0.08).timeout


## バッドエンドタイトル演出
func _show_ending_title(title: String) -> void:
	var vp_size := Vector2(1280, 720)

	# 画面を暗転
	var tw_dark := create_tween().set_parallel(true)
	tw_dark.tween_property(_text_label, "modulate:a", 0.0, 1.0)
	tw_dark.tween_property(_center_big, "theme_override_colors/font_color:a", 0.0, 1.0)
	tw_dark.tween_property(_section_lbl, "theme_override_colors/font_color:a", 0.0, 1.0)
	tw_dark.tween_property(_bg_rect, "modulate:a", 0.0, 2.0)
	tw_dark.tween_property(_bg_color, "color", Color(0, 0, 0, 1), 2.0)
	await tw_dark.finished

	await get_tree().create_timer(1.5).timeout

	# BAD END ラベル（小さめ、上）
	var bad_lbl := Label.new()
	bad_lbl.text = "BAD END"
	bad_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bad_lbl.size = Vector2(vp_size.x, 40)
	bad_lbl.position = Vector2(0, vp_size.y * 0.38)
	bad_lbl.add_theme_font_size_override("font_size", 16)
	bad_lbl.add_theme_color_override("font_color", Color(0.6, 0.15, 0.15, 0.0))
	bad_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	bad_lbl.add_theme_constant_override("shadow_offset_x", 1)
	bad_lbl.add_theme_constant_override("shadow_offset_y", 1)
	bad_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(bad_lbl)

	# タイトルラベル（大きく、中央）
	var title_lbl := Label.new()
	title_lbl.text = "「%s」" % title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.size = Vector2(vp_size.x, 60)
	title_lbl.position = Vector2(0, vp_size.y * 0.45)
	title_lbl.add_theme_font_size_override("font_size", 40)
	title_lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.7, 0.0))
	title_lbl.add_theme_color_override("font_shadow_color", Color(0.3, 0.0, 0.0, 0.8))
	title_lbl.add_theme_constant_override("shadow_offset_x", 2)
	title_lbl.add_theme_constant_override("shadow_offset_y", 2)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(title_lbl)

	# 区切り線
	var line_rect := ColorRect.new()
	line_rect.color = Color(0.5, 0.1, 0.1, 0.0)
	line_rect.size = Vector2(0, 1)
	line_rect.position = Vector2(vp_size.x * 0.5, vp_size.y * 0.43)
	line_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(line_rect)

	# フェードイン
	var tw_in := create_tween().set_parallel(true)
	tw_in.tween_property(bad_lbl, "theme_override_colors/font_color:a", 0.8, 1.5).set_trans(Tween.TRANS_SINE)
	tw_in.tween_property(title_lbl, "theme_override_colors/font_color:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_delay(0.5)
	tw_in.tween_property(line_rect, "color:a", 0.4, 1.5)
	tw_in.tween_property(line_rect, "size:x", 300.0, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(line_rect, "position:x", vp_size.x * 0.5 - 150.0, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw_in.finished

	# しばらく表示
	await get_tree().create_timer(4.0).timeout


## フェードアウトして終了
func fade_out(dur: float = 2.0) -> void:
	_is_playing = false
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
	var tw := create_tween()
	tw.tween_property(_container, "modulate:a", 0.0, dur).set_trans(Tween.TRANS_SINE)
	await tw.finished
	queue_free()
