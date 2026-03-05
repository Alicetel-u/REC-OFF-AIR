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
    
    # 主観の位置 (Head) をさらに高く調整 (1.65m -> 1.75m)
    var head = player.find_child("Head", true, false)
    if head:
        head.position = Vector3(0, 1.75, 0)
        print("Updated eyes height to 1.75m")

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Success: Eyes height increased to 1.75m.")
    
    instance.free()
    quit()
