extends SceneTree

func _init():
    var scene = load("res://assets/models/bus_stop/BusStop.tscn")
    var instance = scene.instantiate()
    
    var sign_sys = instance.get_node("BusSign")
    if sign_sys:
        var board = sign_sys.get_node("Timetable")
        if board:
            # 時刻表(Timetable)のすべての子ノード(文字・足跡など)を強制削除
            var labels_to_delete = []
            for child in board.get_children():
                if child is Label3D:
                    labels_to_delete.append(child)
                    
            for label in labels_to_delete:
                board.remove_child(label)
                label.free()

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://assets/models/bus_stop/BusStop.tscn")
    print("All timetable text completely removed!")
    quit()
