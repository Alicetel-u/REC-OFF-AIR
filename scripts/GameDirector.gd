extends Node

## ホラーゲーム「REC:OFF-ARE —霧原村の惨劇—」
## YouTubeChrome UI を使ったビジュアルノベル形式メインディレクター

# ── レイアウト定数（1280×720）──────────────────────────────────
const VW        = 1280
const VH        = 720
const TOP_H     = 56
const VIDEO_W   = 960
const VIDEO_BOT = 624   # VH - CTRL_H(32) - ENGAGE_H(64)
const NARR_H    = 200
const NARR_Y    = VIDEO_BOT - NARR_H  # 424

const TACHIE_W  = 480
const TACHIE_H  = 560
const TACHIE_X  = 40
const TACHIE_Y  = VIDEO_BOT - TACHIE_H  # 64

const BG_IMAGE_PATH = "res://assets/textures/_8542c43a02.png"

# ── ノード参照 ────────────────────────────────────────────────────
var _chrome     : YouTubeChrome

var _bg_c       : CanvasLayer
var _bg_img     : TextureRect
var _bg_rect    : ColorRect

var _hud_c      : CanvasLayer
var _rec_lbl    : Label
var _bat_lbl    : Label
var _loc_lbl    : Label

var _narr_c     : CanvasLayer
var _narr_panel : Panel
var _spk_lbl    : Label
var _narr_txt   : RichTextLabel
var _adv_lbl    : Label

var _choice_c   : CanvasLayer
var _choice_vb  : VBoxContainer

var _fx_c       : CanvasLayer
var _glitch     : ColorRect
var _fade       : ColorRect

var _meta_c     : CanvasLayer
var _meta_lbl   : RichTextLabel

var _tachie_c    : CanvasLayer
var _tachie_rect : TextureRect
var _tachie_cur  : String = ""
var _tachie_tw   : Tween  = null

# ── ゲーム状態 ────────────────────────────────────────────────────
var _beats      : Dictionary = {}
var _cur        : String     = "prologue_01"
var _battery    : float      = 0.95
var _waiting    : bool       = false
var _tw_active  : bool       = false
var _tw_full    : String     = ""
var _tw_pos     : int        = 0
var _blink_tw   : Tween      = null
var _meta_active: bool       = false
var _beat_seq   : int        = 0


# ════════════════════════════════════════════════════════════════
# 初期化
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_ui()
	_load_story()
	await get_tree().process_frame
	_play(_cur)


func _process(delta: float) -> void:
	# バッテリーの微細ドレイン（演出・リアリティ用）
	if _battery > 0.0 and not _meta_active:
		_battery = max(0.0, _battery - delta * 0.0003)
		_update_battery()


# ════════════════════════════════════════════════════════════════
# UI 構築
# ════════════════════════════════════════════════════════════════

