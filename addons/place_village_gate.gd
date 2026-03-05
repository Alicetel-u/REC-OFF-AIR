extends SceneTree

func _init():
    var scene = load("res://scenes/Main.tscn")
    var instance = scene.instantiate()
    
    var old_gate = instance.get_node_or_null("VillageGate")
    if old_gate:
        instance.remove_child(old_gate)
        old_gate.free()
        
    var gate_scene = load("res://assets/models/environment/VillageGate.tscn")
    var gate = gate_scene.instantiate()
    gate.name = "VillageGate"
    
    # バス停から少し歩いた先（奥）。
    # カメラが (1.5, 1.4, 1.8) で +Y(左) 30度 を向いている(Xプラス方向を見ている)。
    # 道は X軸に沿って伸び、Z=4.3 の位置が道の中央。
    # なので、プレイヤーが進むべき方向である X = 25 の地点にゲートをまたがせる。
    gate.position = Vector3(25.0, 0, 4.3)
    
    # ゲートが「道をまたぐ」ように90度回転させる
    gate.rotation_degrees = Vector3(0, 90, 0)
    
    instance.add_child(gate)
    gate.owner = instance
    
    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://scenes/Main.tscn")
    print("Welcome Gate successfully placed on the road!")
    quit()
