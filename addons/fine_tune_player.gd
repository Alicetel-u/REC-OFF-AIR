extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var toilet_scene = load(target_scene_path)
    var instance = toilet_scene.instantiate()

    var player = instance.find_child("Player", true, false)
    if not player:
        print("Error: Player not found.")
        quit()
        return
    
    # 1. 主観の位置 (Head) をさらに高くする (1.5m -> 1.65m)
    var head = player.find_child("Head", true, false)
    if head:
        head.position = Vector3(0, 1.65, 0)
        print("Updated eyes height to 1.65m")

    # 2. 懐中電灯の明るさを抑える
    var flashlight = player.find_child("Flashlight", true, false)
    if flashlight and flashlight is SpotLight3D:
        flashlight.light_energy = 5.0 # 明るさを半分に
        flashlight.spot_attenuation = 1.0 # 減衰を標準的に
        print("Reduced flashlight energy to 5.0")

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Success: Flashlight softened and eyes height increased.")
    
    instance.free()
    quit()
