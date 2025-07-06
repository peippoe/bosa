extends Node


func spawn_entity(entity := "", parent : Node = null, pos := Vector3.ZERO, randomness := 0.0):
	if not parent: parent = get_tree().current_scene
	
	var new_entity = load(entity).instantiate()
	parent.add_child(new_entity)
		
	var x = Vector3(
		randf_range(-randomness, randomness),
		randf_range(-randomness, randomness),
		randf_range(-randomness, randomness)
	)
	new_entity.global_position = pos + x
	
	return new_entity


const TARGETS = [
	"res://Targets/target.tscn",
]

func spawn_target(target_data):
	return spawn_entity(TARGETS[target_data["type"]], GameManager.target_parent, target_data["pos"])
