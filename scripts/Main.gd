extends Node3D

const EntranceDirectorScript := preload("res://scripts/EntranceDirector.gd")
const EndingPlayerScript := preload("res://scripts/EndingPlayer.gd")

# ── 弾幕レイヤー定数（YouTubeChrome と同じ座標系）──────────────
const _DANK_VIDEO_W   = 940
const _DANK_TOP_H     = 48
const _DANK_VIDEO_BOT = 612
const _DANK_ROWS      = 7
const _DANK_ROW_H     = 44

# 演出終了後に自動で次チャプターへ進むチャプターID一覧（CP2・CP3は手動＝プレイアブル）
const AUTO_PROGRESS_CHAPTERS : Array[String] = [
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
	# 前チャプターのEntranceDirectorが残したCanvasLayerを掃除
	_cleanup_orphan_layers()
	# プレイヤーをイントロ中は操作無効（ESC等は効くようにDISABLEDにしない）
	player.input_disabled = true
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

	# CP2: .tresがGodotエディタに上書きされるためコードで強制設定
	if chapter.chapter_id == "ch02_mura_tansaku":
		chapter.stage_scene_path = "res://scenes/KiriharaVillageMap/VillageMap.tscn"
		chapter.player_spawn = Vector3(0.0, 1.0, 7.5)
		var vhs_positions := PackedVector3Array()
		vhs_positions.append(Vector3(-24.25, 1, -11.25))
		chapter.item_positions = vhs_positions
		chapter.exit_position = Vector3(0.25, 1.5, 17.5)

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

	# ゴースト初期化
	var cp2_immediate_ghost : bool = chapter.chapter_id == "ch02_mura_tansaku"
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		ghost.ghost_spotted_player.connect(_on_ghost_spotted)
		ghost.ghost_lost_player.connect(_on_ghost_lost)
		if cp2_immediate_ghost:
			ghost.process_mode = Node.PROCESS_MODE_INHERIT
			ghost.visible = true
		else:
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

	# 廃村入口: 初期状態を設定してスナップを防ぐ
	if chapter.chapter_id == "ch01_haison_iriguchi" and GameManager.start_section == 0:
		player.rotation.y      = 0.29   # バス停方向（-Z）を向く
		player.head.rotation.x = -0.06
		player.flashlight.visible  = false
		player.flashlight_on       = false

	# CP2 村の探索: 出口方向（+Z）を向く
	if chapter.chapter_id == "ch02_mura_tansaku":
		player.rotation.y = PI  # +Z方向（出口方面）を向く

	_setup_debug_ui()

	SoundManager.start_ambient(GameManager.chapter_index)

	# ローディング画面をフェードアウト
	await LoadingScreen.fade_out()

	# 廃村入口チャプターは自動演出シーケンスを実行して次チャプターへ進む
	var cur_chapter := GameManager.current_chapter
	if cur_chapter and cur_chapter.chapter_id == "ch01_haison_iriguchi":
		await _run_entrance_sequence()
		return

	# プレイアブルチャプター（CP2・CP3）はJSON演出なし → 即プレイ開始
	var is_cinematic : bool = cur_chapter != null and cur_chapter.chapter_id in AUTO_PROGRESS_CHAPTERS
	var is_playable : bool = cur_chapter != null and cur_chapter.chapter_id in ["ch02_haison_souko", "ch02_mura_tansaku"]

	if is_playable:
		# CP2廃倉庫: start_section==1 → CP2-2紙芝居へ直接遷移
		if cur_chapter.chapter_id == "ch02_haison_souko" and GameManager.start_section == 1:
			GameManager.start_section = 0
			await _play_souko_exit()
			GameManager.advance_to_next_chapter()
			return
		# プレイアブル: 即操作可能
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		player.input_disabled = false
		# CP2廃倉庫: 動きながらセリフ・コメントが流れるバックグラウンド演出
		if cur_chapter.chapter_id == "ch02_haison_souko":
			_run_chapter_opening_background(cur_chapter.chapter_id)
	elif cur_chapter:
		# シネマティック: JSON演出を実行
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

	# プレイアブルチャプター: 操作可能にしてゲーム開始
	player.input_disabled = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	hud.play_monologue()

	# シナリオシステム（視聴者アンケート）は現在無効
	#ScenarioManager.scenario_triggered.connect(_on_scenario_triggered)
	#ScenarioManager.trigger("game_start")

	# ゴーストはVHS2個回収で有効化（_on_ghosts_awaken で処理）
	GameManager.item_collected.connect(_on_item_for_ghost_awaken)
	GameManager.item_collected.connect(_on_item_collected_warehouse)

	# CP2廃倉庫: ゴール到達時にv103,v104演出を挟んでから遷移
	if cur_chapter and cur_chapter.chapter_id == "ch02_haison_souko":
		stage_gen.exit_node.on_exit_callback = Callable(self, "_play_souko_exit")

	# ナビ矢印用: プレイヤー参照をHUDに渡す
	hud._player_ref = player


## シーン再ロード後に root 直下に残った孤立 CanvasLayer を削除
func _cleanup_orphan_layers() -> void:
	for child in get_tree().root.get_children():
		# Main（現在のシーン）とAutoload以外のCanvasLayerを削除
		if child is CanvasLayer and not child.is_in_group("autoload"):
			# Autoloadでないか確認（Autoloadはシーン再ロードでも残るべき）
			var is_autoload := false
			for al_name in ["GameManager", "ScenarioManager", "InventorySingleton", "SoundManager", "LoadingScreen"]:
				if child.name == al_name:
					is_autoload = true
					break
			if not is_autoload and child != get_tree().current_scene:
				push_warning("Main: removing orphan CanvasLayer: " + child.name)
				child.queue_free()


func _run_entrance_sequence() -> void:
	## 廃村入口: EntranceDirector に演出を委譲し、完了後に次チャプターへ進む
	var director: Node = EntranceDirectorScript.new()
	director.set("player", player)
	director.set("hud", hud)
	add_child(director)
	await director.run()
	director.cleanup()
	remove_child(director)
	director.queue_free()
	GameManager.advance_to_next_chapter()


func _run_chapter_opening_background(chapter_id: String) -> void:
	## プレイアブルチャプター用: セリフ・コメントをバックグラウンドで流す（操作を止めない）
	var path := "res://dialogue/%s.json" % chapter_id
	if not FileAccess.file_exists(path):
		return
	var director: Node = EntranceDirectorScript.new()
	director.set("player", player)
	director.set("hud", hud)
	add_child(director)
	await director.run_from_path(path)
	if is_instance_valid(director):
		director.cleanup()
		remove_child(director)
		director.queue_free()


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
	director.cleanup()
	remove_child(director)
	director.queue_free()


func _input(event: InputEvent) -> void:
	# ESC: マウスカーソル表示/トグル
	if event.is_action_pressed("ui_cancel"):
		if player.input_disabled:
			# シネマティック中は常にVISIBLEへ（トグルしない）
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			# プレイヤー操作中はトグル
			var mode := Input.get_mouse_mode()
			var new_mode := Input.MOUSE_MODE_VISIBLE if mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
			Input.set_mouse_mode(new_mode)
		get_viewport().set_input_as_handled()
		return

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
		player.input_disabled = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		player.input_disabled = true
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
	else:
		_remove_vhs_overlay()


# ──────────────────────────────────────────────
# VHS オーバーレイ
# ──────────────────────────────────────────────

var _vhs_layer : CanvasLayer = null
var _vhs_rect  : ColorRect   = null   # シェーダーパラメータ制御用

func _setup_vhs_overlay() -> void:
	if _vhs_layer:
		return
	var shader := load("res://shaders/vhs_noise.gdshader") as Shader
	if not shader:
		return
	_vhs_layer = CanvasLayer.new()
	_vhs_layer.layer = 1   # 3Dビューの上、HUD(2)の下
	add_child(_vhs_layer)
	_vhs_rect = ColorRect.new()
	_vhs_rect.anchor_right  = 1.0
	_vhs_rect.anchor_bottom = 1.0
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("shake_intensity", 0.005)
	mat.set_shader_parameter("noise_intensity", 0.08)
	_vhs_rect.material = mat
	_vhs_layer.add_child(_vhs_rect)


## VHSシェーダーパラメータを動的に設定（EntranceDirectorから呼ぶ）
func set_vhs_param(param_name: String, value: float) -> void:
	_ensure_vhs_overlay()
	if is_instance_valid(_vhs_rect) and _vhs_rect.material:
		(_vhs_rect.material as ShaderMaterial).set_shader_parameter(param_name, value)


## VHSシェーダーパラメータをTweenでアニメーション
func tween_vhs_param(param_name: String, target: float, dur: float) -> Tween:
	_ensure_vhs_overlay()
	if not is_instance_valid(_vhs_rect) or not _vhs_rect.material:
		return null
	var mat := _vhs_rect.material as ShaderMaterial
	var current_val : float = float(mat.get_shader_parameter(param_name))
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter(param_name, v),
		current_val, target, dur)
	return tw


