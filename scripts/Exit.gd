extends Area3D

## 脱出ポイント: 全テープ収集後に有効化

@onready var exit_light : OmniLight3D = $ExitLight

var active  : bool  = false
var pulse_t : float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	GameManager.item_collected.connect(_on_item_collected)
	exit_light.light_energy = 0.3   # 最初は薄暗く


func _process(delta: float) -> void:
	if not active:
		return
	pulse_t += delta * 3.0
	exit_light.light_energy = 2.5 + sin(pulse_t) * 0.8


func _on_item_collected(count: int, total: int) -> void:
	if count >= total:
		active = true
		exit_light.light_energy = 3.0


func _on_body_entered(body: Node3D) -> void:
	if active and body.is_in_group("player"):
		GameManager.trigger_win()
