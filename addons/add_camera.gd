extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var toilet_scene = load(target_scene_path)
    var instance = toilet_scene.instantiate()

    # カメラがなければ追加
    if not instance.find_child("Camera3D", true, false):
        print("Adding a temporary camera...")
        var camera = Camera3D.new()
        camera.name = "Camera3D"
        instance.add_child(camera)
        camera.owner = instance
        # 全体が見える位置に配置
        camera.position = Vector3(0, 2, 8)
        camera.look_at(Vector3(0, 1.5, 0))

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Camera check/add completed.")
    
    instance.free()
    quit()