func _build_ui() -> void:

	# ── Layer 1: 背景 ─────────────────────────────────────────
	_bg_c = CanvasLayer.new()
	_bg_c.layer = 1
	add_child(_bg_c)

	# 背景画像
	_bg_img = TextureRect.new()
	_bg_img.position = Vector2.ZERO
	_bg_img.size = Vector2(VW, VH)
	_bg_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(BG_IMAGE_PATH):
		_bg_img.texture = load(BG_IMAGE_PATH) as Texture2D
	else:
		var raw := Image.load_from_file(ProjectSettings.globalize_path(BG_IMAGE_PATH))
		if raw:
			_bg_img.texture = ImageTexture.create_from_image(raw)
	_bg_c.add_child(_bg_img)

	# 雰囲気用の暗色オーバーレイ
	_bg_rect = ColorRect.new()
	_bg_rect.position = Vector2.ZERO
	_bg_rect.size = Vector2(VW, VH)
	_bg_rect.color = Color(0.05, 0.05, 0.08, 0.45)
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_c.add_child(_bg_rect)

	# ── Layer 20: YouTubeChrome ──────────────────────────────
	_chrome = YouTubeChrome.new()
	add_child(_chrome)

	# ── Layer 22: 録画 HUD ───────────────────────────────────
	_hud_c = CanvasLayer.new()
	_hud_c.layer = 22
	add_child(_hud_c)

	_rec_lbl = Label.new()
	_rec_lbl.position = Vector2(12, TOP_H + 8)
	_rec_lbl.text = "● REC"
	_rec_lbl.add_theme_font_size_override("font_size", 13)
	_rec_lbl.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
	_hud_c.add_child(_rec_lbl)
	_blink_rec()

	_bat_lbl = Label.new()
	_bat_lbl.position = Vector2(VIDEO_W - 165, TOP_H + 8)
	_bat_lbl.add_theme_font_size_override("font_size", 13)
	_hud_c.add_child(_bat_lbl)
	_update_battery()

	_loc_lbl = Label.new()
	_loc_lbl.position = Vector2(12, TOP_H + 26)
	_loc_lbl.add_theme_font_size_override("font_size", 12)
	_loc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75, 0.9))
	_hud_c.add_child(_loc_lbl)

	# ── Layer 24: 立ち絵 ─────────────────────────────────────
	_tachie_c = CanvasLayer.new()
	_tachie_c.layer = 24
	add_child(_tachie_c)

	_tachie_rect = TextureRect.new()
	_tachie_rect.position = Vector2(TACHIE_X, TACHIE_Y)
	_tachie_rect.size = Vector2(TACHIE_W, TACHIE_H)
	_tachie_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tachie_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tachie_rect.modulate.a = 0.0
	_tachie_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tachie_c.add_child(_tachie_rect)

	# ── Layer 25: 語り欄 ─────────────────────────────────────
	_narr_c = CanvasLayer.new()
	_narr_c.layer = 25
	add_child(_narr_c)

	_narr_panel = Panel.new()
	_narr_panel.position = Vector2(0, NARR_Y)
	_narr_panel.size = Vector2(VIDEO_W, NARR_H)
	_narr_panel.visible = false
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.0, 0.0, 0.0, 0.86)
	ps.border_color = Color(0.22, 0.22, 0.32, 0.8)
	ps.border_width_top = 1
	_narr_panel.add_theme_stylebox_override("panel", ps)
	_narr_c.add_child(_narr_panel)

	_spk_lbl = Label.new()
	_spk_lbl.position = Vector2(14, 8)
	_spk_lbl.add_theme_font_size_override("font_size", 14)
	_spk_lbl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.45))
	_narr_panel.add_child(_spk_lbl)

	_narr_txt = RichTextLabel.new()
	_narr_txt.position = Vector2(14, 34)
	_narr_txt.size = Vector2(VIDEO_W - 28, NARR_H - 52)
	_narr_txt.bbcode_enabled = false
	_narr_txt.scroll_active = false
	_narr_txt.fit_content = false
	_narr_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_narr_txt.add_theme_color_override("default_color", Color(0.94, 0.92, 0.88))
	_narr_txt.add_theme_font_size_override("normal_font_size", 17)
	_narr_panel.add_child(_narr_txt)

	_adv_lbl = Label.new()
	_adv_lbl.position = Vector2(VIDEO_W - 172, NARR_H - 24)
	_adv_lbl.text = "▼ クリックで続ける"
	_adv_lbl.add_theme_font_size_override("font_size", 12)
	_adv_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.65, 0.85))
	_adv_lbl.visible = false
	_narr_panel.add_child(_adv_lbl)

	# ── Layer 27: 選択肢 ─────────────────────────────────────
	_choice_c = CanvasLayer.new()
	_choice_c.layer = 27
	add_child(_choice_c)

	_choice_vb = VBoxContainer.new()
	_choice_vb.position = Vector2((VIDEO_W - 430) / 2, 280)
	_choice_vb.custom_minimum_size = Vector2(430, 0)
	_choice_vb.add_theme_constant_override("separation", 14)
	_choice_vb.visible = false
	_choice_c.add_child(_choice_vb)

	# ── Layer 30: エフェクト ─────────────────────────────────
	_fx_c = CanvasLayer.new()
	_fx_c.layer = 30
	add_child(_fx_c)

	_glitch = ColorRect.new()
	_glitch.position = Vector2.ZERO
	_glitch.size = Vector2(VW, VH)
	_glitch.color = Color(1, 0, 0, 0)
	_glitch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_c.add_child(_glitch)

	_fade = ColorRect.new()
	_fade.position = Vector2.ZERO
	_fade.size = Vector2(VW, VH)
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_c.add_child(_fade)

	# ── Layer 40: メタエンディング ───────────────────────────
	_meta_c = CanvasLayer.new()
	_meta_c.layer = 40
	add_child(_meta_c)

	_meta_lbl = RichTextLabel.new()
	_meta_lbl.position = Vector2.ZERO
	_meta_lbl.size = Vector2(VW, VH)
	_meta_lbl.bbcode_enabled = true
	_meta_lbl.scroll_active = false
	_meta_lbl.fit_content = false
	_meta_lbl.add_theme_color_override("default_color", Color.WHITE)
	_meta_lbl.add_theme_font_size_override("normal_font_size", 28)
	_meta_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meta_lbl.visible = false
	_meta_c.add_child(_meta_lbl)


