extends WispBase

const SPEED := 35.0
const BOB_AMP := 18.0
const BOB_FREQ := 2.0

var origin_y: float
var dir: float = 1.0
var dir_timer: float = 0.0

func _ready() -> void:
	max_health = 1
	orb_color = Color("e8f4ff")
	orb_radius = 5.0
	super._ready()
	origin_y = position.y

func _process(delta: float) -> void:
	super._process(delta)
	# Drift toward player horizontally with a small reaction delay
	dir_timer -= delta
	if dir_timer <= 0:
		var arr := get_tree().get_nodes_in_group("player")
		if arr.size() > 0:
			var to_player: float = arr[0].global_position.x - global_position.x
			if abs(to_player) > 8.0:
				dir = signf(to_player)
		dir_timer = 0.4
	position.x += dir * SPEED * delta
	position.y = origin_y + sin(t * BOB_FREQ) * BOB_AMP

func _draw() -> void:
	super._draw()
	# Trailing sparkles to feel boost-y
	for i in range(3):
		var ang: float = t * 4.0 + float(i) * (TAU / 3.0)
		var p: Vector2 = Vector2(cos(ang), sin(ang)) * (orb_radius + 4.0)
		draw_circle(p, 1.0, Color(1, 1, 1, 0.6))
