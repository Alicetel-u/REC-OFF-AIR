extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var toilet_scene = load(target_scene_path)
    var instance = toilet_scene.instantiate()

    var player = instance.find_child("Player", true, false)
    if not player:
        print("Error: Player not found.")
        quit()
        return
    
    # 1. 当たり判定を少し高くする (1.4m -> 1.6m)
    var col_shape = player.find_child("CollisionShape3D", true, false)
    if col_shape and col_shape.shape is CapsuleShape3D:
        var shape = col_shape.shape
        shape.height = 1.6 
        col_shape.position = Vector3(0, 0.8, 0)
        print("Updated player collision shape height to 1.6m")

    # 2. 目の高さ (Head) を調整 (1.3m -> 1.5m)
    var head = player.find_child("Head", true, false)
    if head:
        head.position = Vector3(0, 1.5, 0)
        print("Updated eyes height to 1.5m")

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Success: Player height adjusted slightly.")
    
    instance.free()
    quit()