# ════════════════════════════════════════════════════════════════
# ストーリー読み込み
# ════════════════════════════════════════════════════════════════

func _load_story() -> void:
	var f := FileAccess.open("res://scenarios/horror_scenario.json", FileAccess.READ)
	if not f:
		push_error("horror_scenario.json が見つかりません")
		return
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	for beat: Dictionary in data.get("beats", []):
		_beats[beat["id"]] = beat


# ════════════════════════════════════════════════════════════════
# ビート再生
# ════════════════════════════════════════════════════════════════

func _play(beat_id: String) -> void:
	_cur = beat_id
	_beat_seq += 1
	var seq := _beat_seq

	var b: Dictionary = _beats.get(beat_id, {})
	if b.is_empty():
		push_error("ビート不明: " + beat_id)
		return

	_waiting = false
	_hide_choices()

	# 背景色
	var bg_str: String = b.get("background", "#0a0a0a")
	var bg_color := Color(bg_str)
	bg_color.a = 0.45
	_bg_rect.color = bg_color

	# 場所ラベル
	var loc: String = b.get("location", "")
	_loc_lbl.text = loc
	_loc_lbl.visible = not loc.is_empty()

	# 立ち絵
	if b.has("tachie"):
		_update_tachie(b.get("tachie", ""))

	# 即時エフェクト
	_apply_effects(b.get("effects", {}))

	# 語り
	_show_narration(b.get("narration", ""), b.get("speaker", ""))

	# チャット（beat_seq でキャンセル可能）
	_schedule_chats(b.get("chat_events", []), seq)

	# 進行設定
	var adv_type: String = b.get("advance_type", "click")

	if adv_type == "timed":
		var delay: float = float(b.get("advance_delay", 3.0))
		var nxt: String  = b.get("advance_next", "")
		var cb_timed := func():
			if _beat_seq == seq and not nxt.is_empty():
				_play(nxt)
		get_tree().create_timer(delay).timeout.connect(cb_timed, CONNECT_ONE_SHOT)
	# choices / click → タイプライター完了後に _on_narr_done() で処理


# ════════════════════════════════════════════════════════════════
# 語り・タイプライター
# ════════════════════════════════════════════════════════════════

func _show_narration(text: String, speaker: String) -> void:
	_narr_panel.visible = not text.is_empty()
	if text.is_empty():
		return
	_spk_lbl.text = speaker
	_spk_lbl.visible = not speaker.is_empty()
	_adv_lbl.visible = false
	_narr_txt.text = ""
	_tw_full   = text
	_tw_pos    = 0
	_tw_active = true
	_tw_step()


func _tw_step() -> void:
	if not _tw_active:
		return
	if _tw_pos >= _tw_full.length():
		_tw_active = false
		_on_narr_done()
		return
	_tw_pos += 1
	_narr_txt.text = _tw_full.substr(0, _tw_pos)
	var ch := _tw_full[_tw_pos - 1]
	var wait := 0.04 if ch not in ["。", "、", "…", "！", "？", "\n"] else 0.14
	get_tree().create_timer(wait).timeout.connect(_tw_step, CONNECT_ONE_SHOT)


