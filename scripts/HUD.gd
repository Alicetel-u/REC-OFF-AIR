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


func set_exit_guide_refs(_camcorder: Node3D, _exit: Node3D) -> void:
	pass


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


func _update_item_label(count: int) -> void:
	item_label.text = "VHS  %d / %d" % [count, GameManager.items_total]


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
