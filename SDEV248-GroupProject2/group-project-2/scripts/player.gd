extends CharacterBody2D

@export var speed: float = 100
@export var jump_velocity = -350.0

@export var gravity = 400

@onready var animated_sprite = $AnimatedSprite2D # Use @onready instead of _ready
@onready var animation_player = $AnimationPlayer
@onready var sword_animation = $swordhitbox/AnimationPlayer
@onready var health_animation = $Camera2D/VBoxContainer/AnimatedSprite2D
@onready var shield_hitbox = $shieldhitbox
@onready var shield_animation = $shieldhitbox/AnimationPlayer
@onready var sfx_attack = $SfxAttack
@onready var sfx_block = $SfxBlock
@onready var sfx_death = $SfxDeath

var last_direction = "side"
var enemy_in_range = false #flag to track if enemy is in range
var is_attacking = false
var attack_timer = 0.0
var attack_duration = 0.25
var is_dead = false
var is_blocking = false


func _ready():
	#adds player to group so other assets can recongnize player
	add_to_group("player")

func _physics_process(delta):
	if is_dead:
		
		return
		
	#check if blocking
	if Input.is_action_pressed("block") and not is_attacking and is_on_floor():
		is_blocking = true
		# play the physoca; hitbox animation
		#using .play ensures the hitbox stays moved/enambed
		var animation_name = "block_" + last_direction
		if last_direction == "side" and animated_sprite.flip_h:
			animation_name = "block_weest"
			
		shield_animation.play(animation_name)
		#
	else:
		if is_blocking: #If we just released the button
			is_blocking = false
			shield_animation.stop() #stops blocking animation
			#Manually disable the hitbox just to be safe
			$shieldhitbox/CollisionShape2D.set_deferred("disabled", true)
		
	#attack timer
	if is_attacking:
		attack_timer += delta
		if attack_timer >= attack_duration:
			is_attacking = false
			attack_timer = 0.0
			
	var direction = Input.get_axis("left", "right")
	if is_attacking or is_blocking:
		velocity.x = move_toward(velocity.x, 0, speed)
	else:
		if direction:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
	
	update_animation(velocity) # Using velocity instead of direction is often more reliable
	
	if velocity != Vector2.ZERO:
		print("Moving! Velocity is: ", velocity)
		
		#gravity
	print("On floor: ", is_on_floor(), " Velocity: ", velocity)
	print(delta)
	if not is_on_floor(): 
		velocity.y += gravity * delta
		
		#jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking and not is_blocking:
		velocity.y = jump_velocity 
		
	move_and_slide()

func update_animation(direction):
	if is_attacking:
		#velocity = Vector2.ZERO 
		animated_sprite.offset = Vector2.ZERO
		if last_direction == "north":
			animated_sprite.offset.y = -10.0
		elif last_direction == "south":
			animated_sprite.offset.y = 10.0
		elif last_direction == "side":
			var offset_x = -10 if animated_sprite.flip_h else 10
			animated_sprite.offset.x = offset_x
			
		animated_sprite.play("attack_" + last_direction)
		return

	if is_blocking:
		var block_anim = "block_" + last_direction
		if animated_sprite.animation != block_anim:
			animated_sprite.play(block_anim)
		return
		
	# Reset offset when walking/idling
	animated_sprite.offset = Vector2.ZERO

	if direction.x != 0:
		animated_sprite.flip_h = direction.x < 0
		last_direction = "side"
	elif direction.y < 0:
		animated_sprite.flip_h = false
		last_direction = "north"
	elif direction.y > 0:
		animated_sprite.flip_h = false
		last_direction = "south"

	var state = "walk" if direction != Vector2.ZERO else "idle"
	var current_anim = state + "_" + last_direction
	
	if animated_sprite.animation != current_anim:
		animated_sprite.play(current_anim)
	
func _input(event):
	if is_dead: 
		return
	if event.is_action_pressed("attack") and not is_attacking and not is_blocking:
		# Check for directional modifiers
		if Input.is_action_pressed("up"):
			last_direction = "north"
		elif Input.is_action_pressed("down") and not is_on_floor():
			last_direction = "south"
		elif Input.is_action_pressed("down") and is_on_floor() and last_direction == "south":
			return
		elif is_on_floor and last_direction == "south":
			return
		# If neither is held, it keeps the 'side' direction from movement
		is_attacking = true
		attack_timer = 0.0
		#play sound
		sfx_attack.play()
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
			
			# Calculate knockback direction: from player to enemy
			var knockback_dir = (body.global_position - global_position).normalized()
			
			# Call the function on Skelly
			body.take_damage(1, knockback_dir)
			
			print("Player hit Skelly!")
		print("hit enemy!")
		



func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_attack"):
		if is_blocking and shield_hitbox.overlaps_area(area):
			print("attack caught by shield!")
			#play block sound or spark effect
			
			sfx_block.play()
			return #exit the function so take() is never called
		flash_effect()
		var damage = 1
		take_damage(damage)
func flash_effect():
	var animation_name = "player_flash"
	animation_player.play(animation_name)
	
func take_damage(damage):
	if is_dead: return
	
	if is_blocking:
		print("Blocked!")
		damage = 0
		#add a block sound or spark effect here
		return
	var max_frame = 10
	health_animation.frame += damage
	if health_animation.frame >= max_frame:
		get_tree().call_group("player", "die")
		die()

func die():
	if is_dead:
		return
	print("DIE FUNCTION CALLED")
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process_input(false)
	$CollisionShape2D.set_deferred("disabled", true)
	sfx_death.play()
	 
	animated_sprite.offset = Vector2.ZERO
	velocity = Vector2.ZERO
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	get_tree().change_scene_to_file("res://start_menu.tscn")
	



func _on_shieldhitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_attack"):
		#1. check if the shield hitbox is overlapping the attack
		if is_blocking and shield_hitbox.overlaps_area(area):
			print("Attack caught by shield!")
			return #
