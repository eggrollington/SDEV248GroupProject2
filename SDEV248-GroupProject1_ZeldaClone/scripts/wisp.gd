extends CharacterBody2D



@export var speed: float = 50.0
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 1.2

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea  # Add this Area2D child for player detection

var player = null
var last_direction = Vector2.DOWN
var attack_timer = 0.0
var is_attacking = false
var health = 3

func _ready():
	# Connect signals from DetectionArea
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta):
	attack_timer = max(0.0, attack_timer - delta)
	
	if is_attacking:
		velocity = Vector2.ZERO
	else:
		if player:
			chase_and_attack_player()
		else:
			patrol()   # simple non-random back-and-forth movement
	
	move_and_slide()
	update_animation()

func patrol():
	# Simple non-random movement: move in last_direction, reverse when hitting wall or timer
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
	
	# Play correct attack animation based on facing direction
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			anim.play("Right_Side_Attack")
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

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body):
	if body == player:
		player = null

# Call this from player script when sword hits skeleton
func take_damage(damage: int, knockback: Vector2 = Vector2.ZERO):
	if is_attacking or health <= 0:
		return
	
	health -= damage
	velocity = knockback * 120  # knockback effect
	
	anim.play("Hurt")
	
	if health <= 0:
		die()
	else:
		await anim.animation_finished
		# Return to normal after hurt

func die():
	is_attacking = true
	velocity = Vector2.ZERO
	anim.play("Death")
