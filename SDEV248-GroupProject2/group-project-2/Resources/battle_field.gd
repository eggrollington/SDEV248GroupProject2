extends Node2D
@export var player_group : Node2D
@export var enemy_group : Node2D
@export var timeline : HBoxContainer
@export var options : VBoxContainer 
@export var enemy_button : PackedScene
@export var notify_label : Label

var sorted_array = []
var players : Array[Character]
var enemies : Array[Character]
var monster_is_crouching : bool = false
@onready var climb_button = %ClimbButton
var battle_over : bool = false


var next_monster_move = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for player in player_group.get_children():
		players.append(player.character)
		
	for enemy in enemy_group.get_children():
		enemies.append(enemy.character)
		
		var button = enemy_button.instantiate()
		button.character = enemy.character
		button.name = enemy.character.title
		%EnemySelection.add_child(button)
		
		if enemy.character.title == "Head":
			button.hide()
		
	sort_and_display()
	EventBus.next_attack.connect(next_attack)
	EventBus.part_destroyed.connect(_on_part_depleted)
	next_attack()

func predict_monster_move():
	# Logic to decide what the monster WILL do
	var target = players.pick_random()
	next_monster_move = {"type": "Bite", "target": target}

func update_foresight_ui():
	# 1. Check if any player named "Seer" is in the party
	var has_foresight = false
	for p in players:
		if p.title == "Seer": 
			has_foresight = true
			break

	# 2. Get the current character at the top of the timeline
	var current_char = sorted_array[0]["character"]
	
	# 3. Handle Label visibility
	if current_char in enemies:
		var monster_node = current_char.node # Reference to the Sprite2D
		var label = monster_node.get_node("IntentLabel")
		
		if has_foresight:
			label.text = "Intent: " + next_monster_move["type"]
			label.show()
		else:
			label.hide()
	else:
		# If it's a player turn, ensure all enemy intent labels are hidden
		for enemy in enemies:
			if enemy.node.has_node("IntentLabel"):
				enemy.node.get_node("IntentLabel").hide()

func sort_combined_queue():
	var player_array = []
	for player in players:
		for i in player.queue:
			player_array.append({"character" : player, "time": i})
			
	var enemy_array = []
	for enemy in enemies:
		for i in enemy.queue:
			enemy_array.append({"character" : enemy, "time": i})
			
	sorted_array = player_array
	sorted_array.append_array(enemy_array)
	sorted_array.sort_custom(sort_by_time)
			
func sort_by_time(a,b):
	return a["time"] < b["time"]
	
func update_timeline():
	var index : int = 0
	for slot in timeline.get_children():
		slot.find_child("TextureRect").texture = sorted_array[index]["character"].icon
		index += 1

func sort_and_display():
	sort_combined_queue()
	update_timeline()
	
	# If an enemy is up next, predict their move
	if sorted_array[0]["character"] in enemies:
		predict_monster_move()
	
	update_foresight_ui()
	
	if sorted_array[0]["character"] in players:
		show_options()

func pop_out():
	sorted_array[0]["character"].pop_out()
	sort_and_display()
	
func attack():
	sorted_array[0]["character"].attack(get_tree())

func next_attack():
	if sorted_array[0]["character"] in players:
		return
		
	attack()
	pop_out()
	
	var target_char = next_monster_move.get("target", players.pick_random())
	
	target_char.get_attacked()
	target_char.take_damage(10)
	
	# Use the predicted target instead of a random one
	#if next_monster_move.has("target"):
	#	next_monster_move["target"].get_attacked()
	#else:
	#	players.pick_random().get_attacked()
	
func set_status(status_type):
	# Fixed the typo "charater" and "seet_status" from your original snippet
	sorted_array[0]["character"].set_status(status_type)
	sort_and_display()
	
func show_options():
	if battle_over:
		return
	options.show()
	options.get_child(0).grab_focus()
	
func choose_enemy():
	%EnemySelection.show()
	%EnemySelection.get_child(0).grab_focus()
	
func _on_part_depleted(part_name):
	if part_name == "Leg":
		monster_is_crouching = true
		# This makes your Climb button clickable
		if climb_button:
			climb_button.disabled = false
			climb_button.show()
		#disable leg button
		if %EnemySelection.has_node("Leg"):
			var leg_button = %EnemySelection.get_node("Leg")
			leg_button.disabled = true
			leg_button.hide()

			
		if notify_label:
			notify_label.text = "The leg was distroyed! Climb and attack the Head!"
			notify_label.show()
			#hide message after a time
			await get_tree().create_timer(3.0).timeout
			notify_label.hide()
	elif part_name == "Head":
		battle_over = true
		set_process(false)
		options.hide()
		timeline.hide()
		%EnemySelection.hide()
		climb_button.hide()
		
		if notify_label:
			notify_label.text = "The Giant has been slain!!!"
			notify_label.show()
		
func _on_climb_pressed():
	var current_player = sorted_array[0]["character"]
	var monster_head = get_node("Enemies/Head") # Adjust path to your Head node
	var target_pos = monster_head.get_node("ClimbPoint").global_position
	
	# Disable options and move player
	options.hide()
	climb_button.disabled = true
	
	var tween = create_tween()
	# Move the player sprite to the monster's head
	tween.tween_property(current_player.node, "global_position", target_pos, 0.6).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	if %EnemySelection.has_node("Head"):
		%EnemySelection.get_node("Head").show()
		
	options.show()
	
	if notify_label:
		notify_label.text = "you've reached the Head! Finishe it!"
		notify_label.show()
		await get_tree().create_timer(2.0).timeout
		notify_label.hide()
#	execute_killing_blow(current_player, monster_head)

#func execute_killing_blow(player, head_node):
#	# Deal massive damage to the head
#	head_node.character.take_damage(999)
#	print("FINISHING MOVE!")
#	# After animation, return player or end battle
#	pop_out()
#	next_attack()

func _process(_delta: float) -> void:
	pass
