extends Node2D

@export_file("*.tscn") var target_scene_path: String
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AudioStreamPlayer.play()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	# Check if the object entering is actually the player
	if body.is_in_group("player"):
		# Optional: Add a small delay or a fade-out animation here
		call_deferred("_change_scene")
func _change_scene():
	if target_scene_path == "":
		print("Warning: No target scene path set for this portal!")
		return
		
	get_tree().change_scene_to_file(target_scene_path)
