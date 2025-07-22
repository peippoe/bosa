extends Node

var beatmap_path := ""

var target_parent : Node

var in_editor := false

func _ready():
	update_in_editor()
	update_target_parent()

func update_in_editor():
	in_editor = get_tree().current_scene.name == "MapEditor"

func change_scene(path : String):
	get_tree().change_scene_to_file(path)
	
	while not get_tree().current_scene:
		await get_tree().process_frame
	
	while get_tree().current_scene.scene_file_path != path:
		await get_tree().process_frame
	
	update_in_editor()
	update_target_parent()

func update_target_parent():
	if in_editor: target_parent = Utility.get_node_or_null_in_scene("%Preview")
	else: target_parent = Utility.get_node_or_null_in_scene("%Map")
	if not target_parent: print("ERROR GETTING TARGET PARENT")

func play_map(path):
	if path:
		beatmap_path = path
	
	change_scene("res://MapPlayer/map_player.tscn")
