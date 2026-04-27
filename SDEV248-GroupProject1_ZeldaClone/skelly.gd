extends CharacterBody2D

@export var speed: float = 50.0
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 1.2
@onready var attack_area: Area2D = $AttackArea
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var hurtbox: Area2D = $Hurtbox  

var player = null
var last_direction = Vector2.DOWN
var attack_timer = 0.0
var is_attacking = false
var health = 2
var is_dead = false

func _ready():
	add_to_group("enemies")
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.monitoring = false
	else:
		push_error("AttackArea child is missing on Skelly!")
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	else:
		push_error("Hurtbox child is missing on Skelly!")
	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		return
	attack_timer = max(0.0, attack_timer - delta)
	
	if is_attacking:
		velocity = Vector2.ZERO
	else:
		if player:
			chase_and_attack_player()
		else:
			patrol() # simple non-random back-and-forth movement
	
	move_and_slide()
	update_animation()

var patrol_timer = 0.0
@export var patrol_time = 2.0 # Change direction every 2 seconds

func patrol():
	patrol_timer += get_physics_process_delta_time()
	
	if patrol_timer >= patrol_time:
		# Flip direction (e.g., switch between UP and DOWN)
		last_direction = -last_direction 
		patrol_timer = 0.0
		
	velocity = last_direction * speed

func chase_and_attack_player():
	if not player:
		return
		
	var direction = (player.global_position - global_position).normalized()
	var distance = global_position.distance_to(player.global_position)
	
	last_direction = direction
	
	if distance < attack_range and attack_timer <= 0:
		start_attack()
	else:
		velocity = direction * speed

func start_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	attack_timer = attack_cooldown
	attack_area.monitoring = true
	# Play correct attack animation based on facing direction
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			anim.play("Right_Attack")
		else:
			anim.play("Left_Side_Attack")
	else:
		if last_direction.y < 0:
			anim.play("Back_Attack")
		else:
			anim.play("Front_Attack")

func update_animation():
	if is_attacking:
		return  # attack animation is already playing
	
	if velocity.length() > 5:
		# Walking animation based on direction
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x > 0:
				anim.play("Right_Side_Walk")
			else:
				anim.play("Left_Side_Walk")
		else:
			if last_direction.y < 0:
				anim.play("Back_Walk")
			else:
				anim.play("Front_Walk")
	else:
		anim.play("Idle")

func _on_animation_finished(anim_name: String) -> void:
	if "Attack" in anim_name:
		is_attacking = false
		attack_area.monitoring = false

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body):
	if body == player:
		player = null

# Call this from player script when sword hits skeleton
func take_damage(damage: int, knockback: Vector2 = Vector2.ZERO):
	if is_dead:
		return
	health -= damage
	print(">>> SKELLY TOOK ", damage, " DAMAGE! Remaining health: ", health)
	velocity = knockback * 120  # knockback effect
	
	anim.play("Hurt")
	
	if health <= 0:
		die()
	else:
		await anim.animation_finished
		# Return to normal after hurt

func die():
	is_dead = true
	is_attacking = true
	velocity = Vector2.ZERO
	print(">>> SKELLY DIED - playing death animation")
	anim.play("Death")
	await anim.animation_finished
	print(">>> SKELLY death animation finished - removing")
	queue_free()

  


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_dead:
		body.take_damage(1)
		print(">>> Skelly hit PLAYER for 1 damage!")


func _on_attack_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_dead:
		print(">>> Hurtbox hit by player body (ignore for now)")
