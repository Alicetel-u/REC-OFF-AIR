extends CharacterBody3D
class_name Player

const WALK_SPEED     := 4.0
const DASH_SPEED     := 8.0
const GRAVITY        := 9.8
const MOUSE_SENS     := 0.002
const BOB_FREQ       := 2.2
const BOB_AMP        := 0.06
const BATTERY_DRAIN  := 0.045   # 懐中電灯ON時の消耗 /sec
const BATTERY_CHARGE := 0.018   # 懐中電灯OFF時の回復 /sec

# 手ブレ定数
const SWAY_SPEED     := 1.8    # 揺れの速度
const SWAY_AMOUNT    := 0.018  # 静止時の揺れ幅 (rad)
const SWAY_MOVE_MULT := 2.5    # 移動時の揺れ倍率
const HEAD_PITCH_MIN := -1.2   # 見下ろし限界 (rad)
const HEAD_PITCH_MAX := 1.2    # 見上げ限界 (rad)

@onready var head       : Node3D      = $Head
@onready var camera     : Camera3D    = $Head/Camera3D
@onready var flashlight : SpotLight3D = $Head/Camera3D/Flashlight

var bob_t        : float = 0.0
var flashlight_on: bool  = true
var _prev_moving : bool  = false
var battery      : float = 1.0   # 0.0 〜 1.0
var _sway_t      : float = 0.0   # 手ブレ用タイマー
var forced_moving : bool = false  # EntranceDirector等から強制的に移動中扱い

# ── カメラシェイク ──
var _shake_intensity : float = 0.0   # 現在のシェイク強度
var _shake_decay     : float = 0.0   # 減衰速度

# ── デバッグ ──
const _DEBUG_LOGGING : bool = false  # デバッグログ出力（リリース時はfalse）
var _auto_walk    : bool  = false    # デバッグ時は true に
var _auto_timer   : float = 0.0
var _auto_dir     : Vector3 = Vector3.FORWARD
var _auto_turn_t  : float = 3.0
var _log_timer    : float = 0.0
var _log_prev_nodes : float = 0.0
var _log_prev_mem   : float = 0.0

signal player_moved
signal flashlight_toggled(on: bool)
signal battery_changed(level: float)


func _ready() -> void:
	add_to_group("player")
	# マウスモードはMain.gdが管理するため、ここでは設定しない
	# バッテリー・懐中電灯は常時ON（実装前の固定値）
	battery = 1.0
	flashlight_on = true
	flashlight.visible = true


var input_disabled : bool = false:
	set(v):
		input_disabled = v
		if not v and is_inside_tree() and GameManager.state == GameManager.State.PLAYING:
			# 操作有効化時に自らマウスをキャプチャしに行く（保険）
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# ESCはMain._input()で処理済み（set_input_as_handled）

	if GameManager.state != GameManager.State.PLAYING:
		return

	if input_disabled:
		return

	# マウスルックはCAPTUREDモード時のみ（VISIBLEモードでは無効）
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotate_x(-event.relative.y * MOUSE_SENS)
		head.rotation.x = clamp(head.rotation.x, HEAD_PITCH_MIN, HEAD_PITCH_MAX)

	if event.is_action_pressed("toggle_flashlight"):
		_toggle_flashlight()


func _toggle_flashlight() -> void:
	# TODO: バッテリーシステム実装後に有効化
	pass


