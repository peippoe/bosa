extends Node3D


const TARGET = preload("res://Scenes/target.tscn")

func _ready():
	await get_tree().create_timer(1).timeout
	
	spawn_target()

func spawn_target():
	var new_target = TARGET.instantiate()
	get_tree().current_scene.add_child(new_target)
	print(new_target.global_position)
	
	var a = 10.0
	var x = randf_range(0, a) - a/2
	var y = randf_range(0, a) - a/2
	var z = -5
	new_target.global_position = Vector3(x, y, z)
	
