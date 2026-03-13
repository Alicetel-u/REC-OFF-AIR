@tool
extends Node3D

# --- レイアウト設定 ---
@export_group("Layout Settings")
@export var grid_size: Vector2i = Vector2i(25, 25)
@export var cell_size: float = 12.0
@export var path_width: float = 3.0

@export_group("Assets")
@export var house_models: Array[PackedScene] = []
@export var tree_model: PackedScene
@export var grass_model: PackedScene
@export var statue_model: PackedScene
@export var utility_pole_model: PackedScene

@export_group("Actions")
@export var edit_mode: bool = true : set = _on_edit_mode_changed
@export var generate_map: bool = false : set = _on_generate_pressed
@export var clear_map: bool = false : set = _on_clear_pressed

var grid = {}

func _ready():
	if not Engine.is_editor_hint():
		# ゲーム開始時に少し待ってから確実に生成
		await get_tree().create_timer(0.1).timeout
		_build()

func _on_edit_mode_changed(val):
	edit_mode = val
	var light = get_node_or_null("DirectionalLight3D")
	var env_node = get_node_or_null("WorldEnvironment")
	
	if light:
		light.light_energy = 4.0 if val else 0.1
	if env_node and env_node.environment:
		env_node.environment.fog_enabled = !val
		env_node.environment.background_mode = 1 # Color
		env_node.environment.background_color = Color(0.1, 0.1, 0.12) if !val else Color(0.8, 0.8, 0.9)
		env_node.environment.ambient_light_source = 2 # Specified Color
		env_node.environment.ambient_light_color = Color(0.05, 0.05, 0.1) if !val else Color(0.7, 0.7, 0.8)
		env_node.environment.ambient_light_energy = 3.0 if val else 0.5

func _on_generate_pressed(_v):
	_build()

func _on_clear_pressed(_v):
	var container = get_node_or_null("MapContainer")
	if container:
		for child in container.get_children():
			child.queue_free()

func _get_container():
	var c = get_node_or_null("MapContainer")
	if not c:
		c = Node3D.new()
		c.name = "MapContainer"
		add_child(c)
	return c

func _build():
	_on_clear_pressed(false)
	var container = _get_container()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	_generate_roads(rng)
	_draw_map(container, rng)

func _generate_roads(rng):
	grid.clear()
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			grid[Vector2i(x, y)] = 0
	
	var cells = [Vector2i(grid_size.x/2, grid_size.y/2)]
	grid[cells[0]] = 1
	
	for i in range(200):
		var curr = cells[rng.randi() % cells.size()]
		var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		dirs.shuffle()
		for d in dirs:
			var n = curr + d
			if n.x >= 0 and n.x < grid_size.x and n.y >= 0 and n.y < grid_size.y:
				if grid[n] == 0:
					grid[n] = 1
					cells.append(n)
					break

func _draw_map(container, rng):
	# 地面
	var g_mesh = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(500, 500)
	g_mesh.mesh = pm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.08, 0.05)
	mat.roughness = 1.0
	g_mesh.set_surface_override_material(0, mat)
	container.add_child(g_mesh)
	if Engine.is_editor_hint(): g_mesh.owner = get_tree().edited_scene_root
	
	# 各セル
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos = Vector3((x - grid_size.x/2) * cell_size, 0, (y - grid_size.y/2) * cell_size)
			if grid[Vector2i(x, y)] == 1:
				_create_path(pos, container)
			else:
				_spawn_scatter(pos, container, rng)

func _create_path(pos, container):
	var p = CSGBox3D.new()
	p.size = Vector3(cell_size, 0.1, path_width)
	p.position = pos
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.15, 0.1)
	p.material = m
	container.add_child(p)
	if Engine.is_editor_hint(): p.owner = get_tree().edited_scene_root
	
	# --- 電信柱の配置 (道の脇) ---
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	if utility_pole_model and rng.randf() < 0.15: # 15%の確率
		var pole = utility_pole_model.instantiate()
		container.add_child(pole)
		# 道の端 (path_width/2) より少し外側に配置
		var offset_x = (path_width / 2.0 + 0.5) * (1 if rng.randf() > 0.5 else -1)
		pole.position = pos + Vector3(offset_x, 0, 0)
		# 傾きをランダムに変えて不気味さを出す
		if "lean_angle" in pole:
			pole.lean_angle = rng.randf_range(-5, 5)
		if Engine.is_editor_hint(): pole.owner = get_tree().edited_scene_root

func _spawn_scatter(pos, container, rng):
	var r = rng.randf()
	if r < 0.2 and not house_models.is_empty():
		var h = house_models[rng.randi() % house_models.size()].instantiate()
		container.add_child(h)
		h.position = pos
		h.rotation.y = rng.randf() * PI * 2
		if Engine.is_editor_hint(): h.owner = get_tree().edited_scene_root
	elif r < 0.4:
		var t = tree_model.instantiate()
		container.add_child(t)
		t.position = pos + Vector3(rng.randf_range(-2,2), 0, rng.randf_range(-2,2))
		if Engine.is_editor_hint(): t.owner = get_tree().edited_scene_root
