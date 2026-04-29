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

	# 🔥 CRITICAL: must match WispBase system
	swordhitbox.add_to_group("damage")
	swordhitbox.add_to_group("player_attack")

	swordhitbox.monitoring = true
	swordhitbox.monitorable = true


func _physics_process(delta: float):
	if is_dead:
		velocity = Vector2.ZERO
		return

	is_blocking = Input.is_action_pressed("block")

	if is_attacking:
		velocity = Vector2.ZERO
		attack_timer += delta

		if attack_timer >= attack_duration:
			is_attacking = false
			attack_timer = 0.0
	else:
		var direction = Input.get_vector("left", "right", "up", "down")
		velocity = direction * speed
		move_and_slide()
		update_animation(velocity)


func update_animation(direction: Vector2):
	if is_attacking:
		animated_sprite.play("attack_" + last_direction)
		return

	if is_blocking:
		animated_sprite.play("block_" + last_direction)
		return

	if direction.x != 0:
		animated_sprite.flip_h = direction.x < 0
		last_direction = "side"
	elif direction.y < 0:
		last_direction = "north"
	elif direction.y > 0:
		last_direction = "south"

	var state = "walk" if direction != Vector2.ZERO else "idle"
	animated_sprite.play(state + "_" + last_direction)


func _input(event):
	if is_dead:
		return

	if event.is_action_pressed("attack") and not is_attacking and not is_blocking:
		is_attacking = true
		attack_timer = 0.0

		sword_animation.play("attack_" + last_direction)
		swordhitbox.monitoring = true


# -----------------------------
# DAMAGE OUTPUT (FIXED + GUARANTEED)
# -----------------------------
func get_damage() -> int:
	return 1


func _on_swordhitbox_area_entered(area: Area2D):
	var enemy = area.get_parent()

	if enemy and enemy.is_in_group("enemies") and enemy.has_method("take_damage"):
		enemy.take_damage(1)


func _on_swordhitbox_body_entered(body: Node2D):
	if body == self:
		return

	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(1)


# -----------------------------
# PLAYER DAMAGE INPUT
# -----------------------------
func take_damage(damage: int):
	if is_dead or is_blocking:
		return

	health_animation.frame += damage
	flash_effect()

	if health_animation.frame >= 10:
		die()


func flash_effect():
	animation_player.play("player_flash")


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
