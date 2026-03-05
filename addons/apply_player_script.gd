extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var script_path = "res://assets/scripts/player_controller.gd"
    
    var toilet_scene = load(target_scene_path)
    var player_script = load(script_path)
    
    if not toilet_scene or not player_script:
        print("Error: Could not load scene or script file.")
        quit()
        return

    var instance = toilet_scene.instantiate()
    var player = instance.find_child("Player", true, false)
    
    if not player:
        print("Player not found, creating a new one...")
        player = CharacterBody3D.new()
        player.name = "Player"
        instance.add_child(player)
        player.owner = instance
    
    player.position = Vector3(0, 2.0, 5.0) # 空中から開始して埋まりを確実に避ける
    player.set_script(player_script)

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Success: External script attached to Player.")
    
    instance.free()
    quit()
