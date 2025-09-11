extends Node3D

func _ready():
	await get_tree().create_timer(1).timeout
	
	while true:
		await get_tree().create_timer(.3).timeout
		
		if get_tree().current_scene.get_child_count() < 20:
			
			var a = 20.0
			var b = 10.0
			var z = -5.0
			
			var x = randf_range(0, b) - b/2.0
			var y = randf_range(0, a) - a/2.0
			
			var pos = self.global_position + Vector3(x, y, z)
			
			var data = {
				"global_position": pos
			}
			Utility.spawn_entity(Utility.PROPS[10], null, data)
