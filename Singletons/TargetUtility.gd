extends Node

const TARGET = preload("res://Scenes/target.tscn")


func spawn_target(pos := Vector3.ZERO):
	var new_target = TARGET.instantiate()
	get_tree().current_scene.add_child(new_target)
	new_target.global_position = pos
