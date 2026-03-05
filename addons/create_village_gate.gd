extends SceneTree

func _init():
    var base_node = Node3D.new()
    base_node.name = "VillageGateRoot"

    # アーチ用の錆びた暗い赤の鉄素材
    var mat_red = StandardMaterial3D.new()
    mat_red.albedo_color = Color(0.35, 0.03, 0.03) # どす黒い血のような赤
    mat_red.metallic = 0.4
    mat_red.roughness = 0.85
    
    # 看板の汚れ気味の白い板素材
    var mat_white = StandardMaterial3D.new()
    mat_white.albedo_color = Color(0.75, 0.72, 0.68) # くすんだ白
    mat_white.roughness = 0.95

    var gate_w = 7.0
    var gate_h = 5.0
    var p_thick = 0.45
    
    var arch = CSGCombiner3D.new()
    arch.name = "ArchStructure"
    base_node.add_child(arch)
    arch.owner = base_node
    
    # 左柱
    var l_pillar = CSGBox3D.new()
    l_pillar.name = "LeftPillar"
    l_pillar.size = Vector3(p_thick, gate_h, p_thick)
    l_pillar.position = Vector3(-gate_w/2, gate_h/2, 0)
    l_pillar.material = mat_red
    arch.add_child(l_pillar)
    l_pillar.owner = base_node

    # 右柱
    var r_pillar = CSGBox3D.new()
    r_pillar.name = "RightPillar"
    r_pillar.size = Vector3(p_thick, gate_h, p_thick)
    r_pillar.position = Vector3(gate_w/2, gate_h/2, 0)
    r_pillar.material = mat_red
    arch.add_child(r_pillar)
    r_pillar.owner = base_node

    # 一番上の梁
    var top_beam = CSGBox3D.new()
    top_beam.name = "TopBeam"
    top_beam.size = Vector3(gate_w + 1.2, p_thick * 0.8, p_thick * 0.8)
    top_beam.position = Vector3(0, gate_h - 0.2, 0)
    top_beam.material = mat_red
    arch.add_child(top_beam)
    top_beam.owner = base_node
    
    # 二番目の梁（看板を支える下側）
    var mid_beam = CSGBox3D.new()
    mid_beam.name = "MidBeam"
    mid_beam.size = Vector3(gate_w + 1.2, p_thick * 0.6, p_thick * 0.6)
    mid_beam.position = Vector3(0, gate_h - 1.5, 0)
    mid_beam.material = mat_red
    arch.add_child(mid_beam)
    mid_beam.owner = base_node

    # 看板の土台 (白)
    var sign_bg = CSGBox3D.new()
    sign_bg.name = "SignBoard"
    sign_bg.size = Vector3(4.5, 1.3, 0.1)
    sign_bg.position = Vector3(0, gate_h - 0.85, 0)
    sign_bg.material = mat_white
    arch.add_child(sign_bg)
    sign_bg.owner = base_node
    
    # 看板の赤い縁取り
    var sign_frame = CSGBox3D.new()
    sign_frame.name = "SignFrame"
    sign_frame.size = Vector3(4.6, 1.4, 0.05)
    sign_frame.position = Vector3(0, gate_h - 0.85, -0.01)
    sign_frame.material = mat_red
    arch.add_child(sign_frame)
    sign_frame.owner = base_node

    # テキスト等
    var labels = Node3D.new()
    labels.name = "SignText"
    base_node.add_child(labels)
    labels.owner = base_node
    
    var black_ink = Color(0.1, 0.1, 0.1)
    var faded_red = Color(0.6, 0.2, 0.2)
    
    var txt_sub = Label3D.new()
    txt_sub.name = "TxtWelcome"
    txt_sub.text = "ようこそ！呪われた地へ"
    txt_sub.font_size = 40
    txt_sub.pixel_size = 0.003
    txt_sub.modulate = faded_red
    txt_sub.position = Vector3(0, gate_h - 0.5, 0.06)
    txt_sub.outline_size = 0
    labels.add_child(txt_sub)
    txt_sub.owner = base_node
    
    var txt_main = Label3D.new()
    txt_main.name = "TxtVillageName"
    txt_main.text = "霧 原 村"
    txt_main.font_size = 140
    txt_main.pixel_size = 0.003
    txt_main.modulate = black_ink
    txt_main.outline_size = 0
    txt_main.position = Vector3(0, gate_h - 0.95, 0.06)
    labels.add_child(txt_main)
    txt_main.owner = base_node
    
    var txt_eng = Label3D.new()
    txt_eng.name = "TxtEng"
    txt_eng.text = "K I R I H A R A   V I L L A G E"
    txt_eng.font_size = 24
    txt_eng.pixel_size = 0.003
    txt_eng.modulate = black_ink
    txt_eng.position = Vector3(0, gate_h - 1.3, 0.06)
    txt_eng.outline_size = 0
    labels.add_child(txt_eng)
    txt_eng.owner = base_node
    
    # 吊り下げ電球(ワイヤーと玉)の装飾（恐怖演出：大半が割れている）
    var wire = CSGCylinder3D.new()
    wire.name = "Wire"
    wire.radius = 0.01
    wire.height = gate_w
    wire.rotation_degrees.z = 90
    wire.position = Vector3(0, gate_h - 1.7, 0)
    var mat_black = StandardMaterial3D.new()
    mat_black.albedo_color = Color(0.05, 0.05, 0.05)
    wire.material = mat_black
    arch.add_child(wire)
    wire.owner = base_node
    
    for i in range(11):
        var lx = -gate_w/2 + 0.6 + i * 0.58
        
        var drop_wire = CSGCylinder3D.new()
        drop_wire.name = "DropWire_" + str(i)
        drop_wire.radius = 0.005
        drop_wire.height = 0.15
        drop_wire.position = Vector3(lx, gate_h - 1.775, 0)
        drop_wire.material = mat_black
        arch.add_child(drop_wire)
        drop_wire.owner = base_node
        
        var bulb = CSGSphere3D.new()
        bulb.name = "Bulb_" + str(i)
        bulb.radius = 0.05
        bulb.position = Vector3(lx, gate_h - 1.85, 0)
        
        var mat_glass = StandardMaterial3D.new()
        if randf() > 0.8:
            mat_glass.albedo_color = Color(0.9, 0.9, 0.3) # 辛うじて点灯している
            mat_glass.emission_enabled = true
            mat_glass.emission = Color(0.8, 0.8, 0.2)
            mat_glass.emission_energy_multiplier = 1.0
        else:
            mat_glass.albedo_color = Color(0.2, 0.2, 0.2) # 割れて真っ暗
            mat_glass.roughness = 1.0
        bulb.material = mat_glass
        arch.add_child(bulb)
        bulb.owner = base_node
        
    var packed = PackedScene.new()
    packed.pack(base_node)
    
    var dir = DirAccess.open("res://assets")
    if not dir.dir_exists("models/environment"):
        dir.make_dir("models/environment")
        
    ResourceSaver.save(packed, "res://assets/models/environment/VillageGate.tscn")
    print("Village Gate Arch successfully created!")
    quit()
