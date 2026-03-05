extends SceneTree
func _init():
    var img = Image.create(1024, 472, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.2,0.8,0.2,1)) # プレースホルダーの緑色
    
    var dir = DirAccess.open("res://assets/models/environment")
    if dir:
        if not dir.dir_exists("textures"):
            dir.make_dir("textures")
    
    img.save_png("res://assets/models/environment/textures/village_sign.png")
    print("Dummy image created!")
    quit()
