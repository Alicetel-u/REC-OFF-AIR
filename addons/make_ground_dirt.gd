extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var toilet_scene = load(target_scene_path)
    if not toilet_scene:
        print("Error: Could not load toilet scene.")
        quit()
        return

    var instance = toilet_scene.instantiate()
    
    # 1. 汎用的な「土」マテリアルを作成
    var dirt_mat = StandardMaterial3D.new()
    dirt_mat.albedo_color = Color(0.15, 0.1, 0.05) # 暗い土の色
    dirt_mat.roughness = 0.9
    
    # 2. MountainsAndFields内の地面を土に変える
    var mf = instance.get_node_or_null("MountainsAndFields")
    if mf:
        print("Changing background elements to dirt...")
        for child in mf.get_children():
            if "Field" in child.name or "Path" in child.name or child.name.begins_with("Ground"):
                if child is CSGPrimitive3D:
                    child.material = dirt_mat
                elif child is MeshInstance3D:
                    child.material_override = dirt_mat

    # 3. トイレの周りに広大な土の地面を追加
    var world_ground = instance.get_node_or_null("WorldDirtGround")
    if world_ground:
        instance.remove_child(world_ground)
        world_ground.free()
    
    print("Adding a massive dirt ground plane...")
    world_ground = CSGBox3D.new()
    world_ground.name = "WorldDirtGround"
    world_ground.size = Vector3(200, 0.2, 200)
    world_ground.position = Vector3(0, -0.1, 0) # 地面スレスレ
    world_ground.material = dirt_mat
    world_ground.use_collision = true
    
    instance.add_child(world_ground)
    world_ground.owner = instance

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Success: Ground around the toilet turned to dirt!")
    
    instance.free()
    quit()
