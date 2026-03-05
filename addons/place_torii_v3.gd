extends SceneTree

func _init():
    var scene_path = "res://scenes/Main.tscn"
    var torii_path = "res://shaders/素材/鳥居.glb"
    
    var main_scene = load(scene_path)
    var root = main_scene.instantiate()
    var shrine = root.get_node_or_null("SmallShrine")
    
    var torii = load(torii_path).instantiate()
    torii.name = "ToriiGate"
    
    # ユーザーが「設置されていない」と言う場合、目立たないか、位置が違う可能性がある
    # 大通り（入り口）に 12倍の大きさで設置
    torii.position = Vector3(0, 0, 15.5)
    torii.scale = Vector3(12, 12, 12)
    torii.rotation_degrees = Vector3(0, 0, 0) # 向きを元に戻してみる
    
    # 子ノードを削除（クリーンにする）
    for child in torii.get_children():
        if child.name.contains("tripo"): # 怪しい自動生成ノードがあれば
            pass
            
    shrine.add_child(torii)
    set_owner_recursive(torii, root)
    
    var packed = PackedScene.new()
    packed.pack(root)
    ResourceSaver.save(packed, scene_path)
    print("Torii placed with Scale 12 at Z=15.5")
    quit()

func set_owner_recursive(node, root):
    node.owner = root
    for child in node.get_children():
        set_owner_recursive(child, root)
