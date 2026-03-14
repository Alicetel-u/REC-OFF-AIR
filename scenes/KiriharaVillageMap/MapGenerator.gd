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
		# 手動配置ノードにも当たり判定を追加
		_add_collisions_to_manual_nodes()

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
				_create_path(pos, container, rng)
			else:
				_spawn_scatter(pos, container, rng)

func _create_path(pos, container, rng):
	var p = CSGBox3D.new()
	p.size = Vector3(cell_size, 0.1, path_width)
	p.position = pos
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.15, 0.1)
	p.material = m
	container.add_child(p)
	if Engine.is_editor_hint(): p.owner = get_tree().edited_scene_root

	# --- 電信柱の配置 (道の脇) ---
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
		# 電信柱にコリジョン追加
		_add_box_collision(pole, Vector3(0.3, 6.0, 0.3), Vector3(0, 3.0, 0))

func _spawn_scatter(pos, container, rng):
	var r = rng.randf()
	if r < 0.2 and not house_models.is_empty():
		var h = house_models[rng.randi() % house_models.size()].instantiate()
		container.add_child(h)
		h.position = pos
		h.rotation.y = rng.randf() * PI * 2
		if Engine.is_editor_hint(): h.owner = get_tree().edited_scene_root
		# 建物にコリジョン追加
		_add_box_collision(h, Vector3(4.0, 6.0, 4.0), Vector3(0, 3.0, 0))
	elif r < 0.4 and tree_model:
		var t = tree_model.instantiate()
		container.add_child(t)
		t.position = pos + Vector3(rng.randf_range(-2,2), 0, rng.randf_range(-2,2))
		if Engine.is_editor_hint(): t.owner = get_tree().edited_scene_root
		# 木にコリジョン追加（幹のみ）
		_add_box_collision(t, Vector3(0.5, 4.0, 0.5), Vector3(0, 2.0, 0))


# ════════════════════════════════════════════════════════════════
# 当たり判定ユーティリティ
# ════════════════════════════════════════════════════════════════

## ノードにBoxShape3Dの当たり判定を追加
func _add_box_collision(node: Node3D, box_size: Vector3, offset: Vector3 = Vector3.ZERO) -> void:
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	col.shape = shape
	col.position = offset
	body.add_child(col)
	node.add_child(body)


## 手動配置された建物・オブジェクトにコリジョンを追加
func _add_collisions_to_manual_nodes() -> void:
	for child in get_children():
		if child is Node3D and child.name != "GroundStaticBody" and child.name != "MapContainer":
			# 既にコリジョンがあるノードはスキップ
			if _has_collision(child):
				continue
			var node_name : String = child.name
			if node_name.begins_with("ManualBuilding"):
				# 建物: スケールに応じたコリジョン
				var s : float = _get_uniform_scale(child)
				var box_w : float = maxf(3.0, s * 0.15)
				var box_h : float = maxf(5.0, s * 0.2)
				_add_box_collision(child, Vector3(box_w, box_h, box_w), Vector3(0, box_h * 0.5, 0))
			elif node_name.begins_with("Concrete"):
				# コンクリート壁: 薄い壁コリジョン
				var s : float = _get_uniform_scale(child)
				var wall_w : float = maxf(1.0, s * 0.18)
				var wall_h : float = maxf(2.0, s * 0.35)
				_add_box_collision(child, Vector3(wall_w, wall_h, 0.3), Vector3(0, wall_h * 0.5, 0))
			elif node_name.begins_with("Tree"):
				_add_box_collision(child, Vector3(0.5, 4.0, 0.5), Vector3(0, 2.0, 0))
			elif node_name.begins_with("Car") or "廃車" in node_name:
				var s : float = _get_uniform_scale(child)
				_add_box_collision(child, Vector3(2.0 * s, 1.5, 4.0 * s), Vector3(0, 0.75, 0))
			elif node_name.begins_with("Manual_Buddha") or "仏像" in node_name:
				_add_box_collision(child, Vector3(1.0, 2.0, 1.0), Vector3(0, 1.0, 0))
			elif node_name.begins_with("Gate") or "Gate" in node_name:
				var s : float = _get_uniform_scale(child)
				_add_box_collision(child, Vector3(6.0 * s, 4.0, 0.5), Vector3(0, 2.0, 0))
			elif node_name.begins_with("Pole") or "Pole" in node_name:
				_add_box_collision(child, Vector3(0.3, 6.0, 0.3), Vector3(0, 3.0, 0))


func _has_collision(node: Node) -> bool:
	for child in node.get_children():
		if child is StaticBody3D or child is CollisionShape3D:
			return true
		if _has_collision(child):
			return true
	return false


func _get_uniform_scale(node: Node3D) -> float:
	var t : Transform3D = node.transform
	return t.basis.x.length()
