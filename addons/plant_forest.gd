extends SceneTree

func _init():
    var scene = load("res://scenes/Main.tscn")
    var instance = scene.instantiate()
    
    # 既存の森があれば削除
    var old_forest = instance.get_node_or_null("SpookyForest")
    if old_forest:
        instance.remove_child(old_forest)
        old_forest.free()
    
    var forest_root = Node3D.new()
    forest_root.name = "SpookyForest"
    instance.add_child(forest_root)
    forest_root.owner = instance
    
    # シェーダーの読み込み
    var mat_tree = ShaderMaterial.new()
    mat_tree.shader = load("res://assets/models/environment/shaders/spooky_trees.gdshader")
    ResourceSaver.save(mat_tree, "res://assets/models/environment/materials/spooky_trees.tres")

    # 木の幹用マテリアル
    var mat_trunk = StandardMaterial3D.new()
    mat_trunk.albedo_color = Color(0.04, 0.03, 0.02)
    mat_trunk.roughness = 1.0

    # 道（DarkStreet）は Z軸周りに幅6m。
    # -Z側からバス停を見て道があり、+X方向に伸びている。
    # したがって道の両脇（Z: -8 から Z: +8 の外側）や、バス停の背後などに木を大量に配置する。
    
    # ランダムに木を植える
    var tree_count = 150
    for i in range(tree_count):
        # バスの周囲 -10～+40m (X)、広がり -20～+20m (Z)
        var bx = randf_range(-10.0, 40.0)
        var bz = randf_range(-20.0, 20.0)
        
        # 道路やバス停のど真ん中（Zが-3〜+7、Xが-5〜+30付近）は避ける
        if abs(bz - 2.0) < 5.0 and bx > -5.0 and bx < 30.0:
            continue
            
        var tree = Node3D.new()
        tree.name = "Tree_" + str(i)
        tree.position = Vector3(bx, 0, bz)
        
        # 木の高さと太さをランダムに
        var scale_f = randf_range(0.8, 1.8)
        var tree_h = 8.0 * scale_f
        
        # 幹
        var trunk = CSGCylinder3D.new()
        trunk.name = "Trunk"
        trunk.radius = randf_range(0.15, 0.3) * scale_f
        trunk.height = tree_h
        trunk.position = Vector3(0, tree_h/2.0, 0)
        trunk.material = mat_trunk
        tree.add_child(trunk)
        trunk.owner = instance
        
        # 葉っぱ（板ポリゴンをクロスさせて立体的に見せる）
        var leaves1 = CSGBox3D.new()
        leaves1.name = "Leaves1"
        leaves1.size = Vector3(4.0 * scale_f, 5.0 * scale_f, 0.1)
        leaves1.position = Vector3(0, tree_h - 2.0 * scale_f, 0)
        leaves1.material = mat_tree
        tree.add_child(leaves1)
        leaves1.owner = instance
        
        var leaves2 = CSGBox3D.new()
        leaves2.name = "Leaves2"
        leaves2.size = Vector3(0.1, 5.0 * scale_f, 4.0 * scale_f)
        leaves2.position = Vector3(0, tree_h - 2.0 * scale_f, 0)
        leaves2.material = mat_tree
        tree.add_child(leaves2)
        leaves2.owner = instance
        
        # ランダムな回転を加えて自然に見せる
        tree.rotation_degrees.y = randf_range(0, 360)
        
        forest_root.add_child(tree)
        tree.owner = instance
        
    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://scenes/Main.tscn")
    print("Spooky Forest successfully planted around the area!")
    quit()
