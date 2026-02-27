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

@onready var head       : Node3D      = $Head
@onready var camera     : Camera3D    = $Head/Camera3D
@onready var flashlight : SpotLight3D = $Head/Camera3D/Flashlight

var bob_t        : float = 0.0
var flashlight_on: bool  = false
var _prev_moving : bool  = false
var battery      : float = 1.0   # 0.0 〜 1.0

signal player_moved
signal flashlight_toggled(on: bool)
signal battery_changed(level: float)


func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


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
	if not flashlight_on and battery <= 0.0:
		return
	flashlight_on = not flashlight_on
	flashlight.visible = flashlight_on
	flashlight_toggled.emit(flashlight_on)


func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	_update_battery(delta)

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir   := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var spd   := DASH_SPEED if Input.is_action_pressed("dash") else WALK_SPEED

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


func _update_battery(delta: float) -> void:
	if flashlight_on:
		battery = max(0.0, battery - BATTERY_DRAIN * delta)
		if battery <= 0.0:
			flashlight_on = false
			flashlight.visible = false
			flashlight_toggled.emit(false)
	else:
		battery = min(1.0, battery + BATTERY_CHARGE * delta)
	battery_changed.emit(battery)


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
