extends SceneTree

func _init():
	var img = Image.new()
	var err = img.load("res://assets/models/environment/textures/happy_street_sign.png")
	if err == OK:
		var width = img.get_width()
		var height = img.get_height()
		var min_x = width
		var max_x = 0
		var min_y = height
		var max_y = 0
		var found = false
		
		for y in range(height):
			for x in range(width):
				var c = img.get_pixel(x, y)
				# Use alpha channel if present, else check if it's NOT white
				if c.a > 0.1 and (c.r < 0.9 or c.g < 0.9 or c.b < 0.9):
					if x < min_x: min_x = x
					if x > max_x: max_x = x
					if y < min_y: min_y = y
					if y > max_y: max_y = y
					found = true
		
		if found:
			print("BBOX: ", min_x, ", ", min_y, " to ", max_x, ", ", max_y, " in (", width, "x", height, ")")
			print("Center X: ", (min_x + max_x) / 2.0 / width)
			print("Center Y: ", (min_y + max_y) / 2.0 / height)
			print("Aspect: ", float(max_x - min_x) / float(max_y - min_y))
		else:
			print("NO TEXT FOUND")
	else:
		print("FAILED TO LOAD")
	quit()
