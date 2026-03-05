extends SceneTree

func apply_material_recursive(node, mat):
    if node is CSGPrimitive3D or node is CSGCombiner3D or node is MeshInstance3D:
        node.material_override = mat
        if "material" in node:
            node.material = null
    for c in node.get_children():
        apply_material_recursive(c, mat)

func _init():
    var scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var instance = scene.instantiate()

    var m_totan = load("res://assets/models/bus_stop/materials/rusty_totan.tres")
    var m_wood = load("res://assets/models/bus_stop/materials/decayed_wood.tres")
    var m_bench = load("res://assets/models/bus_stop/materials/rusty_bench.tres")
    
    # 以前 null を入れたことでシェーダーのデフォルト値が消えてしまった可能性に対処
    # 明示的に色と数値を保存し直す
    m_totan.set_shader_parameter("base_color", Color(0.15, 0.2, 0.25, 1.0))
    m_totan.set_shader_parameter("rust_color", Color(0.2, 0.05, 0.02, 1.0))
    m_totan.set_shader_parameter("bright_rust_color", Color(0.4, 0.1, 0.02, 1.0))
    m_totan.set_shader_parameter("rust_amount", 0.85)
    m_totan.set_shader_parameter("wetness", 0.8)
    
    m_wood.set_shader_parameter("wood_base_color", Color(0.1, 0.08, 0.05, 1.0))
    m_wood.set_shader_parameter("wood_highlight_color", Color(0.2, 0.18, 0.15, 1.0))
    m_wood.set_shader_parameter("moss_color", Color(0.1, 0.25, 0.05, 1.0))
    m_wood.set_shader_parameter("decay_amount", 0.85)
    m_wood.set_shader_parameter("moss_amount", 0.6)
    
    # 確実にすべての小部品にマテリアルを直接書き込む
    var shelter = instance.get_node("BusStopShelter")
    if shelter:
        var walls = shelter.get_node("Walls")
        if walls: apply_material_recursive(walls, m_totan)
        
        var roof = shelter.get_node("Roof")
        if roof: apply_material_recursive(roof, m_totan)
            
        var pillars = shelter.get_node("Pillars")
        if pillars: apply_material_recursive(pillars, m_wood)
            
        var bench = shelter.get_node("Bench")
        if bench: apply_material_recursive(bench, m_bench)

    var sign_sys = instance.get_node("BusSign")
    if sign_sys:
        var pole = sign_sys.get_node("Pole")
        if pole: apply_material_recursive(pole, m_bench)
            
    # 再保存
    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    
    ResourceSaver.save(m_totan, "res://assets/models/bus_stop/materials/rusty_totan.tres")
    ResourceSaver.save(m_wood, "res://assets/models/bus_stop/materials/decayed_wood.tres")
    
    print("Fixed material assignments for all parts explicitly!")
    quit()
