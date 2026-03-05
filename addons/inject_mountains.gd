extends SceneTree

func _init():
    var scene = load("res://scenes/Main.tscn")
    var instance = scene.instantiate()
    
    # 既存のノードがあれば消す
    var old_node = instance.get_node_or_null("MountainsAndFields")
    if old_node:
        instance.remove_child(old_node)
        old_node.free()
        
    var mf_scene = load("res://assets/models/environment/MountainsAndFields.tscn")
    var mf = mf_scene.instantiate()
    mf.name = "MountainsAndFields"
    
    # 追加
    instance.add_child(mf)
    mf.owner = instance
    
    var packed = PackedScene.new()
    packed.pack(instance)
    ResourceSaver.save(packed, "res://scenes/Main.tscn")
    print("Mountains and Fields successfully injected into Main.tscn!")
    quit()
