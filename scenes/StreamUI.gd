extends Control

@onready var viewer_label = $TopInfo/ViewersCount
@onready var comment_container = $CommentSection

var viewers = 1
var time_elapsed = 0.0

var normal_comments = [
	"どここれ？まじの廃村？",
	"音怖すぎだろ…",
	"なんか映ってない？",
	"配信主、後ろ気をつけて",
	"これヤラセじゃないよね？",
	"電波良すぎて草",
	"霧原村とか聞いたことないわ",
	"めっちゃ霧濃いな",
	"バス停？",
	"こんな時間に山奥とか勇気あるなー",
	"画質悪っ",
	"これ絶対でるやつ"
]

func _ready():
	for child in comment_container.get_children():
		child.queue_free()
	
	viewer_label.text = "● " + str(viewers) + " 人が視聴中"
	
	var timer = Timer.new()
	timer.wait_time = 4.0
	timer.autostart = true
	timer.timeout.connect(_add_comment)
	add_child(timer)

func _process(delta):
	time_elapsed += delta
	
	# 視聴者数の「波」を作る
	if randf() < 0.02: # 毎フレーム2%の確率で変動判定
		var change = 0
		if viewers < 5:
			change = randi_range(0, 2) # 増えやすい
		elif viewers > 20:
			change = randi_range(-3, 1) # 減りやすい
		else:
			change = randi_range(-2, 2) # 波
			
		viewers += change
		
		if viewers < 1:
			viewers = 1
			
		viewer_label.text = "● " + str(viewers) + " 人が視聴中"

func _add_comment():
	# 視聴者が少ないうちはコメントも少なめ
	if randf() > 0.4:
		return
		
	var new_comment = Label.new()
	new_comment.add_theme_color_override("font_shadow_color", Color.BLACK)
	
	var user_name = "user" + str(randi_range(10, 999))
	new_comment.text = user_name + ": " + normal_comments.pick_random()
	comment_container.add_child(new_comment)
	
	if comment_container.get_child_count() > 6:
		comment_container.get_child(0).queue_free()
