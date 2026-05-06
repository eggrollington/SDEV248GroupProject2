extends WispBase

const DASH_SPEED := 220.0
const CHARGE_TIME := 1.4
const DASH_TIME := 0.7
const REST_TIME := 0.6
const CONTACT_DAMAGE := 1
const CONTACT_COOLDOWN := 1.0

enum State { CHARGE, DASH, REST }

var state: int = State.CHARGE
var state_t: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var origin_pos: Vector2
var contact_timer: float = 0.0


func _ready() -> void:
	max_health = 2
	orb_color = Color("60ffff")
	orb_radius = 6.0
	super._ready()
	origin_pos = global_position


func _process(delta: float) -> void:
	if is_dead:
		return

	t += delta
	state_t += delta
	contact_timer = max(0.0, contact_timer - delta)

	if flash_timer > 0:
		flash_timer -= delta

	_detect_player()

	match state:

		State.CHARGE:
			global_position.y = origin_pos.y + sin(t * 6.0) * 2.0

			if state_t >= CHARGE_TIME:
				if player:
					dash_dir = (player.global_position - global_position).normalized()
				else:
					dash_dir = Vector2.ZERO

				state = State.DASH
				state_t = 0.0

		State.DASH:
			if dash_dir != Vector2.ZERO:
				global_position += dash_dir * DASH_SPEED * delta

			_try_contact_damage()

			if state_t >= DASH_TIME:
				state = State.REST
				state_t = 0.0

		State.REST:
			var return_dir := origin_pos - global_position
			if return_dir.length() > 2.0:
				global_position += return_dir.normalized() * DASH_SPEED * 0.3 * delta
			else:
				global_position = origin_pos

			if state_t >= REST_TIME:
				origin_pos = global_position
				state = State.CHARGE
				state_t = 0.0

	queue_redraw()


func _try_contact_damage() -> void:
	if contact_timer > 0:
		return

	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p):
			continue
		if global_position.distance_to(p.global_position) < 18.0:
			if p.has_method("take_damage"):
				p.take_damage(CONTACT_DAMAGE)
				contact_timer = CONTACT_COOLDOWN
				break


func _draw() -> void:
	super._draw()

	if state == State.CHARGE:
		var blink := int(t * 8.0) % 2 == 0
		if blink:
			draw_arc(Vector2.ZERO, orb_radius + 4.0, 0.0, TAU, 24, Color(1, 1, 1, 0.7), 1.5)

	elif state == State.DASH:
		var trail_dir := -dash_dir
		for i in range(1, 5):
			var p := trail_dir * float(i) * 4.0
			var c := orb_color
			c.a = 0.5 - float(i) * 0.1
			draw_circle(p, orb_radius - float(i) * 0.7, c)
