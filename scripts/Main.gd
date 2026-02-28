extends Node3D

# ── 弾幕レイヤー定数（YouTubeChrome と同じ座標系）──────────────
const _DANK_VIDEO_W   = 960
const _DANK_TOP_H     = 56
const _DANK_VIDEO_BOT = 624
const _DANK_ROWS      = 7
const _DANK_ROW_H     = 34

@onready var player       : Player          = $Player
@onready var hud          : HUD             = $HUDLayer/HUDRoot
@onready var overlay_layer: CanvasLayer     = $OverlayLayer
@onready var caught_label : Label           = $OverlayLayer/Overlay/VBox/CaughtLabel
@onready var win_label    : Label           = $OverlayLayer/Overlay/VBox/WinLabel
@onready var sub_label    : Label           = $OverlayLayer/Overlay/VBox/SubLabel
@onready var intro_layer  : CanvasLayer     = $IntroLayer
@onready var intro_root   : Control         = $IntroLayer/IntroRoot
@onready var intro_text   : RichTextLabel   = $IntroLayer/IntroRoot/IntroText
@onready var stage_gen    : StageGenerator  = $StageGenerator
@onready var scenario_ui  : ScenarioUI      = $ScenarioUI

var _intro_skip   : bool    = false
var _danmaku_clip : Control = null
var _danmaku_row  : int     = 0


func _ready() -> void:
	# プレイヤーをイントロ中は停止
	player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var result: Dictionary = stage_gen.generate(GameManager.selected_map_type)
	GameManager.items_total = stage_gen.item_count


	# プレイヤー位置をマップ結果に合わせる
	player.position = result.spawns.player

	# シグナル接続
	player.player_moved.connect(_on_player_moved)

	GameManager.player_caught.connect(_show_caught)
	GameManager.player_won.connect(_show_win)

	# ゴーストをイントロ中は停止
	for ghost: Ghost in get_tree().get_nodes_in_group("ghost"):
		ghost.ghost_spotted_player.connect(_on_ghost_spotted)
		ghost.ghost_lost_player.connect(_on_ghost_lost)
		ghost.process_mode = Node.PROCESS_MODE_DISABLED

	overlay_layer.visible = false

	# 出口方向ガイド用の参照をHUDに渡す
	hud.set_exit_guide_refs($Player/Head/Camera3D, stage_gen.exit_node)

	# バッテリーシグナルをHUDに接続
	hud.set_camcorder_ref(player)

	# YouTube Chrome をHUDに渡してチャットを接続
	hud.set_chrome($YouTubeChrome as YouTubeChrome)

	# 弾幕レイヤーを構築してHUDに接続
	_setup_danmaku()
	hud.danmaku_func = Callable(self, "_spawn_danmaku")

	# Inventory シングルトンに参照を渡す
	Inventory.player = player
	Inventory.inventory_ui = $InventoryLayer/InventoryUI

	await _run_intro()

	# プレイヤー＆ゴースト再開
	player.process_mode = Node.PROCESS_MODE_INHERIT
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	for ghost: Ghost in get_tree().get_nodes_in_group("ghost"):
		ghost.process_mode = Node.PROCESS_MODE_INHERIT

	# マップ上でキャラのセリフによる状況説明
	hud.play_monologue()

	# シナリオシステム接続
	ScenarioManager.scenario_triggered.connect(_on_scenario_triggered)
	ScenarioManager.trigger("game_start")


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

	var tw := create_tween()
	tw.tween_property(intro_root, "modulate:a", 1.0, 0.6)
	await tw.finished

	# 短い REC 開始演出
	intro_text.bbcode_enabled = true
	intro_text.bbcode_text = _intro_bbcode()
	intro_text.visible_characters = 0
	var total := intro_text.get_total_character_count()
	for i in range(1, total + 1):
		if _intro_skip:
			intro_text.visible_characters = -1
			break
		intro_text.visible_characters = i
		await get_tree().create_timer(0.025).timeout

	# 少し待機
	var wait_t : float = 0.0
	while wait_t < 2.0 and not _intro_skip:
		wait_t += get_process_delta_time()
		await get_tree().process_frame

	tw = create_tween()
	tw.tween_property(intro_root, "modulate:a", 0.0, 0.6)
	await tw.finished
	intro_layer.visible = false


