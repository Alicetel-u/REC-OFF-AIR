extends Control
class_name HUD

@onready var scare_flash   : ColorRect = $ScareFlash

# ── 動的生成HUD要素 ──
var rec_label      : Label = null
var timecode_label : Label = null
var battery_label  : Label = null
var item_label     : Label = null
var _rec_dot       : Label = null
var _rec_bg        : PanelContainer = null
var _date_label    : Label = null
var _cam_label     : Label = null

# 映像エリア定数 (YouTubeChrome準拠)
const VIDEO_LEFT   := 14
const VIDEO_TOP    := 56
const VIDEO_RIGHT  := 886  # 900 - 14
const VIDEO_BOTTOM := 600  # 612 - 12

var record_time : float = 0.0
var rec_blink_t : float = 0.0
var _last_tc_frame : int = -1
var rec_show    : bool  = true
var scare_t     : float = 0.0
var idle_chat_t : float = 0.0
var _chat_next  : float = 0.0

var _chrome: CanvasLayer = null
var danmaku_func: Callable = Callable()

# ── デバッグパネル ──
var _dbg_click_count : int   = 0
var _dbg_click_timer : float = 0.0
var _dbg_panel       : PanelContainer = null

var _mono_panel  : PanelContainer = null
var _mono_text   : RichTextLabel  = null
var _exit_guide  : Control        = null
var _exit_blink_t: float          = 0.0

# ── ビデオカメラオーバーレイ ──
# ── 画面全体ホラーレッド ──
var _horror_red_rect  : ColorRect      = null
var _horror_red_tween : Tween          = null
var _horror_red_active: bool           = false

# ── ビデオカメラオーバーレイ ──
var _camcorder_overlay : Control       = null
var _tracking_line     : ColorRect     = null
var _tracking_t        : float         = 0.0
var _tracking_next     : float         = 8.0   # 次のトラッキングノイズまでの時間
var _tracking_active   : bool          = false
var _tracking_y        : float         = 0.0
var _focus_brackets    : Array[ColorRect] = []

# ── 出口方向矢印 ──
var _exit_arrow     : Control    = null
var _exit_arrow_lbl : Label      = null
var _exit_dist_lbl  : Label      = null
var _player_ref     : Node3D     = null
var _exit_position  : Vector3    = Vector3.ZERO
var _exit_arrow_active : bool    = false

# ── ナビ矢印（イベントナビ） ──
var _nav_arrow       : Control    = null
var _nav_arrow_lbl   : Label      = null
var _nav_title_lbl   : Label      = null
var _nav_dist_lbl    : Label      = null
var _nav_target      : Vector3    = Vector3.ZERO
var _nav_radius      : float      = 3.0
var _nav_active      : bool       = false
signal nav_reached

# ユーザーとコメントのデータ
const CHAT_LINES: Array[String] = [
	"wwwww", "こわすぎｗｗｗ", "うわあああ", "まじかよ",
	"草", "きた！！", "ガチホラーすぎる", "懐中電灯つけて！",
	"後ろ後ろ！！", "震えてるｗ", "LOL", "何か見えた気が...",
	"絶対やばいって", "音した？", "行くな行くな", "ガクブル",
	"お前それ本物だぞ", "ヤバすぎ", "逃げて！！", "ガチ勢かよ",
]
const USERS: Array[String] = [
	"視聴者A", "ホラー好き太郎", "夜更かし中", "ゆきんこ77",
	"幽霊ガチ勢", "名無しさん", "深夜組", "ゴーストハンター",
	"恐怖体験済み", "配信民99", "ガクブル太郎", "おばけ見たい",
]
# モデレーターとメンバーは固定
const MODERATORS: Array[String] = ["ゆきんこ77", "ホラー好き太郎"]
const MEMBERS   : Array[String] = ["幽霊ガチ勢", "配信民99", "ゴーストハンター"]


func _ready() -> void:
	_chat_next = randf_range(6.0, 14.0)
	scare_flash.modulate.a = 0.0
	GameManager.item_collected.connect(_on_item_collected)
	GameManager.player_caught.connect(_on_caught)
	GameManager.player_won.connect(_on_won)
	_build_rec_hud()
	_update_item_label(0)
	_build_monologue_window()
	_build_camcorder_overlay()
	_build_horror_red()


