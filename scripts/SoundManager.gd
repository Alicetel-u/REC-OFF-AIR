extends Node

## SoundManager — 効果音・アンビエント管理 Autoload
## 使い方:
##   SoundManager.start_ambient(GameManager.chapter_index)
##   SoundManager.play_footstep(GameManager.chapter_index, is_dash)
##   SoundManager.play_monster_growl()
##   SoundManager.play_door_creak()

# チャプター別の足音カテゴリ（chapter_index → フォルダ名）
const STEP_CATS : Array = ["leaves", "wooden", "wooden", "wooden", "gravel"]

# チャプター別のアンビエント音量 dB
const AMBIENT_VOLS : Array = [-8.0, -14.0, -12.0, -12.0, -6.0]

var _ambient : AudioStreamPlayer = null
var _step    : AudioStreamPlayer = null
var _monster : AudioStreamPlayer = null
var _door    : AudioStreamPlayer = null

var _ambient_files : Array = []
var _monster_files : Array = []
var _door_files    : Array = []
var _step_cats     : Dictionary = {}   # category → Array of paths

var _monster_idx   : int = 0


func _ready() -> void:
	_ambient = _make_player(0.0)
	_step    = _make_player(0.0)
	_monster = _make_player(0.0)
	_door    = _make_player(0.0)
	_scan_all()


func _make_player(vol_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = vol_db
	add_child(p)
	return p


# ════════════════════════════════════════════════════════════════
# ファイルスキャン
# ════════════════════════════════════════════════════════════════

func _scan_all() -> void:
	_ambient_files = _scan_dir("res://assets/audio/sfx/ambient_wind")
	_monster_files = _scan_dir("res://assets/audio/sfx/monster")
	_door_files    = _scan_dir("res://assets/audio/sfx/door")
	for cat in ["leaves", "concrete", "carpet", "metal", "wind",
				"gravel", "mud", "stairs", "wooden"]:
		_step_cats[cat] = _scan_dir("res://assets/audio/sfx/footsteps/" + cat)


func _scan_dir(path: String) -> Array:
	var list : Array = []
	var d := DirAccess.open(path)
	if not d:
		return list
	d.list_dir_begin()
	var fname := d.get_next()
	while fname != "":
		if not d.current_is_dir() and fname.to_lower().ends_with(".mp3"):
			list.append(path + "/" + fname)
		fname = d.get_next()
	d.list_dir_end()
	return list


# ════════════════════════════════════════════════════════════════
# MP3 ロード（バイト読み込み方式 — import 不要）
# ════════════════════════════════════════════════════════════════

func _load_mp3(path: String) -> AudioStreamMP3:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return null
	var bytes := f.get_buffer(f.get_length())
	f.close()
	var s := AudioStreamMP3.new()
	s.data = bytes
	return s


# ════════════════════════════════════════════════════════════════
# 公開 API
# ════════════════════════════════════════════════════════════════

## アンビエント風音を開始（ループ再生）
func start_ambient(chapter_index: int) -> void:
	if _ambient_files.is_empty():
		return
	var vol : float  = AMBIENT_VOLS[clamp(chapter_index, 0, AMBIENT_VOLS.size() - 1)]
	var path : String = _ambient_files[randi() % _ambient_files.size()]
	var s := _load_mp3(path)
	if not s:
		return
	s.loop = true
	_ambient.stream    = s
	_ambient.volume_db = vol
	_ambient.play()


## 足音を再生（直前の足音が再生中なら無視）
func play_footstep(chapter_index: int, is_dash: bool) -> void:
	if _step.playing:
		return
	var cat  : String = STEP_CATS[clamp(chapter_index, 0, STEP_CATS.size() - 1)]
	var list : Array  = _step_cats.get(cat, [])
	if list.is_empty():
		return
	var s := _load_mp3(list[randi() % list.size()])
	if not s:
		return
	_step.stream      = s
	_step.volume_db   = -4.0 if is_dash else -8.0
	_step.pitch_scale = randf_range(0.92, 1.08)
	_step.play()


## ゴーストの唸り声を再生（ファイルを順番に使い回す）
func play_monster_growl(vol_db: float = -5.0) -> void:
	if _monster.playing or _monster_files.is_empty():
		return
	var s := _load_mp3(_monster_files[_monster_idx % _monster_files.size()])
	_monster_idx = (_monster_idx + 1) % _monster_files.size()
	if not s:
		return
	_monster.stream    = s
	_monster.volume_db = vol_db
	_monster.play()


## ドアの軋み音を再生
func play_door_creak() -> void:
	if _door_files.is_empty():
		return
	var s := _load_mp3(_door_files[randi() % _door_files.size()])
	if not s:
		return
	_door.stream    = s
	_door.volume_db = -6.0
	_door.play()
