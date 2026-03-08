extends Control
class_name HUD

@onready var rec_label     : Label    = $TopBar/RecLabel
@onready var timecode_label: Label    = $TopBar/TimecodeLabel
@onready var battery_label : Label    = $TopBar/BatteryLabel
@onready var item_label    : Label    = $BottomBar/ItemLabel
@onready var scare_flash   : ColorRect = $ScareFlash

var record_time : float = 0.0
var rec_blink_t : float = 0.0
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

# ── 出口方向矢印 ──
var _exit_arrow     : Control    = null
var _exit_arrow_lbl : Label      = null
var _exit_dist_lbl  : Label      = null
var _player_ref     : Node3D     = null
var _exit_position  : Vector3    = Vector3.ZERO
var _exit_arrow_active : bool    = false

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
	_update_item_label(0)
	_build_monologue_window()


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

	var speeds := [1.0, 2.0, 4.0, 8.0]
	for spd in speeds:
		var btn := Button.new()
		btn.text = "x%s" % str(spd)
		btn.custom_minimum_size = Vector2(80, 30)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_set_game_speed.bind(spd))
		vbox.add_child(btn)


func _set_game_speed(spd: float) -> void:
	Engine.time_scale = spd


func _process(delta: float) -> void:
	# デバッグクリックのタイムアウト
	if _dbg_click_timer > 0.0:
		_dbg_click_timer -= delta
		if _dbg_click_timer <= 0.0:
			_dbg_click_count = 0

	record_time += delta

	# ── REC 点滅 ──
	rec_blink_t += delta
	if rec_blink_t >= 0.5:
		rec_blink_t = 0.0
		rec_show = not rec_show
		rec_label.visible = rec_show

	# ── タイムコード ──
	var h := int(record_time / 3600.0)
	var m := int(fmod(record_time, 3600.0) / 60.0)
	var s := int(fmod(record_time, 60.0))
	timecode_label.text = "%02d:%02d:%02d" % [h, m, s]

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


func update_battery(level: float) -> void:
	var filled := int(level * 5)
	var empty  := 5 - filled
	battery_label.text = " BAT [" + "I".repeat(filled) + ".".repeat(empty) + "] "
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
	var total := GameManager.items_total
	item_label.visible = total > 0
	item_label.text = "VHS  %d / %d" % [count, total]


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
