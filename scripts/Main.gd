extends Node3D

const EntranceDirectorScript := preload("res://scripts/EntranceDirector.gd")

# ── 弾幕レイヤー定数（YouTubeChrome と同じ座標系）──────────────
const _DANK_VIDEO_W   = 940
const _DANK_TOP_H     = 48
const _DANK_VIDEO_BOT = 612
const _DANK_ROWS      = 7
const _DANK_ROW_H     = 44

# 演出終了後に自動で次チャプターへ進むチャプターID一覧（CP3のみ手動）
const AUTO_PROGRESS_CHAPTERS : Array[String] = [
	"ch02_yashiki",
	"ch04_kirihara_jinja",
	"ch05_haison_dasshutsu",
]

@onready var player       : CharacterBody3D = $Player
@onready var hud          : Control         = $HUDLayer/HUDRoot
@onready var overlay_layer: CanvasLayer     = $OverlayLayer
@onready var overlay_ctrl : Control         = $OverlayLayer/Overlay
@onready var caught_label : Label           = $OverlayLayer/Overlay/VBox/CaughtLabel
@onready var win_label    : Label           = $OverlayLayer/Overlay/VBox/WinLabel
@onready var sub_label    : Label           = $OverlayLayer/Overlay/VBox/SubLabel
@onready var intro_layer  : CanvasLayer     = $IntroLayer
@onready var intro_root   : Control         = $IntroLayer/IntroRoot
@onready var intro_text   : RichTextLabel   = $IntroLayer/IntroRoot/IntroText
@onready var stage_gen    : Node            = $StageGenerator
@onready var scenario_ui  : CanvasLayer     = $ScenarioUI

var _intro_skip   : bool    = false
var _danmaku_clip : Control = null
var _danmaku_row  : int     = 0

# ── デバッグ: チャプタースキップ（F1〜F5） ──────────────────
const _DEBUG_CHAPTER_SKIP := true
var _debug_label : Label = null


