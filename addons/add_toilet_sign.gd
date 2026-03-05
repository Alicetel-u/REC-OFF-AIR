extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var texture_path = "res://assets/textures/toilet_sign.png"
    
    var toilet_scene = load(target_scene_path)
    var texture = load(texture_path)
    
    if not toilet_scene or not texture:
        print("Error: Could not load scene or texture.")
        quit()
        return

    var instance = toilet_scene.instantiate()
    
    # 既存の看板があれば削除
    var old_sign = instance.get_node_or_null("EntranceSign")
    if old_sign:
        instance.remove_child(old_sign)
        old_sign.free()

    print("Adding toilet sign to the entrance wall...")
    var sprite = Sprite3D.new()
    sprite.name = "EntranceSign"
    sprite.texture = texture
    instance.add_child(sprite)
    sprite.owner = instance
    
    # 入り口(Z=-4, X=-1.5)の左側の壁面に配置
    # 向きは-Z方向(外側)を向くように設定
    sprite.position = Vector3(-2.6, 2.0, -4.01) # Xをさらにマイナス方向にずらす
    sprite.rotation_degrees = Vector3(0, 0, 0) # デフォルトで-Zを向く
    sprite.scale = Vector3(0.5, 0.5, 0.5) # サイズ調整

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Success: Toilet sign added to the left side of the entrance.")
    
    instance.free()
    quit()
