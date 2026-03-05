extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var toilet_scene = load(target_scene_path)
    if not toilet_scene:
        print("Error: Could not load scene.")
        quit()
        return

    var instance = toilet_scene.instantiate()

    # 1. 補助光 (Moonlight) を削除
    var moonlight = instance.get_node_or_null("Moonlight")
    if moonlight:
        instance.remove_child(moonlight)
        moonlight.free()
        print("Removed Moonlight.")

    # 2. 環境設定 (WorldEnvironment) を漆黒にする
    var env_node = instance.find_child("WorldEnvironment", true, false)
    if env_node and env_node.environment:
        var env = env_node.environment
        env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        env.ambient_light_color = Color(0, 0, 0, 1) # 漆黒
        env.ambient_light_energy = 0.0
        
        # フォグも真っ暗に
        env.fog_enabled = true
        env.fog_light_color = Color(0, 0, 0, 1)
        env.fog_density = 0.05 # 近くても暗闇に見えるように
        
        # 背景
        env.background_mode = Environment.BG_COLOR
        env.background_color = Color(0, 0, 0, 1)
        
        print("WorldEnvironment set to total darkness.")

    # 3. 蛍光灯モデル自体にライトが含まれていないかチェック（念のため）
    # もしモデルの外部でライトを追加していた場合はここで削除
    for child in instance.get_children():
        if child is OmniLight3D or child is SpotLight3D:
            # プレイヤーが持っている懐中電灯以外を削除
            if child.name != "Player" and not child.is_ancestor_of(instance.find_child("Flashlight", true, false)):
                instance.remove_child(child)
                child.free()
                print("Removed stray light: ", child.name)

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Success: Scene is now Pitch Black. Only the player's flashlight remains.")
    
    instance.free()
    quit()
