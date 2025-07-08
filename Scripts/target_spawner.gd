extends Node3D

func _ready():
	await get_tree().create_timer(1).timeout
	
	var a = 10.0
	var x = randf_range(0, a) - a/2
	var y = randf_range(0, a) - a/2
	var z = -5
	var pos = Vector3(x, y, z)
	
	Utility.spawn_entity("res://Targets/target.tscn", null, pos)