func _intro_bbcode() -> String:
	var location_text := "廃村・深夜配信"
	match GameManager.selected_map_type:
		0: location_text = "廃工場・深夜配信"
	var s := "\n\n\n"
	s += "[center][color=#ff2222][font_size=42][b]● REC[/b][/font_size][/color][/center]\n\n"
	s += "[center][color=#888888][font_size=16]2026/02/24  23:47[/font_size][/color][/center]\n"
	s += "[center][color=#666666][font_size=15]%s[/font_size][/color][/center]\n" % location_text
	return s


# ──────────────────────────────────────────────
# イベントハンドラ
# ──────────────────────────────────────────────

func _on_player_moved() -> void:
	hud.trigger_chat_event("moved")


func _on_ghost_spotted() -> void:
	hud.trigger_chat_event("ghost_spotted")
	ScenarioManager.trigger("ghost_spotted")


func _on_ghost_lost() -> void:
	hud.trigger_chat_event("ghost_lost")


func _show_caught() -> void:
	await get_tree().create_timer(1.4).timeout
	_close_inventory()
	caught_label.visible  = true
	win_label.visible     = false
	sub_label.text        = "カメラの電源が切れた..."
	overlay_layer.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _show_win() -> void:
	await get_tree().create_timer(0.6).timeout
	_close_inventory()
	caught_label.visible  = false
	win_label.visible     = true
	sub_label.text        = "証拠映像を持ち帰った。"
	overlay_layer.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _close_inventory() -> void:
	var inv_ui = $InventoryLayer/InventoryUI
	if inv_ui and inv_ui.is_open():
		inv_ui.close_inventory()


func _on_scenario_triggered(scenario: Dictionary) -> void:
	scenario_ui.show_scenario(scenario)
	scenario_ui.choice_made.connect(
		func(s: Dictionary, idx: int) -> void: ScenarioManager.resolve(s, idx),
		CONNECT_ONE_SHOT
	)


func _on_retry_pressed() -> void:
	GameManager.restart()


# ════════════════════════════════════════════════════════════════
# 弾幕コメント（ニコニコ風・動画エリアにクリップ）
# ════════════════════════════════════════════════════════════════

func _setup_danmaku() -> void:
	var dank_c := CanvasLayer.new()
	dank_c.layer = 15  # HUD(2)より上、YouTubeChrome(20)より下
	add_child(dank_c)

	var dank_cont := SubViewportContainer.new()
	dank_cont.position = Vector2(0, _DANK_TOP_H)
	dank_cont.size = Vector2(_DANK_VIDEO_W, _DANK_VIDEO_BOT - _DANK_TOP_H)
	dank_cont.stretch = true
	dank_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dank_c.add_child(dank_cont)

	var dank_sv := SubViewport.new()
	dank_sv.size = Vector2i(_DANK_VIDEO_W, int(_DANK_VIDEO_BOT - _DANK_TOP_H))
	dank_sv.transparent_bg = true
	dank_sv.disable_3d = true
	dank_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	dank_cont.add_child(dank_sv)

	_danmaku_clip = Control.new()
	_danmaku_clip.size = Vector2(_DANK_VIDEO_W, _DANK_VIDEO_BOT - _DANK_TOP_H)
	_danmaku_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dank_sv.add_child(_danmaku_clip)


func _spawn_danmaku(msg: String, utype: String) -> void:
	if not is_instance_valid(_danmaku_clip):
		return

	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.88))

	var col := Color(1.0, 1.0, 1.0, 0.86)
	match utype:
		"member":    col = Color(0.35, 1.0,  0.55, 0.92)
		"moderator": col = Color(0.55, 0.82, 1.0,  0.92)
		"owner":     col = Color(1.0,  0.85, 0.2,  0.95)
	lbl.add_theme_color_override("font_color", col)

	var row := _danmaku_row % _DANK_ROWS
	_danmaku_row += 1
	lbl.position = Vector2(_DANK_VIDEO_W + 4.0, 8.0 + row * _DANK_ROW_H)
	_danmaku_clip.add_child(lbl)

	await get_tree().process_frame
	var travel := _DANK_VIDEO_W + lbl.size.x + 20.0
	var speed  := randf_range(130.0, 185.0)
	var tw := create_tween()
	tw.tween_property(lbl, "position:x", -lbl.size.x - 20.0, travel / speed)
	tw.tween_callback(lbl.queue_free)