func _ensure_vhs_overlay() -> void:
	if not _vhs_layer:
		_setup_vhs_overlay()


func _remove_vhs_overlay() -> void:
	if is_instance_valid(_vhs_layer):
		_vhs_layer.queue_free()
		_vhs_layer = null
		_vhs_rect = null


# ──────────────────────────────────────────────
# 魚眼レンズオーバーレイ
# ──────────────────────────────────────────────

var _fisheye_layer : CanvasLayer = null
var _fisheye_rect  : ColorRect   = null

func _setup_fisheye_overlay() -> void:
	if _fisheye_layer:
		return
	var shader := load("res://shaders/fisheye.gdshader") as Shader
	if not shader:
		return
	_fisheye_layer = CanvasLayer.new()
	_fisheye_layer.layer = 3   # VHS(1)・HUD(2)の上
	add_child(_fisheye_layer)
	_fisheye_rect = ColorRect.new()
	_fisheye_rect.anchor_right  = 1.0
	_fisheye_rect.anchor_bottom = 1.0
	_fisheye_rect.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_fisheye_rect.material = mat
	_fisheye_layer.add_child(_fisheye_rect)


func _ensure_fisheye_overlay() -> void:
	if not _fisheye_layer:
		_setup_fisheye_overlay()


func set_fisheye_param(param_name: String, value: float) -> void:
	_ensure_fisheye_overlay()
	if is_instance_valid(_fisheye_rect) and _fisheye_rect.material:
		(_fisheye_rect.material as ShaderMaterial).set_shader_parameter(param_name, value)


