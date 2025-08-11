extends Node3D

@onready var player = get_tree().get_first_node_in_group("player")

func _process(delta):
	global_position = player.global_position + Vector3(0, 0, 10)
