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

	# [CP3村探索廃止] CP3 村の探索: JSON外部定義から読み込み（村探索廃止のためコメントアウト）
	#if chapter.chapter_id == "ch02_mura_tansaku":
	#	_apply_mura_config(chapter)

	# items_total を generate() より前に設定（Exit._ready() が参照するため）
	GameManager.items_total = chapter.item_positions.size()
	print("[Main] items_total set to: ", GameManager.items_total)
	# CP2 section 2: souko exit + mura exit（CP3-2 神社階段まで）連鎖
	if GameManager.start_section == 2 and chapter.chapter_id == "ch02_haison_souko":
		GameManager.start_section = 0
		hud.set_chrome($YouTubeChrome)
		_setup_danmaku()
		hud.danmaku_func = Callable(self, "_spawn_danmaku")
		await LoadingScreen.fade_out()
		await _play_souko_exit()
		return
	# CP2 section 3: CP3-2（神社階段→3択）デバッグ直行（ソウコ脱出演出スキップ）
	if GameManager.start_section == 3 and chapter.chapter_id == "ch02_haison_souko":
		GameManager.start_section = 0
		hud.set_chrome($YouTubeChrome)
		_setup_danmaku()
		hud.danmaku_func = Callable(self, "_spawn_danmaku")
		await LoadingScreen.fade_out()
		await _play_mura_exit()
		return
	# CP2 section 4: 3択（cp3_choice）デバッグ直行（神社階段演出もスキップ）
	if GameManager.start_section == 4 and chapter.chapter_id == "ch02_haison_souko":
		GameManager.start_section = 0
		hud.set_chrome($YouTubeChrome)
		_setup_danmaku()
		hud.danmaku_func = Callable(self, "_spawn_danmaku")
		await LoadingScreen.fade_out()
		player.input_disabled = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		await _run_chapter_opening_from_label("ch02_mura_tansaku_exit", "cp3_choice")
		return
	# [CP3村探索廃止] start_section==1 でmura_tansaku直接再生するパス（廃止）
	#if GameManager.start_section == 1 and chapter.chapter_id not in ["ch01_haison_iriguchi", "ch02_haison_souko"]:
	#	GameManager.start_section = 0
	#	hud.set_chrome($YouTubeChrome)
	#	_setup_danmaku()
	#	hud.danmaku_func = Callable(self, "_spawn_danmaku")
	#	await LoadingScreen.fade_out()
	#	await _play_mura_exit() if chapter.chapter_id == "ch02_mura_tansaku" else _play_souko_exit()
	#	GameManager.advance_to_next_chapter()
	#	return
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

	# ゴースト初期化（CP3は LoadingScreen.fade_out() 後に有効化するため、ここでは全て無効）
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
	# items_totalが確定した後でHUDラベルを強制更新
	hud.refresh_item_label()
	print("[Main] HUD item label refreshed. Total: ", GameManager.items_total)

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

	# [CP3村探索廃止] CP3 村の探索: 出口方向（+Z）を向く
	#if chapter.chapter_id == "ch02_mura_tansaku":
	#	player.rotation.y = PI  # +Z方向（出口方面）を向く

	_setup_debug_ui()

	SoundManager.start_ambient(GameManager.chapter_index)

	# ローディング画面をフェードアウト
	await LoadingScreen.fade_out()

	# デバッグチャプター: イントロ・演出を全スキップして即プレイ
	if chapter.chapter_id.begins_with("debug_"):
		_intro_skip = true
		intro_layer.visible = false
		player.input_disabled = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		player.set_head_height(2.5)
		# ゴーストを即有効化 + 番号ラベル付与
		const MOTION_NAMES : Array[String] = [
			"NORMAL", "HEAD_JERK", "SERPENTINE", "FREEZE_BURST",
			"TREMOR", "SLOW_TURN", "LEVITATE",
			"LEAN_DASH", "CRAB_WALK", "TELEPORT_FAKE", "CRAWL",
			"FACE_CLOSE", "UPSIDE_DOWN"]
		var ghost_idx : int = 0
		for ghost: Node in get_tree().get_nodes_in_group("ghost"):
			ghost.process_mode = Node.PROCESS_MODE_INHERIT
			ghost.visible = true
			# 頭上に番号+モーション名の3Dラベルを配置
			if ghost.forced_motion >= 0:
				var lbl := Label3D.new()
				var motion_id : int = ghost.forced_motion
				var name_str : String = MOTION_NAMES[motion_id] if motion_id < MOTION_NAMES.size() else "???"
				lbl.text = "%d  %s" % [ghost_idx + 1, name_str]
				lbl.font_size = 48
				lbl.pixel_size = 0.01
				lbl.position = Vector3(0, 3.5, 0)
				lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				lbl.no_depth_test = true
				lbl.modulate = Color(1, 1, 0.3)
				lbl.outline_modulate = Color(0, 0, 0)
				lbl.outline_size = 12
				ghost.add_child(lbl)
			ghost_idx += 1
		_setup_debug_ui()
		_refresh_debug_label()
		return

	# 廃村入口チャプターは自動演出シーケンスを実行して次チャプターへ進む
	var cur_chapter := GameManager.current_chapter
	if cur_chapter and cur_chapter.chapter_id == "ch01_haison_iriguchi":
		await _run_entrance_sequence()
		return

	# プレイアブルチャプター（CP2・CP3）はJSON演出なし → 即プレイ開始
	var is_cinematic : bool = cur_chapter != null and cur_chapter.chapter_id in AUTO_PROGRESS_CHAPTERS
	var is_playable : bool = cur_chapter != null and cur_chapter.chapter_id in ["ch02_haison_souko"]

	if is_playable:
		# start_section==1 のつなぎ演出は _ready() 冒頭で処理済み
		# [CP3村探索廃止] CP3 村の探索: 即プレイアブル + バックグラウンドで演出
		#if cur_chapter.chapter_id == "ch02_mura_tansaku":
		#	SoundManager.play_bgm("res://assets/audio/bgm/静寂ノ境界.mp3", -12.0, 1.0, 3.0)
		#	GameManager.ghost_grace = true
		#	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		#		ghost.process_mode = Node.PROCESS_MODE_INHERIT
		#		ghost.visible = true
		#	get_tree().create_timer(15.0).timeout.connect(func() -> void:
		#		GameManager.ghost_grace = false)

		# 廃倉庫パートでは視点を高くする（ユーザー要望）
		if cur_chapter.chapter_id in ["ch02_haison_souko"]:
			player.set_head_height(2.5)
		else:
			player.set_head_height(0.7)
		# CP2: 紙芝居演出→暗転→操作説明→自由移動（section 0のみ）
		if cur_chapter.chapter_id == "ch02_haison_souko" and GameManager.start_section == 0:
			var cam := player.get_node_or_null("Head/Camera3D")
			if cam:
				cam.current = false
			await _run_chapter_opening(cur_chapter.chapter_id)
			await _show_controls_guide()
			if cam:
				cam.current = true
		# CP2 section 1使用後リセット
		if cur_chapter.chapter_id == "ch02_haison_souko" and GameManager.start_section == 1:
			GameManager.start_section = 0
		# プレイアブル: 即操作可能
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		player.input_disabled = false
		# 自動探索モード: 操作なしでストーリー自動進行（視覚障碍者対応）
		if GameManager.auto_explore_mode:
			_start_auto_explore()
		# CP2廃倉庫: 自由移動開始後のバックグラウンドコメント
		if cur_chapter.chapter_id == "ch02_haison_souko":
			_run_chapter_opening_background("ch02_haison_souko_free")
		# [CP3村探索廃止] CP3村の探索: アイテム探索目標画面を表示（非ブロック）
		#if cur_chapter.chapter_id == "ch02_mura_tansaku":
		#	_show_mura_objective()
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
	# [CP3村探索廃止] 村アイテム収集コールバックはCP3廃止のためコメントアウト
	#GameManager.item_collected.connect(_on_item_collected_village)

	# CP2廃倉庫: ゴール到達時にsouko_exit→mura_exit（CP3-2紙芝居）を連鎖して遷移
	# skip_advance=true でエンディング遷移はコールバック内で完結させる
	if cur_chapter and cur_chapter.chapter_id == "ch02_haison_souko":
		stage_gen.exit_node.on_exit_callback = Callable(self, "_play_souko_exit")
		stage_gen.exit_node.skip_advance = true
	# [CP3村探索廃止] CP3村探索ゴール時コールバック（廃止）
	#if cur_chapter and cur_chapter.chapter_id == "ch02_mura_tansaku":
	#	stage_gen.exit_node.on_exit_callback = Callable(self, "_play_mura_exit")

	# ミニマップ: CP2は演出後にフェードイン
	if cur_chapter and cur_chapter.chapter_id == "ch02_haison_souko":
		_setup_minimap_delayed(Vector2(-25, -18), Vector2(25, 18))
	# [CP3村探索廃止] CP3村ミニマップ（廃止）
	#if cur_chapter and cur_chapter.chapter_id == "ch02_mura_tansaku":
	#	_setup_minimap(Vector2(-80, -80), Vector2(120, 120))

	# ナビ矢印用: プレイヤー参照をHUDに渡す
	hud._player_ref = player

	# オートテスト継続（シーン再ロード後に自動で次チャプターを走破）
	if GameManager.autotest_active:
		# autotest_mode: "play" = 自動プレイ（歩いて回収）, それ以外 = 即クリア
		if GameManager.autotest_mode == "play":
			_debug_auto_play_chapter()
		elif GameManager.autotest_mode == "cp3-2":
			# CP3-2: アイテム全取得+出口テレポート→クリア演出確認
			await get_tree().create_timer(1.0).timeout
			_debug_auto_complete_chapter()
		elif GameManager.autotest_mode == "skip":
			# 即クリアモード: アイテム全取得+出口テレポート
			await get_tree().create_timer(2.0).timeout
			_debug_auto_complete_chapter()
		else:
			_run_autotest(GameManager.autotest_chapter_wait)


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
	await director.run_from_path(path)
	director.cleanup()
	remove_child(director)
	director.queue_free()


