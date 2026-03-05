extends SceneTree

func _init():
    var scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var instance = scene.instantiate()
    
    var rusty_totan_mat = load("res://assets/models/bus_stop/materials/rusty_totan.tres")
    var decayed_wood_mat = load("res://assets/models/bus_stop/materials/decayed_wood.tres")
    
    var shelter = instance.get_node("BusStopShelter")
    if shelter:
        # トタン壁を「細かく分割されたMeshInstance3D」に変更
        var walls = shelter.get_node("Walls")
        if walls:
            var wall_children = walls.get_children()
            for c in wall_children:
                if c is CSGBox3D:
                    var mi = MeshInstance3D.new()
                    mi.name = c.name
                    mi.transform = c.transform
                    var mesh = BoxMesh.new()
                    mesh.size = c.size
                    # シェーダーで頂点を曲げるため、メッシュを細かく分割しておく
                    mesh.subdivide_width = 30
                    mesh.subdivide_height = 30
                    mesh.subdivide_depth = 5
                    mi.mesh = mesh
                    mi.material_override = rusty_totan_mat if c.name != "WallBackWood" else decayed_wood_mat
                    
                    walls.add_child(mi)
                    mi.owner = instance
                    walls.remove_child(c)
                    c.queue_free()

        # 屋根を「MeshInstance3D」に変更して分割
        var roof = shelter.get_node("Roof")
        if roof and roof is CSGBox3D:
            var mi = MeshInstance3D.new()
            mi.name = roof.name
            mi.transform = roof.transform
            var mesh = BoxMesh.new()
            mesh.size = roof.size
            mesh.subdivide_width = 50
            mesh.subdivide_height = 5
            mesh.subdivide_depth = 40
            mi.mesh = mesh
            mi.material_override = rusty_totan_mat
            
            shelter.add_child(mi)
            mi.owner = instance
            shelter.remove_child(roof)
            roof.queue_free()

        # 柱と梁を「MeshInstance3D」に変更して分割
        var pillars = shelter.get_node("Pillars")
        if pillars:
            var pillar_children = pillars.get_children()
            for c in pillar_children:
                if c is CSGBox3D:
                    var mi = MeshInstance3D.new()
                    mi.name = c.name
                    mi.transform = c.transform
                    var mesh = BoxMesh.new()
                    mesh.size = c.size
                    mesh.subdivide_width = 5
                    mesh.subdivide_height = 30 if c.size.y > c.size.x else 5
                    mesh.subdivide_depth = 30 if c.size.z > c.size.x else 5
                    mi.mesh = mesh
                    mi.material_override = decayed_wood_mat
                    
                    pillars.add_child(mi)
                    mi.owner = instance
                    pillars.remove_child(c)
                    c.queue_free()

        # ベンチを「MeshInstance3D」に変更して分割
        var bench = shelter.get_node("Bench")
        if bench:
            var bench_children = bench.get_children()
            for c in bench_children:
                if c is CSGBox3D:
                    var mi = MeshInstance3D.new()
                    mi.name = c.name
                    mi.transform = c.transform
                    var mesh = BoxMesh.new()
                    mesh.size = c.size
                    mesh.subdivide_width = 25
                    mesh.subdivide_height = 5
                    mesh.subdivide_depth = 15
                    mi.mesh = mesh
                    mi.material_override = decayed_wood_mat
                    
                    bench.add_child(mi)
                    mi.owner = instance
                    bench.remove_child(c)
                    c.queue_free()

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    print("BusStop upgraded: CSG primitive boxes replaced with heavily subdivided 3D Meshes, making them malleable to vertex displacement shaders!")
    quit()