func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING or input_disabled:
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var dir := Vector3.ZERO
	var spd := WALK_SPEED

	if _auto_walk:
		# 自動歩行: ランダムに方向転換しながら歩く
		_auto_timer += delta
		if _auto_timer >= _auto_turn_t:
			_auto_timer = 0.0
			_auto_turn_t = randf_range(2.0, 5.0)
			rotate_y(randf_range(-PI * 0.5, PI * 0.5))
		dir = -transform.basis.z
		# FPS・メモリログ（5秒ごと・_DEBUG_LOGGING=true時のみ）
		_log_timer += delta
		if _DEBUG_LOGGING and _log_timer >= 5.0:
			_log_timer = 0.0
			var fps := Engine.get_frames_per_second()
			var mem := OS.get_static_memory_usage() / 1048576.0
			var vram := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
			var tex_mem := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
			var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
			var resources := Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
			var phys3d := Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)
			var phys_pairs := Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS)
			var t := Time.get_ticks_msec() / 1000.0
			print("[DEBUG] t=%.0fs FPS=%d MEM=%.0fMB VRAM=%.0fMB TEX=%.0fMB NODES=%.0f RES=%.0f PHYS3D=%.0f PAIRS=%.0f pos=%s" % [t, fps, mem, vram, tex_mem, nodes, resources, phys3d, phys_pairs, str(global_position)])
			# ノード・メモリの急増を警告（リーク早期検知）
			var node_diff := nodes - _log_prev_nodes
			var mem_diff  := mem   - _log_prev_mem
			if _log_prev_nodes > 0 and node_diff > 20:
				print("[WARN] NODE SPIKE +%.0f in 5s — possible node leak!" % node_diff)
			if _log_prev_mem > 0 and mem_diff > 5.0:
				print("[WARN] MEM SPIKE +%.1fMB in 5s — possible memory leak!" % mem_diff)
			_log_prev_nodes = nodes
			_log_prev_mem   = mem
	else:
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		dir = (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
		spd = DASH_SPEED if Input.is_action_pressed("dash") else WALK_SPEED

	if dir != Vector3.ZERO:
		velocity.x = dir.x * spd
		velocity.z = dir.z * spd
	else:
		velocity.x = move_toward(velocity.x, 0.0, spd)
		velocity.z = move_toward(velocity.z, 0.0, spd)

	move_and_slide()

	var now_moving := dir != Vector3.ZERO
	if now_moving and not _prev_moving:
		player_moved.emit()
	_prev_moving = now_moving

	# カメラボブを先に更新し、着地タイミング（bob_t が π を跨ぐ瞬間）で足音1回
	var dashing := Input.is_action_pressed("dash") if now_moving else false
	var prev_bob := bob_t
	_do_camera_bob(delta, now_moving)
	# bob_t が π の倍数を跨いだら着地 → 足音1回
	if now_moving and is_on_floor() and prev_bob > 0.0:
		if int(bob_t / PI) != int(prev_bob / PI):
			SoundManager.play_footstep(GameManager.chapter_index, dashing)
	_do_flashlight_sway(delta, now_moving or forced_moving)
	_do_camera_shake(delta)




func _do_camera_bob(delta: float, moving: bool) -> void:
	if moving and is_on_floor():
		var rate := 1.8 if Input.is_action_pressed("dash") else 1.0
		bob_t += delta * BOB_FREQ * rate
		var target := Vector3(
			sin(bob_t * 2.0) * BOB_AMP * 0.4,
			abs(sin(bob_t))  * BOB_AMP,
			0.0
		)
		camera.position = camera.position.lerp(target, delta * 12.0)
	else:
		bob_t = 0.0
		camera.position = camera.position.lerp(Vector3.ZERO, delta * 6.0)


## カメラシェイク開始（intensity: 強さ、duration: 秒）
func start_camera_shake(intensity: float = 0.05, duration: float = 0.5) -> void:
	_shake_intensity = intensity
	_shake_decay = intensity / max(duration, 0.05)


func _do_camera_shake(delta: float) -> void:
	if _shake_intensity <= 0.0:
		return
	var offset := Vector3(
		randf_range(-1.0, 1.0) * _shake_intensity,
		randf_range(-1.0, 1.0) * _shake_intensity,
		0.0
	)
	camera.position += offset
	_shake_intensity = max(_shake_intensity - _shake_decay * delta, 0.0)


func _do_flashlight_sway(delta: float, moving: bool) -> void:
	if not flashlight_on:
		flashlight.rotation = flashlight.rotation.lerp(Vector3.ZERO, delta * 8.0)
		return

	_sway_t += delta * SWAY_SPEED
	var mult := SWAY_MOVE_MULT if moving else 1.0
	var dash_mult := 1.6 if Input.is_action_pressed("dash") else 1.0
	var amt := SWAY_AMOUNT * mult * dash_mult

	# 複数のsin波を重ねて自然な手ブレに
	var sway_x := sin(_sway_t * 1.0) * amt + sin(_sway_t * 2.7) * amt * 0.4
	var sway_y := sin(_sway_t * 1.3) * amt * 0.7 + cos(_sway_t * 2.1) * amt * 0.3

	var target_rot := Vector3(sway_x, sway_y, 0.0)
	flashlight.rotation = flashlight.rotation.lerp(target_rot, delta * 6.0)