func _run_chapter_opening_from_label(chapter_id: String, label: String) -> void:
	## 指定ラベルからシーケンスを開始（デバッグ直行用）
	var path := "res://dialogue/%s.json" % chapter_id
	if not FileAccess.file_exists(path):
		return
	var director: Node = EntranceDirectorScript.new()
	director.set("player", player)
	director.set("hud", hud)
	director.set("start_label", label)
	add_child(director)
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

	# F8: チャット音声オン/オフ トグル
	if kc == KEY_F8:
		SoundManager.chat_voice_muted = not SoundManager.chat_voice_muted
		if SoundManager.chat_voice_muted and SoundManager._chat_voice.playing:
			SoundManager._chat_voice.stop()
		_refresh_debug_label()
		get_viewport().set_input_as_handled()
		return

	# F8: デバッグチャプター起動（モーションショーケース等）
	if kc == KEY_F8:
		GameManager.load_debug_chapter("res://chapters/debug_motion_showcase.tres")
		get_viewport().set_input_as_handled()
		return

	# F9: シナリオ中自由移動トグル（常時有効）
	if kc == KEY_F9:
		_toggle_debug_free_move()
		get_viewport().set_input_as_handled()
		return

	# Shift+F10: 現チャプター自動プレイ（アイテム順に歩いて回収→出口）
	if kc == KEY_F10 and event.shift_pressed:
		get_viewport().set_input_as_handled()
		_debug_auto_play_chapter()
		return

	# F10: 現チャプター即クリア（アイテム全取得＋出口テレポート）
	if kc == KEY_F10:
		get_viewport().set_input_as_handled()
		_debug_auto_complete_chapter()
		return

	# F11: 全チャプター自動走破テスト開始
	if kc == KEY_F11:
		get_viewport().set_input_as_handled()
		_debug_start_autotest()
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
# ──────────────────────────────────────────────
# [CP3村探索廃止] CP3設定: JSONから読み込み（廃止のためコメントアウト）
# ──────────────────────────────────────────────

#func _apply_mura_config(chapter: Resource) -> void:
#	var cfg := _load_json("res://dialogue/ch02_mura_items_config.json")
#	if cfg.is_empty():
#		push_warning("Main: ch02_mura_items_config.json が読み込めません、フォールバック")
#		return
#	if cfg.has("stage_scene_path"):
#		chapter.stage_scene_path = cfg["stage_scene_path"]
#	if cfg.has("player_spawn"):
#		var sp : Array = cfg["player_spawn"]
#		chapter.player_spawn = Vector3(sp[0], sp[1], sp[2])
#	if cfg.has("exit_position"):
#		var ep : Array = cfg["exit_position"]
#		chapter.exit_position = Vector3(ep[0], ep[1], ep[2])
#	if cfg.has("items"):
#		var items_arr : Array = cfg["items"]
#		var positions := PackedVector3Array()
#		for item_data in items_arr:
#			var p : Array = item_data["position"]
#			positions.append(Vector3(p[0], p[1], p[2]))
#		chapter.item_positions = positions
#	if cfg.has("ghosts"):
#		var GhostConfigScript := preload("res://scripts/GhostConfig.gd")
#		var ghost_configs : Array[Resource] = []
#		for gd_data in cfg["ghosts"]:
#			var gc := GhostConfigScript.new()
#			var gp : Array = gd_data["position"]
#			gc.position = Vector3(gp[0], gp[1], gp[2])
#			gc.model_path = gd_data.get("model", "res://assets/models/characters/Miyuki.glb")
#			var s : float = float(gd_data.get("scale", 3))
#			gc.model_scale = Vector3(s, s, s)
#			ghost_configs.append(gc)
#		chapter.ghost_configs = ghost_configs


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		return {}
	var data = json.get_data()
	if data is Dictionary:
		return data
	return {}


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
		env.fog_light_energy       = 0.05
		env.fog_aerial_perspective = chapter.fog_aerial_perspective

	# ── ボリュメトリックフォグ (Forward Plus — gl_compatibility では無視される) ──
	env.volumetric_fog_enabled = chapter.volumetric_fog_enabled
	if chapter.volumetric_fog_enabled:
		env.volumetric_fog_density = chapter.volumetric_fog_density

	# ── Glow / Bloom（HD-2D演出）──
	env.glow_enabled       = chapter.glow_enabled
	env.glow_intensity     = chapter.glow_intensity
	env.glow_bloom         = chapter.glow_bloom
	env.glow_blend_mode    = chapter.glow_blend_mode
	env.glow_hdr_threshold = chapter.glow_hdr_threshold

	$DirectionalLight3D.light_energy = chapter.directional_light_energy

	# ── HD-2D パーティクル（全チャプター共通）──
	_setup_atmosphere_particles()

	# ── CP1: VillageGate電球ライト + 環境小物追加 ──
	if chapter.chapter_id == "ch01_haison_iriguchi":
		_add_bulb_lights()
		_add_cp1_debris()

	# ── VHS オーバーレイ（CP2 section 1 はクリーン状態で開始） ──
	if chapter.vhs_overlay and not (chapter.chapter_id == "ch02_haison_souko" and GameManager.start_section == 1):
		_setup_vhs_overlay()
	else:
		_remove_vhs_overlay()


# ──────────────────────────────────────────────
# HD-2D パーティクル（全チャプター共通）
# ──────────────────────────────────────────────

## VillageGate の電球にOmniLight + Emissionを動的追加
func _add_bulb_lights() -> void:
	var stage := get_node_or_null("StageGenerator/Stage")
	if not stage:
		return
	# VillageGate > ArchStructure > Bulb_0〜Bulb_10 を探す
	for node in _find_nodes_recursive(stage, "Bulb_"):
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.85, 0.55)
		light.light_energy = 0.4
		light.omni_range = 3.0
		light.shadow_enabled = false
		node.add_child(light)
		# Emissionマテリアル（Bloom対応）
		if node is CSGSphere3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.9, 0.6)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.85, 0.55)
			mat.emission_energy_multiplier = 3.0
			node.material = mat

func _find_nodes_recursive(root: Node, prefix: String) -> Array[Node]:
	var result : Array[Node] = []
	for child in root.get_children():
		if child.name.begins_with(prefix):
			result.append(child)
		result.append_array(_find_nodes_recursive(child, prefix))
	return result


