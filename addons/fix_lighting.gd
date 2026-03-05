extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var toilet_scene = load(target_scene_path)
    var instance = toilet_scene.instantiate()

    # 1. WorldEnvironmentの設定を強化
    var env_node = instance.find_child("WorldEnvironment", true, false)
    if env_node and env_node.environment:
        var env = env_node.environment
        
        # 色指定は安全なのでそのまま使用
        env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        env.ambient_light_color = Color(0.04, 0.04, 0.1, 1.0) # 少し明るめの紺色
        env.ambient_light_energy = 0.5 

        # トーンマップなどは数値で指定（安全策）
        env.tonemap_mode = 2 # ACES
        
        env.fog_enabled = true
        env.fog_light_color = Color(0, 0, 0, 1)
        env.fog_density = 0.01
        
        print("Updated Environment settings (Manual value for tonemap).")

    # 2. 補助的な月明かり (DirectionalLight3D)
    var moonlight = instance.get_node_or_null("Moonlight")
    if moonlight:
        instance.remove_child(moonlight)
        moonlight.free()
    
    print("Adding subtle moonlight...")
    moonlight = DirectionalLight3D.new()
    moonlight.name = "Moonlight"
    instance.add_child(moonlight)
    moonlight.owner = instance
    
    moonlight.light_energy = 0.15
    moonlight.light_color = Color(0.4, 0.4, 0.6) # 青白い
    moonlight.rotation_degrees = Vector3(-50, 45, 0)
    moonlight.light_specular = 0
    moonlight.shadow_enabled = false # 影なしで全体の暗さを底上げ

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Lighting fix applied securely.")
    
    instance.free()
    quit()
