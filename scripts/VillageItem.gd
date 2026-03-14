extends Area3D

## CP3 村の探索: 固有アイテム（木彫りの頭 / 錆びた鎌 / 写し鏡の御札）

const ItemResourceScript := preload("res://Inventory/ItemResource.gd")

@onready var mesh_inst : MeshInstance3D = $MeshInstance3D
@onready var glow      : OmniLight3D    = $GlowLight

var item_id : String = ""            # "kibori_head" / "sabi_kama" / "utsushi_ofuda"
var item_display_name : String = ""
var item_description  : String = ""
var glow_color : Color = Color(0.3, 0.8, 0.4)

var bob_t : float = 0.0
var _item_resource : Resource = null


func _ready() -> void:
	bob_t = randf() * TAU
	body_entered.connect(_on_body_entered)

	_item_resource = ItemResourceScript.new()
	_item_resource.item_name = item_display_name
	_item_resource.quantity = 1
	_item_resource.description = item_description

	# 見た目をアイテム別に設定
	_setup_appearance()


func _setup_appearance() -> void:
	glow.light_color = glow_color
	glow.light_energy = 1.5
	glow.omni_range = 6.0

	match item_id:
		"kibori_head":
			# 球体（木彫りの頭）
			var sphere := SphereMesh.new()
			sphere.radius = 0.2
			sphere.height = 0.4
			mesh_inst.mesh = sphere
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.45, 0.3, 0.15)
			mat.emission_enabled = true
			mat.emission = glow_color * 0.3
			mat.emission_energy_multiplier = 0.5
			mesh_inst.material_override = mat
		"sabi_kama":
			# 平板（鎌の刃）
			var box := BoxMesh.new()
			box.size = Vector3(0.6, 0.05, 0.15)
			mesh_inst.mesh = box
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.3, 0.15, 0.1)
			mat.emission_enabled = true
			mat.emission = glow_color * 0.3
			mat.emission_energy_multiplier = 0.5
			mesh_inst.material_override = mat
		"utsushi_ofuda":
			# 薄い板（御札）
			var box := BoxMesh.new()
			box.size = Vector3(0.12, 0.2, 0.01)
			mesh_inst.mesh = box
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.9, 0.85, 0.7)
			mat.emission_enabled = true
			mat.emission = glow_color * 0.4
			mat.emission_energy_multiplier = 0.8
			mesh_inst.material_override = mat


func _process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	bob_t += delta * 1.5
	mesh_inst.position.y = sin(bob_t) * 0.08
	mesh_inst.rotate_y(delta * 1.0)
	glow.light_energy = 1.5 + sin(bob_t * 1.5) * 0.5


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	GameManager.collect_item()
	Inventory.collect.emit(_item_resource)
	# 鎌入手時: EncodingError に通知
	if item_id == "sabi_kama":
		var enc := get_tree().current_scene.get_node_or_null("EncodingError")
		if enc and enc.has_method("notify_kama_acquired"):
			enc.notify_kama_acquired()
	# モノローグ表示
	var hud := _find_hud()
	if hud and hud.has_method("show_monologue"):
		var msg := ""
		match item_id:
			"kibori_head":
				msg = "なにこれ……目が、こっち見てる……？"
			"sabi_kama":
				msg = "重い……この鎌、誰かの恨みがこもってるみたい……"
			"utsushi_ofuda":
				msg = "鏡みたいな御札……スマホに映すと顔が……"
		if msg != "":
			hud.show_monologue(msg)
			var tree := get_tree()
			if tree:
				await tree.create_timer(4.0).timeout
				if is_instance_valid(hud) and hud.has_method("hide_monologue"):
					hud.hide_monologue()
	queue_free()


func _find_hud() -> Control:
	var main := get_tree().current_scene
	if main and main.has_node("HUDLayer/HUDRoot"):
		return main.get_node("HUDLayer/HUDRoot") as Control
	return null
