extends WispBase

const SPEED := 60.0

@export var patrol_min: float = -120.0
@export var patrol_max: float = 120.0

var origin_x: float
var dir: int = -1

func _ready() -> void:
	max_health = 2
	orb_color = Color("ff70d8")
	orb_radius = 7.0

	super._ready()
	origin_x = global_position.x


func _process(delta: float) -> void:
	super._process(delta)

	# Patrol movement (stable via velocity)
	velocity.x = float(dir) * SPEED

	global_position += velocity * delta

	# Patrol bounds
	if global_position.x < origin_x + patrol_min:
		global_position.x = origin_x + patrol_min
		dir = 1

	elif global_position.x > origin_x + patrol_max:
		global_position.x = origin_x + patrol_max
		dir = -1

	# Soft hover bob (no drift)
	global_position.y += sin(t * 8.0) * 0.2


func _draw() -> void:
	super._draw()

	var spike_color: Color = Color("ffaae0") if flash_timer <= 0 else Color.WHITE
	var spikes := 8

	for i in range(spikes):
		var ang: float = (TAU / float(spikes)) * float(i) + t * 2.0
		var p1: Vector2 = Vector2(cos(ang), sin(ang)) * (orb_radius + 1.0)
		var p2: Vector2 = Vector2(cos(ang), sin(ang)) * (orb_radius + 5.0)
		draw_line(p1, p2, spike_color, 1.5)