func set_chrome(chrome: CanvasLayer) -> void:
	_chrome = chrome
	# 最初のウェルカムチャット
	_add_chat("配信始まったー！", "視聴者A")
	_add_chat("きたきた！よろ〜", "ゆきんこ77")
	_add_chat("今日も来たよ！", "幽霊ガチ勢")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var vp_size := get_viewport().get_visible_rect().size
		# 左下 120x120 の範囲
		if event.position.x < 120 and event.position.y > vp_size.y - 120:
			_dbg_click_count += 1
			_dbg_click_timer = 1.0  # 1秒以内に3回
			if _dbg_click_count >= 3:
				_dbg_click_count = 0
				_toggle_debug_panel()


func _toggle_debug_panel() -> void:
	if is_instance_valid(_dbg_panel):
		_dbg_panel.visible = not _dbg_panel.visible
		return
	_build_debug_panel()


func _build_debug_panel() -> void:
	_dbg_panel = PanelContainer.new()
	_dbg_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_dbg_panel.position = Vector2(10, -260)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.85)
	style.border_color = Color(0.0, 1.0, 0.0, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	_dbg_panel.add_theme_stylebox_override("panel", style)
	add_child(_dbg_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_dbg_panel.add_child(vbox)

	var title := Label.new()
	title.text = "DEBUG"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	vbox.add_child(title)

	pass  # 倍速ボタンは YouTubeChrome の ⏭ ボタンに移動


func _process(delta: float) -> void:
	# デバッグクリックのタイムアウト
	if _dbg_click_timer > 0.0:
		_dbg_click_timer -= delta
		if _dbg_click_timer <= 0.0:
			_dbg_click_count = 0

	record_time += delta

	# ── REC 点滅（状態変化時のみUI更新） ──
	rec_blink_t += delta
	if rec_blink_t >= 0.6:
		rec_blink_t = 0.0
		rec_show = not rec_show
		if is_instance_valid(_rec_dot):
			_rec_dot.modulate.a = 1.0 if rec_show else 0.15
		if is_instance_valid(rec_label):
			rec_label.modulate.a = 1.0 if rec_show else 0.7

	# ── タイムコード（フレーム番号が変わった時のみ更新） ──
	var cur_frame := int(record_time * 30)
	if cur_frame != _last_tc_frame and is_instance_valid(timecode_label):
		_last_tc_frame = cur_frame
		var h := int(record_time / 3600.0)
		var m := int(fmod(record_time, 3600.0) / 60.0)
		var s := int(fmod(record_time, 60.0))
		var f : int = cur_frame % 30
		timecode_label.text = "%02d:%02d:%02d.%02d" % [h, m, s, f]

	# ── 放置中のランダムコメント ──
	idle_chat_t += delta
	if idle_chat_t >= _chat_next:
		idle_chat_t = 0.0
		_chat_next = randf_range(6.0, 14.0)
		_add_chat(CHAT_LINES[randi() % CHAT_LINES.size()])

	# ── スケアフラッシュのフェードアウト ──
	if scare_t > 0.0:
		scare_t -= delta * 1.8
		scare_flash.modulate.a = clamp(scare_t, 0.0, 0.65)

	# ── 出口ガイド点滅 ──
	if is_instance_valid(_exit_guide) and _exit_guide.visible:
		_exit_blink_t += delta * 2.2
		_exit_guide.modulate.a = 0.6 + sin(_exit_blink_t) * 0.4

	# ── 出口方向矢印の回転更新 ──
	if _exit_arrow_active and is_instance_valid(_exit_arrow) and is_instance_valid(_player_ref):
		_update_exit_arrow()

	# ── ナビ矢印の更新 ──
	if _nav_active and is_instance_valid(_nav_arrow) and is_instance_valid(_player_ref):
		_update_nav_arrow()

	# ── トラッキングノイズ（ビデオカメラ） ──
	_update_tracking_noise(delta)


func update_battery(level: float) -> void:
	if not is_instance_valid(battery_label):
		return
	var filled := int(level * 5)
	var empty  := 5 - filled
	battery_label.text = "⚡ " + "▮".repeat(filled) + "▯".repeat(empty)
	if level < 0.25:
		battery_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	elif level < 0.5:
		battery_label.add_theme_color_override("font_color", Color(1, 0.75, 0.1))
	else:
		battery_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))


