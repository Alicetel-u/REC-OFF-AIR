extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var toilet_scene = load(target_scene_path)
    if not toilet_scene:
        print("Error: Could not load scene.")
        quit()
        return

    var instance = toilet_scene.instantiate()
    var sign = instance.find_child("EntranceSign", true, false)
    
    if sign and sign is Sprite3D:
        print("Fixing EntranceSign shading mode...")
        # Sprite3Dの陰影設定を「ライティングあり」に強制する
        # Godot 4では flags_unshaded を false に設定します
        sign.shaded = true # ライトに反応するように設定
        
        # アルベドの色も微調整（必要に応じて）
        sign.modulate = Color(1, 1, 1, 1) 
    else:
        print("EntranceSign not found or is not a Sprite3D.")

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Success: Toilet sign is now affected by light.")
    
    instance.free()
    quit()