func _ready() -> void:
	# プレイヤーをイントロ中は停止
	player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# チャプターデータからステージを動的生成
	var chapter := GameManager.current_chapter
	if chapter == null:
		# フォールバック: チャプター未ロード時はデフォルトをロード
		GameManager.load_chapter(0)
		chapter = GameManager.current_chapter
	if chapter == null:
		push_error("Main: chapter data failed to load — aborting _ready()")
		return

	# items_total を generate() より前に設定（Exit._ready() が参照するため）
	GameManager.items_total = chapter.item_positions.size()
	var result: Dictionary = stage_gen.generate(chapter)

	# プレイヤー位置をチャプターデータに合わせる
	player.position = result.spawns.player

	# 環境設定をチャプターデータから適用
	_apply_environment(chapter)

	# シグナル接続
	player.player_moved.connect(_on_player_moved)

	GameManager.player_caught.connect(_show_caught)
	GameManager.player_won.connect(_show_win)
	GameManager.player_hit.connect(_on_player_hit)

	# ゴーストをイントロ中は停止＋透明化（VHS2個回収で出現）
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		ghost.ghost_spotted_player.connect(_on_ghost_spotted)
		ghost.ghost_lost_player.connect(_on_ghost_lost)
		ghost.process_mode = Node.PROCESS_MODE_DISABLED
		ghost.visible = false

	overlay_layer.visible = false

	# バッテリーシグナルをHUDに接続
	hud.set_camcorder_ref(player)

	# YouTube Chrome をHUDに渡してチャットを接続
	hud.set_chrome($YouTubeChrome)
	# items_totalが確定した後でHUDラベルを更新（0個のときは非表示にするため）
	hud.refresh_item_label()

	# 弾幕レイヤーを構築してHUDに接続
	_setup_danmaku()
	hud.danmaku_func = Callable(self, "_spawn_danmaku")

	# Inventory シングルトンに参照を渡す
	Inventory.player = player
	Inventory.inventory_ui = $InventoryLayer/InventoryUI

	# 廃村入口: イントロ前（画面が黒い間）に初期状態を設定してスナップを防ぐ
	if chapter.chapter_id == "ch01_haison_iriguchi":
		player.rotation.y      = 0.29   # バス停方向（-Z）を向く
		player.head.rotation.x = -0.06
		player.flashlight.visible  = false
		player.flashlight_on       = false

	_setup_debug_ui()

	SoundManager.start_ambient(GameManager.chapter_index)

	# ローディング画面をフェードアウト
	await LoadingScreen.fade_out()

	await _run_intro()

	# 廃村入口チャプターは自動演出シーケンスを実行して次チャプターへ進む
	var cur_chapter := GameManager.current_chapter
	if cur_chapter and cur_chapter.chapter_id == "ch01_haison_iriguchi":
		await _run_entrance_sequence()
		return

	# CP2/CP4/CP5 は映像演出（プレイヤー無効）。CP3 だけ操作可能。
	var is_cinematic : bool = cur_chapter != null and cur_chapter.chapter_id in AUTO_PROGRESS_CHAPTERS
	if not is_cinematic:
		player.process_mode = Node.PROCESS_MODE_INHERIT
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# チャプターオープニング演出（JSON駆動。映像演出中はプレイヤー動作なし）
	if cur_chapter:
		await _run_chapter_opening(cur_chapter.chapter_id)

	# 映像演出チャプター: 演出完了後に自動で次チャプターへ
	if is_cinematic:
		if not is_inside_tree():
			return
		await get_tree().create_timer(1.5).timeout
		if not is_inside_tree():
			return
		GameManager.advance_to_next_chapter()
		return

	# マップ上でキャラのセリフによる状況説明（CP3のみここに到達）
	hud.play_monologue()

	# シナリオシステム接続
	ScenarioManager.scenario_triggered.connect(_on_scenario_triggered)
	ScenarioManager.trigger("game_start")

	# ゴーストはVHS2個回収で有効化（_on_ghosts_awaken で処理）
	GameManager.item_collected.connect(_on_item_for_ghost_awaken)

	# 出口方向矢印用: プレイヤーと出口位置をHUDに渡す
	var exit_pos : Vector3 = chapter.exit_position if chapter else Vector3(23, 1.5, 15)
	hud.setup_exit_arrow(player, exit_pos)


func _run_entrance_sequence() -> void:
	## 廃村入口: EntranceDirector に演出を委譲し、完了後に次チャプターへ進む
	var director: Node = EntranceDirectorScript.new()
	director.set("player", player)
	director.set("hud", hud)
	add_child(director)
	await director.run()
	director.queue_free()
	GameManager.advance_to_next_chapter()


func _run_chapter_opening(chapter_id: String) -> void:
	## CP2〜CP5: チャプター開始演出（dialogue/{chapter_id}.json を実行）
	var path := "res://dialogue/%s.json" % chapter_id
	if not FileAccess.file_exists(path):
		return  # JSONが無ければスキップ（CP5後は不要）
	var director: Node = EntranceDirectorScript.new()
	director.set("player", player)
	director.set("hud", hud)
	add_child(director)
	# EntranceDirector.run() は DIALOGUE_JSON 定数を使うため、
	# 動的パスは _run_from_path() で渡す
	await director.run_from_path(path)
	director.queue_free()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var kc := (event as InputEventKey).keycode

	# F9: シナリオ中自由移動トグル（常時有効）
	if kc == KEY_F9:
		_toggle_debug_free_move()
		get_viewport().set_input_as_handled()
		return

	if not _DEBUG_CHAPTER_SKIP:
		return
	var idx := -1
	match kc:
		KEY_F1: idx = 0
		KEY_F2: idx = 1
		KEY_F3: idx = 2
		KEY_F4: idx = 3
		KEY_F5: idx = 4
	if idx < 0:
		return
	get_viewport().set_input_as_handled()
	_debug_skip_to_chapter(idx)


