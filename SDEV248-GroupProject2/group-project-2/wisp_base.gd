class_name WispBase
extends Area2D

@export var max_health: int = 2
@export var orb_color: Color = Color.WHITE
@export var orb_radius: float = 6.0

@export var speed: float = 60.0
@export var detection_radius: float = 120.0
@export var damage: int = 1

var health: int
var flash_timer: float = 0.0
var t: float = 0.0

var player: Node2D = null

var wander_dir: int = 1
var wander_timer: float = 0.0

var velocity: Vector2 = Vector2.ZERO

var can_damage: bool = true
var is_dead: bool = false


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if is_dead:
		return

	t += delta

	_detect_player()
	_ai_move(delta)

	global_position += velocity * delta

	if flash_timer > 0:
		flash_timer -= delta

	queue_redraw()


# -------------------------
# AI CORE
# -------------------------
func _detect_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	player = null

	for p in players:
		if p and global_position.distance_to(p.global_position) <= detection_radius:
			player = p
			break


func _ai_move(delta: float) -> void:
	if player:
		# CHASE PLAYER
		var dir := (player.global_position - global_position).normalized()
		velocity = dir * speed
	else:
		# WANDER STATE (no more LEFT lock bug)
		wander_timer -= delta

		if wander_timer <= 0:
			wander_dir = -1 if randi() % 2 == 0 else 1
			wander_timer = randf_range(1.0, 3.0)

		var float_y := sin(t * 2.5) * 10.0
		velocity = Vector2(wander_dir * speed * 0.5, float_y)


# -------------------------
# DAMAGE HANDLING
# -------------------------
func _on_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	# bullet damage
	if area.is_in_group("bullet"):
		take_damage(1)
		if area.has_method("hit"):
			area.hit()

	# player melee / sword hitbox
	elif area.is_in_group("player_attack"):
		take_damage(1)


func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount
	flash_timer = 0.08

	if health <= 0:
		die()


# -------------------------
# DEATH SYSTEM
# -------------------------
func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	set_process(false)
	set_physics_process(false)

	# optional animation hook
	if has_method("play_death"):
		play_death()
	else:
		queue_free()


func play_death() -> void:
	queue_free()


# -------------------------
# DRAW VISUALS (UNCHANGED STYLE)
# -------------------------
func _draw() -> void:
	var c: Color = orb_color
	if flash_timer > 0:
		c = Color.WHITE

	# glow
	for i in range(3, 0, -1):
		var glow := c
		glow.a = 0.18
		draw_circle(Vector2.ZERO, orb_radius + i * 2.5, glow)

	# core
	draw_circle(Vector2.ZERO, orb_radius, c)

	# highlight
	var hl := Color(1, 1, 1, 0.7)
	draw_circle(Vector2(-orb_radius * 0.3, -orb_radius * 0.3), orb_radius * 0.4, hl)

	# eyes
	var eye_c := Color(0, 0, 0) if flash_timer <= 0 else c
	draw_circle(Vector2(-orb_radius * 0.35, 0), max(1.0, float(orb_radius) * 0.18), eye_c)
	draw_circle(Vector2(orb_radius * 0.35, 0), max(1.0, float(orb_radius) * 0.18), eye_c)
