extends SceneTree

func _init():
    var scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var instance = scene.instantiate()
    var shelter = instance.get_node("BusStopShelter")
    
    if shelter:
        # 古い CreepyObjects を完全に削除
        var old_creepy = shelter.get_node("CreepyObjects")
        if old_creepy:
            shelter.remove_child(old_creepy)
            old_creepy.free()
            
        # 新しく作り直す（空き缶3つだけ）
        var creepy_root = Node3D.new()
        creepy_root.name = "CreepyObjects"
        shelter.add_child(creepy_root)
        creepy_root.owner = instance
        
        var rusty_mat = load("res://assets/models/bus_stop/materials/rusty_bench.tres")
        
        var xs = [-0.8, 0.5, 0.9]
        var zs = [0.1, 0.6, 0.3]
        for i in range(3):
            var can = CSGCylinder3D.new()
            can.name = "EmptyCan_" + str(i)
            can.radius = 0.035
            can.height = 0.12
            can.position = Vector3(xs[i], 0.035, zs[i])
            
            # ランダムに転がす（1番目と3番目は横倒し）
            if i != 1:
                can.rotation_degrees = Vector3(90, i * 65, 0)
            else:
                can.position.y = 0.06 # 縦置き
                
            can.material = rusty_mat
            creepy_root.add_child(can)
            can.owner = instance

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    print("Removed overkill objects. Only 3 subtle rusted cans remain.")
    quit()
