extends SceneTree

func _init():
    var scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var instance = scene.instantiate()
    
    var sign_sys = instance.get_node("BusSign")
    if sign_sys:
        var board = sign_sys.get_node("Timetable")
        if board:
            # 古い時刻表の中身を一回消す（もしあれば）
            for child in board.get_children():
                if child is Label3D:
                    child.queue_free()
            
            # --- タイトル ---
            var title = Label3D.new()
            title.name = "TableTitle"
            title.text = "【 霧原村 路線バス時刻表 】"
            title.pixel_size = 0.0008
            title.font_size = 32
            title.modulate = Color(0.1, 0.1, 0.1) # 黒インク
            title.position = Vector3(0, 0.3, 0.021) # ボードの表面に合わせる
            board.add_child(title)
            title.owner = instance
            
            # --- 罫線とヘッダー ---
            var header = Label3D.new()
            header.name = "TableHeader"
            header.text = " 時 |   平日   |  土日祝  "
            header.pixel_size = 0.0008
            header.font_size = 28
            header.modulate = Color(0.1, 0.1, 0.1)
            header.position = Vector3(0, 0.22, 0.021)
            board.add_child(header)
            header.owner = instance
            
            # --- 時刻表の中身（ホラー風にスカスカで、最後がおかしい） ---
            var schedule_text = ""
            schedule_text += "  6 | 45       | --      \n"
            schedule_text += "  8 | 10       | 15      \n"
            schedule_text += " 11 | --       | 30      \n"
            schedule_text += " 14 | 05       | --      \n"
            schedule_text += " 17 | 20       | 10      \n"
            schedule_text += " 19 | 50       | --      \n"
            schedule_text += " 22 |          |         \n"
            schedule_text += "    |          |         \n"
            schedule_text += "  2 | 44 44 44 | 44 44 44\n" # あり得ない時間の不気味なバス
            
            var schedule = Label3D.new()
            schedule.name = "TableBody"
            schedule.text = schedule_text
            schedule.pixel_size = 0.0008
            schedule.font_size = 24
            schedule.modulate = Color(0.2, 0.2, 0.2)
            # 行間を詰める
            schedule.line_spacing = -2.0
            # 左揃えにする（Label3Dはデフォルト中央配置なので細かい位置合わせが必要になるが、今回は簡易的にスペースで合わせる）
            schedule.position = Vector3(0, -0.05, 0.021)
            board.add_child(schedule)
            schedule.owner = instance
            
            # --- 赤い警告文 ---
            var warning = Label3D.new()
            warning.name = "TableWarning"
            warning.text = "※深夜2時の便は\n　「乗らないでください」"
            warning.pixel_size = 0.0006
            warning.font_size = 28
            warning.modulate = Color(0.6, 0.05, 0.05) # 血のような赤
            warning.position = Vector3(0, -0.3, 0.021)
            warning.rotation_degrees.z = -5.0 # 少し斜めに貼られている
            board.add_child(warning)
            warning.owner = instance

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    print("Timetable added with creepy midnight schedule!")
    quit()
