extends Node

const TARGET = preload("res://Scenes/target.tscn")


func spawn_target(pos := Vector3.ZERO, randomness := 0.0):
	var new_target = TARGET.instantiate()
	get_tree().current_scene.add_child(new_target)
	
	var x = Vector3(
		randf_range(-randomness, randomness),
		randf_range(-randomness, randomness),
		randf_range(-randomness, randomness)
	)
	new_target.global_position = pos + x
