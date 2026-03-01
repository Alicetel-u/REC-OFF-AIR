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
const SWAY_AMOUNT    := 0.004  # 静止時の揺れ幅 (rad)
const SWAY_MOVE_MULT := 2.5    # 移動時の揺れ倍率

@onready var head       : Node3D      = $Head
@onready var camera     : Camera3D    = $Head/Camera3D
@onready var flashlight : SpotLight3D = $Head/Camera3D/Flashlight

var bob_t        : float = 0.0
var flashlight_on: bool  = true
var _prev_moving : bool  = false
var battery      : float = 1.0   # 0.0 〜 1.0
var _sway_t      : float = 0.0   # 手ブレ用タイマー

# ── デバッグ自動歩行 ──
var _auto_walk    : bool  = false  # デバッグ時は true に
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
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# バッテリー・懐中電灯は常時ON（実装前の固定値）
	battery = 1.0
	flashlight_on = true
	flashlight.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		if event.is_action_pressed("ui_accept"):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotate_x(-event.relative.y * MOUSE_SENS)
		head.rotation.x = clamp(head.rotation.x, -1.2, 1.2)

	if event.is_action_pressed("toggle_flashlight"):
		_toggle_flashlight()

	if event.is_action_pressed("ui_cancel"):
		var mode := Input.get_mouse_mode()
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)


func _toggle_flashlight() -> void:
	# TODO: バッテリーシステム実装後に有効化
	pass


func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
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
		# FPS・メモリログ（5秒ごと）
		_log_timer += delta
		if _log_timer >= 5.0:
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

	_do_camera_bob(delta, now_moving)
	_do_flashlight_sway(delta, now_moving)




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


