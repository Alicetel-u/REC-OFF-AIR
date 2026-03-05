extends SceneTree

func _init():
    var scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var instance = scene.instantiate()
    
    # 既存の shader ファイルを強制リロードさせて最新の定数を取らせるための一時ロード
    var m_totan = load("res://assets/models/bus_stop/materials/rusty_totan.tres")
    var m_wood = load("res://assets/models/bus_stop/materials/decayed_wood.tres")
    if m_totan and m_totan is ShaderMaterial:
        # override cleared just to be perfectly sure it loads default uniforms from .gdshader
        m_totan.set_shader_parameter("base_color", null)
        m_totan.set_shader_parameter("rust_amount", null)
        m_totan.set_shader_parameter("wetness", null)
        ResourceSaver.save(m_totan, "res://assets/models/bus_stop/materials/rusty_totan.tres")
        
    if m_wood and m_wood is ShaderMaterial:
        m_wood.set_shader_parameter("wood_base_color", null)
        m_wood.set_shader_parameter("decay_amount", null)
        m_wood.set_shader_parameter("moss_amount", null)
        ResourceSaver.save(m_wood, "res://assets/models/bus_stop/materials/decayed_wood.tres")

    # 新しい金属ベンチ用マテリアルのロードと作成
    var bench_metal = ShaderMaterial.new()
    var bench_shader = load("res://assets/models/bus_stop/shaders/rusty_bench.gdshader")
    bench_metal.shader = bench_shader
    ResourceSaver.save(bench_metal, "res://assets/models/bus_stop/materials/rusty_bench.tres")
    
    # 新しいマテリアルをベンチとポールに適用
    var shelter = instance.get_node("BusStopShelter")
    if shelter:
        var bench = shelter.get_node("Bench")
        if bench:
            bench.material_override = bench_metal
            for child in bench.get_children():
                if "material_override" in child:
                    child.material_override = bench_metal
                    
    var sign_sys = instance.get_node("BusSign")
    if sign_sys:
        var pole = sign_sys.get_node("Pole")
        if pole:
            pole.material_override = bench_metal
            
    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    print("Horror grunge (Rust & Moss) applied to all components!")
    quit()