func tween_fisheye_param(param_name: String, target: float, dur: float) -> Tween:
	_ensure_fisheye_overlay()
	if not is_instance_valid(_fisheye_rect) or not _fisheye_rect.material:
		return null
	var mat := _fisheye_rect.material as ShaderMaterial
	var current_val : float = float(mat.get_shader_parameter(param_name))
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter(param_name, v),
		current_val, target, dur)
	return tw


func remove_fisheye_overlay() -> void:
	if is_instance_valid(_fisheye_layer):
		_fisheye_layer.queue_free()
		_fisheye_layer = null
		_fisheye_rect  = null


# ──────────────────────────────────────────────
# CRT ブラウン管モニターオーバーレイ
# ──────────────────────────────────────────────

var _crt_layer : CanvasLayer = null
var _crt_rect  : ColorRect   = null

func _setup_crt_overlay() -> void:
	if _crt_layer:
		return
	var shader := load("res://shaders/crt_monitor.gdshader") as Shader
	if not shader:
		return
	_crt_layer = CanvasLayer.new()
	_crt_layer.layer = 4   # VHS(1)・HUD(2)・Fisheye(3)の上
	add_child(_crt_layer)
	_crt_rect = ColorRect.new()
	_crt_rect.anchor_right  = 1.0
	_crt_rect.anchor_bottom = 1.0
	_crt_rect.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("intensity", 0.0)
	_crt_rect.material = mat
	_crt_layer.add_child(_crt_rect)


func _ensure_crt_overlay() -> void:
	if not _crt_layer:
		_setup_crt_overlay()


func set_crt_param(param_name: String, value: float) -> void:
	_ensure_crt_overlay()
	if is_instance_valid(_crt_rect) and _crt_rect.material:
		(_crt_rect.material as ShaderMaterial).set_shader_parameter(param_name, value)


func tween_crt_param(param_name: String, target: float, dur: float) -> Tween:
	_ensure_crt_overlay()
	if not is_instance_valid(_crt_rect) or not _crt_rect.material:
		return null
	var mat := _crt_rect.material as ShaderMaterial
	var current_val : float = float(mat.get_shader_parameter(param_name))
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter(param_name, v),
		current_val, target, dur)
	return tw


func remove_crt_overlay() -> void:
	if is_instance_valid(_crt_layer):
		_crt_layer.queue_free()
		_crt_layer = null
		_crt_rect  = null


## フォグ密度を動的変更
func tween_fog(density: float, dur: float, color: Color = Color(-1, 0, 0)) -> Tween:
	var we := $WorldEnvironment as WorldEnvironment
	if not we or not we.environment:
		return null
	var env := we.environment
	env.fog_enabled = true
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v: float) -> void: env.fog_density = v,
		env.fog_density, density, dur)
	if color.r >= 0.0:
		tw.tween_method(func(c: Color) -> void: env.fog_light_color = c,
			env.fog_light_color, color, dur)
	return tw


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
	if _intro_skip:
		tw.kill()
		intro_root.modulate.a = 0.0
	else:
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

func _on_item_for_ghost_awaken(count: int, total: int) -> void:
	if _ghosts_awakened:
		return
	if count < total or total <= 0:
		return
	_ghosts_awakened = true
	GameManager.ghost_grace = true
	# ゴーストをプレイヤーから離れた位置にテレポートしてから有効化
	var player_pos := player.global_position
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		var gpos : Vector3 = ghost.global_position
		var dist : float = gpos.distance_to(player_pos)
		if dist < 15.0:
			var away_dir : Vector3 = (gpos - player_pos)
			away_dir.y = 0
			if away_dir.length() < 0.1:
				away_dir = Vector3(-1, 0, -1)
			ghost.global_position = player_pos + away_dir.normalized() * 18.0
			ghost.global_position.y = gpos.y
		ghost.visible = true
		ghost.process_mode = Node.PROCESS_MODE_INHERIT
		_fade_in_ghost(ghost)
	# ghost_grace はみゆき遭遇演出（_run_escape_nav_sequence）終了後に解除


func _fade_in_ghost(ghost: Node) -> void:
	# Ghost の GhostBody を dissolve=1→0 でフェードイン
	var body : Node3D = ghost.get_node_or_null("GhostBody")
	if not body:
		return
	var meshes : Array[MeshInstance3D] = []
	_collect_meshes(body, meshes)
	# dissolve=1（完全透明）から開始
	for mi in meshes:
		var mat := mi.material_override
		if mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("dissolve", 1.0)
		elif mat is StandardMaterial3D:
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
		if mat is ShaderMaterial:
			tw.tween_method(func(v: float) -> void:
				(mat as ShaderMaterial).set_shader_parameter("dissolve", v)
			, 1.0, 0.0, 2.0)
		elif mat is StandardMaterial3D:
			tw.tween_property(mat, "albedo_color:a", 1.0, 2.0)
	if light:
		tw.tween_property(light, "light_energy", orig_energy, 2.0)
	await tw.finished
	for mi in meshes:
		var mat := mi.material_override
		if mat is StandardMaterial3D:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED


func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, out)


var _ghost_alert_shown := false

func _on_ghost_spotted() -> void:
	hud.trigger_chat_event("ghost_spotted")
	ScenarioManager.trigger("ghost_spotted")
	if not _ghost_alert_shown:
		_ghost_alert_shown = true
		_show_ghost_alert()


