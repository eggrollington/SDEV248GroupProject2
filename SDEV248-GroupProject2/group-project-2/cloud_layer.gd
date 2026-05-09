extends ParallaxLayer
@export var CLOUD_SPEED = -15

func _process(delta) -> void:
	self.motion_offset.x += CLOUD_SPEED*delta

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
