extends SceneTree

func _init():
    var scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var instance = scene.instantiate()
    
    var rusty_totan_mat = load("res://assets/models/bus_stop/materials/rusty_totan.tres")
    var decayed_wood_mat = load("res://assets/models/bus_stop/materials/decayed_wood.tres")
    
    # 確実な上書きロジック：各部品に直接マテリアルを設定する
    var shelter = instance.get_node("BusStopShelter")
    if shelter:
        # トタン壁の再設定
        var walls = shelter.get_node("Walls")
        if walls:
            walls.material_override = rusty_totan_mat
            for child in walls.get_children():
                if child is CSGBox3D and child.name != "WallBackWood":
                    child.material_override = rusty_totan_mat
                    child.material = null
        
        # 朽ち木（柱・梁・筋交い）の再設定
        var pillars = shelter.get_node("Pillars")
        if pillars:
            pillars.material_override = decayed_wood_mat
            for child in pillars.get_children():
                if child.name.begins_with("Front") or child.name.begins_with("Back") or child.name.begins_with("Beam") or child.name.begins_with("Brace"):
                    child.material_override = decayed_wood_mat
                    child.material = null
                
        # ベンチの再設定
        var bench = shelter.get_node("Bench")
        if bench:
            bench.material_override = decayed_wood_mat
            for child in bench.get_children():
                if child is CSGBox3D:
                    child.material_override = decayed_wood_mat
                    child.material = null

        # 屋根の再設定
        var roof = shelter.get_node("Roof")
        if roof:
            roof.material_override = rusty_totan_mat
            roof.material = null # デフォルトマテリアルを消して確実に入れる
            
    # 更なる歪みの追加
    var pt_fl = instance.get_node("BusStopShelter/Pillars/FrontLeft")
    if pt_fl:
        pt_fl.rotation_degrees.z = 2.5 # 前の柱が少し傾いてしまっている
    var bench_seat = instance.get_node("BusStopShelter/Bench/Seat")
    if bench_seat:
        bench_seat.position.y -= 0.05
        bench_seat.rotation_degrees.z = -1.0 # 座面が少し沈んで傾いている
    
    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    print("BusStop upgraded with FULL procedural materials applied and more decay!")
    quit()
