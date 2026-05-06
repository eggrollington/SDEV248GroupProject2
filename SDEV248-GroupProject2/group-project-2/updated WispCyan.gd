extends WispBase

const DASH_SPEED := 220.0
const CHARGE_TIME := 1.4
const DASH_TIME := 0.7
const REST_TIME := 0.6

enum State { CHARGE, DASH, REST }

var state: int = State.CHARGE
var state_t: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO

var origin_pos: Vector2

# prevents multi-hit per dash (replaces cooldown system)
var has_damaged_this_dash: bool = false


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
<<<<<<< Updated upstream
	state_t += delta

	match state:

		State.CHARGE:
			# hover idle motion
			global_position.y = origin_pos.y + sin(t * 6.0) * 2.0

			if state_t >= CHARGE_TIME:

				if player:
					dash_dir = (player.global_position - global_position).normalized()
				else:
					dash_dir = Vector2.ZERO

				state = State.DASH
				state_t = 0.0

				# reset hit tracking each dash
				has_damaged_this_dash = false
=======

	if damage_timer > 0:
		damage_timer -= delta

	state_t += delta

	match state:

		State.CHARGE:
			# stable hover (no horizontal drift)
			global_position.y = origin_pos.y + sin(t * 6.0) * 2.0

			if state_t >= CHARGE_TIME:

				# 🔥 NEVER ALLOW LEFT FALLBACK ANYMORE
				if player:
					dash_dir = (player.global_position - global_position).normalized()
				else:
					# safe fallback: stay in place instead of escaping map
					dash_dir = Vector2.ZERO

				state = State.DASH
				state_t = 0.0
>>>>>>> Stashed changes


		State.DASH:
			global_position += dash_dir * DASH_SPEED * delta

<<<<<<< Updated upstream
			_try_damage_player()
=======
			_try_damage_player_local()
>>>>>>> Stashed changes

			if state_t >= DASH_TIME:
				state = State.REST
				state_t = 0.0


		State.REST:
<<<<<<< Updated upstream
			var return_dir := origin_pos - global_position

			if return_dir.length() > 2.0:
				global_position += return_dir.normalized() * DASH_SPEED * 0.3 * delta
			else:
				global_position = origin_pos

=======
			# 🔥 HARD RESET POSITION STABILITY (NO DRIFT)
			var return_dir := (origin_pos - global_position)

			if return_dir.length() > 2.0:
				global_position += return_dir.normalized() * DASH_SPEED * 0.3 * delta

			else:
				global_position = origin_pos

>>>>>>> Stashed changes
			if state_t >= REST_TIME:
				state = State.CHARGE
				state_t = 0.0


# -------------------------
# DASH DAMAGE (FIXED)
# -------------------------
<<<<<<< Updated upstream
func _try_damage_player() -> void:
	if has_damaged_this_dash:
=======
func _try_damage_player_local() -> void:
	if damage_timer > 0:
>>>>>>> Stashed changes
		return

	for p in get_tree().get_nodes_in_group("player"):
		if not p:
			continue

		if global_position.distance_to(p.global_position) < 18.0:
			if p.has_method("take_damage"):
				p.take_damage(damage)
<<<<<<< Updated upstream
				has_damaged_this_dash = true
=======
				damage_timer = damage_cooldown
>>>>>>> Stashed changes
				break
