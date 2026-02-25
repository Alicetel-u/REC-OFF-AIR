extends Node
class_name StageGenerator

## ステージ情報を収集し、スポーン情報を返す
## (マップはシーンに静的配置済み。このクラスは情報の集約のみ担当)

var item_count: int   = 0
var exit_node : Node3D = null

## map_type 別プレイヤースポーン位置
const PLAYER_SPAWNS := {
	0: Vector3(0.0, 1.0, 15.0),  # INDUSTRIAL (廃工場)
	1: Vector3(0.0, 1.0, 15.0),  # HAISON     (廃村)
}


func generate(map_type: int) -> Dictionary:
	var parent := get_parent()

	# シーン内のアイテムをカウント
	item_count = 0
	for child in parent.get_children():
		var s = child.get_script()
		if s and (s as Script).resource_path.ends_with("Item.gd"):
			item_count += 1

	# 出口ノードを取得
	exit_node = parent.get_node_or_null("Exit")

	var spawn: Vector3 = PLAYER_SPAWNS.get(map_type, Vector3(0.0, 1.0, 15.0))
	return { "spawns": { "player": spawn } }
