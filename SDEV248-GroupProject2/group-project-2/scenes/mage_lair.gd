extends Node2D

@export var wait_time: float = 10.0 # 10 sec
var idle_timer: float = 0.0
var player: CharacterBody2D

@onready var you_win_label = $YouWinLabel 

func _ready() -> void:
	# 1. Play your initial text animation
	$AnimationPlayer.play("text")
	$AudioStreamPlayer.play()
	
	# 2. Find the player using the group you created earlier
	player = get_tree().get_first_node_in_group("player")
	
	# 3. Make sure the win label is hidden at the start
	you_win_label.modulate.a = 0.0
	you_win_label.hide()

func _process(delta: float) -> void:
	# Make sure the player exists before checking velocity
	if player:
		if player.velocity.length() < 1.0:
			# Player is standing still, start counting
			idle_timer += delta
			print("timer counting")
		else:
			# Player moved, reset the count to zero
			idle_timer = 0.0
			print("timer reset")
			
		# If they've been still for long enough, trigger the event
		if idle_timer >= wait_time:
			trigger_shadow_death()

func trigger_shadow_death():
	set_process(false) 
	
	var tween = create_tween()
	you_win_label.show()
	tween.tween_property(you_win_label, "modulate:a", 1.0, 2.0)
	
	await get_tree().create_timer(3.0).timeout
	
	# INSTEAD OF queue_free() (which kills the whole scene)
	# Target only the shadow node:
	if has_node("shadow"): # Replace "Shadow" with the actual name of your shadow node
		$shadow.queue_free()
	
	# If you want the text to stay, don't queue_free the label.
	# If you want the text to leave too:
	# you_win_label.queue_free()