func trigger_chat_event(event: String) -> void:
	match event:
		"moved":
			if randf() > 0.55:
				_add_chat(CHAT_LINES[randi() % CHAT_LINES.size()])
		"flashlight_on":
			_add_chat("懐中電灯きたー！")
			_add_chat("明るくなったｗ")
		"flashlight_off":
			_add_chat("消したｗｗｗこわ")
		"ghost_spotted":
			_add_chat("うわああああ！！！！")
			_add_chat("逃げてーーー！！！", "ゆきんこ77")
			_add_chat("wwwwwwww配信事故", "配信民99")
			_do_scare_flash(Color(1, 1, 1))
		"ghost_lost":
			_add_chat("なんか逃げた？")
			_add_chat("セーフだったの？？", "視聴者A")


func _on_item_collected(count: int, total: int) -> void:
	_update_item_label(count)
	_add_chat("VHSテープ拾った！ (%d/%d)" % [count, total])
	if count >= total:
		_add_chat("全部集まったー！！出口へ！！", "ホラー好き太郎")
		_add_chat("EXIT探して！！！", "視聴者A")
		_show_exit_guide()


func _on_caught() -> void:
	_do_scare_flash(Color(0.9, 0.0, 0.0))
	_add_chat("配信が途切れた...", "視聴者A")
	_add_chat("???", "名無しさん")


func _on_won() -> void:
	_add_chat("脱出成功！！！！", "ホラー好き太郎")
	_add_chat("ガチで良かったｗｗ")


func _do_scare_flash(col: Color) -> void:
	scare_flash.color = col
	scare_t = 1.0


func set_camcorder_ref(camcorder: Node) -> void:
	if camcorder and camcorder.has_signal("battery_changed"):
		camcorder.battery_changed.connect(update_battery)


func play_monologue() -> void:
	var chapter := GameManager.current_chapter
	if chapter and chapter.monologue_lines.size() > 0:
		for line: String in chapter.monologue_lines:
			_add_chat(line, "しゅっち", "owner")
	else:
		_add_chat("ここが…例の場所か", "しゅっち", "owner")
		_add_chat("VHSテープを全部回収して脱出しよう", "しゅっち", "owner")


func refresh_item_label() -> void:
	_update_item_label(GameManager.items_found)


func _update_item_label(count: int) -> void:
	if not is_instance_valid(item_label):
		return
	var total := GameManager.items_total
	item_label.visible = total > 0
	item_label.text = "📼 VHS  %d / %d" % [count, total]


func add_chat(msg: String, user: String = "", user_type: String = "") -> void:
	_add_chat(msg, user, user_type)


# ════════════════════════════════════════════════════════════════
# 主人公モノローグウィンドウ（下部メッセージ表示）
# ════════════════════════════════════════════════════════════════

func _build_monologue_window() -> void:
	_mono_panel = PanelContainer.new()
	_mono_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_mono_panel.position = Vector2(20, -200)
	_mono_panel.custom_minimum_size = Vector2(860, 0)
	_mono_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mono_panel.modulate.a = 0.0
	_mono_panel.visible = false

	# ── シンプル半透明パネル（背景が少し透ける） ──
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.01, 0.01, 0.72)
	panel_style.set_corner_radius_all(6)
	panel_style.border_color = Color(0.85, 0.08, 0.08, 0.45)
	panel_style.set_border_width_all(1)
	panel_style.content_margin_left   = 20
	panel_style.content_margin_right  = 20
	panel_style.content_margin_top    = 14
	panel_style.content_margin_bottom = 14
	_mono_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_mono_panel)

	# セリフ本文
	_mono_text = RichTextLabel.new()
	_mono_text.bbcode_enabled = true
	_mono_text.fit_content    = true
	_mono_text.scroll_active  = false
	_mono_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mono_text.add_theme_font_size_override("normal_font_size", 22)
	_mono_text.add_theme_color_override("default_color", Color(0.96, 0.94, 0.90))
	_mono_panel.add_child(_mono_text)


## ホラー強調キーワード（自動で赤く＋震える）
const HORROR_KEYWORDS : Array[String] = [
	"みゆき", "みゆきちゃん", "みゆきさん",
	"首", "切断", "血", "赤い", "死",
	"凶器", "一振り", "殺", "遺体", "死体",
	"うしろ", "逃げて", "来る", "くる",
	"お札", "呪", "霊", "幽霊", "心霊",
	"イヤァァ", "きゃあ", "ヒッ",
	"K",
]

