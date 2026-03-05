extends SceneTree

func _init():
    var target_scene_path = "res://scenes/公衆トイレ.tscn"
    var toilet_scene = load(target_scene_path)
    var instance = toilet_scene.instantiate()

    # 1. 懐中電灯の設定を修正
    var flashlight = instance.find_child("Flashlight", true, false)
    if flashlight and flashlight is SpotLight3D:
        print("Adjusting Flashlight settings...")
        # 影の設定が強すぎて黒ずんでいる可能性が高いため、一度オフにするか弱める
        flashlight.shadow_enabled = false 
        # ライトの減衰を調整して、近くでも白飛びせず綺麗に映るようにする
        flashlight.light_energy = 10.0
        flashlight.spot_attenuation = 0.5 
    
    # 2. 洗面台とトイレットペーパーのマテリアルをチェック/修正
    # 自己発光(Emission)を極微量入れることで、真っ黒に潰れるのを防ぐ
    var targets = ["Washbasin_0", "Washbasin_1", "ToiletPaper_0", "ToiletPaper_1", "ToiletPaper_2"]
    for t_name in targets:
        var node = instance.find_child(t_name, true, false)
        if node:
            print("Applying visibility fix to: ", t_name)
            # 各メッシュのマテリアルを調整（あれば）
            # ここではノード全体の座標やスケールに異常がないかも確認
            if node.scale.length() < 0.1: # 小さすぎると黒く見えることがある
                node.scale = Vector3(1, 1, 1)

    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, target_scene_path)
    print("Visibility fix for objects applied successfully.")
    
    instance.free()
    quit()
