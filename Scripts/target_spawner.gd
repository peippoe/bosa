extends Node3D

func _ready():
	await get_tree().create_timer(1).timeout
	
	var a = 10.0
	var x = randf_range(0, a) - a/2
	var y = randf_range(0, a) - a/2
	var z = -5
	var pos = Vector3(x, y, z)
	
	UtilityFunctions.spawn_entity("res://Scenes/target.tscn", null, pos)