## ストーリー強調キーワード（黄みがかった白で目立たせる）
const STORY_KEYWORDS : Array[String] = [
	"公衆トイレ", "霧原村", "廃村",
	"VHS", "テープ", "1994",
	"２つ目", "個室", "天井",
	"目撃者", "事件",
]


func show_monologue(text: String) -> void:
	if not is_instance_valid(_mono_panel):
		return
	var styled := _highlight_keywords(_colorize_usernames(text))
	_mono_text.bbcode_text = "[shake rate=20 level=1]%s[/shake]" % styled
	_mono_panel.visible = true
	var tw := create_tween()
	tw.tween_property(_mono_panel, "modulate:a", 1.0, 0.2)


func _highlight_keywords(text: String) -> String:
	var result := text
	# ホラーキーワード → 赤＋強い震え
	for kw in HORROR_KEYWORDS:
		if kw in result:
			result = result.replace(kw,
				"[shake rate=40 level=4][color=#ff3030]%s[/color][/shake]" % kw)
	# ストーリーキーワード → 明るい強調色
	for kw in STORY_KEYWORDS:
		if kw in result:
			result = result.replace(kw,
				"[color=#ffe0a0]%s[/color]" % kw)
	return result


func _colorize_usernames(text: String) -> String:
	var result := text
	for user in MODERATORS:
		result = result.replace(user, "[color=#7aa8ff]%s[/color]" % user)
	for user in MEMBERS:
		result = result.replace(user, "[color=#5fd67a]%s[/color]" % user)
	return result


func hide_monologue() -> void:
	if not is_instance_valid(_mono_panel) or not _mono_panel.visible:
		return
	var tw := create_tween()
	tw.tween_property(_mono_panel, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func() -> void: _mono_panel.visible = false)


func _show_exit_guide() -> void:
	if is_instance_valid(_exit_guide):
		return  # 既に表示中

	_exit_guide = Control.new()
	_exit_guide.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_exit_guide.position = Vector2(30, 60)
	_exit_guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_exit_guide)

	# 背景パネル
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.80, 0.0, 0.0, 0.88)
	style.border_color = Color(1.0, 0.5, 0.0, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	_exit_guide.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var top_lbl := Label.new()
	top_lbl.text = "▼ VHS 全回収完了 ▼"
	top_lbl.add_theme_font_size_override("font_size", 11)
	top_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	top_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(top_lbl)

	var lbl := Label.new()
	lbl.text = "  ◆ 出口へ向かえ  EXIT ◆  "
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)

	# フェードイン
	_exit_guide.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_exit_guide, "modulate:a", 1.0, 0.5)

	# 出口方向矢印を有効化
	_activate_exit_arrow()


# ════════════════════════════════════════════════════════════════
# ナビ矢印（イベントナビ — ソシャゲ風の目的地誘導）
# ════════════════════════════════════════════════════════════════

func start_nav(target: Vector3, label_text: String = "NEXT", radius: float = 3.0) -> void:
	_nav_target = target
	_nav_radius = radius
	if not is_instance_valid(_nav_arrow):
		_build_nav_arrow()
	if is_instance_valid(_nav_title_lbl):
		_nav_title_lbl.text = label_text
	_nav_active = true
	_nav_arrow.visible = true
	_nav_arrow.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_nav_arrow, "modulate:a", 1.0, 0.4)


func stop_nav() -> void:
	_nav_active = false
	if is_instance_valid(_nav_arrow):
		_nav_arrow.visible = false


