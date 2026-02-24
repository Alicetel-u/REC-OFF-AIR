extends Node3D

@onready var player       : CharacterBody3D = $Player
@onready var hud          : Control         = $HUDLayer/HUDRoot
@onready var overlay_layer: CanvasLayer     = $OverlayLayer
@onready var caught_label : Label           = $OverlayLayer/Overlay/VBox/CaughtLabel
@onready var win_label    : Label           = $OverlayLayer/Overlay/VBox/WinLabel
@onready var sub_label    : Label           = $OverlayLayer/Overlay/VBox/SubLabel
@onready var intro_layer  : CanvasLayer     = $IntroLayer
@onready var intro_root   : Control         = $IntroLayer/IntroRoot
@onready var intro_text   : RichTextLabel   = $IntroLayer/IntroRoot/IntroText

var _intro_skip : bool = false


func _ready() -> void:
	# プレイヤーをイントロ中は停止
	player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# シグナル接続
	player.player_moved.connect(_on_player_moved)
	player.flashlight_toggled.connect(_on_flashlight_toggled)
	player.battery_changed.connect(hud.update_battery)

	GameManager.player_caught.connect(_show_caught)
	GameManager.player_won.connect(_show_win)

	for ghost in get_tree().get_nodes_in_group("ghost"):
		ghost.ghost_spotted_player.connect(_on_ghost_spotted)
		ghost.ghost_lost_player.connect(_on_ghost_lost)

	overlay_layer.visible = false

	await _run_intro()

	# プレイヤー再開
	player.process_mode = Node.PROCESS_MODE_INHERIT
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	var is_key   : bool = event is InputEventKey         and event.pressed and not event.echo
	var is_click : bool = event is InputEventMouseButton and event.pressed
	if (is_key or is_click) and not _intro_skip:
		_intro_skip = true


# ──────────────────────────────────────────────
# イントロシーケンス
# ──────────────────────────────────────────────

func _run_intro() -> void:
	intro_layer.visible    = true
	intro_root.modulate.a  = 0.0

	# フェードイン
	var tw := create_tween()
	tw.tween_property(intro_root, "modulate:a", 1.0, 0.9)
	await tw.finished

	# タイプライター
	await _intro_typewrite(_intro_bbcode())

	# 読む時間 or スキップ待ち
	var wait_t : float = 0.0
	while wait_t < 3.0 and not _intro_skip:
		wait_t += get_process_delta_time()
		await get_tree().process_frame

	# フェードアウト
	tw = create_tween()
	tw.tween_property(intro_root, "modulate:a", 0.0, 0.8)
	await tw.finished
	intro_layer.visible = false


func _intro_typewrite(bbcode: String) -> void:
	intro_text.bbcode_enabled    = true
	intro_text.bbcode_text       = bbcode
	intro_text.visible_characters = 0
	var total := intro_text.get_total_character_count()
	for i in range(1, total + 1):
		if _intro_skip:
			intro_text.visible_characters = -1
			return
		intro_text.visible_characters = i
		await get_tree().create_timer(0.016).timeout


func _intro_bbcode() -> String:
	var s := "[color=#555555]● REC  00:00:00[/color]\n\n"
	s += "[color=#888888][i]2026/02/24  23:47  旧・ヤマネ精工 第三工場跡[/i][/color]\n"
	s += "[color=#333333]─────────────────────────────────────────────[/color]\n\n"
	s += "[color=#ffffff][font_size=19][b]状況[/b][/font_size][/color]\n\n"
	s += "[color=#cccccc]「謎のDMで頼まれた仕事。[/color]\n"
	s += "[color=#cccccc]廃工場に置き忘れたというVHSテープを回収する。\n"
	s += "配信しながらやれば絶対バズる。」[/color]\n\n"
	s += "[color=#333333]─────────────────────────────────────────────[/color]\n\n"
	s += "[color=#ffffff][font_size=19][b]ミッション[/b][/font_size][/color]\n\n"
	s += "[color=#dddddd]▶  工場内の[/color][color=#ffffff][b]VHSテープを5本[/b][/color][color=#dddddd]すべて回収する[/color]\n"
	s += "[color=#dddddd]▶  集め終わったら[/color][color=#00ff55][b]脱出口（EXIT）[/b][/color][color=#dddddd]から逃げ出す[/color]\n\n"
	s += "[color=#ff4444][b]⚠  工場内に何かがいる。見つかったら……終わり。[/b][/color]\n\n"
	s += "[color=#333333]─────────────────────────────────────────────[/color]\n\n"
	s += "[color=#555555]WASD : 移動　　Shift : ダッシュ　　F : 懐中電灯[/color]"
	return s


# ──────────────────────────────────────────────
# イベントハンドラ
# ──────────────────────────────────────────────

func _on_player_moved() -> void:
	hud.trigger_chat_event("moved")


func _on_flashlight_toggled(on: bool) -> void:
	hud.trigger_chat_event("flashlight_on" if on else "flashlight_off")


func _on_ghost_spotted() -> void:
	hud.trigger_chat_event("ghost_spotted")


func _on_ghost_lost() -> void:
	hud.trigger_chat_event("ghost_lost")


func _show_caught() -> void:
	await get_tree().create_timer(1.4).timeout
	caught_label.visible  = true
	win_label.visible     = false
	sub_label.text        = "カメラの電源が切れた..."
	overlay_layer.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _show_win() -> void:
	await get_tree().create_timer(0.6).timeout
	caught_label.visible  = false
	win_label.visible     = true
	sub_label.text        = "証拠映像を持ち帰った。"
	overlay_layer.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_retry_pressed() -> void:
	GameManager.restart()
