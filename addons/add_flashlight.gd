extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var toilet_scene = load(target_scene_path)
    var instance = toilet_scene.instantiate()

    var camera = instance.find_child("Camera3D", true, false)
    if not camera:
        print("Camera not found, creating one...")
        camera = Camera3D.new()
        camera.name = "Camera3D"
        instance.add_child(camera)
        camera.owner = instance
    
    # 懐中電灯の位置を目の高さに調整 (1.7m)
    camera.position = Vector3(0, 1.7, 5) # 入り口付近から見渡す位置
    camera.rotation_degrees = Vector3(-5, 0, 0) # 若干下を向ける

    # 懐中電灯 (SpotLight3D) を追加
    var flashlight = camera.get_node_or_null("Flashlight")
    if flashlight:
        camera.remove_child(flashlight)
        flashlight.free()
    
    print("Adding flashlight...")
    flashlight = SpotLight3D.new()
    flashlight.name = "Flashlight"
    camera.add_child(flashlight)
    flashlight.owner = instance
    
    # 懐中電灯のパラメータ設定
    flashlight.light_energy = 8.0     # 明るさ
    flashlight.spot_range = 25.0      # 届く距離
    flashlight.spot_angle = 35.0      # 光の広がり
    flashlight.light_color = Color(0.95, 0.95, 1.0) # 少し冷たい白
    flashlight.shadow_enabled = true  # 影を有効にして立体感を出す

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Flashlight successfully attached to Camera3D!")
    
    instance.free()
    quit()
