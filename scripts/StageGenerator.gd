extends Node

## チャプターデータからステージ・ゴースト・アイテム・出口・ライトを動的生成

const GhostScene := preload("res://scenes/Ghost.tscn")
const ItemScene  := preload("res://scenes/Item.tscn")
const VillageItemScene := preload("res://scenes/VillageItem.tscn")
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
		for i in range(gc.patrol_points.size()):
			var marker := Marker3D.new()
			marker.name = "Patrol_%d" % i
			marker.position = gc.patrol_points[i] - gc.position
			ghost.add_child(marker)
		parent.add_child(ghost)

	# 3. アイテムをスポーン
	item_count = chapter.item_positions.size()
	if chapter.chapter_id == "ch02_mura_tansaku":
		_spawn_village_items(chapter, parent)
	else:
		for i in range(item_count):
			var item := ItemScene.instantiate()
			item.name = "Item_%d" % (i + 1)
			item.position = chapter.item_positions[i]
			parent.add_child(item)

	# 4. 出口を生成
	exit_node = _create_exit(chapter.exit_position)
	if chapter.chapter_id == "ch02_mura_tansaku":
		exit_node._requires_ofuda = true
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


## CP3 村の探索: 固有アイテム3種 + 使用ポイント2箇所を生成
func _spawn_village_items(chapter: Resource, parent: Node) -> void:
	# アイテム定義: [item_id, display_name, description, glow_color]
	var item_defs := [
		["kibori_head", "木彫りの頭",
			"眼球の嵌め込まれた木彫りの頭。視線がカメラを追ってくる。",
			Color(0.6, 0.2, 0.1)],
		["sabi_kama", "錆びた鎌",
			"刃こぼれした錆びた鎌。誰かの恨みがこもっている。",
			Color(0.8, 0.15, 0.1)],
		["utsushi_ofuda", "写し鏡の御札",
			"鏡のように光を反射する特殊な御札。",
			Color(0.9, 0.85, 0.5)],
	]

	for i in range(mini(item_defs.size(), chapter.item_positions.size())):
		var vi := VillageItemScene.instantiate()
		vi.name = "VillageItem_%d" % (i + 1)
		vi.position = chapter.item_positions[i]
		vi.item_id = item_defs[i][0]
		vi.item_display_name = item_defs[i][1]
		vi.item_description = item_defs[i][2]
		vi.glow_color = item_defs[i][3]
		parent.add_child(vi)

	# 使用ポイント: 案山子（木彫りの頭を載せる）
	var kakashi := _create_use_point(
		Vector3(24.50, 1.0, -68.25),
		"kakashi",
		"木彫りの頭",
		"頭を案山子に載せた……封印が、解けていく……！",
		"首のない案山子がある……何か載せるものが必要みたい。"
	)
	parent.add_child(kakashi)

	# 使用ポイント: 門（錆びた鎌で髪の紐を切る）
	var mon := _create_use_point(
		Vector3(87.75, 1.0, 45.75),
		"mon",
		"錆びた鎌",
		"髪の毛のような紐を……切った！ 門が開く！",
		"門に髪の毛のような紐が絡みついている……切るものが必要だ。"
	)
	parent.add_child(mon)


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
