extends SceneTree

func _init():
    # 1. BusStop.tscn の地面を小さく再追加
    var bs_scene = load("res://assets/models/bus_stop/BusStop.tscn")
    if bs_scene:
        var bs_instance = bs_scene.instantiate()
        
        # 既存のGroundAsphaltがあれば削除
        var old_ground = bs_instance.get_node_or_null("GroundAsphalt")
        if old_ground:
            bs_instance.remove_child(old_ground)
            old_ground.free()
            
        # バス停の待合所のピッタリ真下だけの小さなアスファルト地面を復活させる
        # 待合所の幅3m、奥行1.6mに合わせて、少しだけ広めの4m x 3mにする
        var ground = CSGBox3D.new()
        ground.name = "GroundAsphalt"
        ground.size = Vector3(5.0, 0.1, 4.0)
        ground.position = Vector3(0, -0.05, -1.0) # バス停自体(z=-2)と看板(z=1)をカバー
        ground.use_collision = true
        var mat_asphalt = StandardMaterial3D.new()
        mat_asphalt.albedo_color = Color(0.15, 0.15, 0.15)
        mat_asphalt.roughness = 0.95
        ground.material = mat_asphalt
        bs_instance.add_child(ground)
        ground.owner = bs_instance
        
        # バス停の標識ポールもついでにサビサビにする
        var sign_sys = bs_instance.get_node_or_null("BusSign")
        if sign_sys:
            var pole = sign_sys.get_node_or_null("Pole")
            if pole:
                # すでにある rusty_bench マテリアルを使う
                var mat_rust = load("res://assets/models/bus_stop/materials/rusty_bench.tres")
                if mat_rust:
                    pole.material_override = mat_rust
                    if "material" in pole: pole.material = mat_rust
                    
        var packed1 = PackedScene.new()
        packed1.pack(bs_instance)
        ResourceSaver.save(packed1, "res://assets/models/bus_stop/BusStop.tscn")

    # 2. VillageGate.tscn の柱をボロボロのサビに変更
    var mat_rust_shader = ShaderMaterial.new()
    mat_rust_shader.shader = load("res://assets/models/environment/shaders/heavy_rust.gdshader")
    ResourceSaver.save(mat_rust_shader, "res://assets/models/environment/materials/heavy_rust.tres")
    
    var arch_scene = load("res://assets/models/environment/VillageGate.tscn")
    if arch_scene:
        var arch_instance = arch_scene.instantiate()
        
        var structure = arch_instance.get_node_or_null("ArchStructure")
        if structure:
            for child in structure.get_children():
                # Materialが mat_red (ベース色) だったすべての柱や梁をシェーダーマテリアルに置き換え
                if child is CSGBox3D and ("Pillar" in child.name or "Beam" in child.name):
                    child.material = mat_rust_shader
                    
        var packed2 = PackedScene.new()
        packed2.pack(arch_instance)
        ResourceSaver.save(packed2, "res://assets/models/environment/VillageGate.tscn")
        
    print("Bus stop ground shrunken and Pillars completely rusted!")
    quit()
