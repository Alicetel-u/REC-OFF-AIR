extends SceneTree

func _init():
    var base_node = Node3D.new()
    base_node.name = "VillageGateRoot"

    # アーチ用の錆びた暗い赤の鉄素材
    var mat_red = StandardMaterial3D.new()
    mat_red.albedo_color = Color(0.35, 0.03, 0.03) 
    mat_red.metallic = 0.4
    mat_red.roughness = 0.85
    
    # 画像用マテリアル
    var mat_sign = StandardMaterial3D.new()
    var tex = load("res://素材/新しい看板.jpg")
    mat_sign.albedo_texture = tex
    mat_sign.roughness = 0.9

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
    mid_beam.position = Vector3(0, gate_h - 2.0, 0)
    mid_beam.material = mat_red
    arch.add_child(mid_beam)
    mid_beam.owner = base_node

    # 看板の土台 (画像の比率に合わせて余白無しでベタ置きする)
    var px_size = 4.5 / float(tex.get_width())
    
    var z_offset = 0.35 # 柱や梁の厚みより外側に配置する

    # 物理的な土台ブロック（表面用）
    var sign_bg_front = CSGBox3D.new()
    sign_bg_front.name = "SignBoardFront"
    sign_bg_front.size = Vector3(4.5, 2.08, 0.05)
    sign_bg_front.position = Vector3(0, gate_h - 1.1, z_offset)
    sign_bg_front.material = mat_red
    arch.add_child(sign_bg_front)
    sign_bg_front.owner = base_node
    
    # 前面の画像
    var sign_front = Sprite3D.new()
    sign_front.name = "SignFront"
    sign_front.texture = tex
    sign_front.position = Vector3(0, gate_h - 1.1, z_offset + 0.03)
    sign_front.pixel_size = px_size
    sign_front.modulate = Color(0.8, 0.8, 0.8)
    arch.add_child(sign_front)
    sign_front.owner = base_node
    
    # 物理的な土台ブロック（裏面用）
    var sign_bg_back = CSGBox3D.new()
    sign_bg_back.name = "SignBoardBack"
    sign_bg_back.size = Vector3(4.5, 2.08, 0.05)
    sign_bg_back.position = Vector3(0, gate_h - 1.1, -z_offset)
    sign_bg_back.material = mat_red
    arch.add_child(sign_bg_back)
    sign_bg_back.owner = base_node
    
    # 後面の画像 (両側から読めるように反転配置)
    var sign_back = Sprite3D.new()
    sign_back.name = "SignBack"
    sign_back.texture = tex
    sign_back.position = Vector3(0, gate_h - 1.1, -z_offset - 0.03)
    sign_back.rotation_degrees = Vector3(0, 180, 0)
    sign_back.pixel_size = px_size
    sign_back.modulate = Color(0.8, 0.8, 0.8)
    arch.add_child(sign_back)
    sign_back.owner = base_node

    # 吊り下げ電球(ワイヤーと玉)の装飾（すべて割れて光らない、サビている）
    var wire = CSGCylinder3D.new()
    wire.name = "Wire"
    wire.radius = 0.01
    wire.height = gate_w
    wire.rotation_degrees.z = 90
    wire.position = Vector3(0, gate_h - 2.2, 0)
    var mat_wire = StandardMaterial3D.new()
    mat_wire.albedo_color = Color(0.1, 0.05, 0.02)
    mat_wire.roughness = 1.0
    wire.material = mat_wire
    arch.add_child(wire)
    wire.owner = base_node
    
    for i in range(11):
        var lx = -gate_w/2 + 0.6 + i * 0.58
        
        var drop_wire = CSGCylinder3D.new()
        drop_wire.name = "DropWire_" + str(i)
        drop_wire.radius = 0.005
        drop_wire.height = 0.15
        drop_wire.position = Vector3(lx, gate_h - 2.275, 0)
        drop_wire.material = mat_wire
        arch.add_child(drop_wire)
        drop_wire.owner = base_node
        
        var bulb = CSGSphere3D.new()
        bulb.name = "Bulb_" + str(i)
        bulb.radius = 0.05
        bulb.position = Vector3(lx, gate_h - 2.35, 0)
        
        # すべて割れて光らない、サビた質感に
        var mat_glass = StandardMaterial3D.new()
        mat_glass.albedo_color = Color(0.1, 0.05, 0.02)
        mat_glass.roughness = 1.0
        mat_glass.metallic = 0.2
        bulb.material = mat_glass
        arch.add_child(bulb)
        bulb.owner = base_node
        
    var packed = PackedScene.new()
    packed.pack(base_node)
    
    ResourceSaver.save(packed, "res://assets/models/environment/VillageGate.tscn")
    print("Village Gate Arch updated with image sign and unlit rusty bulbs!")
    quit()