func _show_ghost_alert() -> void:
	## みゆき遭遇時のリッチなアラート演出（操作は止めない）
	SoundManager.play_sfx_file("metal/impactMetal_heavy_000.ogg")
	player.start_camera_shake(0.8, 0.5)

	# HUDのScareFlash（赤）
	if is_instance_valid(hud):
		hud._do_scare_flash(Color(0.8, 0.0, 0.0))

	var vp_size := get_viewport().get_visible_rect().size
	var alert_canvas := CanvasLayer.new()
	alert_canvas.layer = 150
	get_tree().root.add_child(alert_canvas)

	# ── 赤い枠フラッシュ（画面端が赤く光る） ──
	var border_top := ColorRect.new()
	border_top.size = Vector2(vp_size.x, 6)
	border_top.position = Vector2.ZERO
	border_top.color = Color(0.9, 0.1, 0.0, 0.9)
	border_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_canvas.add_child(border_top)

	var border_bot := ColorRect.new()
	border_bot.size = Vector2(vp_size.x, 6)
	border_bot.position = Vector2(0, vp_size.y - 6)
	border_bot.color = Color(0.9, 0.1, 0.0, 0.9)
	border_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_canvas.add_child(border_bot)

	var border_left := ColorRect.new()
	border_left.size = Vector2(6, vp_size.y)
	border_left.color = Color(0.9, 0.1, 0.0, 0.9)
	border_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_canvas.add_child(border_left)

	var border_right := ColorRect.new()
	border_right.size = Vector2(6, vp_size.y)
	border_right.position = Vector2(vp_size.x - 6, 0)
	border_right.color = Color(0.9, 0.1, 0.0, 0.9)
	border_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_canvas.add_child(border_right)

	# ── 赤オーバーレイ（画面全体が一瞬赤く）──
	var red_flash := ColorRect.new()
	red_flash.size = vp_size
	red_flash.color = Color(0.5, 0.0, 0.0, 0.3)
	red_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_canvas.add_child(red_flash)

	# ── 警告テキスト（画面中央・巨大） ──
	var warn_lbl := Label.new()
	warn_lbl.text = "逃 げ ろ"
	warn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warn_lbl.size = vp_size
	warn_lbl.add_theme_font_size_override("font_size", 64)
	warn_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 0.0))
	warn_lbl.add_theme_color_override("font_shadow_color", Color(0.6, 0.0, 0.0, 0.9))
	warn_lbl.add_theme_constant_override("shadow_offset_x", 3)
	warn_lbl.add_theme_constant_override("shadow_offset_y", 3)
	warn_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_canvas.add_child(warn_lbl)

	# ── 三角警告アイコン（テキスト上） ──
	var icon_lbl := Label.new()
	icon_lbl.text = "⚠"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.size = Vector2(vp_size.x, 80)
	icon_lbl.position = Vector2(0, vp_size.y * 0.3)
	icon_lbl.add_theme_font_size_override("font_size", 52)
	icon_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0, 0.0))
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_canvas.add_child(icon_lbl)

	# ── アニメーション ──
	# テキスト: グリッチ点滅→表示→フェードアウト
	var tw := create_tween()
	tw.tween_property(warn_lbl, "theme_override_colors/font_color:a", 0.9, 0.03)
	tw.tween_property(warn_lbl, "theme_override_colors/font_color:a", 0.0, 0.03)
	tw.tween_property(warn_lbl, "theme_override_colors/font_color:a", 0.7, 0.03)
	tw.tween_property(warn_lbl, "theme_override_colors/font_color:a", 0.0, 0.04)
	tw.tween_property(warn_lbl, "theme_override_colors/font_color:a", 1.0, 0.1)
	tw.parallel().tween_property(icon_lbl, "theme_override_colors/font_color:a", 1.0, 0.15)

	# 赤フラッシュの点滅
	var tw_flash := create_tween().set_loops(3)
	tw_flash.tween_property(red_flash, "color:a", 0.35, 0.08)
	tw_flash.tween_property(red_flash, "color:a", 0.05, 0.12)

	await tw.finished

	# 1.2秒表示
	await get_tree().create_timer(1.2).timeout

	# フェードアウト
	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(warn_lbl, "theme_override_colors/font_color:a", 0.0, 0.4)
	tw_out.tween_property(icon_lbl, "theme_override_colors/font_color:a", 0.0, 0.4)
	tw_out.tween_property(red_flash, "color:a", 0.0, 0.5)
	tw_out.tween_property(border_top, "color:a", 0.0, 0.5)
	tw_out.tween_property(border_bot, "color:a", 0.0, 0.5)
	tw_out.tween_property(border_left, "color:a", 0.0, 0.5)
	tw_out.tween_property(border_right, "color:a", 0.0, 0.5)
	await tw_out.finished

	alert_canvas.queue_free()

	# ── 「逃げろ」後の入口→出口ナビ演出（CP2廃倉庫のみ） ──
	if GameManager.current_chapter and GameManager.current_chapter.chapter_id == "ch02_haison_souko":
		_run_escape_nav_sequence()