func _tw_skip() -> void:
	if not _tw_active:
		return
	_tw_active = false
	_narr_txt.text = _tw_full
	_on_narr_done()


func _on_narr_done() -> void:
	var b: Dictionary = _beats.get(_cur, {})
	var choices: Array = b.get("choices", [])
	if choices.size() > 0:
		_show_choices(choices)
		return
	if b.get("advance_type", "click") == "click":
		_waiting = true
		_adv_lbl.visible = true
		_blink_adv()


func _blink_adv() -> void:
	if not _waiting:
		return
	if _blink_tw and _blink_tw.is_valid():
		_blink_tw.kill()
	_blink_tw = create_tween()
	_blink_tw.tween_property(_adv_lbl, "modulate:a", 0.2, 0.5)
	_blink_tw.tween_property(_adv_lbl, "modulate:a", 1.0, 0.5)
	_blink_tw.finished.connect(_blink_adv, CONNECT_ONE_SHOT)


# ════════════════════════════════════════════════════════════════
# 入力処理
# ════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if _meta_active:
		return
	if not (event is InputEventMouseButton and event.pressed):
		return
	if _tw_active:
		_tw_skip()
		get_viewport().set_input_as_handled()
	elif _waiting:
		_waiting = false
		_adv_lbl.visible = false
		if _blink_tw and _blink_tw.is_valid():
			_blink_tw.kill()
		var b: Dictionary = _beats.get(_cur, {})
		var nxt: String   = b.get("advance_next", "")
		if not nxt.is_empty():
			_play(nxt)
		get_viewport().set_input_as_handled()


# ════════════════════════════════════════════════════════════════
# チャットスケジューリング
# ════════════════════════════════════════════════════════════════

func _schedule_chats(events: Array, seq: int) -> void:
	for ce: Dictionary in events:
		var delay: float  = float(ce.get("delay", 1.0))
		var msg: String   = ce.get("msg", "")
		var user: String  = ce.get("user", "視聴者")
		var utype: String = ce.get("type", "viewer")
		var cb := func():
			if _beat_seq == seq:
				_send_chat(msg, user, utype)
		get_tree().create_timer(delay).timeout.connect(cb, CONNECT_ONE_SHOT)


func _send_chat(msg: String, user: String, utype: String) -> void:
	if not is_instance_valid(_chrome):
		return
	if utype == "superchat":
		# "メッセージ ¥金額" 形式をパース
		var parts := msg.rsplit("¥", true, 1)
		var sc_msg := parts[0].strip_edges() if parts.size() > 0 else msg
		var sc_amt := int(parts[1].strip_edges()) if parts.size() > 1 else 500
		_chrome.spawn_story_superchat(user, sc_msg, sc_amt)
	else:
		_chrome.add_message(msg, user, utype)


# ════════════════════════════════════════════════════════════════
# 選択肢
# ════════════════════════════════════════════════════════════════

func _show_choices(choices: Array) -> void:
	for c in _choice_vb.get_children():
		c.queue_free()
	for ch_data: Dictionary in choices:
		var btn := Button.new()
		btn.text = ch_data.get("text", "")
		btn.custom_minimum_size = Vector2(430, 54)
		btn.size_flags_horizontal = Control.SIZE_FILL
		_style_btn(btn)
		var nxt: String = ch_data.get("next", "")
		btn.pressed.connect(_on_choice.bind(nxt), CONNECT_ONE_SHOT)
		_choice_vb.add_child(btn)
	_choice_vb.visible = true


func _style_btn(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.07, 0.07, 0.17, 0.93)
	s.border_color = Color(0.32, 0.32, 0.62)
	s.set_border_width_all(1)
	s.set_corner_radius_all(5)
	s.set_content_margin_all(10.0)
	btn.add_theme_stylebox_override("normal", s)

	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color = Color(0.15, 0.15, 0.33, 0.96)
	btn.add_theme_stylebox_override("hover", sh)

	var sf := s.duplicate() as StyleBoxFlat
	sf.bg_color = Color(0.22, 0.22, 0.44, 1.0)
	btn.add_theme_stylebox_override("pressed", sf)

	btn.add_theme_color_override("font_color", Color(0.92, 0.90, 1.0))
	btn.add_theme_font_size_override("font_size", 18)