func _build_nav_arrow() -> void:
	_nav_arrow = Control.new()
	_nav_arrow.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_nav_arrow.position = Vector2(60, -100)
	_nav_arrow.custom_minimum_size = Vector2(120, 80)
	_nav_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nav_arrow.visible = false
	add_child(_nav_arrow)

	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	style.border_color = Color(0.2, 0.6, 1.0, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	bg.add_theme_stylebox_override("panel", style)
	_nav_arrow.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	bg.add_child(vbox)

	_nav_title_lbl = Label.new()
	_nav_title_lbl.text = "NEXT"
	_nav_title_lbl.add_theme_font_size_override("font_size", 12)
	_nav_title_lbl.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	_nav_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_nav_title_lbl)

	_nav_arrow_lbl = Label.new()
	_nav_arrow_lbl.text = "▲"
	_nav_arrow_lbl.add_theme_font_size_override("font_size", 30)
	_nav_arrow_lbl.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	_nav_arrow_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.3, 0.8, 0.6))
	_nav_arrow_lbl.add_theme_constant_override("shadow_offset_x", 0)
	_nav_arrow_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_nav_arrow_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nav_arrow_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(_nav_arrow_lbl)

	_nav_dist_lbl = Label.new()
	_nav_dist_lbl.text = "-- m"
	_nav_dist_lbl.add_theme_font_size_override("font_size", 11)
	_nav_dist_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_nav_dist_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_nav_dist_lbl)


func _update_nav_arrow() -> void:
	var player_pos := _player_ref.global_position
	var to_target := _nav_target - player_pos
	to_target.y = 0.0
	var dist := to_target.length()

	if is_instance_valid(_nav_dist_lbl):
		_nav_dist_lbl.text = "%dm" % int(dist)

	# 到達判定
	if dist < _nav_radius:
		stop_nav()
		nav_reached.emit()
		return

	# 矢印回転
	var player_yaw := _player_ref.rotation.y
	var target_angle := atan2(to_target.x, to_target.z)
	var rel_angle := target_angle - player_yaw
	rel_angle = fmod(rel_angle + PI, TAU) - PI

	if is_instance_valid(_nav_arrow_lbl):
		_nav_arrow_lbl.pivot_offset = _nav_arrow_lbl.size / 2.0
		_nav_arrow_lbl.rotation = -rel_angle

	# 距離に応じて色変化（近づくと緑に）
	var color_t := clampf(1.0 - dist / 30.0, 0.0, 1.0)
	var arrow_color := Color(0.3, 0.7, 1.0).lerp(Color(0.3, 1.0, 0.4), color_t)
	if is_instance_valid(_nav_arrow_lbl):
		_nav_arrow_lbl.add_theme_color_override("font_color", arrow_color)


# ════════════════════════════════════════════════════════════════
# 出口方向矢印（VHS全回収後にプレイヤーの視点に対して出口方向を示す）
# ════════════════════════════════════════════════════════════════

func setup_exit_arrow(player_node: Node3D, exit_pos: Vector3) -> void:
	_player_ref = player_node
	_exit_position = exit_pos
	_build_exit_arrow()


func _build_exit_arrow() -> void:
	# 画面中央下に配置する方向矢印UI
	_exit_arrow = Control.new()
	_exit_arrow.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_exit_arrow.position = Vector2(-60, -100)
	_exit_arrow.custom_minimum_size = Vector2(120, 80)
	_exit_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exit_arrow.visible = false
	add_child(_exit_arrow)

	# 背景パネル
	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	style.border_color = Color(0.9, 0.15, 0.05, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	bg.add_theme_stylebox_override("panel", style)
	_exit_arrow.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	bg.add_child(vbox)

	# EXIT ラベル
	var title_lbl := Label.new()
	title_lbl.text = "EXIT"
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	# 矢印（大きめ、回転で方向を示す）
	_exit_arrow_lbl = Label.new()
	_exit_arrow_lbl.text = "▲"
	_exit_arrow_lbl.add_theme_font_size_override("font_size", 30)
	_exit_arrow_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
	_exit_arrow_lbl.add_theme_color_override("font_shadow_color", Color(0.8, 0.0, 0.0, 0.6))
	_exit_arrow_lbl.add_theme_constant_override("shadow_offset_x", 0)
	_exit_arrow_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_exit_arrow_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exit_arrow_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(_exit_arrow_lbl)

	# 距離ラベル
	_exit_dist_lbl = Label.new()
	_exit_dist_lbl.text = "-- m"
	_exit_dist_lbl.add_theme_font_size_override("font_size", 11)
	_exit_dist_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_exit_dist_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_exit_dist_lbl)


func _activate_exit_arrow() -> void:
	if is_instance_valid(_exit_arrow):
		_exit_arrow_active = true
		_exit_arrow.visible = true
		_exit_arrow.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_exit_arrow, "modulate:a", 1.0, 0.6)