## CP1: 道路脇の環境小物（落ちたゴミ・缶・瓦礫）
func _add_cp1_debris() -> void:
	var stage := get_node_or_null("StageGenerator/Stage")
	if not stage:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # 固定シードで毎回同じ配置
	var debris_mat := StandardMaterial3D.new()
	debris_mat.albedo_color = Color(0.15, 0.12, 0.10)
	debris_mat.roughness = 0.95
	var metal_mat := StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.25, 0.25, 0.28)
	metal_mat.metallic = 0.4
	metal_mat.roughness = 0.7

	# 道路沿い（Z=-50〜Z=20）に小物を散布
	for i in range(15):
		var z_pos : float = rng.randf_range(-40.0, 15.0)
		var x_off : float = rng.randf_range(-4.5, -2.5) if rng.randf() > 0.5 else rng.randf_range(2.5, 4.5)
		var item := CSGBox3D.new()
		item.name = "Debris_%d" % i
		if rng.randf() > 0.6:
			# 潰れた缶
			item.size = Vector3(0.08, 0.04, 0.08)
			item.material = metal_mat
		else:
			# 瓦礫・紙くず
			item.size = Vector3(rng.randf_range(0.1, 0.25), 0.02, rng.randf_range(0.1, 0.2))
			item.material = debris_mat
		item.position = Vector3(x_off, 0.01, z_pos)
		item.rotation_degrees.y = rng.randf_range(0, 360)
		stage.add_child(item)

	# 倒れた自転車（道路脇に1台）
	var bike := Node3D.new()
	bike.name = "AbandonedBike"
	bike.position = Vector3(3.8, 0.0, -5.0)
	bike.rotation_degrees = Vector3(0, 35, 75)  # 横倒し
	# フレーム
	var frame := CSGBox3D.new()
	frame.size = Vector3(0.03, 0.5, 0.9)
	frame.material = metal_mat
	bike.add_child(frame)
	# 前輪
	var wheel_f := CSGCylinder3D.new()
	wheel_f.radius = 0.3
	wheel_f.height = 0.03
	wheel_f.sides = 12
	wheel_f.position = Vector3(0, 0.0, 0.4)
	wheel_f.rotation_degrees.x = 90
	wheel_f.material = metal_mat
	bike.add_child(wheel_f)
	# 後輪
	var wheel_r := CSGCylinder3D.new()
	wheel_r.radius = 0.3
	wheel_r.height = 0.03
	wheel_r.sides = 12
	wheel_r.position = Vector3(0, 0.0, -0.4)
	wheel_r.rotation_degrees.x = 90
	wheel_r.material = metal_mat
	bike.add_child(wheel_r)
	stage.add_child(bike)


var _atmosphere_particles: Array[GPUParticles3D] = []

