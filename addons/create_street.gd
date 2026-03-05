extends SceneTree

func _init():
    var base_node = Node3D.new()
    base_node.name = "StreetRoot"
    
    # マテリアル設定
    var mat_asphalt = ShaderMaterial.new()
    mat_asphalt.shader = load("res://assets/models/environment/shaders/dark_asphalt.gdshader")
    ResourceSaver.save(mat_asphalt, "res://assets/models/environment/materials/dark_asphalt.tres")
    
    var mat_wood = load("res://assets/models/bus_stop/materials/decayed_wood.tres")
    var mat_metal = load("res://assets/models/bus_stop/materials/rusty_bench.tres")
    
    # 永遠に続く道 (Z軸に長く伸びる)
    var road_len = 200.0
    var road_w = 6.0
    var road = CSGBox3D.new()
    road.name = "LongAsphaltRoad"
    road.size = Vector3(road_w, 0.2, road_len)
    road.position = Vector3(0, -0.1, 0)
    road.use_collision = true
    road.material_override = mat_asphalt
    if "material" in road: road.material = mat_asphalt
    base_node.add_child(road)
    road.owner = base_node
    
    # 歩道の縁石 (ガードレール代わり)
    var curb = CSGBox3D.new()
    curb.name = "LeftCurb"
    curb.size = Vector3(0.3, 0.4, road_len)
    curb.position = Vector3(road_w/2 + 0.15, 0.1, 0)
    curb.use_collision = true
    var curb_mat = StandardMaterial3D.new()
    curb_mat.albedo_color = Color(0.2, 0.2, 0.2)
    curb_mat.roughness = 0.95
    curb.material_override = curb_mat
    if "material" in curb: curb.material = curb_mat
    base_node.add_child(curb)
    curb.owner = base_node
    
    var right_curb = curb.duplicate()
    right_curb.name = "RightCurb"
    right_curb.position = Vector3(-road_w/2 - 0.15, 0.1, 0)
    base_node.add_child(right_curb)
    right_curb.owner = base_node

    # 傾いた電柱を並べる
    var pole_count = 10
    var z_spacing = road_len / pole_count
    
    for i in range(pole_count):
        var z_pos = -road_len/2 + i * z_spacing
        
        var pole_group = Node3D.new()
        pole_group.name = "TelephonePole_" + str(i)
        pole_group.position = Vector3(-road_w/2 - 0.6, 0.0, z_pos)
        base_node.add_child(pole_group)
        pole_group.owner = base_node
        
        # 傾きをランダムに
        pole_group.rotation_degrees.z = randf_range(-8.0, 8.0)
        pole_group.rotation_degrees.x = randf_range(-5.0, 5.0)
        
        # 柱
        var pillar = CSGCylinder3D.new()
        pillar.name = "PoleBody"
        pillar.radius = 0.15
        pillar.height = 7.0
        pillar.position = Vector3(0, 3.5, 0)
        pillar.use_collision = true
        pillar.material = mat_wood
        pole_group.add_child(pillar)
        pillar.owner = base_node
        
        # 横木
        var cross = CSGBox3D.new()
        cross.name = "CrossBeam"
        cross.size = Vector3(1.2, 0.1, 0.1)
        cross.position = Vector3(0, 6.2, 0.1)
        cross.material = mat_wood
        pole_group.add_child(cross)
        cross.owner = base_node
        
        # 錆びたトランス(変圧器) - ランダム確率で付いている
        if randf() > 0.5:
            var trans = CSGCylinder3D.new()
            trans.name = "Transformer"
            trans.radius = 0.3
            trans.height = 0.6
            trans.position = Vector3(-0.3, 5.5, 0.25)
            trans.material = mat_metal
            pole_group.add_child(trans)
            trans.owner = base_node

    # ゴミの散乱（プレイヤーが歩く道にさりげなく）
    for i in range(15):
        var can = CSGCylinder3D.new()
        can.name = "TrashCan_" + str(i)
        can.radius = randf_range(0.02, 0.05)
        can.height = randf_range(0.08, 0.15)
        can.position = Vector3(randf_range(-road_w/2+0.5, road_w/2-0.5), 0.05, randf_range(-road_len/2, road_len/2))
        can.rotation_degrees = Vector3(randf_range(0, 360), randf_range(0, 360), randf_range(0, 360))
        can.material = mat_metal
        if can.position.y > 0.02: can.position.y = 0.02
        base_node.add_child(can)
        can.owner = base_node

    var packed = PackedScene.new()
    packed.pack(base_node)
    
    var dir = DirAccess.open("res://assets")
    if not dir.dir_exists("models/environment"):
        dir.make_dir("models/environment")
        
    ResourceSaver.save(packed, "res://assets/models/environment/DarkStreet.tscn")
    print("Dark Street Environment created!")
    quit()
