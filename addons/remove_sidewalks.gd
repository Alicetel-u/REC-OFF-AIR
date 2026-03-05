extends SceneTree

func _init():
    # 1. バスの周囲に敷き詰められていた巨大な歩道（コンクリートパネル）を完全に削除
    var bs_scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var bs_instance = bs_scene.instantiate()
    var ground = bs_instance.get_node_or_null("GroundAsphalt")
    if ground:
        bs_instance.remove_child(ground)
        ground.free()
    var packed1 = PackedScene.new()
    packed1.pack(bs_instance)
    ResourceSaver.save(packed1, "res://assets/models/bus_stop/BusStop.tscn")
    
    # 2. 道路の両側にあった縁石（歩道の段差）を完全に削除
    var st_scene = load("res://assets/models/environment/DarkStreet.tscn")
    var st_instance = st_scene.instantiate()
    for cur_name in ["LeftCurb", "RightCurb"]:
        var cur = st_instance.get_node_or_null(cur_name)
        if cur:
            st_instance.remove_child(cur)
            cur.free()
            
    var packed2 = PackedScene.new()
    packed2.pack(st_instance)
    ResourceSaver.save(packed2, "res://assets/models/environment/DarkStreet.tscn")
    
    # === ついでに隙間の調整 ===
    # 縁石が無くなったことで、道(幅6m, Z=1.3〜7.3)と田んぼ(Z=0.3から奥)の間に隙間ができるため、
    # 田んぼの配置スクリプトで指定していた田んぼの位置をピッタリ道路まで引き寄せるための調整をMain上で行う
    var main_scene = load("res://scenes/Main.tscn")
    var main_instance = main_scene.instantiate()
    
    var mf = main_instance.get_node_or_null("MountainsAndFields")
    if mf:
        var right_field = mf.get_node_or_null("MountainsAndFieldsRoot/RiceFieldRight")
        if right_field:
            # 道路のZ最大値は 4.3 + 3.0 = 7.3
            # 田んぼのZ幅は200なので中心は 7.3 + 100 = 107.3
            right_field.position.z = 107.3
        var left_field = mf.get_node_or_null("MountainsAndFieldsRoot/RiceFieldLeft")
        if left_field:
            # 道路のZ最小値は 4.3 - 3.0 = 1.3
            # 田んぼのZ幅は200なので中心は 1.3 - 100 = -98.7
            left_field.position.z = -98.7
            
    var packed3 = PackedScene.new()
    packed3.pack(main_instance)
    ResourceSaver.save(packed3, "res://scenes/Main.tscn")
    
    print("Sidewalks entirely removed, and fields attached directly to the road edges!")
    quit()
