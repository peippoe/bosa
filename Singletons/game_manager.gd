extends Node

var beatmap_path := ""

var target_parent : Node

var in_editor := false
var editor_playtest := false:
	set(value):
		editor_playtest = value
		if value:
			playtest_ghost_positions = []

var playtest_ghost_positions := []

@export var pp_accuracy_curve : Curve

var points := 0
var combo := 0
var health := 100:
	set(value):
		if GameManager.in_editor: return
		
		health = clampi(value, 0, 100)
		
		if health < 25.0:
			AudioServer.set_bus_effect_enabled(1, 1, true)
			var filter = AudioServer.get_bus_effect(1, 1)
			var a = remap(GameManager.health, 25, 10, 0, 1)
			a = clampf(a, 0.0, 1.0)
			filter.cutoff_hz = remap(a, 0.0, 1.0, 20000, 2000)
		else:
			AudioServer.set_bus_effect_enabled(1, 1, false)
		
		if value > 0: return
		
		Playback.beatmap_ended(true)


func _ready():
	update_in_editor(get_tree().current_scene)
	update_target_parent()

func update_in_editor(scene):
	var scene_name
	if scene is String:
		scene_name = scene.get_file()
	else:
		scene_name = scene.name
	
	print(scene_name)
	
	in_editor = bool(scene_name == "MapEditor" or scene_name == "map_editor.tscn")
	print(in_editor)


func back_to_editor():
	change_scene("res://MapEditor/Parts/map_editor.tscn")
	
	while not get_tree().current_scene:
		await get_tree().process_frame
	
	await get_tree().create_timer(.1).timeout
	
	get_tree().current_scene.load_map(beatmap_path)

func retry():
	change_scene(get_tree().current_scene.scene_file_path)

func change_scene(scene_path : String):
	Playback.playback_speed = 0
	get_tree().paused = false
	
	
	if in_editor and scene_path == "res://MapPlayer/map_player.tscn":
		editor_playtest = true
	elif scene_path == get_tree().current_scene.scene_file_path and get_tree().get_first_node_in_group("player").get_node("%UI/%BackToEditor").visible:
		editor_playtest = true
	else:
		editor_playtest = false
	
	update_in_editor(scene_path)
	get_tree().change_scene_to_file(scene_path)
	
	while not get_tree().current_scene:
		await get_tree().process_frame
	
	#while get_tree().current_scene.scene_file_path != scene_path:
		#await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.get_node("%UI/%BackToEditor").visible = editor_playtest
	
	update_target_parent()
	
	
	var buttons : Array = get_tree().get_nodes_in_group("button_1")
	for inst in buttons:
		inst.pressed.connect(button_pressed)

func button_pressed():
	AudioPlayer.play_audio("res://Assets/Audio/Effect/menubutton.wav")

func update_target_parent():
	target_parent = Utility.get_node_or_null_in_scene("%Beatmap")
	#if not target_parent: push_error("%Beatmap not found")

func play_map(path : String):
	if path: beatmap_path = path
	
	change_scene("res://MapPlayer/map_player.tscn")
