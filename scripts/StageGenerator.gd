extends Node

## チャプターデータからステージ・ゴースト・アイテム・出口・ライトを動的生成

const GhostScene := preload("res://scenes/Ghost.tscn")
const ItemScene  := preload("res://scenes/Item.tscn")
const ExitScript   := preload("res://scripts/Exit.gd")
const UsePointScript := preload("res://scripts/UsePoint.gd")
const ChapterDataScript := preload("res://scripts/ChapterData.gd")
const GhostConfigScript := preload("res://scripts/GhostConfig.gd")
const LightConfigScript := preload("res://scripts/LightConfig.gd")

var item_count: int    = 0
var exit_node : Node3D = null


func generate(chapter: Resource) -> Dictionary:
	var parent := get_parent()

	# 1. ステージシーンをインスタンス化
	if not chapter.stage_scene_path.is_empty():
		var stage_scene := load(chapter.stage_scene_path) as PackedScene
		if stage_scene:
			var stage := stage_scene.instantiate()
			stage.name = "Stage"
			parent.add_child(stage)
			# デバッグ: CSGのシャドウを無効化（ドローコール削減）
			_disable_csg_shadows(stage)

	# 2. ゴーストをスポーン（デバッグ時は _DEBUG_NO_GHOST = true でスキップ）
	const _DEBUG_NO_GHOST := false
	for gc: Resource in chapter.ghost_configs:
		if _DEBUG_NO_GHOST:
			break
		var ghost := GhostScene.instantiate()
		ghost.position = gc.position
		# カスタムモデル指定（みゆき等）
		if gc.model_path and not gc.model_path.is_empty():
			ghost.custom_model_path = gc.model_path
			ghost.custom_model_scale = gc.model_scale
		# デバッグ: モーション/状態固定
		if gc.get("forced_motion") != null and gc.forced_motion >= 0:
			ghost.forced_motion = gc.forced_motion
		if gc.get("forced_state") != null and gc.forced_state >= 0:
			ghost.forced_state = gc.forced_state
		for i in range(gc.patrol_points.size()):
			var marker := Marker3D.new()
			marker.name = "Patrol_%d" % i
			marker.position = gc.patrol_points[i] - gc.position
			ghost.add_child(marker)
		parent.add_child(ghost)

	# 3. アイテムをスポーン
	item_count = chapter.item_positions.size()
	for i in range(item_count):
		var item := ItemScene.instantiate()
		item.name = "Item_%d" % (i + 1)
		item.position = chapter.item_positions[i]
		parent.add_child(item)

	# 4. 出口を生成
	exit_node = _create_exit(chapter.exit_position)
	parent.add_child(exit_node)

	# 5. エリアライトを生成
	for lc: Resource in chapter.lights:
		var light := OmniLight3D.new()
		light.position = lc.position
		light.light_color = lc.color
		light.light_energy = lc.energy
		light.omni_range = lc.omni_range
		parent.add_child(light)

	return { "spawns": { "player": chapter.player_spawn } }


func _disable_csg_shadows(node: Node) -> void:
	if node is CSGShape3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_csg_shadows(child)


func _create_exit(pos: Vector3) -> Area3D:
	var exit := Area3D.new()
	exit.name = "Exit"
	exit.position = pos
	exit.set_script(ExitScript)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.0, 3.0, 2.0)
	col.shape = shape
	exit.add_child(col)

	var light := OmniLight3D.new()
	light.name = "ExitLight"
	light.light_color = Color(0.2, 1.0, 0.35)
	light.light_energy = 0.45
	light.omni_range = 10.0
	exit.add_child(light)

	return exit



func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		return {}
	var data = json.get_data()
	if data is Dictionary:
		return data
	return {}


func _create_use_point(pos: Vector3, pid: String, req_item: String, use_msg: String, locked_msg: String) -> Area3D:
	var point := Area3D.new()
	point.name = "UsePoint_%s" % pid
	point.position = pos
	point.set_script(UsePointScript)
	point.point_id = pid
	point.required_item = req_item
	point.use_message = use_msg
	point.locked_message = locked_msg

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.0, 3.0, 3.0)
	col.shape = shape
	point.add_child(col)

	# 目印の光
	var light := OmniLight3D.new()
	light.name = "PointLight"
	light.light_color = Color(0.4, 0.1, 0.1)
	light.light_energy = 0.8
	light.omni_range = 8.0
	point.add_child(light)

	return point
