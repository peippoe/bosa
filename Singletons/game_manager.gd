extends Node

var beatmap_path := ""

var target_parent : Node

var in_editor := false

func _ready():
	update_in_editor()

func update_in_editor():
	in_editor = get_tree().current_scene.name == "MapEditor"
	Playback.setup_signals()

func change_scene(path : String):
	get_tree().change_scene_to_file(path)
	await get_tree().create_timer(1).timeout
	await get_tree().physics_frame
	update_in_editor()
	target_parent = get_tree().current_scene.get_node_or_null("%Map")

func play_map(path):
	beatmap_path = path
	
	change_scene("res://MapPlayer/map_player.tscn")
	