func _update_exit_arrow() -> void:
	# プレイヤーのY回転（水平向き）から出口方向への角度差を計算
	var player_pos := _player_ref.global_position
	var to_exit := _exit_position - player_pos
	to_exit.y = 0.0
	var dist := to_exit.length()

	# 距離表示更新
	if is_instance_valid(_exit_dist_lbl):
		_exit_dist_lbl.text = "%dm" % int(dist)

	if dist < 0.5:
		return

	# プレイヤーが向いている方向（-Z が前方）
	var player_yaw := _player_ref.rotation.y
	# 出口方向の角度（atan2: X/Z平面）
	var exit_angle := atan2(to_exit.x, to_exit.z)
	# プレイヤー視点からの相対角度
	var rel_angle := exit_angle - player_yaw
	# -PI〜PI に正規化
	rel_angle = fmod(rel_angle + PI, TAU) - PI

	# 矢印ラベルを回転（▲ は上向きなので、relAngle=0 → 前方 → rotation=0）
	if is_instance_valid(_exit_arrow_lbl):
		_exit_arrow_lbl.pivot_offset = _exit_arrow_lbl.size / 2.0
		_exit_arrow_lbl.rotation = -rel_angle

	# 距離に応じて色変化（近づくと緑に）
	var color_t := clampf(1.0 - dist / 30.0, 0.0, 1.0)
	var arrow_color := Color(1.0, 0.4, 0.2).lerp(Color(0.3, 1.0, 0.4), color_t)
	if is_instance_valid(_exit_arrow_lbl):
		_exit_arrow_lbl.add_theme_color_override("font_color", arrow_color)


# ════════════════════════════════════════════════════════════════
# ビデオカメラ録画オーバーレイ（ホラー風ファインダー表示）
# ════════════════════════════════════════════════════════════════

# ════════════════════════════════════════════════════════════════
# リッチ REC HUD（映像エリア内に配置）
# ════════════════════════════════════════════════════════════════

func _build_rec_hud() -> void:
	# ── 左上: REC バッジ（角丸パネル＋点滅ドット） ──
	# ファインダー括弧の内側に配置（bracket_margin=8 + bracket_w=2 + 余白4 = 14）
	var inset : float = 14.0
	_rec_bg = PanelContainer.new()
	_rec_bg.position = Vector2(VIDEO_LEFT + inset, VIDEO_TOP + inset)
	_rec_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rec_sb := StyleBoxFlat.new()
	rec_sb.bg_color = Color(0.75, 0.04, 0.04, 0.85)
	rec_sb.set_corner_radius_all(6)
	rec_sb.content_margin_left = 10
	rec_sb.content_margin_right = 12
	rec_sb.content_margin_top = 3
	rec_sb.content_margin_bottom = 3
	_rec_bg.add_theme_stylebox_override("panel", rec_sb)
	add_child(_rec_bg)

	var rec_hbox := HBoxContainer.new()
	rec_hbox.add_theme_constant_override("separation", 6)
	rec_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rec_bg.add_child(rec_hbox)

	_rec_dot = Label.new()
	_rec_dot.text = "●"
	_rec_dot.add_theme_font_size_override("font_size", 14)
	_rec_dot.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_rec_dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rec_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rec_hbox.add_child(_rec_dot)

	rec_label = Label.new()
	rec_label.text = "REC"
	rec_label.add_theme_font_size_override("font_size", 15)
	rec_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	rec_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rec_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rec_hbox.add_child(rec_label)

	# ── 左上: タイムコード（RECバッジの右） ──
	timecode_label = Label.new()
	timecode_label.text = "00:00:00.00"
	timecode_label.add_theme_font_size_override("font_size", 14)
	timecode_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.75))
	timecode_label.position = Vector2(VIDEO_LEFT + inset + 82, VIDEO_TOP + inset + 4)
	timecode_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(timecode_label)

	# ── 右上: バッテリー ──
	battery_label = Label.new()
	battery_label.text = "⚡ ▮▮▮▮▮"
	battery_label.add_theme_font_size_override("font_size", 13)
	battery_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 0.85))
	battery_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	battery_label.position = Vector2(VIDEO_RIGHT - inset - 120, VIDEO_TOP + inset + 4)
	battery_label.size = Vector2(120, 24)
	battery_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(battery_label)

	# ── 左下: CAM + 日付 ──
	_cam_label = Label.new()
	_cam_label.text = "CAM 1"
	_cam_label.add_theme_font_size_override("font_size", 12)
	_cam_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))
	_cam_label.position = Vector2(VIDEO_LEFT + inset, VIDEO_BOTTOM - inset - 18)
	_cam_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cam_label)

	_date_label = Label.new()
	_date_label.text = "2026/02/24  23:48"
	_date_label.add_theme_font_size_override("font_size", 12)
	_date_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	_date_label.position = Vector2(VIDEO_LEFT + inset + 56, VIDEO_BOTTOM - inset - 18)
	_date_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_date_label)

	# ── 右下: アイテム数 ──
	item_label = Label.new()
	item_label.text = ""
	item_label.add_theme_font_size_override("font_size", 14)
	item_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 0.9))
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	item_label.position = Vector2(VIDEO_RIGHT - inset - 160, VIDEO_BOTTOM - inset - 20)
	item_label.size = Vector2(160, 24)
	item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_label.visible = false
	add_child(item_label)


