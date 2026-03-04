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

var _voice    : AudioStreamPlayer = null


func _ready() -> void:
	_ambient = _make_player(0.0)
	_step    = _make_player(0.0)
	_monster = _make_player(0.0)
	_door    = _make_player(0.0)
	_voice   = _make_player(0.0)
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


## ボイス（WAV）を再生 — 直前のボイスは停止してから再生
func play_voice(path: String, vol_db: float = 0.0) -> void:
	# Godotのリソースシステム経由で読み込み（エクスポートビルドでも動作）
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path) as AudioStream
	if not s:
		# フォールバック: 生バイト読み込み（import未対応ファイル用）
		s = _load_wav(path)
	if not s:
		push_warning("SoundManager: voice not found: " + path)
		return
	_voice.stop()
	_voice.stream    = s
	_voice.volume_db = vol_db
	_voice.play()


## ボイスを停止
func stop_voice() -> void:
	_voice.stop()


## ボイス再生中かどうかを返す
func is_voice_playing() -> bool:
	return _voice.playing


## ボイス再生が終わるまで待機（再生中でなければ即リターン）
## finished シグナルに頼らずポーリングで待機（stop()時にシグナルが来ないバグ回避）
func await_voice() -> void:
	while _voice.playing:
		await get_tree().process_frame


# ════════════════════════════════════════════════════════════════
# WAV ローダー（バイト読み込み方式 — import 不要）
# ════════════════════════════════════════════════════════════════

func _load_wav(path: String) -> AudioStreamWAV:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		push_warning("SoundManager: WAV not found: " + path)
		return null
	var bytes := f.get_buffer(f.get_length())
	f.close()

	if bytes.size() < 44:
		return null

	# WAV ヘッダを解析
	var channels        := bytes.decode_u16(22)
	var sample_rate     := bytes.decode_u32(24)
	var bits_per_sample := bytes.decode_u16(34)

	# "data" チャンクを探す（fmt チャンクが可変長の場合に対応）
	var offset := 12
	while offset + 8 <= bytes.size():
		var chunk_id := bytes.slice(offset, offset + 4).get_string_from_ascii()
		var chunk_sz := bytes.decode_u32(offset + 4)
		offset += 8
		if chunk_id == "data":
			break
		offset += chunk_sz

	if offset >= bytes.size():
		return null

	var stream          := AudioStreamWAV.new()
	stream.data          = bytes.slice(offset)
	stream.mix_rate      = int(sample_rate)
	stream.stereo        = (channels == 2)
	stream.format        = AudioStreamWAV.FORMAT_16_BITS if bits_per_sample == 16 \
							else AudioStreamWAV.FORMAT_8_BITS
	return stream


## スーパーチャット通知チャイム（プログラム生成・昇順2音）
func play_superchat_chime(vol_db: float = -6.0) -> void:
	const RATE    := 44100
	const FREQ1   := 523.0   # C5
	const FREQ2   := 659.0   # E5
	const DUR1    := 0.13    # 秒
	const DUR2    := 0.16

	var gen := AudioStreamGenerator.new()
	gen.mix_rate     = float(RATE)
	gen.buffer_length = DUR1 + DUR2 + 0.05

	var player := AudioStreamPlayer.new()
	player.stream    = gen
	player.volume_db = vol_db
	add_child(player)
	player.play()

	var pb := player.get_stream_playback() as AudioStreamGeneratorPlayback

	# 第1音（C5）
	var n1 := int(RATE * DUR1)
	for i in n1:
		var t   := float(i) / RATE
		var env := sin(PI * t / DUR1)          # 半周期 sin エンベロープ
		var v   := sin(TAU * FREQ1 * t) * env * 0.45
		pb.push_frame(Vector2(v, v))

	# 第2音（E5）
	var n2 := int(RATE * DUR2)
	for i in n2:
		var t   := float(i) / RATE
		var env := sin(PI * t / DUR2)
		var v   := sin(TAU * FREQ2 * t) * env * 0.45
		pb.push_frame(Vector2(v, v))

	await get_tree().create_timer(DUR1 + DUR2 + 0.05).timeout
	player.queue_free()
