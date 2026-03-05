extends SceneTree

func _init():
    var scene = load("res://scenes/Main.tscn")
    var instance = scene.instantiate()
    
    var street = instance.get_node_or_null("DarkStreet")
    if street:
        # 道路を90度回転させて、バス停の「前」を左右に横切るようにする
        street.rotation_degrees = Vector3(0, 90, 0)
        
        # 縁石がバス停の看板や地面とぴったり合うようにZ軸（奥・手前）を調整
        # Y軸も微調整して、アスファルトの高さが揃うようにする
        street.position = Vector3(0, 0.05, 4.3)
        
    var cam = instance.get_node_or_null("Camera3D")
    if cam:
        # カメラを道路側（縁石の少し外側）に立たせ、バス停を斜めから見上げるような構図に
        cam.position = Vector3(1.5, 1.4, 1.8)
        cam.rotation_degrees = Vector3(0, 30, 0)

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://scenes/Main.tscn")
    print("Dark Street successfully aligned along the front of the Bus Stop!")
    quit()