func _build_camcorder_overlay() -> void:
	_camcorder_overlay = Control.new()
	_camcorder_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_camcorder_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_camcorder_overlay)

	# 映像エリア内にファインダー枠を配置
	var area_l : float = VIDEO_LEFT
	var area_t : float = VIDEO_TOP
	var area_r : float = VIDEO_RIGHT
	var area_b : float = VIDEO_BOTTOM

	# ── ファインダー角括弧（四隅のL字マーク） ──
	var bracket_len : float = 40.0
	var bracket_w   : float = 2.0
	var bracket_margin : float = 8.0
	var bracket_col := Color(1.0, 1.0, 1.0, 0.45)

	# 四隅: [top-left, top-right, bottom-left, bottom-right]
	var corners : Array[Vector2] = [
		Vector2(area_l + bracket_margin, area_t + bracket_margin),
		Vector2(area_r - bracket_margin, area_t + bracket_margin),
		Vector2(area_l + bracket_margin, area_b - bracket_margin),
		Vector2(area_r - bracket_margin, area_b - bracket_margin),
	]
	# 各コーナーのL字方向 [横方向, 縦方向]
	var dirs : Array[Array] = [
		[Vector2(1, 0), Vector2(0, 1)],    # 左上 → 右・下
		[Vector2(-1, 0), Vector2(0, 1)],   # 右上 → 左・下
		[Vector2(1, 0), Vector2(0, -1)],   # 左下 → 右・上
		[Vector2(-1, 0), Vector2(0, -1)],  # 右下 → 左・上
	]
	for i in range(4):
		var corner : Vector2 = corners[i]
		var h_dir  : Vector2 = dirs[i][0]
		var v_dir  : Vector2 = dirs[i][1]
		# 横線
		var h_bar := ColorRect.new()
		h_bar.color = bracket_col
		h_bar.size = Vector2(bracket_len, bracket_w)
		h_bar.position = Vector2(
			corner.x if h_dir.x > 0 else corner.x - bracket_len,
			corner.y if v_dir.y > 0 else corner.y - bracket_w
		)
		h_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camcorder_overlay.add_child(h_bar)
		# 縦線
		var v_bar := ColorRect.new()
		v_bar.color = bracket_col
		v_bar.size = Vector2(bracket_w, bracket_len)
		v_bar.position = Vector2(
			corner.x if h_dir.x > 0 else corner.x - bracket_w,
			corner.y if v_dir.y > 0 else corner.y - bracket_len
		)
		v_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camcorder_overlay.add_child(v_bar)

	# ── 中央フォーカス十字（映像エリア中央） ──
	var cx : float = (area_l + area_r) / 2.0
	var cy : float = (area_t + area_b) / 2.0
	var cross_len : float = 14.0
	var cross_w   : float = 1.0
	var cross_col := Color(1.0, 1.0, 1.0, 0.30)
	var cross_gap : float = 6.0

	for seg in [
		Vector4(-cross_w / 2.0, -cross_gap - cross_len, cross_w, cross_len),
		Vector4(-cross_w / 2.0, cross_gap, cross_w, cross_len),
		Vector4(-cross_gap - cross_len, -cross_w / 2.0, cross_len, cross_w),
		Vector4(cross_gap, -cross_w / 2.0, cross_len, cross_w),
	]:
		var bar := ColorRect.new()
		bar.color = cross_col
		bar.position = Vector2(cx + seg.x, cy + seg.y)
		bar.size = Vector2(seg.z, seg.w)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camcorder_overlay.add_child(bar)

	# ── トラッキングノイズ用の水平線（映像エリア幅） ──
	_tracking_line = ColorRect.new()
	_tracking_line.color = Color(1.0, 1.0, 1.0, 0.12)
	_tracking_line.size = Vector2(area_r - area_l, 3.0)
	_tracking_line.position = Vector2(area_l, -10)
	_tracking_line.visible = false
	_tracking_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camcorder_overlay.add_child(_tracking_line)


