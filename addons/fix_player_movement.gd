extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var toilet_scene = load(target_scene_path)
    var instance = toilet_scene.instantiate()

    var player = instance.find_child("Player", true, false)
    if not player:
        print("Error: Player node not found.")
        quit()
        return
    
    # 埋まり防止のため位置を少し上げる
    player.position = Vector3(0, 1.5, 3) 

    # 文字列ベースのスクリプトを直接キー判定を行うものに書き換え
    var new_script = GDScript.new()
    new_script.set_source_code("""
extends CharacterBody3D

const SPEED = 4.0
const MOUSE_SENSITIVITY = 0.003
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
        head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))
    
    if event is InputEventKey:
        if event.pressed and event.keycode == KEY_ESCAPE:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
    if not is_on_floor():
        velocity.y -= gravity * delta

    if is_on_floor() and Input.is_key_pressed(KEY_SPACE):
        velocity.y = JUMP_VELOCITY

    var input_dir = Vector2.ZERO
    if Input.is_key_pressed(KEY_W): input_dir.y -= 1
    if Input.is_key_pressed(KEY_S): input_dir.y += 1
    if Input.is_key_pressed(KEY_A): input_dir.x -= 1
    if Input.is_key_pressed(KEY_D): input_dir.x += 1
    
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)

    move_and_slide()
""")
    player.set_script(new_script)

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Fixed player script with direct keyboard input and height adjustment.")
    
    instance.free()
    quit()
