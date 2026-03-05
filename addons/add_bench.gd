extends SceneTree

func _init():
    var scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var instance = scene.instantiate()
    
    # 既存の金属マテリアルの作成（ベンチ用）
    var MetalMat = StandardMaterial3D.new()
    MetalMat.albedo_color = Color(0.75, 0.75, 0.8)
    MetalMat.metallic = 0.5
    MetalMat.roughness = 0.6
    
    var shelter = instance.get_node("BusStopShelter")
    if shelter:
        var bench = CSGCombiner3D.new()
        bench.name = "Bench"
        bench.material_override = MetalMat
        shelter.add_child(bench)
        bench.owner = instance
        
        var bench_w = 2.4
        
        # 座面
        var seat = CSGBox3D.new()
        seat.name = "Seat"
        seat.size = Vector3(bench_w, 0.05, 0.4)
        seat.position = Vector3(0, 0.45, -0.4)
        bench.add_child(seat)
        seat.owner = instance
        
        # 背もたれ
        var backrest = CSGBox3D.new()
        backrest.name = "Backrest"
        backrest.size = Vector3(bench_w, 0.3, 0.05)
        backrest.position = Vector3(0, 0.8, -0.6)
        bench.add_child(backrest)
        backrest.owner = instance
        
        # 背もたれを支える棒
        for lx in [-bench_w/2 + 0.2, 0, bench_w/2 - 0.2]:
            var back_bar = CSGBox3D.new()
            back_bar.name = "BackBar"
            back_bar.size = Vector3(0.05, 0.4, 0.05)
            back_bar.position = Vector3(lx, 0.65, -0.5)
            back_bar.rotation_degrees.x = -20.0 # 傾斜をつける
            bench.add_child(back_bar)
            back_bar.owner = instance
            
        # 足
        for lx in [-bench_w/2 + 0.2, bench_w/2 - 0.2]:
            var leg_f = CSGBox3D.new()
            leg_f.name = "Leg_F"
            leg_f.size = Vector3(0.05, 0.45, 0.05)
            leg_f.position = Vector3(lx, 0.225, -0.25)
            bench.add_child(leg_f)
            leg_f.owner = instance
            
            var leg_b = CSGBox3D.new()
            leg_b.name = "Leg_B"
            leg_b.size = Vector3(0.05, 0.45, 0.05)
            leg_b.position = Vector3(lx, 0.225, -0.55)
            bench.add_child(leg_b)
            leg_b.owner = instance
            
            var brace = CSGBox3D.new()
            brace.name = "Brace"
            brace.size = Vector3(0.04, 0.04, 0.35)
            brace.position = Vector3(lx, 0.15, -0.4)
            bench.add_child(brace)
            brace.owner = instance
            
    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    print("Bench added back with proper metal material and structure.")
    quit()
