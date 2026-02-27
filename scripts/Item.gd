extends Area3D

## VHSテープ: プレイヤーが近づくと自動収集

@onready var mesh_inst : MeshInstance3D = $MeshInstance3D
@onready var glow      : OmniLight3D    = $GlowLight

var bob_t: float = 0.0
var _vhs_resource: ItemResource = null


func _ready() -> void:
	bob_t = randf() * TAU   # ランダムな位相でボブを開始
	body_entered.connect(_on_body_entered)
	_vhs_resource = ItemResource.new()
	_vhs_resource.item_name = "VHSテープ"
	_vhs_resource.quantity = 1
	_vhs_resource.description = "貴重な証拠映像が収録されたVHSテープ"


func _process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	bob_t += delta * 1.8
	mesh_inst.position.y = sin(bob_t) * 0.09
	mesh_inst.rotate_y(delta * 1.4)
	glow.light_energy = 0.4 + sin(bob_t * 2.2) * 0.15


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameManager.collect_item()
		Inventory.collect.emit(_vhs_resource)
		queue_free()
