extends Camera3D

@export var move_speed: float = 3.0
@export var mouse_sensitivity: float = 0.003
@export var shake_amount: float = 0.015
@export var shake_speed: float = 2.0
@export var flashlight_path: NodePath

@onready var flashlight = get_node(flashlight_path)

var _time = 0.0
var _rotation_x = 0.0
var _rotation_y = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_rotation_y = rotation.y
	_rotation_x = rotation.x

func _input(event):
	if event is InputEventMouseMotion:
		_rotation_y -= event.relative.x * mouse_sensitivity
		_rotation_x -= event.relative.y * mouse_sensitivity
		_rotation_x = clamp(_rotation_x, -PI/2, PI/2)

func _process(delta):
	# 視点移動
	rotation.y = _rotation_y
	rotation.x = _rotation_x

	# プレイヤーの移動 (WASDの物理キーを直接判定して確実に動かす)
	var input_dir = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_D): input_dir.x += 1
	if Input.is_physical_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_S): input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_W): input_dir.y -= 1
	
	var move_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if move_dir.length() > 0:
		global_position += move_dir * move_speed * delta

	# カメラの手ブレ（歩行時も適用）
	_time += delta * shake_speed
	var current_shake = shake_amount * (2.0 if move_dir.length() > 0.1 else 1.0)
	
	var offset_x = sin(_time * 0.7) * current_shake
	var offset_y = cos(_time * 1.3) * current_shake
	
	h_offset = offset_x
	v_offset = offset_y

	# 懐中電灯の追従（視点と完全に固定）
	if flashlight:
		flashlight.global_transform = global_transform

	# ESCキーでマウスロック解除
	if Input.is_action_just_pressed("ui_cancel") or Input.is_physical_key_pressed(KEY_ESCAPE):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