func _update_tracking_noise(delta: float) -> void:
	if not is_instance_valid(_tracking_line):
		return

	if _tracking_active:
		# トラッキングノイズ発動中 — 映像エリア内を上から下へ走る
		_tracking_y += delta * float(VIDEO_BOTTOM - VIDEO_TOP) * 1.8
		_tracking_line.position.y = _tracking_y
		if _tracking_y > VIDEO_BOTTOM + 5.0:
			_tracking_active = false
			_tracking_line.visible = false
			_tracking_next = randf_range(5.0, 15.0)
	else:
		_tracking_t += delta
		if _tracking_t >= _tracking_next:
			_tracking_t = 0.0
			_tracking_active = true
			_tracking_y = float(VIDEO_TOP) - 5.0
			_tracking_line.visible = true
			var alpha : float = randf_range(0.06, 0.18)
			_tracking_line.color.a = alpha
			_tracking_line.size.y = randf_range(2.0, 6.0)


# ════════════════════════════════════════════════════════════════
# 画面全体ホラーレッド（発見の瞬間の恐怖演出）
# ════════════════════════════════════════════════════════════════

func _build_horror_red() -> void:
	_horror_red_rect = ColorRect.new()
	_horror_red_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_horror_red_rect.color = Color(0.5, 0.0, 0.0, 0.0)
	_horror_red_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_horror_red_rect.visible = false
	add_child(_horror_red_rect)


func start_horror_red(dur: float = 8.0) -> void:
	if not is_instance_valid(_horror_red_rect) or _horror_red_active:
		return
	_horror_red_active = true
	_horror_red_rect.visible = true
	_horror_red_rect.color = Color(0.45, 0.0, 0.0, 0.0)

	# フェードイン
	var fade_in := create_tween()
	fade_in.tween_property(_horror_red_rect, "color:a", 0.35, 0.3)
	await fade_in.finished

	# 脈動ループ（心臓の鼓動リズム）
	_horror_red_tween = create_tween().set_loops()
	_horror_red_tween.tween_property(_horror_red_rect, "color:a", 0.5, 0.35).set_trans(Tween.TRANS_SINE)
	_horror_red_tween.tween_property(_horror_red_rect, "color:a", 0.15, 0.55).set_trans(Tween.TRANS_SINE)
	_horror_red_tween.tween_property(_horror_red_rect, "color:a", 0.45, 0.3).set_trans(Tween.TRANS_SINE)
	_horror_red_tween.tween_property(_horror_red_rect, "color:a", 0.1, 0.8).set_trans(Tween.TRANS_SINE)

	# 自動解除
	if dur > 0.0:
		get_tree().create_timer(dur).timeout.connect(stop_horror_red, CONNECT_ONE_SHOT)


func stop_horror_red() -> void:
	if not _horror_red_active:
		return
	_horror_red_active = false
	if _horror_red_tween and _horror_red_tween.is_valid():
		_horror_red_tween.kill()
		_horror_red_tween = null
	if is_instance_valid(_horror_red_rect):
		var tw := create_tween()
		tw.tween_property(_horror_red_rect, "color:a", 0.0, 2.0)
		tw.tween_callback(func() -> void: _horror_red_rect.visible = false)


func _add_chat(msg: String, user: String = "", user_type: String = "") -> void:
	if user.is_empty():
		user = USERS[randi() % USERS.size()]

	# ユーザータイプを自動判定
	if user_type.is_empty():
		if user in MODERATORS:
			user_type = "moderator"
		elif user in MEMBERS:
			user_type = "member"
		else:
			user_type = "viewer"

	if is_instance_valid(_chrome):
		_chrome.add_message(msg, user, user_type)
	if danmaku_func.is_valid():
		danmaku_func.call(msg, user_type)
