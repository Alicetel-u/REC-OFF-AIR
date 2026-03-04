@tool
extends Node3D
## MapEditor 用カメラコントローラー（ゲーム実行時・エディター両対応）
##
## 操作:
##   WASD / 矢印キー  — 水平移動
##   マウスホイール    — ズームイン/アウト
##   中クリックドラッグ — パン
##   F キー           — 原点(0,0,0)にリセット
##   テンキー7        — 真上から見下ろし（Godot エディター標準ショートカット）

@export var move_speed  : float = 20.0
@export var zoom_speed  : float = 3.0
@export var min_height  : float = 5.0
@export var max_height  : float = 120.0

var _cam      : Camera3D = null
var _drag     : bool     = false
var _drag_pos : Vector2  = Vector2.ZERO


const MESHLIB_PATH := "res://assets/models/village_meshlib.meshlib"


func _ready() -> void:
	_cam = _find_camera(self)
	if not _cam:
		# 子に Camera3D がなければ作成
		_cam = Camera3D.new()
		_cam.name = "Camera3D"
		add_child(_cam)

	# 真上から見下ろす俯瞰設定
	_cam.projection       = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size             = 40.0
	_cam.position         = Vector3(0, 60, 0)
	_cam.rotation_degrees = Vector3(-90, 0, 0)

	# MeshLibrary を自動割り当て（create_meshlib.gd 実行後に有効になる）
	_auto_assign_meshlib()


func _auto_assign_meshlib() -> void:
	if not ResourceLoader.exists(MESHLIB_PATH):
		return
	var gridmap := _find_gridmap(self)
	if gridmap and not gridmap.mesh_library:
		gridmap.mesh_library = load(MESHLIB_PATH)
		print("MapEditor: MeshLibrary 自動割り当て完了")


func _find_gridmap(node: Node) -> GridMap:
	if node is GridMap:
		return node
	for child in node.get_children():
		var result := _find_gridmap(child)
		if result:
			return result
	return null


func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	for child in node.get_children():
		var result := _find_camera(child)
		if result:
			return result
	return null


func _unhandled_input(event: InputEvent) -> void:
	# ズーム（ホイール）
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom(-zoom_speed)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(zoom_speed)
			elif mb.button_index == MOUSE_BUTTON_MIDDLE:
				_drag     = true
				_drag_pos = mb.position
		else:
			if mb.button_index == MOUSE_BUTTON_MIDDLE:
				_drag = false

	# 中クリックドラッグ → パン
	if event is InputEventMouseMotion and _drag:
		var mm    := event as InputEventMouseMotion
		var delta := mm.position - _drag_pos
		_drag_pos  = mm.position
		var scale : float = _cam.size / get_viewport().get_visible_rect().size.y
		_cam.position.x -= delta.x * scale
		_cam.position.z -= delta.y * scale

	# F キー → 原点リセット
	if event is InputEventKey and event.pressed:
		if (event as InputEventKey).keycode == KEY_F:
			_cam.position = Vector3(0, 60, 0)
			_cam.size     = 40.0


func _process(delta: float) -> void:
	if not is_instance_valid(_cam):
		return

	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1

	if dir != Vector2.ZERO:
		var speed := move_speed * (_cam.size / 20.0)   # ズームに比例して速度調整
		_cam.position.x += dir.x * speed * delta
		_cam.position.z += dir.y * speed * delta


func _zoom(amount: float) -> void:
	_cam.size = clamp(_cam.size + amount, min_height, max_height)
