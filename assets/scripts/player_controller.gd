extends CharacterBody3D

const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.003

@onready var head = $Head

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    print("Player script ready. Use WASD to move.")

func _input(event):
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
        head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))
    
    if event is InputEventKey:
        if event.pressed and event.keycode == KEY_ESCAPE:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
    var input_dir = Vector2.ZERO
    if Input.is_key_pressed(KEY_W): input_dir.y -= 1
    if Input.is_key_pressed(KEY_S): input_dir.y += 1
    if Input.is_key_pressed(KEY_A): input_dir.x -= 1
    if Input.is_key_pressed(KEY_D): input_dir.x += 1
    
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    # 物理演算で動けない場合のデバッグ用：強制的に座標を書き換える
    if direction:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
        # move_and_slideがダメな場合でも動けるように少しだけ座標を足す
        global_position += direction * SPEED * delta
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)

    move_and_slide()