## ソフトな円形グラデーションテクスチャ（中心→白→外側→透明）
func _create_soft_circle_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_offset(0, 0.0)
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.add_point(0.4, Color(1, 1, 1, 0.6))
	grad.set_offset(2, 1.0)
	grad.set_color(2, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	return tex

func _make_particle_mat(color: Color, emission_col: Color,
		emission_energy: float, circle_tex: GradientTexture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = circle_tex
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = emission_col
		m.emission_energy_multiplier = emission_energy
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	return m

func _setup_atmosphere_particles() -> void:
	if _atmosphere_particles.size() > 0:
		return

	var circle_tex := _create_soft_circle_texture()

	# ── 1. 塵・埃パーティクル ──
	var dust := GPUParticles3D.new()
	dust.name = "HD2D_Dust"
	dust.amount = 40
	dust.lifetime = 6.0
	dust.visibility_aabb = AABB(Vector3(-15, -3, -15), Vector3(30, 8, 30))

	var dust_proc := ParticleProcessMaterial.new()
	dust_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	dust_proc.emission_box_extents = Vector3(10.0, 3.0, 10.0)
	dust_proc.gravity = Vector3(0, -0.02, 0)
	dust_proc.initial_velocity_min = 0.05
	dust_proc.initial_velocity_max = 0.15
	dust_proc.spread = 180.0
	dust_proc.scale_min = 0.3
	dust_proc.scale_max = 0.7
	dust_proc.color = Color(0.9, 0.85, 0.7, 0.35)
	dust.process_material = dust_proc

	var dust_mesh := QuadMesh.new()
	dust_mesh.size = Vector2(0.05, 0.05)
	dust_mesh.material = _make_particle_mat(
		Color(0.9, 0.85, 0.7, 0.4),
		Color(0.9, 0.85, 0.7), 0.3, circle_tex)
	dust.draw_pass_1 = dust_mesh
	add_child(dust)
	_atmosphere_particles.append(dust)

	# ── 2. 地面の霧パーティクル ──
	var fog := GPUParticles3D.new()
	fog.name = "HD2D_GroundFog"
	fog.amount = 8
	fog.lifetime = 12.0
	fog.visibility_aabb = AABB(Vector3(-20, -1, -20), Vector3(40, 4, 40))

	var fog_proc := ParticleProcessMaterial.new()
	fog_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	fog_proc.emission_box_extents = Vector3(12.0, 0.2, 12.0)
	fog_proc.gravity = Vector3(0, 0, 0)
	fog_proc.initial_velocity_min = 0.08
	fog_proc.initial_velocity_max = 0.2
	fog_proc.direction = Vector3(1, 0, 0.3)
	fog_proc.spread = 45.0
	fog_proc.scale_min = 4.0
	fog_proc.scale_max = 8.0
	fog_proc.color = Color(0.6, 0.6, 0.7, 0.04)
	fog.process_material = fog_proc
	fog.position = Vector3(0, 0.4, 0)

	var fog_mesh := QuadMesh.new()
	fog_mesh.size = Vector2(3.0, 3.0)
	var fog_draw := _make_particle_mat(
		Color(0.6, 0.6, 0.7, 0.04),
		Color.BLACK, 0.0, circle_tex)
	fog_draw.no_depth_test = true
	fog_mesh.material = fog_draw
	fog.draw_pass_1 = fog_mesh
	add_child(fog)
	_atmosphere_particles.append(fog)

	# ── 3. ボケパーティクル（HD-2D定番：柔らかい光の玉）──
	var bokeh := GPUParticles3D.new()
	bokeh.name = "HD2D_Bokeh"
	bokeh.amount = 8
	bokeh.lifetime = 8.0
	bokeh.visibility_aabb = AABB(Vector3(-15, -1, -15), Vector3(30, 10, 30))

	var bokeh_proc := ParticleProcessMaterial.new()
	bokeh_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	bokeh_proc.emission_box_extents = Vector3(8.0, 2.0, 8.0)
	bokeh_proc.gravity = Vector3(0, 0.03, 0)
	bokeh_proc.initial_velocity_min = 0.02
	bokeh_proc.initial_velocity_max = 0.06
	bokeh_proc.direction = Vector3(0, 1, 0)
	bokeh_proc.spread = 80.0
	bokeh_proc.scale_min = 0.5
	bokeh_proc.scale_max = 1.2
	bokeh_proc.color = Color(0.4, 0.9, 0.5, 0.15)
	bokeh.process_material = bokeh_proc

	var bokeh_mesh := QuadMesh.new()
	bokeh_mesh.size = Vector2(0.12, 0.12)
	bokeh_mesh.material = _make_particle_mat(
		Color(1, 1, 1, 0.2),
		Color(0.3, 0.9, 0.4), 3.0, circle_tex)  # Bloom強化
	bokeh.draw_pass_1 = bokeh_mesh
	add_child(bokeh)
	_atmosphere_particles.append(bokeh)


# ──────────────────────────────────────────────
# VHS オーバーレイ
# ──────────────────────────────────────────────

var _vhs_layer : CanvasLayer = null
var _vhs_rect  : ColorRect   = null   # シェーダーパラメータ制御用
var _enc_vhs_layer : CanvasLayer = null  # CP3 EncodingError 用VHSエフェクト

## CP3 Encoding Error 用: vhs_effect.gdshader でオーバーレイを作成
func _setup_encoding_vhs_overlay() -> ShaderMaterial:
	var shader := load("res://shaders/vhs_effect.gdshader") as Shader
	if not shader:
		return null
	_enc_vhs_layer = CanvasLayer.new()
	_enc_vhs_layer.layer = 1
	add_child(_enc_vhs_layer)
	var rect := ColorRect.new()
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	var mat := ShaderMaterial.new()
	mat.shader = shader
	rect.material = mat
	_enc_vhs_layer.add_child(rect)
	return mat


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
	mat.set_shader_parameter("noise_intensity", 0.06)
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
	# CP2: ホラー遭遇イベントを起動（ゴーストはイベント内で有効化）
	var cur_ch := GameManager.current_chapter
	if cur_ch and cur_ch.chapter_id == "ch02_haison_souko":
		_run_cp2_horror_encounter()
		return
	# CP2以外: 従来のフェードイン有効化
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
	# CP2: ホラー遭遇イベントで直接管理するため、ghost_spotted経由の警告はスキップ
	var cur_ch := GameManager.current_chapter
	if cur_ch and cur_ch.chapter_id == "ch02_haison_souko":
		return
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
	_auto_explore_active = false
	GameManager.ghost_grace = true

	# ゴーストを有効化（追跡開始）
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		ghost.process_mode = Node.PROCESS_MODE_INHERIT

	# プレイヤー操作可能に
	player.input_disabled = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# ── ナビ矢印を入口方向に設定 + ミニマップにも入口を表示 ──
	var entrance_pos : Vector3 = GameManager.current_chapter.player_spawn if GameManager.current_chapter else Vector3(0, 1, 15)
	if is_instance_valid(hud):
		hud.show_monologue("入口！　入口から逃げないと……！")
		hud.start_nav(entrance_pos, "入口", Color(0.2, 0.85, 0.3), player)
	var minimap_layer := get_node_or_null("MinimapLayer")
	if minimap_layer and minimap_layer.get_child_count() > 0:
		var minimap = minimap_layer.get_child(0)
		if minimap.has_method("show_exit"):
			minimap.show_exit(entrance_pos)
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return

	if is_instance_valid(hud):
		hud.hide_monologue()

	# ── grace解除（ゴーストに捕まるようになる）──
	GameManager.ghost_grace = false

	# ── 入口到達を監視（プレイヤーが入口付近に来たら「開かない」イベント）──
	await _wait_for_entrance_arrival(entrance_pos)
	if not is_inside_tree():
		return

	# ── 入口が開かない！（みゆきも停止） ──
	var voice_dir : String = "res://assets/audio/voice/ch02_souko/"
	player.input_disabled = true
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		ghost.process_mode = Node.PROCESS_MODE_DISABLED

	# 入口が消えている
	SoundManager.play_sfx_file("metal/impactMetal_heavy_000.ogg")
	player.start_camera_shake(0.5, 0.6)
	SoundManager.play_voice(voice_dir + "v118.wav")
	if is_instance_valid(hud):
		hud.show_monologue("え……入口が、ない……？さっきここから入ったのに……壁しかない！！")
	_add_chat_safe("え？入口消えた！？", "視聴者A")
	await get_tree().create_timer(0.5).timeout
	_add_chat_safe("壁になってる……", "ガクブル太郎")
	await get_tree().create_timer(0.3).timeout
	_add_chat_safe("閉じ込められた？", "配信民99")
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return

	# 懐中電灯が消える
	SoundManager.play_sfx_file("metal/impactMetal_heavy_003.ogg")
	player.flashlight_on = false
	player.flashlight.visible = false
	player.start_camera_shake(0.3, 0.4)
	SoundManager.play_voice(voice_dir + "v119.wav")
	if is_instance_valid(hud):
		hud.show_monologue("嘘……懐中電灯まで消えた……何も見えない……")
	_add_chat_safe("真っ暗！！", "視聴者A")
	await get_tree().create_timer(0.3).timeout
	_add_chat_safe("映像どこ！？", "ゆきんこ77")
	await get_tree().create_timer(0.3).timeout
	_add_chat_safe("ガチでやばい", "深夜組")
	await get_tree().create_timer(0.3).timeout
	_add_chat_safe("配信事故だろこれ", "配信民99")
	await get_tree().create_timer(2.5).timeout
	if not is_inside_tree():
		return

	# 自分を奮い立たせる → ナビぐるぐる + ミニマップ消去
	SoundManager.play_voice(voice_dir + "v120.wav")
	if is_instance_valid(hud):
		hud.start_spinning()
		hud.show_monologue("どこかに出口があるはず……落ち着け、落ち着け私……")
	var ml2 := get_node_or_null("MinimapLayer")
	if ml2 and ml2.get_child_count() > 0:
		var mm2 = ml2.get_child(0)
		if mm2.has_method("hide_exit"):
			mm2.hide_exit()
	_add_chat_safe("別の出口探して！", "ホラー好き太郎")
	await get_tree().create_timer(0.3).timeout
	_add_chat_safe("壁沿いに歩いて！", "ゆきんこ77")
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return

	if is_instance_valid(hud):
		hud.hide_monologue()
	player.input_disabled = false
	# みゆき再開
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		ghost.process_mode = Node.PROCESS_MODE_INHERIT

	# ── 60秒後に真の出口を表示（自力で見つければ待たなくてOK）──
	_schedule_real_exit_reveal(60.0)


func _wait_for_entrance_arrival(entrance_pos: Vector3) -> void:
	## プレイヤーが入口付近(5m以内)に来るまで待機
	while is_inside_tree() and is_instance_valid(player):
		var dist := player.global_position.distance_to(entrance_pos)
		if dist < 5.0:
			break
		await get_tree().physics_frame


func _schedule_real_exit_reveal(delay: float) -> void:
	## delay秒後に真の出口をナビ矢印+ミニマップに表示
	await get_tree().create_timer(delay).timeout
	if not is_inside_tree():
		return
	var exit_pos : Vector3 = GameManager.current_chapter.exit_position if GameManager.current_chapter else Vector3(23, 1.5, 15)
	var voice_dir2 : String = "res://assets/audio/voice/ch02_souko/"

	# 真の出口にライトを設置（暗闇の中で発見しやすく）
	var exit_light := OmniLight3D.new()
	exit_light.position = exit_pos + Vector3(0, 2.0, 0)
	exit_light.light_color = Color(0.2, 0.9, 0.3)
	exit_light.light_energy = 0.0
	exit_light.omni_range = 12.0
	get_parent().add_child(exit_light) if get_parent() else add_child(exit_light)
	# ライトをじわっと点灯
	var tw_light := create_tween()
	tw_light.tween_property(exit_light, "light_energy", 3.0, 2.0)

	if is_instance_valid(hud):
		hud.stop_spinning()
		hud.retarget_nav(exit_pos, "EXIT")
		if is_instance_valid(hud._nav_poly):
			hud._nav_poly.color = Color(0.2, 0.85, 0.3)
		if is_instance_valid(hud._nav_title_lbl):
			hud._nav_title_lbl.add_theme_color_override("font_color", Color(0.2, 0.85, 0.3))
		SoundManager.play_voice(voice_dir2 + "v121.wav")
		hud.show_monologue("……あっちに風を感じる……出口か！？")
	_add_chat_safe("あっちじゃない！？", "ゆきんこ77")
	_add_chat_safe("行け行け！！", "視聴者A")
	var minimap_layer := get_node_or_null("MinimapLayer")
	if minimap_layer and minimap_layer.get_child_count() > 0:
		var minimap = minimap_layer.get_child(0)
		if minimap.has_method("show_exit"):
			minimap.show_exit(exit_pos)
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(hud):
		hud.hide_monologue()


## ════════════════════════════════════════════════════════════════
## CP2 ホラー遭遇イベント（VHS取得→暗闇→懐中電灯カチカチ→みゆき登場→逃げろ）
## ════════════════════════════════════════════════════════════════

func _run_cp2_horror_encounter() -> void:
	_auto_explore_active = false
	player.input_disabled = true
	var voice_dir : String = "res://assets/audio/voice/ch02_souko/"

	# ── 他の演出を停止（干渉防止） ──
	SoundManager.stop_voice()
	SoundManager.stop_chat_voice()
	if is_instance_valid(hud):
		hud.hide_monologue()

	# ── 1. ミニマップ出口マーカーを消す ──
	var minimap_layer := get_node_or_null("MinimapLayer")
	if minimap_layer and minimap_layer.get_child_count() > 0:
		var minimap = minimap_layer.get_child(0)
		if minimap.has_method("hide_exit"):
			minimap.hide_exit()

	# ── 2. 照明を暗くする ──
	_dim_all_lights(0.3, 2.0)
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return

	# ── 3. 懐中電灯が強制的に消える ──
	SoundManager.play_sfx_file("metal/impactMetal_heavy_003.ogg")
	player.flashlight_on = false
	player.flashlight.visible = false
	player.start_camera_shake(0.3, 0.4)
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return

	# ── 4. 完全暗闇 + ボイス ──
	SoundManager.play_voice(voice_dir + "v115.wav")
	if is_instance_valid(hud):
		hud.show_monologue("え……懐中電灯が……つかない！")
	_add_chat_safe("映像真っ暗なんだけど", "視聴者A")
	await get_tree().create_timer(1.0).timeout
	_add_chat_safe("こわ", "名無しさん")
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return

	# ── 5. 懐中電灯カチカチ（3回失敗）+ ボイス ──
	SoundManager.play_voice(voice_dir + "v116.wav")
	if is_instance_valid(hud):
		hud.show_monologue("お願い、ついて……！")
	for i in range(3):
		if not is_inside_tree():
			return
		SoundManager.play_sfx_file("metal/metalClick.ogg", -6.0)
		await get_tree().create_timer(0.8).timeout
	_add_chat_safe("やばいやばい", "ゆきんこ77")
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return

	# ── 6. みゆきをプレイヤー正面3mにテレポート（まだ暗闇） ──
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		var forward : Vector3 = -player.transform.basis.z.normalized()
		forward.y = 0
		if forward.length() < 0.01:
			forward = Vector3(0, 0, -1)
		forward = forward.normalized()
		ghost.global_position = player.global_position + forward * 3.0
		ghost.global_position.y = player.global_position.y - 0.5  # 足元から立つ
		# プレイヤーの方を向かせる
		var look_target := player.global_position
		look_target.y = ghost.global_position.y
		ghost.look_at(look_target, Vector3.UP)
		ghost.rotation.y += PI * 0.5  # Ghost.gdの向き補正
		# モーション固定: NORMAL + PATROL（直立・等倍サイズ）
		ghost.forced_motion = Ghost.MotionPattern.NORMAL
		ghost.forced_state = Ghost.GhostState.PATROL
		ghost.process_mode = Node.PROCESS_MODE_DISABLED
		ghost.visible = true
	if is_instance_valid(hud):
		hud.hide_monologue()
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree():
		return

	# ── 7. 点灯 → みゆきが目の前（視線ロック） ──
	SoundManager.play_sfx_file("metal/metalClick.ogg", -2.0)
	await get_tree().create_timer(0.15).timeout
	player.flashlight_on = true
	player.flashlight.visible = true

	# 2.0秒間みゆきをプレイヤーの顔面に張り付かせる（どこを向いても視界を塞ぐ）
	var _lock_t : float = 0.0
	# みゆきのスケールを一時的に大きく
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		var body : Node3D = ghost.get_node_or_null("GhostBody")
		if body:
			body.scale = Vector3(1.8, 1.8, 1.8)
	while _lock_t < 2.0 and is_inside_tree() and is_instance_valid(player):
		var dt : float = get_process_delta_time()
		_lock_t += dt
		for ghost: Node in get_tree().get_nodes_in_group("ghost"):
			if not is_instance_valid(ghost):
				continue
			# カメラの正面2.5mに配置
			var cam_pos : Vector3 = player.head.global_position
			var cam_forward : Vector3 = -player.head.global_transform.basis.z.normalized()
			ghost.global_position = cam_pos + cam_forward * 2.5
			# みゆきの顔をカメラに向ける
			var look_tgt := cam_pos
			look_tgt.y = ghost.global_position.y
			ghost.look_at(look_tgt, Vector3.UP)
			ghost.rotation.y += PI * 0.5
		await get_tree().process_frame
	# スケールを戻す
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		var body : Node3D = ghost.get_node_or_null("GhostBody")
		if body:
			body.scale = Vector3.ONE
	if not is_inside_tree():
		return

	# ── 8. 悲鳴 + 衝撃 ──
	SoundManager.play_voice(voice_dir + "v117.wav")
	SoundManager.play_sfx_file("metal/impactMetal_heavy_000.ogg")
	SoundManager.play_monster_growl(0.0)
	player.start_camera_shake(1.0, 0.8)
	if is_instance_valid(hud):
		hud._do_scare_flash(Color(0.8, 0.0, 0.0))
	_add_chat_safe("うわああああ！！！！", "視聴者A")
	await get_tree().create_timer(0.3).timeout
	_add_chat_safe("なにあれ！！！", "名無しさん")
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return

	# ── 8.5. みゆき認識 — トイレから追ってきた恐怖 ──
	SoundManager.play_voice(voice_dir + "v123.wav")
	if is_instance_valid(hud):
		hud.show_monologue("みゆき……ちゃん……？　なんで……トイレにいたはずなのに……")
	_add_chat_safe("トイレの人形！？", "配信民99")
	await get_tree().create_timer(0.5).timeout
	_add_chat_safe("追いかけてきた！？", "ゆきんこ77")
	await get_tree().create_timer(0.5).timeout
	_add_chat_safe("ガチじゃん……", "幽霊ガチ勢")
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return

	SoundManager.play_voice(voice_dir + "v124.wav")
	if is_instance_valid(hud):
		hud.show_monologue("こっち見てる……動いてる……来ないで来ないで来ないでっ！！")
	player.start_camera_shake(0.4, 1.0)
	_add_chat_safe("逃げてーーー！！！", "ゆきんこ77")
	await get_tree().create_timer(0.5).timeout
	_add_chat_safe("wwwwwwww配信事故", "配信民99")
	await get_tree().create_timer(0.5).timeout
	_add_chat_safe("走れ走れ走れ！！", "ホラー好き太郎")
	await get_tree().create_timer(0.5).timeout
	_add_chat_safe("鳥肌やばい", "深夜組")
	await get_tree().create_timer(2.5).timeout
	if not is_inside_tree():
		return

	if is_instance_valid(hud):
		hud.hide_monologue()

	# ── 9. みゆき即CHASE開始（モーションNORMAL固定 + AI有効） ──
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		ghost.forced_motion = Ghost.MotionPattern.NORMAL
		ghost.motion_lock_only = true
		ghost.forced_state = -1
		ghost.ghost_state = Ghost.GhostState.CHASE
		ghost._prev_ghost_state = -1
		ghost._stuck_timer = 0.0
		ghost._stuck_last_pos = ghost.global_position
		ghost.process_mode = Node.PROCESS_MODE_INHERIT  # 即追跡開始

	# ── 10.「逃 げ ろ」演出（awaitで完了を待つ） ──
	_ghost_alert_shown = true
	await _show_ghost_alert()
	# _show_ghost_alert 完了後 → _run_escape_nav_sequence が呼ばれる
	# → 操作可能, ナビ矢印, ghost_grace解除


func _add_chat_safe(msg: String, user: String) -> void:
	if is_instance_valid(hud):
		hud._add_chat(msg, user)


func _on_ghost_lost() -> void:
	hud.trigger_chat_event("ghost_lost")


func _on_item_collected_warehouse(count: int, total: int) -> void:
	## 廃倉庫チャプター専用：VHS発見時
	if not (GameManager.current_chapter and GameManager.current_chapter.chapter_id == "ch02_haison_souko"):
		return
	# ポラロイド演出を先に完了させてからセリフを流す
	await _show_item_acquired(count, total)
	# VHS全回収時はホラー遭遇イベントに移行するためfound演出をスキップ
	if count >= total:
		return
	# まだ残りがある場合のみfound演出
	_run_chapter_opening_background("ch02_haison_souko_found")


## ステージ内の全ライトを暗くする（恐怖演出用）
func _dim_all_lights(multiplier: float, duration: float) -> void:
	var stage := get_node_or_null("StageGenerator")
	if not stage:
		return
	_dim_lights_recursive(stage, multiplier, duration)

func _dim_lights_recursive(node: Node, mult: float, dur: float) -> void:
	if node is OmniLight3D or node is SpotLight3D:
		var tw := create_tween()
		tw.tween_property(node, "light_energy", node.light_energy * mult, dur)
	for child in node.get_children():
		_dim_lights_recursive(child, mult, dur)


## [CP3村探索廃止] _on_item_collected_village — CP3廃止のためコメントアウト
#func _on_item_collected_village(count: int, total: int) -> void:
#	if not (GameManager.current_chapter and GameManager.current_chapter.chapter_id == "ch02_mura_tansaku"):
#		return
#	var minimap_layer := get_node_or_null("MinimapLayer")
#	if minimap_layer and minimap_layer.get_child_count() > 0:
#		var minimap = minimap_layer.get_child(0)
#		if is_instance_valid(minimap) and minimap.has_method("update_items"):
#			var items : Array = []
#			for node in get_tree().get_nodes_in_group("village_item"):
#				if is_instance_valid(node) and not node.is_queued_for_deletion():
#					items.append(node)
#			minimap.update_items(items)
#	if count >= total:
#		_reveal_mura_exit()


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


func _setup_minimap(map_min: Vector2, map_max: Vector2) -> void:
	## プレイアブルチャプター用ミニマップを生成
	var chapter := GameManager.current_chapter
	if chapter == null:
		return
	# アイテムをミニマップに渡す（CP2はミニマップにアイテム非表示）
	# CP3: VillageItemノード自体を渡す（回収=queue_freeで自動消失）
	# それ以外: Vector3座標を渡す（カウンタ方式フォールバック）
	var items : Array = []
	# [CP3村探索廃止] mura_tansaku専用アイテム処理は廃止
	#if chapter.chapter_id == "ch02_mura_tansaku":
	#	for node in get_tree().get_nodes_in_group("village_item"):
	#		if is_instance_valid(node):
	#			items.append(node)
	#el
	if chapter.chapter_id != "ch02_haison_souko":
		# CP2以外は座標配列として扱う
		for v in chapter.item_positions:
			items.append(v)
	# ゴーストノード取得
	var ghosts : Array = get_tree().get_nodes_in_group("ghost")
	# CanvasLayer (YouTubeChrome=20 の手前)
	var canvas := CanvasLayer.new()
	canvas.layer = 19
	canvas.name = "MinimapLayer"
	add_child(canvas)
	# Minimap Control
	var minimap := preload("res://scripts/Minimap.gd").new()
	minimap.position = Vector2(686, 344)
	canvas.add_child(minimap)
	minimap.setup(player, chapter.exit_position, items, ghosts, map_min, map_max)
	# 構造物データを追加
	if chapter.chapter_id == "ch02_haison_souko":
		minimap.add_warehouse_walls()
	# [CP3村探索廃止] mura_tansaku ミニマップ構造物は廃止
	#elif chapter.chapter_id == "ch02_mura_tansaku":
	#	minimap.hide_exit()
	#	_populate_village_minimap(minimap)


## [CP3村探索廃止] _populate_village_minimap（廃止）
#func _populate_village_minimap(minimap: Control) -> void:
#	await get_tree().create_timer(0.3).timeout
#	if not is_instance_valid(minimap):
#		return
#	var stage_node : Node = get_node_or_null("Stage")
#	if stage_node == null:
#		return
#	var structures : Array = []
#	for child in stage_node.get_children():
#		if child.name.begins_with("ManualBuilding") or child.name.begins_with("Concrete"):
#			structures.append(child)
#	if structures.size() > 0:
#		minimap.add_manual_buildings(structures)


## [CP3村探索廃止] _show_mura_objective（廃止）
#func _show_mura_objective() -> void:
#	var canvas := CanvasLayer.new()
#	canvas.layer = 100
#	get_tree().root.add_child(canvas)
#	var root_ctrl := Control.new()
#	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
#	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
#	root_ctrl.modulate.a = 0.0
#	canvas.add_child(root_ctrl)
#	var dim := ColorRect.new()
#	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
#	dim.color = Color(0, 0, 0, 0.72)
#	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
#	root_ctrl.add_child(dim)
#	var center := CenterContainer.new()
#	center.set_anchors_preset(Control.PRESET_FULL_RECT)
#	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
#	root_ctrl.add_child(center)
#	var vbox := VBoxContainer.new()
#	vbox.add_theme_constant_override("separation", 18)
#	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
#	center.add_child(vbox)
#	var title_lbl := Label.new()
#	title_lbl.text = "アイテムを探せ！"
#	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
#	title_lbl.add_theme_font_size_override("font_size", 42)
#	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
#	vbox.add_child(title_lbl)
#	var sub_lbl := Label.new()
#	sub_lbl.text = "%d 個のアイテムを集めて村の謎を解け" % GameManager.items_total
#	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
#	sub_lbl.add_theme_font_size_override("font_size", 20)
#	sub_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78))
#	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
#	vbox.add_child(sub_lbl)
#	var tw_in := create_tween()
#	tw_in.tween_property(root_ctrl, "modulate:a", 1.0, 0.6)
#	await tw_in.finished
#	await get_tree().create_timer(2.5).timeout
#	var tw_out := create_tween()
#	tw_out.tween_property(root_ctrl, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
#	await tw_out.finished
#	canvas.queue_free()


## [CP3村探索廃止] _reveal_mura_exit（廃止）
#func _reveal_mura_exit() -> void:
#	if not is_inside_tree():
#		return
#	var exit_pos : Vector3 = GameManager.current_chapter.exit_position if GameManager.current_chapter else Vector3.ZERO
#	var exit_node : Node3D = stage_gen.exit_node
#	if is_instance_valid(exit_node):
#		var exit_light : Node = exit_node.get_node_or_null("ExitLight")
#		if exit_light:
#			var tw_light := create_tween()
#			tw_light.tween_property(exit_light, "light_energy", 3.0, 2.0)
#	var minimap_layer := get_node_or_null("MinimapLayer")
#	if minimap_layer and minimap_layer.get_child_count() > 0:
#		var mm = minimap_layer.get_child(0)
#		if is_instance_valid(mm) and mm.has_method("show_exit"):
#			mm.show_exit(exit_pos)
#	if is_instance_valid(hud):
#		hud.retarget_nav(exit_pos, "EXIT")
#		hud.show_monologue("全部集めた……出口を探せ！")
#	await get_tree().create_timer(3.0).timeout
#	if is_instance_valid(hud):
#		hud.hide_monologue()


func _show_controls_guide() -> void:
	## 操作説明画像を3秒表示して自動で閉じる
	SoundManager.stop_voice()
	if SoundManager._chat_voice.playing:
		SoundManager._chat_voice.stop()

	var canvas := CanvasLayer.new()
	canvas.layer = 100
	get_tree().root.add_child(canvas)

	# 全体をまとめるControlノード（フェード用）
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root_ctrl)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 1.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(dim)

	var tex := load("res://assets/textures/controls_guide.png") as Texture2D
	if tex:
		var img := TextureRect.new()
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.offset_left = 80
		img.offset_right = -80
		img.offset_top = 40
		img.offset_bottom = -80
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root_ctrl.add_child(img)

	# フェードイン
	root_ctrl.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(root_ctrl, "modulate:a", 1.0, 1.0)
	await tw.finished

	# 3秒表示
	await get_tree().create_timer(3.0).timeout

	# フェードアウト
	var tw_out := create_tween()
	tw_out.tween_property(root_ctrl, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	await tw_out.finished
	canvas.queue_free()


func _setup_minimap_delayed(map_min: Vector2, map_max: Vector2) -> void:
	## バックグラウンド演出が終わってからミニマップをフェードイン表示
	# 演出完了を待つ（バックグラウンドchatが流れ終わるまで）
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return
	# 脱出演出が既に始まっている場合はミニマップを作らない
	if _souko_exiting:
		return
	var chapter := GameManager.current_chapter
	if chapter == null:
		return
	var items : Array = []
	if chapter.chapter_id != "ch02_haison_souko":
		for v in chapter.item_positions:
			items.append(v)
	var ghosts : Array = get_tree().get_nodes_in_group("ghost")
	var canvas := CanvasLayer.new()
	canvas.layer = 19
	canvas.name = "MinimapLayer"
	add_child(canvas)
	var minimap := preload("res://scripts/Minimap.gd").new()
	minimap.position = Vector2(686, 344)
	minimap.modulate.a = 0.0
	canvas.add_child(minimap)
	# CP2: ミニマップの出口をスタート地点に設定（VHS取得時に消す）
	var minimap_exit : Vector3 = chapter.player_spawn if chapter.chapter_id == "ch02_haison_souko" else chapter.exit_position
	minimap.setup(player, minimap_exit, items, ghosts, map_min, map_max)
	if chapter.chapter_id == "ch02_haison_souko":
		minimap.add_warehouse_walls()
	# フェードイン
	var tw := create_tween()
	tw.tween_property(minimap, "modulate:a", 1.0, 1.5)


var _souko_exiting : bool = false  # 脱出演出中フラグ（ミニマップ遅延作成を抑止）

func _play_souko_exit() -> void:
	## CP2廃倉庫ゴール到達時の演出
	_souko_exiting = true
	player.input_disabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ナビ矢印を停止（HUD自体は非表示にしない — narrationボックスが見えなくなるため）
	if is_instance_valid(hud):
		hud.stop_nav()
	# ミニマップを非表示にする（紙芝居演出中に残らないように）
	var minimap_layer := get_node_or_null("MinimapLayer")
	if minimap_layer:
		minimap_layer.visible = false
	# ゴーストを無効化（みゆきの唸り声・金属音を止める）
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		ghost.process_mode = Node.PROCESS_MODE_DISABLED
		ghost.visible = false
	await _run_chapter_opening("ch02_haison_souko_exit")
	# CP3村探索をスキップしてそのままCP3-2（神社階段→3択→エンディング）へ直行
	await _play_mura_exit()
	# エンディング遷移は _play_mura_exit 内で完結するため、ここでは操作復帰しない
	# （skip_advance=true でExit.gdからの advance_to_next_chapter もスキップ済み）


func _play_mura_exit() -> void:
	## CP3村の探索ゴール到達時のつなぎ演出（紙芝居）
	player.input_disabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ボイス・チャットボイスを停止
	SoundManager.stop_voice()
	SoundManager.stop_chat_voice()
	# ゴーストを無効化（みゆきの唸り声・金属音を止める）
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		ghost.process_mode = Node.PROCESS_MODE_DISABLED
		ghost.visible = false
	# ミニマップを非表示にする
	var minimap_layer := get_node_or_null("MinimapLayer")
	if minimap_layer:
		minimap_layer.visible = false
	# 3Dカメラ無効化（紙芝居中に3Dモデルが見えないように）
	var cam := player.get_node_or_null("Head/Camera3D")
	if cam:
		cam.current = false
	# EncodingError停止
	var enc_err := get_node_or_null("EncodingError")
	if enc_err:
		enc_err.set_physics_process(false)
	# 紙芝居演出
	await _run_chapter_opening("ch02_mura_tansaku_exit")
	player.input_disabled = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


## CP3: Encoding Error 100%到達 — 「配信が終了しました」画面を表示してからBAD END
func _on_encoding_error_maxed() -> void:
	player.input_disabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# デバッグ: 即スキップ（_show_caught内でもスキップされる）
	if _DEBUG_CHAPTER_SKIP:
		print("[Debug] Encoding Error BAD END スキップ")
		GameManager.trigger_caught()
		return
	# 画面を真っ暗にする
	var blackout := ColorRect.new()
	blackout.set_anchors_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color(0, 0, 0, 0)
	blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# HUDの上に表示
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	canvas.add_child(blackout)
	# モザイク → 暗転
	var tw := create_tween()
	tw.tween_property(blackout, "color:a", 1.0, 1.5)
	await tw.finished
	# 「配信が終了しました」テキスト
	var label := Label.new()
	label.text = "配信が終了しました"
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(label)
	await get_tree().create_timer(3.0).timeout
	canvas.queue_free()
	GameManager.trigger_caught()


func _show_caught() -> void:
	_close_inventory()
	player.input_disabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# デバッグ: バッドエンド演出スキップ（CP2以外のみ — CP2はバッドエンド演出を見せる）
	var _is_cp2 : bool = GameManager.current_chapter != null and GameManager.current_chapter.chapter_id == "ch02_haison_souko"
	if _DEBUG_CHAPTER_SKIP and not _is_cp2:
		print("[Debug] バッドエンド演出スキップ → タイトルへ")
		SoundManager.stop_all()
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/Opening.tscn")
		return

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

	# 再生完了 → フローチャート表示 + 選択肢
	await ep.fade_out(1.5)

	var fc := CanvasLayer.new()
	fc.set_script(preload("res://scripts/EndingFlowchart.gd"))
	get_tree().root.add_child(fc)
	fc.show_flowchart("bad_eien")
	var eien_choice : int = await fc.show_return_choice()
	fc.queue_free()

	if eien_choice == 0:
		# 選択肢の直前に戻る → チャプター再スタート
		GameManager.restart()
	else:
		get_tree().change_scene_to_file("res://scenes/Opening.tscn")


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
	_debug_label.visible = false
	cl.add_child(_debug_label)
	_refresh_debug_label()


func _refresh_debug_label() -> void:
	if not is_instance_valid(_debug_label):
		return
	var ch  := GameManager.current_chapter
	var idx : int    = GameManager.chapter_index + 1
	var cname: String = ch.chapter_name if ch else "?"
	var pos_str := ""
	if is_instance_valid(player):
		var p := player.global_position
		pos_str = " | pos=(%.1f, %.1f)" % [p.x, p.z]
	var free_str := " | [F9] 自由移動: ON" if GameManager.debug_free_move else ""
	var chat_str := " | [F8] chat音声: OFF" if SoundManager.chat_voice_muted else ""
	var test_str := " | AUTO-TEST" if GameManager.autotest_active else ""
	_debug_label.text = "CP%d: %s%s%s%s%s" % [idx, cname, pos_str, free_str, chat_str, test_str]


func _process(_delta: float) -> void:
	# HD-2D パーティクルをプレイヤーに追従
	if _atmosphere_particles.size() > 0 and is_instance_valid(player):
		for p in _atmosphere_particles:
			if is_instance_valid(p):
				p.global_position = player.global_position

	# ゴースト接近度をHUDに伝える（REC心拍連動 + VHSグリッチ連動）
	if is_instance_valid(player) and is_instance_valid(hud):
		var ghosts := get_tree().get_nodes_in_group("ghost")
		var closest_dist : float = 999.0
		for ghost: Node in ghosts:
			if is_instance_valid(ghost) and ghost.visible:
				var d : float = player.global_position.distance_to(ghost.global_position)
				closest_dist = min(closest_dist, d)
		# 0.0=遠い(20m+), 1.0=超近い(3m以下)
		var proximity : float = clamp(1.0 - (closest_dist - 3.0) / 17.0, 0.0, 1.0)
		hud._ghost_proximity = proximity
		# VHSグリッチをゴースト距離に連動（Step 10: ゴースト画面演出）
		if is_instance_valid(_vhs_rect) and _vhs_rect.material:
			var mat : ShaderMaterial = _vhs_rect.material as ShaderMaterial
			if mat:
				mat.set_shader_parameter("noise_intensity", 0.06 + proximity * 0.04)
				mat.set_shader_parameter("chroma_boost", proximity * 0.008)
				mat.set_shader_parameter("distortion", proximity * 0.012)
		# ミニマップホラー化: ゴースト接近でノイズ→消失
		var minimap_layer := get_node_or_null("MinimapLayer")
		if minimap_layer and minimap_layer.get_child_count() > 0:
			var minimap_ctrl : Control = minimap_layer.get_child(0) as Control
			if minimap_ctrl:
				if proximity > 0.7:
					minimap_ctrl.visible = fmod(Time.get_ticks_msec() / 100.0, 1.0) > 0.3
					minimap_ctrl.modulate.a = 0.4
				elif proximity > 0.3:
					minimap_ctrl.visible = true
					minimap_ctrl.modulate.a = lerp(1.0, 0.3, (proximity - 0.3) / 0.4)
				else:
					minimap_ctrl.visible = true
					minimap_ctrl.modulate.a = 1.0

	# デバッグラベルのプレイヤー座標をリアルタイム更新
	if _DEBUG_CHAPTER_SKIP and is_instance_valid(_debug_label) and is_instance_valid(player):
		_refresh_debug_label()


func _debug_skip_to_chapter(idx: int) -> void:
	GameManager.state           = GameManager.State.PLAYING
	GameManager.items_found     = 0
	GameManager.hit_count       = 0
	GameManager._hit_invincible = false
	GameManager.load_chapter(idx)
	get_tree().reload_current_scene()


# ════════════════════════════════════════════════════════════════
# 自動探索モード（視覚障碍者向け）
# ════════════════════════════════════════════════════════════════

func _start_auto_explore() -> void:
	var ch := GameManager.current_chapter
	if ch == null:
		return
	print("[AutoExplore] 自動探索モード開始: %s" % ch.chapter_name)
	_auto_explore_active = true
	# 無敵化（ゴーストは表示するが捕まらない）
	GameManager.ghost_grace = true
	# アイテム位置→出口の順に自動歩行
	var targets : Array[Vector3] = []
	for v in ch.item_positions:
		targets.append(v)
	targets.append(ch.exit_position)

	for target in targets:
		if not is_inside_tree():
			return
		await _auto_explore_walk(target)
		await get_tree().create_timer(1.0).timeout


var _auto_explore_chat_timer : float = 0.0
var _auto_explore_active : bool = false  # みゆき遭遇時に停止するためのフラグ
const AUTO_EXPLORE_CHAT_INTERVAL : float = 8.0  # チャットボイス間隔（秒）

func _auto_explore_walk(target: Vector3) -> void:
	if not is_instance_valid(player):
		return
	var speed : float = 2.8  # ゆっくり自動歩行（臨場感）
	while is_inside_tree() and is_instance_valid(player) and _auto_explore_active:
		var to := target - player.global_position
		to.y = 0.0
		var dist := to.length()
		if dist < 2.0:
			break
		var dir := to.normalized()
		# velocity を設定するだけ（move_and_slideはPlayer._physics_process()で呼ばれる）
		player.velocity.x = dir.x * speed
		player.velocity.z = dir.z * speed
		# カメラを進行方向に向ける
		var target_yaw := atan2(dir.x, dir.z)
		player.rotation.y = lerp_angle(player.rotation.y, target_yaw, 0.05)
		# 定期的にチャットボイスを再生（無音防止）
		var dt : float = get_physics_process_delta_time()
		_auto_explore_chat_timer += dt
		if _auto_explore_chat_timer >= AUTO_EXPLORE_CHAT_INTERVAL:
			_auto_explore_chat_timer = 0.0
			hud.trigger_chat_event("moved")
		await get_tree().physics_frame
	player.velocity.x = 0.0
	player.velocity.z = 0.0


## Shift+F10: 現チャプターを自動プレイ（一筆書きルートで歩いてクリア）
func _debug_auto_play_chapter() -> void:
	var ch := GameManager.current_chapter
	if ch == null:
		return
	var cp_num : int = GameManager.chapter_index + 1
	print("[AutoPlay] CP%d「%s」自動プレイ開始" % [cp_num, ch.chapter_name])
	# 無敵化
	GameManager.ghost_grace = true
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		ghost.process_mode = Node.PROCESS_MODE_DISABLED
		ghost.visible = false
	var enc_err := get_node_or_null("EncodingError")
	if enc_err:
		enc_err.set_physics_process(false)
	player.input_disabled = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return

	# CP3一筆書きルート: START → ItemA(西) → ItemB(東) → ItemC(近) → EXIT(北)
	# アイテム順を最適化（item_positions[0]=A, [1]=B, [2]=C）
	var item_order := [0, 1, 2]  # A→B→C
	var items : Array = []
	for v in ch.item_positions:
		items.append(v)

	for idx in item_order:
		if idx >= items.size():
			continue
		var target : Vector3 = items[idx]
		print("[AutoPlay]   アイテム %d へ移動中 → %s" % [idx + 1, str(target)])
		await _road_navigate_to(target)
		if not is_inside_tree():
			return
		# アイテム取得演出を待つ（input_disabledがfalseに戻るまで最大30秒）
		var wait_t : float = 0.0
		while wait_t < 30.0:
			await get_tree().create_timer(0.5).timeout
			if not is_inside_tree():
				return
			wait_t += 0.5
			# 演出が終わった（input_disabled解除）or アイテム取得済み
			if not player.input_disabled and GameManager.items_found > idx:
				break
		if GameManager.items_found > idx:
			print("[AutoPlay]   アイテム %d 取得OK" % (idx + 1))
		else:
			GameManager.items_found = idx + 1
			GameManager.item_collected.emit(GameManager.items_found, GameManager.items_total)
			print("[AutoPlay]   アイテム %d 強制取得" % (idx + 1))

	# 出口へ
	# EncodingError確実停止（アイテム演出で再開されている可能性）
	var enc2 := get_node_or_null("EncodingError")
	if enc2:
		enc2.set_physics_process(false)
	print("[AutoPlay]   出口へ移動中 → %s" % str(ch.exit_position))
	await _road_navigate_to(ch.exit_position)
	if not is_inside_tree():
		return
	print("[AutoPlay]   出口到着、イベント待機...")
	for _w in range(60):
		await get_tree().create_timer(0.5).timeout
		if not is_inside_tree():
			return
	print("[AutoPlay] CP%d 完了" % cp_num)


# ════════════════════════════════════════════════════════════════
# 自動移動エンジン（道路グラフA* + 直線歩行）
# ════════════════════════════════════════════════════════════════

var _road_astar: AStar3D = null

func _load_road_graph() -> void:
	var path := "res://tools/cp3_road_graph.json"
	if not FileAccess.file_exists(path):
		print("[AutoPlay] cp3_road_graph.json not found")
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		print("[AutoPlay] cp3_road_graph.json parse error")
		return
	var data : Dictionary = json.data
	_road_astar = AStar3D.new()
	var nodes : Array = data.get("road_nodes", [])
	var edges : Array = data.get("road_edges", [])
	for n in nodes:
		_road_astar.add_point(int(n["id"]), Vector3(float(n["x"]), 1.0, float(n["z"])))
	for e in edges:
		var a : int = int(e[0])
		var b : int = int(e[1])
		if _road_astar.has_point(a) and _road_astar.has_point(b):
			_road_astar.connect_points(a, b)
	print("[AutoPlay] 道路グラフ: %d nodes, %d edges" % [nodes.size(), edges.size()])


## 道路グラフ経由でナビゲーション
func _road_navigate_to(target: Vector3) -> void:
	if _road_astar == null:
		_load_road_graph()
	if _road_astar == null or _road_astar.get_point_count() == 0:
		print("[AutoPlay]   グラフなし → 直線")
		await _auto_walk_direct(target)
		return
	var from_id : int = _road_astar.get_closest_point(player.global_position)
	var to_id : int = _road_astar.get_closest_point(target)
	if from_id == to_id:
		await _auto_walk_direct(target)
		return
	var path : PackedVector3Array = _road_astar.get_point_path(from_id, to_id)
	print("[AutoPlay]   道路グラフ: %d WP" % path.size())
	for i in range(path.size()):
		await _auto_walk_direct(path[i])
		if not is_inside_tree():
			return
	await _auto_walk_direct(target)


## ターゲットまで直線で歩く（move_and_slide使用）
func _auto_walk_direct(target: Vector3) -> void:
	var timeout : float = 60.0
	var elapsed : float = 0.0
	var spd : float = 7.0
	var stuck_t : float = 0.0
	var prev_pos := player.global_position

	while elapsed < timeout:
		if not is_inside_tree() or not is_instance_valid(player):
			return
		var dt : float = get_process_delta_time()
		elapsed += dt
		var pos := player.global_position
		var dx : float = target.x - pos.x
		var dz : float = target.z - pos.z
		var dist : float = sqrt(dx * dx + dz * dz)
		if dist < 0.5:
			return  # 到着

		# スタック検知（5秒動かない → 少しずらす）
		var moved : float = Vector2(pos.x - prev_pos.x, pos.z - prev_pos.z).length()
		if moved < 0.01:
			stuck_t += dt
			if stuck_t > 5.0:
				# 少し横にずらして再開
				player.global_position += Vector3(randf_range(-2, 2), 0.5, randf_range(-2, 2))
				stuck_t = 0.0
				prev_pos = player.global_position
				print("[AutoPlay]   微調整 pos=%s" % str(player.global_position))
				await get_tree().process_frame
				continue
		else:
			stuck_t = 0.0
			prev_pos = pos

		# ターゲット方向に向いて前進
		player.look_at(Vector3(target.x, pos.y, target.z), Vector3.UP)
		var fwd := -player.transform.basis.z
		player.velocity.x = fwd.x * spd
		player.velocity.z = fwd.z * spd
		if player.is_on_floor():
			player.velocity.y = 0.0
		else:
			player.velocity.y -= 9.8 * dt
		player.move_and_slide()
		await get_tree().process_frame

	print("[AutoPlay]   ⚠ タイムアウト（60秒）")


## F10: 現チャプターを即クリア（アイテム全取得 + 出口テレポート）
func _debug_auto_complete_chapter() -> void:
	var ch := GameManager.current_chapter
	if ch == null:
		return
	print("[AutoTest] CP%d「%s」即クリア実行" % [GameManager.chapter_index + 1, ch.chapter_name])
	# アイテムを全取得扱い
	GameManager.items_found = GameManager.items_total
	GameManager.item_collected.emit(GameManager.items_found, GameManager.items_total)
	# ゴースト無効化 + EncodingError停止
	GameManager.ghost_grace = true
	for ghost: Node in get_tree().get_nodes_in_group("ghost"):
		ghost.process_mode = Node.PROCESS_MODE_DISABLED
	var enc_err := get_node_or_null("EncodingError")
	if enc_err:
		enc_err.set_physics_process(false)
	# プレイヤーを出口にテレポート
	player.input_disabled = false
	player.global_position = ch.exit_position + Vector3(0, 0.5, 0)
	print("[AutoTest] テレポート → ", ch.exit_position)


## F11: 全チャプター自動走破テスト開始
func _debug_start_autotest() -> void:
	if GameManager.autotest_active:
		GameManager.autotest_active = false
		print("[AutoTest] ===== 自動テスト停止 =====")
		return
	GameManager.autotest_active = true
	var wait_sec : float = GameManager.autotest_chapter_wait
	print("[AutoTest] ===== 全チャプター自動走破開始（各%ds滞在） =====" % int(wait_sec))
	_run_autotest(wait_sec)


func _run_autotest(wait_sec: float) -> void:
	var ch := GameManager.current_chapter
	if ch == null:
		return
	var cp_num : int = GameManager.chapter_index + 1
	print("[AutoTest] CP%d「%s」開始 — items=%d, exit=%s" % [
		cp_num, ch.chapter_name, GameManager.items_total, str(ch.exit_position)])
	# 滞在して動作確認（クラッシュしないことを確認）
	await get_tree().create_timer(wait_sec).timeout
	if not GameManager.autotest_active:
		return
	if not is_inside_tree():
		return
	# チャプターを即クリア
	print("[AutoTest] CP%d — %ds経過、即クリア実行" % [cp_num, int(wait_sec)])
	_debug_auto_complete_chapter()
	# 出口のコリジョンに触れるまで少し待つ
	await get_tree().create_timer(1.5).timeout
	if not GameManager.autotest_active:
		return
	if not is_inside_tree():
		return
	# まだ同じチャプターにいる場合（Exitに到達できなかった等）は強制進行
	if GameManager.chapter_index + 1 == cp_num:
		print("[AutoTest] CP%d — Exit未到達、強制進行" % cp_num)
		GameManager.advance_to_next_chapter()
