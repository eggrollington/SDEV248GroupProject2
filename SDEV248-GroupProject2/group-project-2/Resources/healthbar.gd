
extends ProgressBar

func _ready():
	# 'owner' or 'get_parent()' should be your Sprite2D/CharacterSprite2D node
	var parent_node = get_parent() 
	
	if parent_node and parent_node.get("character"):
		var char_res = parent_node.character
		char_res.health_changed.connect(update_bar)
		
		# Set initial values
		max_value = char_res.max_health
		value = char_res.current_health
	else:
		push_warning("HealthBar: Parent does not have a character resource!")

func update_bar(new_val, _max_val):
	value = new_val