func _hide_choices() -> void:
	_choice_vb.visible = false
	for c in _choice_vb.get_children():
		c.queue_free()


func _on_choice(next_beat: String) -> void:
	_hide_choices()
	_play(next_beat)


# ════════════════════════════════════════════════════════════════
# エフェクト
# ════════════════════════════════════════════════════════════════

func _apply_effects(fx: Dictionary) -> void:
	if fx.is_empty():
		return

	if fx.has("battery_set"):
		_battery = float(fx["battery_set"])
		_update_battery()

	if fx.has("flash"):
		_do_flash(Color(fx["flash"] as String))

	if fx.has("glitch_count"):
		_do_glitch(int(fx["glitch_count"]))

	if fx.has("meta_end"):
		var ending: String = str(fx["meta_end"])
		_trigger_meta.call_deferred(ending)


func _do_flash(color: Color) -> void:
	color.a = 0.0
	_glitch.color = color
	var tw := create_tween()
	tw.tween_property(_glitch, "color:a", 0.55, 0.04)
	tw.tween_property(_glitch, "color:a", 0.0,  0.22)


func _do_glitch(count: int) -> void:
	for i in count:
		var cb := func():
			_do_flash(Color(1.0, randf() * 0.2, randf() * 0.1, 0.0))
		get_tree().create_timer(i * 0.20 + randf() * 0.08).timeout.connect(cb, CONNECT_ONE_SHOT)


# ════════════════════════════════════════════════════════════════
# バッテリー表示
# ════════════════════════════════════════════════════════════════

func _update_battery() -> void:
	if not is_instance_valid(_bat_lbl):
		return
	var pct  := int(_battery * 100)
	var bars := clampi(int(_battery * 5), 0, 5)
	var bar  := "["
	for i in 5:
		bar += "I" if i < bars else "."
	bar += "] %d%%" % pct
	_bat_lbl.text = "BAT " + bar

	var col: Color
	if _battery > 0.5:     col = Color(0.2,  1.0,  0.2)
	elif _battery > 0.25:  col = Color(1.0,  0.82, 0.0)
	elif _battery > 0.0:   col = Color(1.0,  0.35, 0.0)
	else:                  col = Color(0.55, 0.1,  0.1)
	_bat_lbl.add_theme_color_override("font_color", col)

	if _battery <= 0.0:
		var tw := create_tween()
		tw.tween_property(_bat_lbl, "modulate:a", 0.0, 1.8)


# ════════════════════════════════════════════════════════════════
# REC 点滅
# ════════════════════════════════════════════════════════════════

func _blink_rec() -> void:
	var tw := create_tween()
	tw.tween_property(_rec_lbl, "modulate:a", 0.1, 0.45)
	tw.tween_property(_rec_lbl, "modulate:a", 1.0, 0.45)
	tw.set_loops()


# ════════════════════════════════════════════════════════════════
# 立ち絵
# ════════════════════════════════════════════════════════════════

func _update_tachie(path: String) -> void:
	if _tachie_tw != null and _tachie_tw.is_valid():
		_tachie_tw.kill()
	if path == _tachie_cur:
		return
	_tachie_cur = path
	if path.is_empty():
		_tachie_tw = create_tween()
		_tachie_tw.tween_property(_tachie_rect, "modulate:a", 0.0, 0.35)
	elif _tachie_rect.modulate.a < 0.05:
		_load_tachie_texture(path)
		_tachie_tw = create_tween()
		_tachie_tw.tween_property(_tachie_rect, "modulate:a", 1.0, 0.45)
	else:
		_tachie_tw = create_tween()
		_tachie_tw.tween_property(_tachie_rect, "modulate:a", 0.0, 0.25)
		_tachie_tw.tween_callback(func(): _load_tachie_texture(path))
		_tachie_tw.tween_property(_tachie_rect, "modulate:a", 1.0, 0.45)


