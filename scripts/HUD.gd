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

var _mono_panel : PanelContainer = null
var _mono_text  : RichTextLabel  = null

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


func _process(delta: float) -> void:
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
	# YouTubeChrome レイアウト: 映像エリアは y=48〜612（layer20の不透明UIで隠れる領域は y>612）
	# HUD(layer2)はlayer20の下に描画されるため、パネル全体を y=612より上に収める
	# ウィンドウ高さ≈65px → top=540, bottom=605 → 映像エリア内に収まる
	_mono_panel = PanelContainer.new()
	_mono_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_mono_panel.position = Vector2(20, -180)
	_mono_panel.custom_minimum_size = Vector2(860, 0)
	_mono_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mono_panel.modulate.a = 0.0
	_mono_panel.visible = false

	# 漆黒＋血赤ボーダーのホラーパネル
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.0, 0.0, 0.90)
	style.border_color = Color(0.60, 0.0, 0.0, 0.95)
	style.border_width_left = 3
	style.set_corner_radius_all(3)
	style.set_content_margin_all(10)
	_mono_panel.add_theme_stylebox_override("panel", style)
	add_child(_mono_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_mono_panel.add_child(vbox)

	# 名前ラベル（血赤＋赤い影）
	var name_lbl := Label.new()
	name_lbl.text = "▶  しゅっち"
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.06, 0.06))
	name_lbl.add_theme_color_override("font_shadow_color", Color(0.5, 0.0, 0.0, 1.0))
	name_lbl.add_theme_constant_override("shadow_offset_x", 1)
	name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(name_lbl)

	# セリフ本文（RichTextLabel で BBCode shake エフェクト対応）
	_mono_text = RichTextLabel.new()
	_mono_text.bbcode_enabled = true
	_mono_text.fit_content = true
	_mono_text.scroll_active = false
	_mono_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mono_text.add_theme_font_size_override("normal_font_size", 22)
	_mono_text.add_theme_color_override("default_color", Color(0.82, 0.76, 0.68))
	vbox.add_child(_mono_text)


func show_monologue(text: String) -> void:
	if not is_instance_valid(_mono_panel):
		return
	# [shake rate=25 level=2] → 微細な震えでホラー感演出
	# ユーザー名を自動色付け（モデレーター=青、メンバー=緑）
	_mono_text.bbcode_text = "[shake rate=25 level=2][color=#d0c8bc]%s[/color][/shake]" % _colorize_usernames(text)
	_mono_panel.visible = true
	var tw := create_tween()
	tw.tween_property(_mono_panel, "modulate:a", 1.0, 0.2)


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
