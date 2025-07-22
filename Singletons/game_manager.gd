extends Node

var beatmap_path := ""

var target_parent : Node

var in_editor := false
var editor_packed_scene : PackedScene = null

func _ready():
	update_in_editor()
	update_target_parent()

func update_in_editor():
	in_editor = get_tree().current_scene.name == "MapEditor"


func back_to_editor():
	if not editor_packed_scene: push_error("NO EDITOR PACKED SCENE"); return
	get_tree().change_scene_to_packed(editor_packed_scene)
	editor_packed_scene = null
	
	get_tree().paused = false
	
	while not get_tree().current_scene:
		await get_tree().process_frame
	
	update_in_editor()
	update_target_parent()

func change_scene(scene_path : String):
	var was_in_editor = in_editor
	var current_scene = PackedScene.new()
	current_scene.pack(get_tree().current_scene)
	
	get_tree().change_scene_to_file(scene_path)
	
	while not get_tree().current_scene:
		await get_tree().process_frame
	
	#while get_tree().current_scene.scene_file_path != scene_path:
		#await get_tree().process_frame
	
	
	update_in_editor()
	if not in_editor and was_in_editor: editor_packed_scene = current_scene
	update_target_parent()

func update_target_parent():
	if in_editor: target_parent = Utility.get_node_or_null_in_scene("%Preview")
	else: target_parent = Utility.get_node_or_null_in_scene("%Map")
	if not target_parent: push_error("ERROR GETTING TARGET PARENT")

func play_map(path):
	if path:
		beatmap_path = path
	
	change_scene("res://MapPlayer/map_player.tscn")
