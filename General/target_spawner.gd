extends Node3D

func _ready():
	await get_tree().create_timer(1).timeout
	
	#var a = 10.0
	#var b = 5.0
	#var x = randf_range(0, b) - b/2.0
	#var y = randf_range(0, a) - a/2.0
	#var z = -5.0
	#var pos = Vector3(x, y, z)
	
	while true:
		await get_tree().create_timer(1).timeout
		Utility.spawn_entity("res://Targets/target.tscn", null, global_position, 10)
