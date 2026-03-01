@tool
extends EditorPlugin

var _panel: Control = null


func _enter_tree() -> void:
	var script := load("res://addons/dialogue_editor/DialogueEditorPanel.gd")
	_panel = script.new()
	add_control_to_bottom_panel(_panel, "Dialogue")


func _exit_tree() -> void:
	if is_instance_valid(_panel):
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
	_panel = null
