extends SceneTree

func _init():
    var scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var instance = scene.instantiate()
    
    var sign_sys = instance.get_node("BusSign")
    if sign_sys:
        # 上（TTop）と下（TBot）の文字を削除し、真ん中（TMid）の文字を「霧原村前」に変更する
        var t_top = sign_sys.get_node("TTop")
        if t_top:
            t_top.queue_free()
            
        var t_bot = sign_sys.get_node("TBot")
        if t_bot:
            t_bot.queue_free()
            
        var t_mid = sign_sys.get_node("TMid")
        if t_mid:
            t_mid.text = "霧原村前"
            # 文字数が変わるので少しフォントサイズや位置を微調整する
            t_mid.font_size = 70
            t_mid.position = Vector3(0, 2.18, 0.08)

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    print("Sign text updated to just 霧原村前!")
    quit()
