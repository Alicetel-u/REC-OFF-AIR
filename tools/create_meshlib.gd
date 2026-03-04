## create_meshlib.gd  —  村・廃村アセットから MeshLibrary を自動生成
## 実行: godot.exe --path <project> --script tools/create_meshlib.gd
extends SceneTree

const MESHLIB_PATH := "res://assets/models/village_meshlib.meshlib"

const GLB_SOURCES := [
	"res://assets/models/Industrial_exterior_v2.glb",
	"res://shaders/素材/shrine_building.glb",
	"res://shaders/素材/komainu.glb",
	"res://shaders/素材/鳥居.glb",
	"res://shaders/素材/dead_tree.glb",
	"res://shaders/素材/立ち入り禁止.glb",
	"res://shaders/素材/案山子.glb",
]


func _initialize() -> void:
	print("\n══ MeshLibrary 生成開始 ══")
	var meshlib := MeshLibrary.new()
	var total   := 0

	for path in GLB_SOURCES:
		var packed : PackedScene = load(path) as PackedScene
		if not packed:
			push_warning("ロード失敗（スキップ）: " + path)
			continue
		var root  : Node   = packed.instantiate()
		var label : String = path.get_file().get_basename()
		var count := _collect(root, meshlib, label)
		root.queue_free()
		print("  %s → %d メッシュ" % [label, count])
		total += count

	var err := ResourceSaver.save(meshlib, MESHLIB_PATH)
	if err == OK:
		print("\n✅ 完了: %d アイテム → %s" % [total, MESHLIB_PATH])
	else:
		push_error("保存失敗 (error %d)" % err)

	quit()


func _collect(node: Node, meshlib: MeshLibrary, prefix: String) -> int:
	var count := 0
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			var id := meshlib.get_last_unused_item_id()
			meshlib.create_item(id)
			meshlib.set_item_name(id, prefix + "/" + node.name)
			meshlib.set_item_mesh(id, mi.mesh)
			meshlib.set_item_mesh_transform(id, Transform3D.IDENTITY)
			var shape := mi.mesh.create_convex_shape(true, true)
			if shape:
				meshlib.set_item_shapes(id, [shape, Transform3D.IDENTITY])
			count += 1
	for child in node.get_children():
		count += _collect(child, meshlib, prefix)
	return count