func _toggle_debug_free_move() -> void:
	GameManager.debug_free_move = not GameManager.debug_free_move
	if GameManager.debug_free_move:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	_refresh_debug_label()


func _unhandled_input(event: InputEvent) -> void:
	var is_key   : bool = event is InputEventKey         and event.pressed and not event.echo
	var is_click : bool = event is InputEventMouseButton and event.pressed
	if (is_key or is_click) and not _intro_skip:
		_intro_skip = true


# ──────────────────────────────────────────────
# 環境設定
# ──────────────────────────────────────────────

func _apply_environment(chapter: Resource) -> void:
	var env := $WorldEnvironment.environment as Environment

	# ── 背景 ──
	if chapter.use_sky_background:
		env.background_mode = Environment.BG_SKY
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color     = chapter.sky_top_color
		sky_mat.sky_horizon_color = chapter.sky_horizon_color
		sky_mat.ground_bottom_color = chapter.sky_top_color
		var sky := Sky.new()
		sky.sky_material = sky_mat
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	else:
		env.background_mode  = Environment.BG_COLOR
		env.background_color = chapter.background_color
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR

	env.ambient_light_color  = chapter.ambient_light_color
	env.ambient_light_energy = chapter.ambient_light_energy

	# ── トーンマッピング ──
	env.tonemap_mode = chapter.tonemap_mode

	# ── SSAO / SSIL / SDFGI (Forward Plus) ──
	env.ssao_enabled  = chapter.ssao_enabled
	env.ssil_enabled  = chapter.ssil_enabled
	env.sdfgi_enabled = chapter.sdfgi_enabled

	# ── フォグ ──
	env.fog_enabled = chapter.fog_enabled
	if chapter.fog_enabled:
		env.fog_density            = chapter.fog_density
		env.fog_light_color        = chapter.fog_light_color
		env.fog_light_energy       = 0.0
		env.fog_aerial_perspective = chapter.fog_aerial_perspective

	# ── ボリュメトリックフォグ (Forward Plus) ──
	env.volumetric_fog_enabled = chapter.volumetric_fog_enabled
	if chapter.volumetric_fog_enabled:
		env.volumetric_fog_density = chapter.volumetric_fog_density

	$DirectionalLight3D.light_energy = chapter.directional_light_energy

	# ── VHS オーバーレイ ──
	if chapter.vhs_overlay:
		_setup_vhs_overlay()


# ──────────────────────────────────────────────
# VHS オーバーレイ
# ──────────────────────────────────────────────

var _vhs_layer : CanvasLayer = null

func _setup_vhs_overlay() -> void:
	if _vhs_layer:
		return
	var shader := load("res://shaders/vhs_noise.gdshader") as Shader
	if not shader:
		return
	_vhs_layer = CanvasLayer.new()
	_vhs_layer.layer = 1   # 3Dビューの上、HUD(2)の下
	add_child(_vhs_layer)
	var rect := ColorRect.new()
	rect.anchor_right  = 1.0
	rect.anchor_bottom = 1.0
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("shake_intensity", 0.005)
	mat.set_shader_parameter("noise_intensity", 0.08)
	rect.material = mat
	_vhs_layer.add_child(rect)


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
	var chapter := GameManager.current_chapter
	var loc : String = chapter.location_text if chapter else "深夜配信"
	var dt  : String = chapter.date_text if chapter else "2026/02/24  23:47"
	var s := "\n\n\n"
	s += "[center][color=#ff2222][font_size=42][b]● REC[/b][/font_size][/color][/center]\n\n"
	s += "[center][color=#888888][font_size=16]%s[/font_size][/color][/center]\n" % dt
	s += "[center][color=#666666][font_size=15]%s[/font_size][/color][/center]\n" % loc
	return s


