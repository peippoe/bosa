extends Node

var beatmap_path := ""

var target_parent : Node

var in_editor := false

var points := 0
var combo := 0
var health := 50


func _ready():
	update_in_editor()
	update_target_parent()

func update_in_editor():
	in_editor = get_tree().current_scene.name == "MapEditor"


func back_to_editor():
	Playback.playback_speed = 0
	change_scene("res://MapEditor/Parts/map_editor.tscn")
	
	while not get_tree().current_scene:
		await get_tree().process_frame
	
	get_tree().current_scene.load_map(beatmap_path)

func change_scene(scene_path : String):
	get_tree().paused = false
	
	var back_to_editor_visible = false
	if in_editor and scene_path == "res://MapPlayer/map_player.tscn":
		back_to_editor_visible = true
	
	get_tree().change_scene_to_file(scene_path)
	
	while not get_tree().current_scene:
		await get_tree().process_frame
	
	#while get_tree().current_scene.scene_file_path != scene_path:
		#await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	if player: player.get_node("%UI/%BackToEditor").visible = back_to_editor_visible
	
	update_in_editor()
	update_target_parent()

func update_target_parent():
	if in_editor: target_parent = Utility.get_node_or_null_in_scene("%Preview")
	else: target_parent = Utility.get_node_or_null_in_scene("%Map")
	if not target_parent: push_error("ERROR GETTING TARGET PARENT")

func play_map(path):
	if path:
		beatmap_path = path
	
	change_scene("res://MapPlayer/map_player.tscn")
