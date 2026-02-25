extends Node

## シナリオ管理 Autoload
## JSON からシナリオを読み込み、トリガー条件に応じて発火する

signal scenario_triggered(scenario: Dictionary)
signal scenario_resolved(scenario: Dictionary, choice_idx: int, agreed: bool)

var _scenarios: Array = []
var _completed: Array[String] = []
var _active: bool = false


func _ready() -> void:
	_load_scenarios()
	GameManager.item_collected.connect(_on_item_collected)


func _load_scenarios() -> void:
	var f := FileAccess.open("res://scenarios/main_scenario.json", FileAccess.READ)
	if f == null:
		push_warning("ScenarioManager: シナリオファイルが見つかりません")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and parsed.has("scenarios"):
		_scenarios = parsed["scenarios"]


func trigger(trigger_type: String, context: Dictionary = {}) -> void:
	if _active:
		return
	for entry: Variant in _scenarios:
		var s: Dictionary = entry
		if s["id"] in _completed:
			continue
		var t: Dictionary = s["trigger"]
		if t["type"] != trigger_type:
			continue
		if trigger_type == "items_collected":
			if context.get("count", 0) != int(t.get("count", -1)):
				continue
		_active = true
		_completed.append(s["id"])
		scenario_triggered.emit(s)
		return


func resolve(scenario: Dictionary, choice_idx: int) -> void:
	var choices: Array = scenario["choices"]
	var choice: Dictionary = choices[choice_idx]
	var agreed: bool = choice["streamer_reaction"] == "agree"
	_active = false
	scenario_resolved.emit(scenario, choice_idx, agreed)


func _on_item_collected(count: int, _total: int) -> void:
	trigger("items_collected", { "count": count })
