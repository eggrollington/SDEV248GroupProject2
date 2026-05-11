extends Button
@export var character : Character:
	set(value):
		character = value
		text = value.title


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if character:
		name = character.title


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	character.get_attacked()
	character.take_damage(20)
	get_parent().hide()
	get_parent().owner.attack()
	get_parent().owner.pop_out()
