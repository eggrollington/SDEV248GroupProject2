extends Sprite2D
@export var character : Character


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if character:
		character.node = self
		texture = character.texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
