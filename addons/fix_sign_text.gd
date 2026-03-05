extends SceneTree

func _init():
    var scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var instance = scene.instantiate()
    
    var sign_sys = instance.get_node("BusSign")
    if sign_sys:
        # RoundSign の表面に直接配置されている Label3D (以前の文字たち) を確実に集める
        var target_nodes = []
        for child in sign_sys.get_children():
            if child is Label3D:
                target_nodes.append(child)
                
        # 全消し (queue_freeだと即時消えないため、強引にツリーから外して破棄)
        for child in target_nodes:
            sign_sys.remove_child(child)
            child.free()
            
        # 唯一の「霧原村前」を作成
        var t_main = Label3D.new()
        t_main.name = "TMid"
        t_main.text = "霧原村前"
        t_main.font_size = 75
        t_main.pixel_size = 0.002
        t_main.modulate = Color(0.1, 0.15, 0.25)
        t_main.position = Vector3(0, 2.18, 0.08)
        t_main.outline_size = 0
        sign_sys.add_child(t_main)
        t_main.owner = instance

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    print("Cleared overlapping text and recreated cleanly!")
    quit()
