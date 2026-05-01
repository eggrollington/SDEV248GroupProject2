extends CharacterBody2D

@export var speed = 60.0
@export var jump_force = -300.0
@export var gravity = 800.0
@export var health = 10

@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer 
@onready var attack_player = $AttackHitbox/AnimationPlayer
@onready var player = get_tree().get_first_node_in_group("player")

enum States { IDLE, CHASE, ATTACK, DEAD }
var current_state = States.IDLE
var attack_cooldown = 0.0
var is_invulnerable = false

func _ready() -> void:
	add_to_group("enemies")

func _physics_process(delta):
	if current_state == States.DEAD:
		return

	# Always apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		# VISUALS
		if current_state != States.ATTACK:
			play_anim("jumping" if velocity.y < 0 else "falling")
	else:
		# LANDING: Only reset horizontal velocity if we are actually ON THE FLOOR
		# This prevents the "straight up" jump issue.
		if current_state == States.IDLE:
			velocity.x = move_toward(velocity.x, 0, speed)

	match current_state:
		States.IDLE:
			# We moved the move_toward logic above to the "is_on_floor" check
			play_anim("idle")
			if attack_cooldown <= 0:
				current_state = States.CHASE
				
		States.CHASE:
			if is_on_floor(): # Don't overwrite velocity while mid-jump leap
				move_logic()
				play_anim("running")
			check_attack_range()
			
		States.ATTACK:
			velocity.x = move_toward(velocity.x, 0, speed)

	attack_cooldown -= delta
	move_and_slide()
func move_logic():
	if not player: return
	
	var dist_x = abs(global_position.x - player.global_position.x)
	var dir = sign(player.global_position.x - global_position.x)
	
	# --- JUMP REPOSITIONING ---
	# 1. If player is very close, high chance to leap AWAY
	if dist_x < 60 and is_on_floor():
		if randf() < 0.05: # 5% chance per frame (approx 3 times per second)
			velocity.y = jump_force
			velocity.x = -dir * (speed * 3) # Leap backward
			return # Skip normal movement this frame
			
	# 2. If player is far away, chance to leap TOWARD them
	if dist_x > 200 and is_on_floor():
		if randf() < 0.02: 
			velocity.y = jump_force * 1.2 # Big jump
			velocity.x = dir * (speed * 4) # Lunge forward
			return

	# --- NORMAL MOVEMENT ---
	if is_on_floor():
		velocity.x = dir * speed
	
	# Handle flipping (only on floor or moving fast)
	if dir != 0 and current_state != States.ATTACK:
		animated_sprite.flip_h = dir < 0
		$AttackHitbox.scale.x = dir

func check_attack_range():
	if not player: return
	var dist_x = abs(global_position.x - player.global_position.x)
	var dist_y = player.global_position.y - global_position.y
	
	# Attack if close
	if dist_x < 70 and is_on_floor():
		if dist_y < -30:
			perform_attack("upward_slash")
		else:
			perform_attack("downward_slash")
	
	# Randomly jump if player is close to avoid being cornered
	if dist_x < 50 and is_on_floor() and randf() < 0.01:
		velocity.y = jump_force
		velocity.x = -sign(player.global_position.x - global_position.x) * (speed * 2)

func perform_attack(type):
	current_state = States.ATTACK
	velocity.x = 0
	
	animated_sprite.play(type)
	if attack_player.has_animation(type):
		attack_player.play(type)
	
	# IMPORTANT: Ensure these animations in AnimatedSprite2D are NOT looping
	await animated_sprite.animation_finished
	
	current_state = States.IDLE
	attack_cooldown = 0.1
	 

func take_damage(amount, _dir = Vector2.ZERO):
	if is_invulnerable or current_state == States.DEAD:
		return
		
	health -= amount
	is_invulnerable = true
	
	animation_player.play("TakeHit") 
	animated_sprite.play("takehit")
	
	if health <= 0:
		die()
	else:
		await animated_sprite.animation_finished
		is_invulnerable = false
		
		if is_on_floor():
			# 1. Find direction to player
			var dir_to_player = sign(player.global_position.x - global_position.x)
			
			# 2. Set State to IDLE so move_logic() doesn't run and overwrite velocity
			current_state = States.IDLE
			
			# 3. LEAP: Vertical + horizontal (opposite of player direction)
			velocity.y = jump_force * 1.5 
			velocity.x = -dir_to_player * 200 # Strong blast away
			
			print("Leaping away with velocity: ", velocity.x)

func die():
	current_state = States.DEAD
	velocity = Vector2.ZERO
	animated_sprite.play("death")
	$CollisionShape2D.set_deferred("disabled", true)
	# Wait for death anim then do something
	await animated_sprite.animation_finished
	# get_tree().change_scene_to_file("res://win_screen.tscn")

func play_anim(anim_name):
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"): # Make sure your player's hitbox area is in this group
		if area.get_parent().has_method("take_damage"):
			area.get_parent().take_damage(1)
			print("Mage hit the player!")
