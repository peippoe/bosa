extends Node


func spawn_entity(entity := "", parent : Node = null, pos := Vector3.ZERO, randomness := 0.0):
	if not parent: parent = get_tree().current_scene
	
	var new_target = load(entity).instantiate()
	parent.add_child(new_target)
	
	var x = Vector3(
		randf_range(-randomness, randomness),
		randf_range(-randomness, randomness),
		randf_range(-randomness, randomness)
	)
	new_target.global_position = pos + x
