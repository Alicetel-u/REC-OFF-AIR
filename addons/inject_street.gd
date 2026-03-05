extends SceneTree

func _init():
    var scene = load("res://scenes/Main.tscn")
    var instance = scene.instantiate()
    
    # 既存のDarkStreetがあれば消す
    var old_street = instance.get_node_or_null("DarkStreet")
    if old_street:
        instance.remove_child(old_street)
        old_street.free()
        
    # DarkStreet.tscnをロードして追加
    var street_scene = load("res://assets/models/environment/DarkStreet.tscn")
    var street = street_scene.instantiate()
    street.name = "DarkStreet"
    
    # バスの道がバス停の目の前を通るように位置をずらす
    # バス停は(0,0,0)にあるので、道を少し奥（Xマイナス方向）にずらす
    street.position = Vector3(-3.5, 0, 0)
    
    # 追加
    instance.add_child(street)
    street.owner = instance
    
    # プレイヤーの立ち位置（カメラ）を少しバス停のベンチ付近に調整
    var cam = instance.get_node("Camera3D")
    if cam:
        cam.position = Vector3(1.2, 1.4, 0.5)
        cam.rotation_degrees = Vector3(0, 15, 0)
    
    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://scenes/Main.tscn")
    print("DarkStreet successfully added to Main.tscn!")
    quit()
