class_name WispBase
extends Area2D

@export var max_health: int = 2
@export var orb_color: Color = Color.WHITE
@export var orb_radius: float = 6.0

@export var damage: int = 1
@export var detection_radius: float = 160.0
@export var speed: float = 60.0

var health: int
var flash_timer: float = 0.0
var t: float = 0.0

var player: Node2D = null
var is_dead: bool = false

# Track overlaps only
var overlapping_bodies: Array = []


func _ready() -> void:
    add_to_group("enemies")
    health = max_health

    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)


func _process(delta: float) -> void:
    if is_dead:
        return

    t += delta

    if flash_timer > 0:
        flash_timer -= delta

    _detect_player()
    queue_redraw()


# -------------------------
# PLAYER DETECTION
# -------------------------
func _detect_player() -> void:
    player = null
    var closest_dist := detection_radius

    for p in get_tree().get_nodes_in_group("player"):
        if not p:
            continue

        var dist := global_position.distance_to(p.global_position)
        if dist < closest_dist:
            closest_dist = dist
            player = p


# -------------------------
# CONTACT SYSTEM (SIMPLIFIED)
# -------------------------
func _on_body_entered(body: Node) -> void:
    _handle_contact(body)


func _on_area_entered(area: Area2D) -> void:
    var target := area.get_parent()
    _handle_contact(target)


func _handle_contact(target: Node) -> void:
    if not target:
        return

    if target.is_in_group("player"):
        if target.has_method("take_damage"):
            target.take_damage(damage)

        if target not in overlapping_bodies:
            overlapping_bodies.append(target)


func _on_body_exited(body: Node) -> void:
    overlapping_bodies.erase(body)


func _on_area_exited(area: Area2D) -> void:
    var target := area.get_parent()
    overlapping_bodies.erase(target)


# -------------------------
# PLAYER DAMAGE TO WISP
# -------------------------
func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
    if is_dead:
        return

    health -= amount
    flash_timer = 0.12

    if health <= 0:
        die()


func die() -> void:
    if is_dead:
        return

    is_dead = true
    queue_free()


# -------------------------
# DRAW
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

    var eye_c: Color = Color.BLACK if flash_timer <= 0 else c
    draw_circle(Vector2(-orb_radius * 0.35, 0), 1.5, eye_c)
    draw_circle(Vector2(orb_radius * 0.35, 0), 1.5, eye_c)