# ──────────────────────────────────────────────
# イベントハンドラ
# ──────────────────────────────────────────────

func _on_player_moved() -> void:
	hud.trigger_chat_event("moved")


var _ghosts_awakened : bool = false

func _on_item_for_ghost_awaken(count: int, _total: int) -> void:
	if _ghosts_awakened or count < 2:
		return
	_ghosts_awakened = true
	# VHS2個目取得 → ゴーストが姿を現して動き出す
	hud.show_monologue("…なんだ？　空気が変わった気がする…")
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		ghost.visible = true
		ghost.modulate = Color(1, 1, 1, 0) if ghost.has_method("set") else Color.WHITE
		ghost.process_mode = Node.PROCESS_MODE_INHERIT
		# 3Dノードは modulate が無いので _ghost_body のフェードで対応
		_fade_in_ghost(ghost)
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(hud):
		hud.hide_monologue()


func _fade_in_ghost(ghost: Node) -> void:
	# Ghost (CharacterBody3D) の GhostBody を透明→不透明にフェードイン
	var body : Node3D = ghost.get_node_or_null("GhostBody")
	if not body:
		return
	# 全 MeshInstance3D のマテリアルを透明開始 → フェードイン
	var meshes : Array[MeshInstance3D] = []
	_collect_meshes(body, meshes)
	for mi in meshes:
		var mat := mi.material_override
		if mat is StandardMaterial3D:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.0
	# GhostLight も暗くしておく
	var light : OmniLight3D = ghost.get_node_or_null("GhostLight") as OmniLight3D
	var orig_energy := light.light_energy if light else 0.8
	if light:
		light.light_energy = 0.0
	# 2秒かけてフェードイン
	var tw := create_tween()
	tw.set_parallel(true)
	for mi in meshes:
		var mat := mi.material_override
		if mat is StandardMaterial3D:
			tw.tween_property(mat, "albedo_color:a", 1.0, 2.0)
	if light:
		tw.tween_property(light, "light_energy", orig_energy, 2.0)
	await tw.finished
	# フェード完了後にtransparencyを無効化（パフォーマンス回復）
	for mi in meshes:
		var mat := mi.material_override
		if mat is StandardMaterial3D:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED


func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, out)


func _on_ghost_spotted() -> void:
	hud.trigger_chat_event("ghost_spotted")
	ScenarioManager.trigger("ghost_spotted")


func _on_ghost_lost() -> void:
	hud.trigger_chat_event("ghost_lost")


func _show_caught() -> void:
	# デバッグ: 自動リスタートは _DEBUG_AUTO_RESTART = true で有効
	const _DEBUG_AUTO_RESTART := false
	if _DEBUG_AUTO_RESTART:
		await get_tree().create_timer(1.5).timeout
		GameManager.restart()
		return
	_close_inventory()
	caught_label.visible  = true
	win_label.visible     = false
	sub_label.text        = "カメラの電源が切れた..."
	overlay_layer.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _show_win() -> void:
	# デバッグ: 自動リスタートは _DEBUG_AUTO_RESTART = true で有効
	const _DEBUG_AUTO_RESTART := false
	if _DEBUG_AUTO_RESTART:
		await get_tree().create_timer(1.0).timeout
		GameManager.restart()
		return
	_close_inventory()

	# 最終チャプター（CP5）ならトゥルーエンディング演出へ
	var chapter := GameManager.current_chapter
	if chapter and chapter.get("next_chapter_id") == "":
		await _show_true_ending()
		return

	caught_label.visible  = false
	win_label.visible     = true
	sub_label.text        = "証拠映像を持ち帰った。"
	overlay_layer.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _show_true_ending() -> void:
	## CP5 エンディング — ending_route に応じた演出
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player.process_mode = Node.PROCESS_MODE_DISABLED

	# 画面を暗転（CanvasLayer には modulate がないので子の Overlay を使う）
	overlay_ctrl.modulate.a = 0.0
	overlay_layer.visible = true
	caught_label.visible = false
	win_label.visible    = false
	var tw := create_tween()
	tw.tween_property(overlay_ctrl, "modulate:a", 1.0, 1.5)
	await tw.finished

	match GameManager.ending_route:
		0:  # NORMAL END: 夢の代償
			win_label.visible = true
			win_label.text    = "NORMAL END"
			win_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
			sub_label.text    = "夢の代償 — 赤い糸は、まだ首に巻きついている"
		1:  # TRUE END: 配信停止
			win_label.visible = true
			win_label.text    = "TRUE END"
			win_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
			sub_label.text    = "配信停止 — 誰にも見られない。それが、いちばん安全だった"
		2:  # BAD END: 永遠のバズり
			win_label.visible = true
			win_label.text    = "BAD END"
			win_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
			sub_label.text    = "永遠のバズり — 配信は、まだ続いている"
		_:  # フォールバック（未選択）
			win_label.visible = true
			win_label.text    = "END"
			win_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			sub_label.text    = ""

	await get_tree().create_timer(5.0).timeout

	# フェードアウト → タイトルへ
	tw = create_tween()
	tw.tween_property(overlay_ctrl, "modulate:a", 0.0, 2.0)
	await tw.finished
	GameManager.restart()


