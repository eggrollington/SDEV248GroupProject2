extends CharacterBody2D

@export var speed = 100 
@onready var animated_sprite = $AnimatedSprite2D # Use @onready instead of _ready
@onready var animation_player = $AnimationPlayer
@onready var sword_animation = $swordhitbox/AnimationPlayer


var last_direction = "south"
var enemy_in_range = false #flag to track if enemy is in range
var is_attacking = false
var attack_timer = 0.0
var attack_duration = 0.25
var is_dead = false
var health = 0

func _ready():
	#adds player to group so other assets can recongnize player
	add_to_group("player")
	
	# Find the player in the scene to get their current health status
	var player_node = get_tree().get_first_node_in_group("player")
	
	if player_node and player_node.has_node("Camera2D/VBoxContainer/AnimatedSprite2D"):
		var player_health_sprite = player_node.get_node("Camera2D/VBoxContainer/AnimatedSprite2D")
		
		# Set the starting frame of the shadow's internal tracking 
		# (if you are still using internal health) or just sync the UI.
		print("Shadow linked. Starting health frame: ", player_health_sprite.frame)

func _physics_process(_delta):
	if is_dead:
		velocity = Vector2.ZERO
		return
	if is_attacking:
		velocity = Vector2.ZERO # Hard stop
		attack_timer += _delta
		if attack_timer >= attack_duration:
			is_attacking = false
			attack_timer = 0.0
	else:
		var shadow_direction = Input.get_vector("left", "right", "up", "down")
		if shadow_direction == null:
			shadow_direction = Vector2.ZERO
			
		velocity = -shadow_direction * speed
	
	update_animation(velocity) # Using velocity instead of direction is often more reliable
	move_and_slide()

func update_animation(direction):
	
	if is_attacking:
		#stops momentum
		velocity = Vector2.ZERO 
		if last_direction == "north":
			#offset sprite to look correct
			var offset_y = -10.0
			animated_sprite.offset.y  = offset_y
			
		elif last_direction == "south":
			animated_sprite.offset.y = 10.0
			
		elif last_direction == "side":
			# If flipped (facing left), move left. If not, move right.
			var offset_x = -10 if animated_sprite.flip_h else 10
			animated_sprite.offset.x = offset_x
			
		animated_sprite.play("attack_" + last_direction)
		return
		
	else:
		animated_sprite.offset = Vector2.ZERO
	# Update last_direction string based on movement
	if direction.x != 0:
		#flip sprite
		animated_sprite.flip_h = direction.x < 0
		last_direction = "side"
	elif direction.y < 0:
		animated_sprite.flip_h = false
		last_direction = "north"
	elif direction.y > 0:
		animated_sprite.flip_h = false
		last_direction = "south"

	# Determine state (idle vs walk)
	var state = "walk" if direction != Vector2.ZERO else "idle"
	
	# Combine state and direction to play the animation (e.g., "walk_side")
	animated_sprite.play(state + "_" + last_direction)
	
func _input(event):
	if is_dead: 
		return
	if event.is_action_pressed("attack") and not is_attacking:
		is_attacking = true
		attack_timer = 0.0
		#Play the physics animation that matches your direction
		var animation_name = "attack_" + last_direction
		if last_direction == "side" and animated_sprite.flip_h:
			animation_name = "attack_weest"
		sword_animation.play(animation_name)




		


func _on_hitbox_body_exited(body: Node2D) -> void:
	pass # Replace with function body.


func _on_swordhitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		print("hit enemy!")
		



func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack"):
		flash_effect()
		var damage = 1
		take_damage(damage)
func flash_effect():
	var animation_name = "shadow_flash"
	animation_player.play(animation_name)
	
func take_damage(damage):
	get_tree().call_group("player", "apply_shared_damage", damage)
	#var max_health = 10
	
	#health += damage
	#if health >= max_health:
	#	shadow_die()

func die():
	if is_dead:
		return
	print("DIE FUNCTION CALLED SHADOW")
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process_input(false)
	$CollisionShape2D.set_deferred("disabled", true)
	 
	animated_sprite.offset = Vector2.ZERO
	velocity = Vector2.ZERO
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	queue_free()
