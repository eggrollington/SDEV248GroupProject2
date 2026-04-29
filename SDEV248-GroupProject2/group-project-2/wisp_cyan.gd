daextends WispBase

const DASH_SPEED := 220.0
const CHARGE_TIME := 1.4
const DASH_TIME := 0.7
const REST_TIME := 0.6

enum State { CHARGE, DASH, REST }

var state: int = State.CHARGE
var state_t: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO

var origin_pos: Vector2

func _ready() -> void:
	max_health = 2
	orb_color = Color("60ffff")
	orb_radius = 6.0

	super._ready()
	origin_pos = global_position


func _process(delta: float) -> void:
	super._process(delta)

	state_t += delta

	match state:

		State.CHARGE:
			# floaty hover
			global_position.y = origin_pos.y + sin(t * 6.0) * 2.0

			if state_t >= CHARGE_TIME:
				if player:
					dash_dir = (player.global_position - global_position).normalized()
				else:
					dash_dir = Vector2.LEFT

				state = State.DASH
				state_t = 0.0


		State.DASH:
			velocity = dash_dir * DASH_SPEED
			global_position += velocity * delta

			if state_t >= DASH_TIME:
				state = State.REST
				state_t = 0.0


		State.REST:
			velocity = Vector2.ZERO

			if state_t >= REST_TIME:
				origin_pos = global_position
				state = State.CHARGE
				state_t = 0.0


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
