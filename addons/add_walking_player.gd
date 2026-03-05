extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var toilet_scene = load(target_scene_path)
    var instance = toilet_scene.instantiate()

    # 1. 既存のカメラをクリーンアップ
    var old_cam = instance.find_child("Camera3D", true, false)
    if old_cam:
        old_cam.get_parent().remove_child(old_cam)
        old_cam.free()

    # 2. Playerノード (CharacterBody3D) を作成
    var player = CharacterBody3D.new()
    player.name = "Player"
    instance.add_child(player)
    player.owner = instance
    player.position = Vector3(0, 1.1, 5) # 入り口付近

    # 3. 当たり判定 (CollisionShape3D) を追加
    var collision = CollisionShape3D.new()
    var shape = CapsuleShape3D.new()
    shape.radius = 0.4
    shape.height = 1.8
    collision.shape = shape
    player.add_child(collision)
    collision.owner = instance
    collision.position = Vector3(0, 0.9, 0)

    # 4. 頭部ノード (Node3D) と カメラ を追加
    var head = Node3D.new()
    head.name = "Head"
    player.add_child(head)
    head.owner = instance
    head.position = Vector3(0, 1.7, 0) # 目の高さ

    var camera = Camera3D.new()
    camera.name = "Camera3D"
    head.add_child(camera)
    camera.owner = instance

    # 5. 懐中電灯 を追加
    var flashlight = SpotLight3D.new()
    flashlight.name = "Flashlight"
    flashlight.light_energy = 8.0
    flashlight.spot_range = 25.0
    flashlight.spot_angle = 35.0
    flashlight.shadow_enabled = true
    camera.add_child(flashlight)
    flashlight.owner = instance

    # 6. 移動用スクリプトをプレイヤーにアタッチ
    var script = GDScript.new()
    script.set_source_code("""
extends CharacterBody3D

const SPEED = 3.0
const MOUSE_SENSITIVITY = 0.002

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
        head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
    
    if event.is_action_pressed("ui_cancel"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
    if not is_on_floor():
        velocity.y -= 9.8 * delta

    var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)

    move_and_slide()
""")
    player.set_script(script)

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Player character with walking logic successfully added!")
    
    instance.free()
    quit()