func _load_tachie_texture(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("立ち絵が見つかりません: " + path)
		_tachie_rect.texture = null
		return
	var tex: Texture2D = load(path)
	# バストアップ: 上部45%を切り出して表示
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(0, 0, tex.get_width(), tex.get_height() * 0.45)
	_tachie_rect.texture = atlas


# ════════════════════════════════════════════════════════════════
# メタエンディング
# ════════════════════════════════════════════════════════════════

func _trigger_meta(ending: String) -> void:
	_meta_active = true
	_waiting     = false
	_tw_active   = false
	_update_tachie("")

	# 全 UI を黒くフェードアウト
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 2.5)
	await tw.finished

	_narr_panel.visible = false
	_loc_lbl.visible    = false
	_meta_lbl.visible   = true

	if ending == "bad":
		await _play_bad_end()
	elif ending == "true":
		await _play_true_end()


func _play_bad_end() -> void:
	await get_tree().create_timer(1.5).timeout

	var content := "[center]\n\n\n\n"
	content += "配信終了\n"
	content += "[color=#555555]視聴者数：1,247人[/color]\n\n\n\n"
	content += "[color=#222222]——[/color]\n"
	content += "[/center]"
	_meta_lbl.bbcode_text = content

	await get_tree().create_timer(5.0).timeout

	var tw := create_tween()
	tw.tween_property(_meta_lbl, "modulate:a", 0.0, 3.0)


func _play_true_end() -> void:
	await get_tree().create_timer(1.0).timeout

	# タイプライターで最後のメッセージを表示
	var final_msg := "次は今これを見てる\n　『君』の番だよ。"
	_meta_lbl.bbcode_text = "[center]\n\n\n\n[/center]"

	await get_tree().create_timer(0.8).timeout

	for i in final_msg.length():
		var partial := final_msg.substr(0, i + 1)
		_meta_lbl.bbcode_text = "[center]\n\n\n\n" + partial + "[/center]"
		var ch := final_msg[i]
		var wait := 0.09 if ch not in ["。", "、", "…", "！", "？", "\n"] else 0.35
		await get_tree().create_timer(wait).timeout

	await get_tree().create_timer(2.5).timeout

	# ウェブカメラ（Web ビルドのみ）
	_try_webcam()

	await get_tree().create_timer(1.5).timeout

	# 「…あなたが映ってる」を徐々に浮かび上がらせる
	var base := "[center]\n\n\n\n" + final_msg + "\n\n"
	_meta_lbl.bbcode_text = base + "[color=#111111]…あなたが映ってる[/color][/center]"

	await get_tree().create_timer(1.5).timeout
	_meta_lbl.bbcode_text = base + "[color=#3a3a3a]…あなたが映ってる[/color][/center]"

	await get_tree().create_timer(1.5).timeout
	_meta_lbl.bbcode_text = base + "[color=#777777]…あなたが映ってる[/color][/center]"

	await get_tree().create_timer(3.0).timeout
	var tw := create_tween()
	tw.tween_property(_meta_lbl, "modulate:a", 0.0, 3.5)


func _try_webcam() -> void:
	if not OS.has_feature("web"):
		return
	var js := """
(function(){
  if(!navigator.mediaDevices||!navigator.mediaDevices.getUserMedia) return;
  navigator.mediaDevices.getUserMedia({video:{facingMode:'user'}})
  .then(function(s){
    var v=document.createElement('video');
    v.srcObject=s; v.autoplay=true; v.muted=true;
    v.style.cssText='position:fixed;top:0;left:0;width:100vw;height:100vh;object-fit:cover;opacity:0;z-index:8888;transform:scaleX(-1);filter:grayscale(1) contrast(1.1) brightness(0.3)';
    document.body.appendChild(v);
    v.style.transition='opacity 4s';
    setTimeout(function(){v.style.opacity='0.35'},200);
  }).catch(function(){});
})();
"""
	JavaScriptBridge.eval(js)
