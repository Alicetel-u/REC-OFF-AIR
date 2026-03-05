extends SceneTree

func _init():
    var base_node = Node3D.new()
    base_node.name = "BusStopRoot"
    
    var old_scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var old_instance = old_scene.instantiate()
    
    # 既存の環境設定や光源などを引き継ぎつつ、超リアル化（AO等）を有効化
    for child in old_instance.get_children():
        if child is WorldEnvironment:
            var dup = child.duplicate()
            # SSAO (隅の暗がり) と SSIL (間接光) を有効化して「CGっぽさ（のっぺり感）」を消滅させる
            if dup.environment:
                dup.environment.ssao_enabled = true
                dup.environment.ssao_radius = 1.0
                dup.environment.ssao_intensity = 2.0
                dup.environment.ssil_enabled = true
                dup.environment.sdfgi_enabled = true
                dup.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
            base_node.add_child(dup)
            dup.owner = base_node
        elif child is SpotLight3D or child is OmniLight3D or child is DirectionalLight3D:
            var dup = child.duplicate()
            base_node.add_child(dup)
            dup.owner = base_node
    old_instance.queue_free()

    var mat_wood = load("res://assets/models/bus_stop/materials/decayed_wood.tres")
    var mat_totan = load("res://assets/models/bus_stop/materials/rusty_totan.tres")
    
    var ground = CSGBox3D.new()
    ground.name = "GroundAsphalt"
    ground.size = Vector3(20, 0.1, 20)
    ground.position = Vector3(0, -0.05, 0)
    ground.use_collision = true
    var StandardMaterial3D_ground = StandardMaterial3D.new()
    StandardMaterial3D_ground.albedo_color = Color(0.15, 0.15, 0.15)
    StandardMaterial3D_ground.roughness = 0.9
    ground.material = StandardMaterial3D_ground
    base_node.add_child(ground)
    ground.owner = base_node

    var shelter = CSGCombiner3D.new()
    shelter.name = "BusStopShelter"
    shelter.position = Vector3(0, 0, -2)
    base_node.add_child(shelter)
    shelter.owner = base_node

    # 構造サイズを劇的にシェイプアップ（スケールダウン）し、コンパクトな田舎のバス停サイズに
    var p_thickness = 0.12 # 柱の細さ（0.15だと太すぎてCGっぽくなる）
    var shelter_w = 3.0    # 横幅を6.0から3.0へ大幅縮小
    var shelter_d = 1.6    # 奥行きも少し狭く
    var h_front = 2.5      # 前の高さ
    var h_back = 2.1       # 後ろの高さ

    var pillars = CSGCombiner3D.new()
    pillars.name = "Pillars"
    pillars.material_override = mat_wood
    shelter.add_child(pillars)
    pillars.owner = base_node

    var x_positions = [-shelter_w/2, -shelter_w/6, shelter_w/6, shelter_w/2]
    # 後ろの柱
    for i in range(4):
        var p = CSGBox3D.new()
        p.name = "BackPillar_" + str(i)
        p.size = Vector3(p_thickness, h_back, p_thickness)
        p.position = Vector3(x_positions[i], h_back/2, -shelter_d/2)
        pillars.add_child(p)
        p.owner = base_node

    # 前の柱
    for i in [0, 3]:
        var p = CSGBox3D.new()
        p.name = "FrontPillar_" + str(i)
        p.size = Vector3(p_thickness, h_front, p_thickness)
        p.position = Vector3(x_positions[i], h_front/2, shelter_d/2)
        pillars.add_child(p)
        p.owner = base_node

    # 梁
    for y in [0.3, h_back/2, h_back - 0.1]:
        var beam = CSGBox3D.new()
        beam.name = "BackBeam_y" + str(y)
        beam.size = Vector3(shelter_w + p_thickness, p_thickness*0.6, p_thickness*0.6)
        beam.position = Vector3(0, y, -shelter_d/2 + p_thickness/2)
        pillars.add_child(beam)
        beam.owner = base_node

    var front_beam = CSGBox3D.new()
    front_beam.name = "FrontTopBeam"
    front_beam.size = Vector3(shelter_w + p_thickness, p_thickness*0.8, p_thickness*0.8)
    front_beam.position = Vector3(0, h_front - 0.05, shelter_d/2)
    pillars.add_child(front_beam)
    front_beam.owner = base_node

    for i in [0, 3]:
        var side_beam = CSGBox3D.new()
        side_beam.name = "SideBeam_" + str(i)
        side_beam.size = Vector3(p_thickness*0.8, p_thickness*0.8, shelter_d)
        side_beam.position = Vector3(x_positions[i], h_back/2, 0)
        pillars.add_child(side_beam)
        side_beam.owner = base_node

    # 屋根の垂木と傾き（前が高く、後ろが低い）GodotのZ軸は手前が+,奥が-
    # つまり屋根は前(+Z)が上がり、後ろ(-Z)が下がるので、X軸回転はプラス方向。
    var tilt_angle = atan((h_front - h_back) / shelter_d)
    var rafter_length = sqrt(shelter_d*shelter_d + (h_front-h_back)*(h_front-h_back)) + 0.8
    for i in range(4):
        var rafter = CSGBox3D.new()
        rafter.name = "Rafter_" + str(i)
        rafter.size = Vector3(0.08, 0.15, rafter_length)
        rafter.position = Vector3(x_positions[i], (h_front+h_back)/2, 0)
        rafter.rotation.x = -tilt_angle
        pillars.add_child(rafter)
        rafter.owner = base_node

    # 壁
    var walls = CSGCombiner3D.new()
    walls.name = "Walls"
    walls.material_override = mat_totan
    shelter.add_child(walls)
    walls.owner = base_node

    var l_wall = CSGBox3D.new()
    l_wall.name = "LeftWall"
    l_wall.size = Vector3(0.02, h_back, shelter_d)
    l_wall.position = Vector3(-shelter_w/2 + p_thickness*0.8, h_back/2 + 0.1, 0)
    walls.add_child(l_wall)
    l_wall.owner = base_node

    for i in range(3):
        var b_wall = CSGBox3D.new()
        b_wall.name = "BackWall_" + str(i)
        b_wall.size = Vector3(shelter_w/3 - p_thickness, h_back - 0.2, 0.02)
        var center_x = (x_positions[i] + x_positions[i+1]) / 2.0
        b_wall.position = Vector3(center_x, h_back/2, -shelter_d/2 + p_thickness*0.8)
        walls.add_child(b_wall)
        b_wall.owner = base_node

    # 屋根
    var roof = CSGBox3D.new()
    roof.name = "Roof"
    roof.material_override = mat_totan
    roof.size = Vector3(shelter_w + 0.8, 0.02, rafter_length + 0.2)
    roof.position = Vector3(0, (h_front+h_back)/2 + 0.1, 0)
    roof.rotation.x = -tilt_angle
    shelter.add_child(roof)
    roof.owner = base_node

    # ベンチは一時的に削除（ユーザー指示）

    var sign_sys = Node3D.new()
    sign_sys.name = "BusSign"
    sign_sys.position = Vector3(shelter_w/2 + 1.0, 0, 1.0)
    base_node.add_child(sign_sys)
    sign_sys.owner = base_node

    # ...看板のコードはそのまま維持...
    var sign_base = CSGCylinder3D.new()
    sign_base.name = "Base"
    sign_base.cone = true
    sign_base.radius = 0.3
    sign_base.height = 0.4
    sign_base.position = Vector3(0, 0.2, 0)
    var ConcMat = StandardMaterial3D.new()
    ConcMat.albedo_color = Color(0.5, 0.5, 0.5)
    ConcMat.roughness = 0.9
    sign_base.material_override = ConcMat
    sign_sys.add_child(sign_base)
    sign_base.owner = base_node

    var pole = CSGCylinder3D.new()
    pole.name = "Pole"
    pole.radius = 0.04
    pole.height = 2.4
    pole.position = Vector3(0, 1.2, 0)
    var MetalMat = StandardMaterial3D.new()
    MetalMat.albedo_color = Color(0.8, 0.8, 0.85)
    MetalMat.metallic = 0.6
    MetalMat.roughness = 0.4
    pole.material_override = MetalMat
    sign_sys.add_child(pole)
    pole.owner = base_node

    var round_sign = CSGCylinder3D.new()
    round_sign.name = "RoundSign"
    round_sign.radius = 0.35
    round_sign.height = 0.04
    round_sign.position = Vector3(0, 2.2, 0.05)
    round_sign.rotation.x = PI/2
    var SignMat = StandardMaterial3D.new()
    SignMat.albedo_color = Color(0.9, 0.9, 0.9)
    round_sign.material_override = SignMat
    sign_sys.add_child(round_sign)
    round_sign.owner = base_node

    var text1 = Label3D.new()
    text1.name = "Text1"
    text1.text = "霧原村入口"
    text1.pixel_size = 0.0015
    text1.font_size = 48
    text1.modulate = Color(0,0,0)
    text1.position = Vector3(0, 2.2, 0.08)
    sign_sys.add_child(text1)
    text1.owner = base_node

    var text2 = Label3D.new()
    text2.name = "Text2"
    text2.text = "BUS STOP"
    text2.pixel_size = 0.001
    text2.font_size = 36
    text2.modulate = Color(0.8, 0.1, 0.1)
    text2.position = Vector3(0, 2.38, 0.08)
    sign_sys.add_child(text2)
    text2.owner = base_node

    var board = CSGBox3D.new()
    board.name = "Timetable"
    board.size = Vector3(0.5, 0.8, 0.04)
    board.position = Vector3(0, 1.4, 0.04)
    board.material_override = SignMat
    sign_sys.add_child(board)
    board.owner = base_node

    var packed = PackedScene.new()
    packed.pack(base_node)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    print("BusStop successfully updated: narrower, correct roof pitch, advanced GI enabled.")
    quit()
