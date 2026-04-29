class_name WispBase
extends Area2D

@export var max_health: int = 2
@export var orb_color: Color = Color.WHITE
@export var orb_radius: float = 6.0

var health: int
var flash_timer: float = 0.0
var t: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	t += delta
	if flash_timer > 0:
		flash_timer -= delta
	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet"):
		take_damage(1)
		if area.has_method("hit"):
			area.hit()

func take_damage(amount: int) -> void:
	health -= amount
	flash_timer = 0.08
	if health <= 0:
		die()

func die() -> void:
	queue_free()

func _draw() -> void:
	var c: Color = orb_color
	if flash_timer > 0:
		c = Color.WHITE

	# Outer glow rings
	for i in range(3, 0, -1):
		var glow := c
		glow.a = 0.18
		draw_circle(Vector2.ZERO, orb_radius + i * 2.5, glow)

	# Core orb
	draw_circle(Vector2.ZERO, orb_radius, c)

	# Inner highlight
	var hl := Color(1, 1, 1, 0.7)
	draw_circle(Vector2(-orb_radius * 0.3, -orb_radius * 0.3), orb_radius * 0.4, hl)

	# Eyes
	var eye_c := Color.BLACK if flash_timer <= 0 else c
	draw_circle(Vector2(-orb_radius * 0.35, 0), max(1.0, orb_radius * 0.18), eye_c)
	draw_circle(Vector2(orb_radius * 0.35, 0), max(1.0, orb_radius * 0.18), eye_c)
