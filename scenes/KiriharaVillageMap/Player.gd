extends CharacterBody3D

const SPEED = 6.0
const SENSITIVITY = 0.003

@onready var head = $Head
@onready var flashlight = $Head/Camera3D/SpotLight3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# 懐中電灯の切り替え（Fキー）
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F:
		flashlight.visible = !flashlight.visible

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENSITIVITY)
		head.rotate_x(-event.relative.y * SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, -1.4, 1.4)
	
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	# 落下救済
	if global_position.y < -10.0:
		global_position = Vector3(0, 5, 0)
		velocity = Vector3.ZERO

	if not is_on_floor():
		velocity += get_gravity() * delta

	# 移動：WASDまたは矢印キーを直接チェック（デフォルトのui_アクションに依存しない）
	var input_dir = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input_dir.x += 1
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
