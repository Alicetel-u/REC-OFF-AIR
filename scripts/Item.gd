extends Area3D

## VHSテープ: プレイヤーが近づくと自動収集

const ItemResourceScript := preload("res://Inventory/ItemResource.gd")

@onready var mesh_inst : MeshInstance3D = $MeshInstance3D
@onready var glow      : OmniLight3D    = $GlowLight

var bob_t: float = 0.0
var _vhs_resource: Resource = null
var _beacon: MeshInstance3D = null


func _ready() -> void:
	bob_t = randf() * TAU
	body_entered.connect(_on_body_entered)
	_vhs_resource = ItemResourceScript.new()
	_vhs_resource.item_name = "VHSテープ"
	_vhs_resource.quantity = 1
	_vhs_resource.description = "貴重な証拠映像が収録されたVHSテープ"

	# ── VHS を目立たせる ──
	mesh_inst.scale = Vector3(2.2, 2.2, 2.2)  # 2倍強に拡大
	glow.omni_range   = 8.0
	glow.light_color  = Color(0.78, 0.45, 1.0)  # 紫色
	glow.light_energy = 2.0

	# 上方向に伸びる光柱（遠くからでも見える目印）
	_beacon = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height        = 8.0
	cyl.top_radius    = 0.03
	cyl.bottom_radius = 0.18
	_beacon.mesh      = cyl
	_beacon.position  = Vector3(0, 4.5, 0)
	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color               = Color(0.78, 0.45, 1.0, 0.28)
	beam_mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.emission_enabled           = true
	beam_mat.emission                   = Color(0.6, 0.2, 0.9)
	beam_mat.emission_energy_multiplier = 1.8
	beam_mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED
	_beacon.material_override           = beam_mat
	add_child(_beacon)


func _process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	bob_t += delta * 1.8
	mesh_inst.position.y = sin(bob_t) * 0.09
	mesh_inst.rotate_y(delta * 1.4)
	# グローをパルス（1.2〜2.8 の範囲）
	glow.light_energy = 2.0 + sin(bob_t * 1.8) * 0.8
	# 光柱フェード
	if is_instance_valid(_beacon):
		var alpha := 0.22 + sin(bob_t * 2.5) * 0.12
		(_beacon.material_override as StandardMaterial3D).albedo_color.a = alpha


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameManager.collect_item()
		Inventory.collect.emit(_vhs_resource)
		queue_free()
