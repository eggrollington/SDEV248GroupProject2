class_name WispBase
extends Area2D

@export var max_health: int = 2
@export var orb_color: Color = Color.WHITE
@export var orb_radius: float = 6.0

@export var speed: float = 50.0
@export var detection_radius: float = 120.0
@export var damage: int = 1

var health: int
var flash_timer: float = 0.0
var t: float = 0.0

var player: Node2D = null

var wander_dir: int = 1
var wander_timer: float = 0.0

var can_damage: bool = true

# IMPORTANT: Area2D still uses position, so we simulate movement via position
var velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("enemies")
	health = max_health

	area_entered.connect(_on_area_entered)

	# detect player via physics overlap scan (no extra nodes needed)
	set_process(true)


func _process(delta: float) -> void:
	t += delta

	_detect_player()
	_ai_move(delta)

	position += velocity * delta

	if flash_timer > 0:
		flash_timer -= delta

	queue_redraw()


# -------------------------
# AI SYSTEM
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
		# CHASE
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed

		_try_damage_player()
	else:
		# WANDER
		wander_timer -= delta

		if wander_timer <= 0:
			wander_dir = randi() % 2 == 0 ? -1 : 1
			wander_timer = randf_range(1.0, 3.0)

		var float_y = sin(t * 2.5) * 10.0
		velocity = Vector2(wander_dir * speed * 0.5, float_y)


# -------------------------
# DAMAGE PLAYER
# -------------------------
func _try_damage_player() -> void:
	if player == null:
		return

	if not can_damage:
		return

	if global_position.distance_to(player.global_position) < orb_radius + 6.0:
		if player.has_method("take_damage"):
			can_damage = false
			player.take_damage(damage)

			await get_tree().create_timer(0.8).timeout
			can_damage = true


# -------------------------
# BULLET DAMAGE (your original system)
# -------------------------
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet"):
		take_damage(1)
		if area.has_method("hit"):
			area.hit()


# -------------------------
# HEALTH SYSTEM (unchanged)
# -------------------------
func take_damage(amount: int) -> void:
	health -= amount
	flash_timer = 0.08

	if health <= 0:
		die()


func die() -> void:
	queue_free()


# -------------------------
# DRAW (UNCHANGED VISUAL STYLE)
# -------------------------
func _draw() -> void:
	var c: Color = orb_color
	if flash_timer > 0:
		c = Color.WHITE

	for i in range(3, 0, -1):
		var glow := c
		glow.a = 0.18
		draw_circle(Vector2.ZERO, orb_radius + i * 2.5, glow)

	draw_circle(Vector2.ZERO, orb_radius, c)

	var hl := Color(1, 1, 1, 0.7)
	draw_circle(Vector2(-orb_radius * 0.3, -orb_radius * 0.3), orb_radius * 0.4, hl)

	var eye_c := Color.BLACK if flash_timer <= 0 else c
	draw_circle(Vector2(-orb_radius * 0.35, 0), max(1.0, orb_radius * 0.18), eye_c)
	draw_circle(Vector2(orb_radius * 0.35, 0), max(1.0, orb_radius * 0.18), eye_c)
