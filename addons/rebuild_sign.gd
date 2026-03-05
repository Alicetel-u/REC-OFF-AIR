extends SceneTree

func _init():
    var scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var instance = scene.instantiate()
    
    var sign_sys = instance.get_node("BusSign")
    if sign_sys:
        # ------- Round Sign --------
        var round_sign = sign_sys.get_node("RoundSign")
        if round_sign:
            var m_round = ShaderMaterial.new()
            m_round.shader = load("res://assets/models/bus_stop/shaders/bus_sign_round.gdshader")
            round_sign.material_override = m_round
            if "material" in round_sign: round_sign.material = null
            
        # Clear existing text
        for child in sign_sys.get_children():
            if child is Label3D:
                child.queue_free()
                
        var dk_blue = Color(0.1, 0.15, 0.25)
        
        var t_top = Label3D.new()
        t_top.name = "TTop"
        t_top.text = "前 山 行"
        t_top.font_size = 50
        t_top.pixel_size = 0.0015
        t_top.modulate = dk_blue
        t_top.position = Vector3(0, 2.33, 0.08)
        t_top.outline_size = 0
        sign_sys.add_child(t_top)
        t_top.owner = instance
        
        var t_mid = Label3D.new()
        t_mid.name = "TMid"
        t_mid.text = "稲 荷 前"
        t_mid.font_size = 80
        t_mid.pixel_size = 0.002
        t_mid.modulate = dk_blue
        t_mid.position = Vector3(0, 2.18, 0.08)
        t_mid.outline_size = 0
        sign_sys.add_child(t_mid)
        t_mid.owner = instance
        
        var t_bot = Label3D.new()
        t_bot.name = "TBot"
        t_bot.text = "山 猫 電 鉄 バ ス"
        t_bot.font_size = 28
        t_bot.pixel_size = 0.0012
        t_bot.modulate = dk_blue
        t_bot.position = Vector3(0, 1.95, 0.08)
        t_bot.outline_size = 0
        sign_sys.add_child(t_bot)
        t_bot.owner = instance
        
        # ------- Timetable Board --------
        var board = sign_sys.get_node("Timetable")
        if board:
            board.size = Vector3(0.35, 0.55, 0.04) # Taller shape, matching image
            board.position = Vector3(0, 1.45, 0.04)
            for child in board.get_children():
                child.queue_free()
                
            var m_board = ShaderMaterial.new()
            m_board.shader = load("res://assets/models/bus_stop/shaders/bus_timetable_handdrawn.gdshader")
            board.material_override = m_board
            if "material" in board: board.material = null
            
            var ink = Color(0.1, 0.1, 0.15)
            
            # Draw header labels manually
            var h_ji = Label3D.new()
            h_ji.name = "HJi"
            h_ji.text = "時"
            h_ji.pixel_size = 0.0015
            h_ji.font_size = 32
            h_ji.modulate = ink
            h_ji.outline_size = 0
            h_ji.position = Vector3(-0.06, 0.23, 0.021)
            board.add_child(h_ji)
            h_ji.owner = instance
            
            var h_fun = Label3D.new()
            h_fun.name = "HFun"
            h_fun.text = "分"
            h_fun.pixel_size = 0.0015
            h_fun.font_size = 32
            h_fun.modulate = ink
            h_fun.outline_size = 0
            h_fun.position = Vector3(0.04, 0.23, 0.021)
            board.add_child(h_fun)
            h_fun.owner = instance
            
            var times = ["21", "22", "23", "0", "1", "2", "3", "4"]
            var start_y = 0.16
            var step_y = -0.052
            for i in range(times.size()):
                var tl = Label3D.new()
                tl.name = "Time_" + str(i)
                tl.text = times[i]
                tl.pixel_size = 0.0015
                tl.font_size = 32
                tl.modulate = ink
                tl.outline_size = 0
                tl.position = Vector3(-0.06, start_y + step_y * i, 0.021)
                board.add_child(tl)
                tl.owner = instance
                
            # Paw prints inside the row of "4"
            var pxs = [0.03, 0.12]
            for i in range(2):
                var paw = Label3D.new()
                paw.name = "Paw_" + str(i)
                paw.text = "🐾"
                paw.pixel_size = 0.0015
                paw.font_size = 30
                paw.modulate = ink
                paw.outline_size = 0
                paw.position = Vector3(pxs[i], start_y + step_y * 7, 0.021)
                paw.rotation_degrees.z = -10.0 + i*5.0
                board.add_child(paw)
                paw.owner = instance

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    print("Signboard meticulously recreated to match the reference image!")
    quit()
