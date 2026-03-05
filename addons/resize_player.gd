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
    
    # 1. 当たり判定を低く、細くする
    var col_shape = player.find_child("CollisionShape3D", true, false)
    if col_shape and col_shape.shape is CapsuleShape3D:
        var shape = col_shape.shape
        shape.height = 1.4 # 身長を1.4mに（子供や屈んだ大人くらい）
        shape.radius = 0.3 # 横幅をスリムに
        col_shape.position = Vector3(0, 0.7, 0) # 判定の中心を調整
        print("Updated player collision shape (height: 1.4m, radius: 0.3m)")

    # 2. 目の高さ (Head) を調整
    var head = player.find_child("Head", true, false)
    if head:
        head.position = Vector3(0, 1.3, 0) # 目の高さを地面から1.3mに
        print("Updated eyes height to 1.3m")

    # 3. スタート位置を微調整（鴨居の下を避ける）
    player.position = Vector3(0, 0.1, 5)

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Success: Player size adjusted for entrance.")
    
    instance.free()
    quit()