func _close_inventory() -> void:
	var inv_ui = $InventoryLayer/InventoryUI
	if inv_ui and inv_ui.is_open():
		inv_ui.close_inventory()


func _on_player_hit(count: int) -> void:
	## ゴーストに当たった時のリアクション（3回目は trigger_caught に移行）
	hud.trigger_chat_event("ghost_spotted")
	match count:
		1:
			hud.show_monologue("なっ…なんだこの人形は！？動いてる！？逃げろ！！")
			await get_tree().create_timer(2.8).timeout
			hud.hide_monologue()
			hud.show_monologue("…大丈夫。まだ大丈夫。あと2回は耐えられる")
			await get_tree().create_timer(2.0).timeout
			hud.hide_monologue()
		2:
			hud.show_monologue("また来た！！もう一回当たったら終わりだ！！")
			await get_tree().create_timer(2.5).timeout
			hud.hide_monologue()


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
	dank_sv.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
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
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))

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


# ════════════════════════════════════════════════════════════════
# デバッグ: チャプタースキップ（F1〜F5）
# ════════════════════════════════════════════════════════════════

func _setup_debug_ui() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 100  # 全 UI の最前面
	add_child(cl)

	_debug_label = Label.new()
	_debug_label.add_theme_font_size_override("font_size", 13)
	_debug_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.1, 0.8))
	_debug_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_debug_label.add_theme_constant_override("shadow_offset_x", 1)
	_debug_label.add_theme_constant_override("shadow_offset_y", 1)
	_debug_label.position = Vector2(8, 8)
	cl.add_child(_debug_label)
	_refresh_debug_label()


func _refresh_debug_label() -> void:
	if not is_instance_valid(_debug_label):
		return
	var ch  := GameManager.current_chapter
	var idx : int    = GameManager.chapter_index + 1
	var cname: String = ch.chapter_name if ch else "?"
	var free_str := " | [F9] 自由移動: ON ✓" if GameManager.debug_free_move else " | [F9] 自由移動"
	var skip_str := "  F1=入口  F2=屋敷  F3=倉庫  F4=神社  F5=脱出" if _DEBUG_CHAPTER_SKIP else ""
	_debug_label.text = "【DEBUG】CP%d: %s%s%s" % [idx, cname, free_str, skip_str]


func _debug_skip_to_chapter(idx: int) -> void:
	GameManager.state           = GameManager.State.PLAYING
	GameManager.items_found     = 0
	GameManager.hit_count       = 0
	GameManager._hit_invincible = false
	GameManager.load_chapter(idx)
	get_tree().reload_current_scene()
