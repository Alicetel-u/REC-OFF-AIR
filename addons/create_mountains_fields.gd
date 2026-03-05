extends SceneTree

func _init():
    var base_node = Node3D.new()
    base_node.name = "MountainsAndFieldsRoot"

    # マテリアル設定
    var mat_field = ShaderMaterial.new()
    mat_field.shader = load("res://assets/models/environment/shaders/rice_field.gdshader")
    ResourceSaver.save(mat_field, "res://assets/models/environment/materials/rice_field.tres")
    
    var mat_wood = load("res://assets/models/bus_stop/materials/decayed_wood.tres")
    var mat_mountain = StandardMaterial3D.new()
    mat_mountain.albedo_color = Color(0.01, 0.02, 0.01) # 暗黒の山脈
    mat_mountain.roughness = 1.0

    # 1. 遠くを囲む山々 (巨大な半球やシリンダーを並べる)
    var mountain_root = Node3D.new()
    mountain_root.name = "DistantMountains"
    base_node.add_child(mountain_root)
    mountain_root.owner = base_node

    var num_mountains = 12
    var angle_step = PI * 2.0 / num_mountains
    for i in range(num_mountains):
        var m_angle = i * angle_step + randf_range(-0.2, 0.2)
        var m_dist = randf_range(160.0, 220.0) # 遠景
        
        var mountain = CSGSphere3D.new()
        mountain.name = "Mountain_" + str(i)
        mountain.radius = randf_range(40.0, 90.0)
        mountain.radial_segments = 12
        mountain.rings = 6
        mountain.position = Vector3(cos(m_angle) * m_dist, -10.0, sin(m_angle) * m_dist)
        
        # 縦に伸ばして山の稜線っぽくする
        var scale_y = randf_range(1.5, 3.0)
        mountain.scale = Vector3(1.0, scale_y, 1.0)
        
        # 山の形を不規則に
        mountain.rotation_degrees = Vector3(randf_range(-20, 20), randf_range(0, 360), randf_range(-20, 20))
        
        mountain.material = mat_mountain
        mountain_root.add_child(mountain)
        mountain.owner = base_node

    # 2. 田んぼ (道路の脇に広がる泥水と稲の平面)
    var field_w = 200.0
    var field_d = 200.0
    
    # 道路(+X方向)の右側 (Zがプラス)
    # 道路の幅は中心(Z=4.3)周りで幅8m(Z=0.3 〜 8.3)。
    var field_right = CSGBox3D.new()
    field_right.name = "RiceFieldRight"
    field_right.size = Vector3(field_w, 0.1, field_d)
    field_right.position = Vector3(50.0, -0.2, 8.3 + 100.0) # ピタリと道の右端に付ける
    field_right.material = mat_field
    base_node.add_child(field_right)
    field_right.owner = base_node

    # 道路の左側 (Zがマイナス)
    var field_left = CSGBox3D.new()
    field_left.name = "RiceFieldLeft"
    field_left.size = Vector3(field_w, 0.1, field_d)
    field_left.position = Vector3(50.0, -0.2, 0.3 - 100.0) # ピタリと道の左端に付ける
    field_left.material = mat_field
    base_node.add_child(field_left)
    field_left.owner = base_node

    # 田んぼのあぜ道 (横切る土の道)
    var mat_dirt = StandardMaterial3D.new()
    mat_dirt.albedo_color = Color(0.1, 0.08, 0.05)
    mat_dirt.roughness = 0.9
    
    var path1 = CSGBox3D.new()
    path1.name = "DirtPath1"
    # 村のゲート(Z=4.3)から神社(Z=50)までを繋ぐあぜ道
    var p1_len = 46.0 # 50 - 4
    path1.size = Vector3(1.5, 0.15, p1_len)
    path1.position = Vector3(30.0, -0.15, 27.0) # (4.3+50)/2 附近
    path1.material = mat_dirt
    base_node.add_child(path1)
    path1.owner = base_node
    
    # 3. 不気味な案山子 (Scarecrow)
    # ※現在はcreate_scarecrow.gdで高度なモデルを生成しているため、ここでは生成しない
    
    var packed = PackedScene.new()
    packed.pack(base_node)
    
    ResourceSaver.save(packed, "res://assets/models/environment/MountainsAndFields.tscn")
    print("Mountains and Fields successfully created (Scarecrows skipped)!")
    quit()