func _run_escape_nav_sequence() -> void:
	var voice_dir : String = "res://assets/audio/voice/ch02_souko/"
	GameManager.ghost_grace = true

	# みゆきに気づく
	SoundManager.play_voice(voice_dir + "v109.wav")
	hud.show_monologue("……急に空気が冷たくなった……？")
	await get_tree().create_timer(2.5).timeout

	if is_instance_valid(hud):
		SoundManager.play_voice(voice_dir + "v110.wav")
		hud.show_monologue("え……みゆき、ちゃん……？　なんで動いて……")
	await get_tree().create_timer(3.0).timeout

	if is_instance_valid(hud):
		SoundManager.play_voice(voice_dir + "v111.wav")
		hud.show_monologue("こっち見てる……！　うそでしょ、来ないで！！")
	await get_tree().create_timer(3.5).timeout
	if is_instance_valid(hud):
		hud.hide_monologue()

	await get_tree().create_timer(2.0).timeout

	# セリフ: 入口から逃げようとする
	if is_instance_valid(hud):
		SoundManager.play_voice(voice_dir + "v112.wav")
		hud.show_monologue("入口！　入口から逃げないと……！")
	await get_tree().create_timer(3.0).timeout

	# セリフ: 入口が塞がっている
	if is_instance_valid(hud):
		SoundManager.play_voice(voice_dir + "v113.wav")
		hud.show_monologue("嘘……入口が塞がってる！？　来た道がない！！")
	await get_tree().create_timer(4.0).timeout

	# 出口ナビ矢印（緑）→ 最初から出口を指して一度だけ表示
	var exit_pos : Vector3 = GameManager.current_chapter.exit_position if GameManager.current_chapter else Vector3(23, 1.5, 15)
	if is_instance_valid(hud):
		SoundManager.play_voice(voice_dir + "v114.wav")
		hud.show_monologue("別の出口を探さなきゃ……！！")
		hud.start_nav(exit_pos, "EXIT", Color(0.2, 0.85, 0.3), player)
	await get_tree().create_timer(2.5).timeout

	if is_instance_valid(hud):
		hud.hide_monologue()
	await get_tree().create_timer(3.0).timeout
	GameManager.ghost_grace = false


func _on_ghost_lost() -> void:
	hud.trigger_chat_event("ghost_lost")


func _on_item_collected_warehouse(count: int, total: int) -> void:
	## 廃倉庫チャプター専用：VHS発見時
	if not (GameManager.current_chapter and GameManager.current_chapter.chapter_id == "ch02_haison_souko"):
		return
	# ポラロイド演出を先に完了させてからセリフを流す
	await _show_item_acquired(count, total)
	# 最初の1個だけセリフ演出を流す（ポラロイド後）
	if count == 1:
		_run_chapter_opening_background("ch02_haison_souko_found")
	# 全VHS回収で脱出演出
	if count >= total and total > 0:
		hud.show_monologue("全部見つけた……！ ここを出ないと！")
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(hud):
			hud.hide_monologue()


