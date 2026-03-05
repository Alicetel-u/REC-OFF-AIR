extends SceneTree

func _init():
    var scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var instance = scene.instantiate()
    var shelter = instance.get_node("BusStopShelter")
    
    if shelter:
        # 既存の小物ノードがあれば削除
        var old_creepy = shelter.get_node("CreepyObjects")
        if old_creepy:
            shelter.remove_child(old_creepy)
            old_creepy.free()
            
        var creepy_root = Node3D.new()
        creepy_root.name = "CreepyObjects"
        shelter.add_child(creepy_root)
        creepy_root.owner = instance
        
        # ---------------------------------------------
        # 1. 忌まわしいお札 (Ofuda: Wards) の配置
        # ---------------------------------------------
        var ofuda_mat = StandardMaterial3D.new()
        ofuda_mat.albedo_color = Color(0.9, 0.85, 0.7) # 古びた和紙の色
        ofuda_mat.roughness = 0.9
        
        # 複数のお札を色々な場所に貼る
        var ofuda_positions = [
            {"pos": Vector3(-0.5, 1.6, -0.65), "rot": Vector3(0, 0, 15)}, # 背面壁
            {"pos": Vector3(0.8, 1.4, -0.65), "rot": Vector3(0, 0, -8)},  # 背面壁
            {"pos": Vector3(1.3, 1.1, 0), "rot": Vector3(0, -90, 5)},     # 横の柱
        ]
        
        for i in range(ofuda_positions.size()):
            var ofuda = CSGBox3D.new()
            ofuda.name = "Ofuda_" + str(i)
            ofuda.size = Vector3(0.12, 0.35, 0.005) # お札のサイズ
            ofuda.position = ofuda_positions[i]["pos"]
            ofuda.rotation_degrees = ofuda_positions[i]["rot"]
            ofuda.material = ofuda_mat
            creepy_root.add_child(ofuda)
            ofuda.owner = instance
            
            # お札の赤い文字（血文字風）
            var text = Label3D.new()
            text.name = "Text"
            text.text = "封"
            if i == 1: text.text = "呪"
            text.font_size = 64
            text.pixel_size = 0.002
            text.modulate = Color(0.6, 0.05, 0.05) # どす黒い赤
            text.position = Vector3(0, 0, 0.003)
            ofuda.add_child(text)
            text.owner = instance

        # ---------------------------------------------
        # 2. 不動のゴミ袋 (Trash Bags) の配置
        # ---------------------------------------------
        var trash_mat = StandardMaterial3D.new()
        trash_mat.albedo_color = Color(0.1, 0.1, 0.1) # 黒いビニール
        trash_mat.roughness = 0.3
        trash_mat.metallic = 0.1
        
        var trash1 = CSGSphere3D.new()
        trash1.name = "TrashBag1"
        trash1.radius = 0.3
        trash1.radial_segments = 8 # ポリゴンを荒くして「ゴツゴツした中身」を表現
        trash1.rings = 6
        trash1.position = Vector3(1.2, 0.25, 0.2)
        trash1.material = trash_mat
        creepy_root.add_child(trash1)
        trash1.owner = instance
        
        # ゴミ袋の結び目
        var knot = CSGCylinder3D.new()
        knot.name = "Knot"
        knot.cone = true
        knot.radius = 0.08
        knot.height = 0.15
        knot.position = Vector3(0, 0.3, 0)
        knot.material = trash_mat
        trash1.add_child(knot)
        knot.owner = instance

        # もう一つのゴミ袋
        var trash2 = CSGSphere3D.new()
        trash2.name = "TrashBag2"
        trash2.radius = 0.25
        trash2.radial_segments = 7
        trash2.rings = 5
        trash2.position = Vector3(1.6, 0.2, 0.0)
        trash2.rotation_degrees.z = 20
        trash2.material = trash_mat
        creepy_root.add_child(trash2)
        trash2.owner = instance

        # ---------------------------------------------
        # 3. 散乱する空き缶 (Scattered Cans)
        # ---------------------------------------------
        var rusty_mat = load("res://assets/models/bus_stop/materials/rusty_bench.tres")
        
        var xs = [-1.0, -0.6, -0.8, 0.5, 0.8]
        var zs = [0.2, 0.5, 0.1, 0.6, 0.4]
        for i in range(5):
            var can = CSGCylinder3D.new()
            can.name = "EmptyCan_" + str(i)
            can.radius = 0.035
            can.height = 0.12
            can.position = Vector3(xs[i], 0.035, zs[i])
            
            # ランダムに転がす
            if i % 2 == 0:
                can.rotation_degrees = Vector3(90, i * 45, 0) # 横倒し
            else:
                can.position.y = 0.06 # 縦置き
                
            can.material = rusty_mat
            creepy_root.add_child(can)
            can.owner = instance

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    print("Creepy objects (Ofuda, Trash, Rusty Cans) added to the scene!")
    quit()
