extends CharacterBody2D

@export var speed: float = 100.0
@export var attack_duration: float = 0.25

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword_animation: AnimationPlayer = $swordhitbox/AnimationPlayer
@onready var health_animation: AnimatedSprite2D = $Camera2D/VBoxContainer/AnimatedSprite2D
@onready var swordhitbox: Area2D = $swordhitbox

var last_direction: String = "south"
var is_attacking: bool = false
var attack_timer: float = 0.0
var is_blocking: bool = false
var is_dead: bool = false

func _ready():
	add_to_group("player")
	if swordhitbox:
		swordhitbox.monitoring = true

func _physics_process(delta: float):
	if is_dead:
		velocity = Vector2.ZERO
		return
	
	# Blocking
	is_blocking = Input.is_action_pressed("block")
	
	# Attacking
	if is_attacking:
		velocity = Vector2.ZERO
		attack_timer += delta
		if attack_timer >= attack_duration:
			is_attacking = false
			attack_timer = 0.0
	else:
		# Movement
		var direction = Input.get_vector("left", "right", "up", "down")
		velocity = direction * speed
		if direction != Vector2.ZERO:
			pass
		move_and_slide()
	if velocity.length() > 0:
		pass
	update_animation(velocity)

func update_animation(direction: Vector2):
	if is_attacking:
		animated_sprite.play("attack_" + last_direction)
		return
	
	if is_blocking:
		animated_sprite.play("block_" + last_direction)
		return
	
	# Update facing direction
	if direction.x != 0:
		animated_sprite.flip_h = direction.x < 0
		last_direction = "side"
	elif direction.y < 0:
		animated_sprite.flip_h = false
		last_direction = "north"
	elif direction.y > 0:
		animated_sprite.flip_h = false
		last_direction = "south"
	
	# Walk or Idle
	var state = "walk" if direction != Vector2.ZERO else "idle"
	animated_sprite.play(state + "_" + last_direction)

func _input(event):
	if is_dead:
		return
	
	# Attack input
	if event.is_action_pressed("attack") and not is_attacking and not is_blocking:
		is_attacking = true
		attack_timer = 0.0
		var animation_name = "attack_" + last_direction
		if last_direction == "side" and animated_sprite.flip_h:
			animation_name = "attack_weest"
		sword_animation.play(animation_name)
		if swordhitbox:
			swordhitbox.monitoring = true

# Damage
func _on_swordhitbox_body_entered(body: Node2D):
	print(">>> Sword hitbox entered: ", body.name, " | Groups: ", body.get_groups())
	if body == self:
		return
	if body.is_in_group("enemies"):
		print(">>> Enemy hit! Sending 1 damage")
		if body.has_method("take_damage"):
			body.take_damage(1)


func take_damage(damage: int):
	if is_dead or is_blocking:
		return
	health_animation.frame += damage
	print(">>> PLAYER TOOK ", damage, " DAMAGE! Health frame now: ", health_animation.frame)
	flash_effect()
	if health_animation.frame >= 10:
		die()

func flash_effect():
	animation_player.play("player_flash")

func _on_hitbox_area_entered(area: Area2D):
	if area.is_in_group("enemy_attack"):
		take_damage(1)



func die():
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process_input(false)
	$CollisionShape2D.set_deferred("disabled", true)
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	queue_free()


func _on_animated_sprite_animation_finished():
	if is_attacking:
		is_attacking = false
		attack_timer = 0.0
		if swordhitbox:
			swordhitbox.monitoring = false