func _show_item_acquired(count: int, total: int) -> void:
	## VHS入手 — ポラロイド風演出（1秒停止・画面中央）
	player.input_disabled = true
	SoundManager.play_sfx_file("metal/impactMetal_heavy_001.ogg")

	var vp_size := get_viewport().get_visible_rect().size
	var canvas := CanvasLayer.new()
	canvas.layer = 140
	get_tree().root.add_child(canvas)

	# ── 背景暗幕 ──
	var dim := ColorRect.new()
	dim.size = vp_size
	dim.color = Color(0, 0, 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(dim)

	# ── ポラロイドカード ──
	var card_w : float = 260.0
	var card_h : float = 340.0
	var card_x : float = (vp_size.x - card_w) * 0.5
	var card_y : float = (vp_size.y - card_h) * 0.5

	# ポラロイド内の影（立体感、先にadd）
	var shadow := ColorRect.new()
	shadow.size = Vector2(card_w, card_h)
	shadow.position = Vector2(card_x + 4, card_y + 44.0)
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.modulate.a = 0.0
	canvas.add_child(shadow)

	# 白枠（ポラロイド風）
	var polaroid := ColorRect.new()
	polaroid.size = Vector2(card_w, card_h)
	polaroid.position = Vector2(card_x, card_y + 40.0)
	polaroid.color = Color(0.92, 0.90, 0.85, 1.0)
	polaroid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	polaroid.modulate.a = 0.0
	polaroid.pivot_offset = Vector2(card_w * 0.5, card_h * 0.5)
	canvas.add_child(polaroid)

	# VHS画像（ポラロイド内の写真部分）
	var img_margin : float = 18.0
	var img_w : float = card_w - img_margin * 2
	var img_h : float = 170.0
	var vhs_tex := load("res://assets/textures/item_vhs.jpg") as Texture2D
	if vhs_tex:
		var img_rect := TextureRect.new()
		img_rect.texture = vhs_tex
		img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img_rect.custom_minimum_size = Vector2(img_w, img_h)
		img_rect.size = Vector2(img_w, img_h)
		img_rect.position = Vector2(img_margin, img_margin)
		img_rect.clip_contents = true
		img_rect.modulate = Color(0.95, 0.9, 0.85, 1.0)
		img_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		polaroid.add_child(img_rect)

	# 「証拠VHS」タイトル（手書き風）
	var title_lbl := Label.new()
	title_lbl.text = "証拠VHS"
	title_lbl.size = Vector2(card_w, 36)
	title_lbl.position = Vector2(0, img_h + img_margin + 12)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1, 1.0))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	polaroid.add_child(title_lbl)

	# 「1994_10_記録」サブテキスト
	var sub_lbl := Label.new()
	sub_lbl.text = "1994_10_記録"
	sub_lbl.size = Vector2(card_w, 24)
	sub_lbl.position = Vector2(0, img_h + img_margin + 44)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 14)
	sub_lbl.add_theme_color_override("font_color", Color(0.35, 0.3, 0.28, 1.0))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	polaroid.add_child(sub_lbl)

	# カウンター
	var count_lbl := Label.new()
	count_lbl.text = "%d / %d" % [count, total]
	count_lbl.size = Vector2(card_w, 28)
	count_lbl.position = Vector2(0, card_h - 38)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 18)
	count_lbl.add_theme_color_override("font_color", Color(0.5, 0.4, 0.35, 1.0))
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	polaroid.add_child(count_lbl)

	# プログレスドット（●○○○○）
	var dots_lbl := Label.new()
	var dots_text := ""
	for i in range(total):
		dots_text += "●  " if i < count else "○  "
	dots_lbl.text = dots_text.strip_edges()
	dots_lbl.size = Vector2(card_w, 24)
	dots_lbl.position = Vector2(0, card_h - 18)
	dots_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots_lbl.add_theme_font_size_override("font_size", 12)
	dots_lbl.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4, 1.0))
	dots_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	polaroid.add_child(dots_lbl)

	# ── 画面上部「VHS を入手」テキスト（ポラロイドの外）──
	var header := Label.new()
	header.text = "VHS を入手"
	header.size = Vector2(vp_size.x, 40)
	header.position = Vector2(0, card_y - 50)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(1.0, 0.93, 0.7, 0.0))
	header.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	header.add_theme_constant_override("shadow_offset_x", 2)
	header.add_theme_constant_override("shadow_offset_y", 2)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(header)

	# ══════════════════════════════════════════════
	#  アニメーション
	# ══════════════════════════════════════════════

	# Phase 1: 暗幕 + ポラロイドがスッと現れる（微回転付き）
	polaroid.rotation_degrees = randf_range(-4.0, 4.0)  # 微妙に傾いてるのがポラロイドっぽい
	var tw_in := create_tween().set_parallel(true)
	tw_in.tween_property(dim, "color:a", 0.55, 0.25)
	tw_in.tween_property(polaroid, "modulate:a", 1.0, 0.3)
	tw_in.tween_property(polaroid, "position:y", card_y, 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(shadow, "modulate:a", 1.0, 0.3)
	tw_in.tween_property(shadow, "position:y", card_y + 4.0, 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(header, "theme_override_colors/font_color:a", 1.0, 0.3).set_delay(0.15)
	await tw_in.finished

	# Phase 2: カメラのシャッター音風SFX
	SoundManager.play_sfx_file("metal/impactMetal_heavy_000.ogg")

	# 白フラッシュ（カメラのフラッシュ風）
	var flash := ColorRect.new()
	flash.size = vp_size
	flash.color = Color(1, 1, 1, 0.4)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(flash)
	var tw_flash := create_tween()
	tw_flash.tween_property(flash, "color:a", 0.0, 0.3)
	await tw_flash.finished
	flash.queue_free()

	# Phase 3: 1秒停止（じっくり見せる）
	await get_tree().create_timer(1.0).timeout

	# 全回収時: ポラロイドが金色に光る
	if count >= total and total > 0:
		var tw_glow := create_tween().set_loops(3)
		tw_glow.tween_property(polaroid, "modulate", Color(1.2, 1.1, 0.8, 1.0), 0.12)
		tw_glow.tween_property(polaroid, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
		await tw_glow.finished

	# Phase 4: フェードアウト（上に浮いて消える）
	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(dim, "color:a", 0.0, 0.35)
	tw_out.tween_property(polaroid, "modulate:a", 0.0, 0.3)
	tw_out.tween_property(polaroid, "position:y", card_y - 30.0, 0.35)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw_out.tween_property(polaroid, "scale", Vector2(0.9, 0.9), 0.35)
	tw_out.tween_property(shadow, "modulate:a", 0.0, 0.3)
	tw_out.tween_property(header, "theme_override_colors/font_color:a", 0.0, 0.25)
	await tw_out.finished

	canvas.queue_free()
	player.input_disabled = false


func _play_souko_exit() -> void:
	## CP2廃倉庫ゴール到達時の演出（v103, v104）
	player.input_disabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await _run_chapter_opening("ch02_haison_souko_exit")
	player.input_disabled = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _show_caught() -> void:
	_close_inventory()
	player.input_disabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# ── ゲーム世界を完全停止（音漏れ・3D描画を遮断）──
	SoundManager.stop_all()
	# YouTubeChrome・HUD・ScenarioUIのプロセスを止める
	var chrome_node := get_node_or_null("YouTubeChrome")
	if chrome_node:
		chrome_node.process_mode = Node.PROCESS_MODE_DISABLED
		chrome_node.visible = false
	if is_instance_valid(hud):
		hud.visible = false
	if is_instance_valid(scenario_ui):
		scenario_ui.visible = false
	# ゴースト・プレイヤーのプロセス停止
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		ghost.process_mode = Node.PROCESS_MODE_DISABLED
	player.process_mode = Node.PROCESS_MODE_DISABLED
	# 3Dカメラの描画を止める（カメラを無効化）
	var cam := player.get_node_or_null("Head/Camera3D")
	if cam:
		cam.current = false

	var vp_size := get_viewport().get_visible_rect().size

	# ══════════════════════════════════════════════════════════
	#  Phase 0: 捕獲ショック（おばけ顔アップ演出）
	# ══════════════════════════════════════════════════════════
	SoundManager.play_sfx_file("metal/impactMetal_heavy_000.ogg")
	await get_tree().create_timer(0.15).timeout

	SoundManager.play_sfx_file("monster/Monster Growl (3).mp3")
	await get_tree().create_timer(0.25).timeout

	# ── おばけ顔レイヤー構築 ──
	var face_canvas := CanvasLayer.new()
	face_canvas.layer = 199
	get_tree().root.add_child(face_canvas)

	# 背景: 真っ黒
	var bg_black := ColorRect.new()
	bg_black.size = vp_size
	bg_black.color = Color(0, 0, 0, 1)
	bg_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_canvas.add_child(bg_black)

	# おばけ顔画像
	var face_tex : Texture2D = load("res://assets/textures/ghost_face.jpg")
	var face_rect := TextureRect.new()
	face_rect.texture = face_tex
	face_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face_rect.size = vp_size
	face_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_rect.modulate = Color(0.7, 0.5, 0.6, 0)
	face_rect.pivot_offset = vp_size * 0.5
	face_canvas.add_child(face_rect)

	# 赤オーバーレイ（恐怖感増幅）
	var red_over := ColorRect.new()
	red_over.size = vp_size
	red_over.color = Color(0.4, 0, 0, 0)
	red_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_canvas.add_child(red_over)

	# スキャンライン（縞模様オーバーレイ）
	var scanlines := ColorRect.new()
	scanlines.size = vp_size
	scanlines.color = Color(0, 0, 0, 0.15)
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_canvas.add_child(scanlines)

	# ── Phase 0a: 赤フラッシュ数回（顔はまだ見えない）──
	for i in range(3):
		if not is_inside_tree(): return
		red_over.color = Color(0.6 + randf() * 0.3, 0, 0, 0.6)
		SoundManager.play_sfx_file("metal/impactMetal_heavy_00%d.ogg" % (i % 3))
		player.start_camera_shake(1.8, 0.12)
		await get_tree().create_timer(0.07).timeout
		red_over.color.a = 0.0
		await get_tree().create_timer(0.08).timeout

	# ── Phase 0b: おばけ顔ドーン！（グリッチ点滅）──
	SoundManager.play_sfx_file("metal/impactMetal_heavy_002.ogg")
	player.start_camera_shake(3.0, 0.4)

	# グリッチ点滅: 顔が一瞬映って消える×3
	for j in range(3):
		if not is_inside_tree(): return
		face_rect.modulate.a = 0.6 + randf() * 0.4
		face_rect.position = Vector2(randf_range(-15, 15), randf_range(-10, 10))
		red_over.color.a = 0.2 + randf() * 0.15
		await get_tree().create_timer(0.04).timeout
		face_rect.modulate.a = 0.0
		face_rect.position = Vector2.ZERO
		await get_tree().create_timer(0.06 - float(j) * 0.01).timeout

	# ── Phase 0c: 顔が完全に表示（ネガポジ反転＋ズームイン）──
	face_rect.modulate = Color(0.8, 0.6, 0.7, 1.0)
	face_rect.position = Vector2.ZERO
	red_over.color = Color(0.3, 0, 0, 0.25)
	SoundManager.play_sfx_file("monster/Monster Growl (3).mp3")

	# ズームイン + 微振動しながら1.5秒表示
	var tw_zoom := create_tween()
	tw_zoom.tween_property(face_rect, "scale", Vector2(1.3, 1.3), 1.5).set_ease(Tween.EASE_IN)

	var face_t : float = 0.0
	while face_t < 1.5:
		if not is_inside_tree(): return
		var dt : float = get_process_delta_time()
		face_t += dt
		# 微振動
		face_rect.position = Vector2(randf_range(-4, 4), randf_range(-3, 3))
		# 色揺らぎ（不安感）
		var r : float = 0.7 + sin(face_t * 12.0) * 0.15
		var g : float = 0.5 + sin(face_t * 8.0) * 0.1
		face_rect.modulate = Color(r, g, 0.65, 1.0)
		# 赤オーバーレイ脈動
		red_over.color.a = 0.2 + sin(face_t * 6.0) * 0.1
		await get_tree().process_frame

	tw_zoom.kill()

	# ── Phase 0d: ネガポジ反転フラッシュ → 暗転 ──
	SoundManager.play_sfx_file("metal/impactMetal_heavy_001.ogg")
	# 一瞬白飛び
	face_rect.modulate = Color(2.0, 2.0, 2.0, 1.0)
	red_over.color = Color(1, 1, 1, 0.5)
	await get_tree().create_timer(0.06).timeout
	# ネガポジ反転風（暗くて青）
	face_rect.modulate = Color(0.2, 0.3, 0.5, 1.0)
	red_over.color = Color(0, 0, 0.1, 0.4)
	await get_tree().create_timer(0.08).timeout
	# もう一回白
	face_rect.modulate = Color(1.5, 1.2, 1.5, 0.8)
	await get_tree().create_timer(0.05).timeout

	# 暗転
	face_rect.modulate.a = 0.0
	red_over.color = Color(0, 0, 0, 0)
	bg_black.color = Color(0, 0, 0, 1)
	await get_tree().create_timer(0.6).timeout
	face_canvas.queue_free()

	# ══════════════════════════════════════════════════════════
	#  Phase 1: EndingPlayerで「永遠の配信」を再生
	# ══════════════════════════════════════════════════════════

	# バッドエンドデータ（直接定義 — JSONに入れるとCP3開始時に強制発動するため）
	var ending_title := "永遠の配信"
	var sections : Array = [
		{
			"title": "", "mood": "dark", "wait": 0.8,
			"lines": [
				{"text": "視聴者A: しゅっち？", "pause": 1.0},
				{"text": "配信民99: 映像止まったんだけど", "pause": 0.8},
				{"text": "ゆきんこ77: 回線落ちた？", "pause": 0.8},
				{"text": "まっちゃん: 画面真っ暗", "pause": 1.0},
			]
		},
		{
			"title": "", "mood": "fear",
			"image": "res://assets/textures/bad_end_eternal.jpg",
			"wait": 0.8,
			"lines": [
				{"text": "視聴者A: あ、映った", "pause": 0.8},
				{"text": "配信民99: しゅっち映ってるけど……動かなくない？", "pause": 1.0},
				{"text": "ゆきんこ77: 目が……こっち見てる", "pause": 1.0},
				{"text": "まっちゃん: なんで笑ってるの", "pause": 1.2},
				{"text": "配信民99: コメント読まないの初めてじゃね", "pause": 1.0},
				{"text": "まっちゃん: え……泣いてる？", "pause": 1.2},
				{"text": "ゆきんこ77: 「たすけて」って言ってない？", "pause": 1.2},
				{"text": "視聴者A: 配信閉じれないんだけど", "pause": 1.0},
				{"text": "配信民99: ブラウザ落ちない 何これ", "pause": 1.5},
			]
		},
		{
			"title": "", "mood": "fear",
			"image": "res://assets/textures/bad_end_eternal.jpg",
			"wait": 1.5,
			"lines": [
				{"text": "K: 止まらないよ", "pause": 2.5, "emphasis": true},
				{"text": "K: 望んだのは君だろう", "pause": 2.5, "emphasis": true},
				{"text": "K: 永遠に、見てもらえるよ", "pause": 3.0, "emphasis": true},
			]
		},
	]

	# EndingPlayerで再生
	var ep := CanvasLayer.new()
	ep.set_script(EndingPlayerScript)
	get_tree().root.add_child(ep)
	await ep.play(sections, ending_title)

	# 再生完了 → タイトルに戻るボタン
	await get_tree().create_timer(1.0).timeout

	var btn_canvas := CanvasLayer.new()
	btn_canvas.layer = 160
	get_tree().root.add_child(btn_canvas)

	var retry_btn := Button.new()
	retry_btn.text = "タイトルに戻る"
	retry_btn.add_theme_font_size_override("font_size", 18)
	retry_btn.size = Vector2(220, 44)
	retry_btn.position = Vector2((vp_size.x - 220) * 0.5, vp_size.y * 0.70)
	retry_btn.modulate.a = 0.0
	btn_canvas.add_child(retry_btn)

	var tw_btn := create_tween()
	tw_btn.tween_property(retry_btn, "modulate:a", 1.0, 0.5)
	await tw_btn.finished

	retry_btn.pressed.connect(func() -> void:
		await ep.fade_out(1.5)
		btn_canvas.queue_free()
		get_tree().change_scene_to_file("res://scenes/Opening.tscn")
	)


# ── バッドエンド補助関数 ──────────────────────────────────

func _format_number(n: int) -> String:
	var s := str(n)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result


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
	player.input_disabled = true

	# 画面を暗転（CanvasLayer には modulate がないので子の Overlay を使う）
	overlay_ctrl.modulate.a = 0.0
	overlay_layer.visible = true
	caught_label.visible = false
	win_label.visible    = false
	var tw := create_tween()
	tw.tween_property(overlay_ctrl, "modulate:a", 1.0, 1.5)
	await tw.finished

	match GameManager.ending_route:
		0:  # NORMAL END: 夢の保存（アーカイブ）
			win_label.visible = true
			win_label.text    = "NORMAL END"
			win_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
			sub_label.text    = "夢の保存 — まばたきは、もう必要ない"
		1:  # TRUE END: 承認欲求からのログアウト
			win_label.visible = true
			win_label.text    = "TRUE END"
			win_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
			sub_label.text    = "承認欲求からのログアウト — 誰にも見られない。それが、自由だった"
		2:  # BAD END: 永遠のサムネイル
			win_label.visible = true
			win_label.text    = "BAD END"
			win_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
			sub_label.text    = "永遠のサムネイル — この配信のアーカイブは削除できません"
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


func _on_player_hit(_count: int) -> void:
	pass


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
	_debug_label.visible = false  # デバッグラベル非表示
	cl.add_child(_debug_label)
	_refresh_debug_label()


func _refresh_debug_label() -> void:
	if not is_instance_valid(_debug_label):
		return
	var ch  := GameManager.current_chapter
	var idx : int    = GameManager.chapter_index + 1
	var cname: String = ch.chapter_name if ch else "?"
	var free_str := " | [F9] 自由移動: ON ✓" if GameManager.debug_free_move else " | [F9] 自由移動"
	var skip_str := "  F1=入口  F2=村探索  F3=民家  F4=神社  F5=脱出" if _DEBUG_CHAPTER_SKIP else ""
	_debug_label.text = "【DEBUG】CP%d: %s%s%s" % [idx, cname, free_str, skip_str]


func _debug_skip_to_chapter(idx: int) -> void:
	GameManager.state           = GameManager.State.PLAYING
	GameManager.items_found     = 0
	GameManager.hit_count       = 0
	GameManager._hit_invincible = false
	GameManager.load_chapter(idx)
	get_tree().reload_current_scene()
