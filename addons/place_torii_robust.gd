extends SceneTree

func _init():
    place_torii_robust()
    quit()

func set_owner_recursive(node, root):
    node.owner = root
    for child in node.get_children():
        set_owner_recursive(child, root)

func place_torii_robust():
    var scene_path = "res://scenes/Main.tscn"
    var torii_path = "res://shaders/素材/鳥居.glb"
    
    if not FileAccess.file_exists(torii_path):
        print("Error: Torii GLB not found at ", torii_path)
        return

    var main_scene = load(scene_path)
    if not main_scene: 
        print("Error: Failed to load Main.tscn")
        return
    
    var root = main_scene.instantiate()
    var shrine = root.get_node_or_null("SmallShrine")
    if not shrine: 
        print("Error: SmallShrine node not found")
        return
    
    # 既存の鳥居を削除
    var old = shrine.get_node_or_null("ToriiGate")
    if old: 
        old.free()
        print("Removed existing Torii node.")
    
    var torii_v = load(torii_path)
    if not torii_v:
        print("Error: Could not load Torii GLB resource.")
        return
        
    var torii = torii_v.instantiate()
    torii.name = "ToriiGate"
    
    # 位置調整 (SmallShrineのローカル座標)
    # 参道の入り口が Z=15.4 付近
    torii.position = Vector3(0, 0, 15.2)
    torii.scale = Vector3(4, 4, 4) # 少し小さめにして調整しやすくする
    torii.rotation_degrees = Vector3(0, 180, 0) # 参道(祠)を向くように反転
    
    shrine.add_child(torii)
    
    # 全ての小ノードに Owner を設定（これが保存に必須）
    set_owner_recursive(torii, root)
    
    var packed = PackedScene.new()
    var result = packed.pack(root)
    if result == OK:
        ResourceSaver.save(packed, scene_path)
        print("SUCCESS: Torii placed and saved to Main.tscn.")
        print("Path: ", torii_path, " -> SmallShrine/ToriiGate")
    else:
        print("Error: Failed to pack scene. Code: ", result)
