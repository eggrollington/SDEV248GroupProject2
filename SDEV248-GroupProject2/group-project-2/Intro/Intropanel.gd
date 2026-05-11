extends Panel


@onready var label: RichTextLabel = $"../RichTextLabel"

var text_queue = []
var current_text = ""

var char_index = 0
var typing_speed = 0.03
var can_advance = false

func _ready():
	start_intro()


func start_intro():
	text_queue = [
		"Welcome to the Holy Relic...",
		"Before you can reach the Holy Relic",
		"Your must defeat the Evil Wizard"
	]
	show_next_text()


func show_next_text():
	if text_queue.is_empty():
		get_tree().change_scene_to_file("res://main_map.tscn")
		return

	current_text = text_queue.pop_front()
	char_index = 0
	label.text = ""
	can_advance = false
	type_text()

func type_text():
	if char_index < current_text.length():
		label.text += current_text[char_index]
		char_index += 1
		await get_tree().create_timer(typing_speed).timeout
		type_text()
	else:
		can_advance = true
		

func _process(delta):
	if Input.is_action_just_pressed("ui_accept") and can_advance:
		show_next_text()
