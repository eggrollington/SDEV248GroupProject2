class_name WispBase
extends Area2D

@export var max_health: int = 2
@export var orb_color: Color = Color.WHITE
@export var orb_radius: float = 6.0
@export var speed: float = 60.0
@export var detection_radius: float = 120.0

var health: int
var flash_timer: float = 0.0
var t: float = 0.0

var player: Node2D = null
var wander_dir: int = 1
var wander_timer: float = 0.0

var velocity: Vector2 = Vector2.ZERO
var is_dead: bool = false


func _ready() -> void:
        add_to_group("enemies")

        health = max_health

        # 🔥 CRITICAL: MUST detect BOTH types of collisions
        area_entered.connect(_on_area_entered)
        body_entered.connect(_on_body_entered)


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
# PLAYER DETECTION
# -------------------------
func _detect_player() -> void:
        player = null

        for p in get_tree().get_nodes_in_group("player"):
                if global_position.distance_to(p.global_position) <= detection_radius:
                        player = p
                        break


# -------------------------
# AI
# -------------------------
func _ai_move(delta: float) -> void:
        if player:
                velocity = (player.global_position - global_position).normalized() * speed
        else:
                wander_timer -= delta

                if wander_timer <= 0:
                        wander_dir = -1 if randi() % 2 == 0 else 1
                        wander_timer = randf_range(1.0, 3.0)

                velocity = Vector2(wander_dir * speed * 0.5, sin(t * 2.5) * 10.0)


# -------------------------
# DAMAGE INPUT (FIXED CORE)
# -------------------------
func _on_area_entered(area: Area2D) -> void:
        _handle_damage(area)


func _on_body_entered(body: Node) -> void:
        _handle_damage(body)


func _handle_damage(obj) -> void:
        if is_dead:
                return

        if obj.is_in_group("damage") or obj.is_in_group("player_attack") or obj.has_method("get_damage"):
                var dmg := 1

                if obj.has_method("get_damage"):
                        dmg = obj.get_damage()

                take_damage(dmg)


# -------------------------
# DAMAGE OUTPUT
# -------------------------
func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
        if is_dead:
                return

        health -= amount
        flash_timer = 0.08

        if health <= 0:
                die()


# -------------------------
# DEATH
# -------------------------
func die() -> void:
        if is_dead:
                return

        is_dead = true
        velocity = Vector2.ZERO

        set_process(false)
        set_physics_process(false)

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

        var hl := Color(1, 1, 1, 0.7)
        draw_circle(Vector2(-orb_radius * 0.3, -orb_radius * 0.3), orb_radius * 0.4, hl)

        var eye_c := Color(0, 0, 0) if flash_timer <= 0 else c
        draw_circle(Vector2(-orb_radius * 0.35, 0), max(1.0, float(orb_radius) * 0.18), eye_c)
        draw_circle(Vector2(orb_radius * 0.35, 0), max(1.0, float(orb_radius) * 0.18), eye_c)
