extends Node3D

@export var child_count : int = 30

func _ready():
	await get_tree().create_timer(1).timeout
	
	while true:
		await get_tree().create_timer(.3).timeout
		
		if get_tree().current_scene.get_child_count() < child_count:
			
			var a = 20.0
			var b = 10.0
			
			var x = randf_range(0, b) - b/2.0
			var y = randf_range(0, a) - a/2.0
			
			var pos = self.global_position + Vector3(x, y, x)
			
			var data = {
				"global_position": pos
			}
			Utility.spawn_entity(Utility.PROPS[10], null, data)
