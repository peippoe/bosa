extends Control




func _process(delta):
	var loudness = AudioPlayer.current_loudness
	
	var s = lerpf(1.0, 1.2
	, ease(loudness * 3, -2))
	self.scale = Vector2.ONE * s
	
	var pos = get_viewport().get_mouse_position()
	pos /= Vector2(1920, 1080)
	pos -= Vector2(0.5, 0.5)
	self.position = pos * -20
	#print(pos)
	
	$Play/RichTextLabel.text = """
	playtime: %dmins
	pp: %d
	""" % [LocalSave.save["playtime"] / 60, get_pp()]

func get_pp():
	var sum = 0
	for key in LocalSave.save["scores_classic"].keys():
		sum += LocalSave.save["scores_classic"][key]["pp"]
	return sum


var start_sizes = []
var start_positions = []

func _ready():
	$Home.show()
	$Play.hide()
	
	for i in $Home/Buttons.get_children().size():
		
		var button = $Home/Buttons.get_child(i)
		start_sizes.append(button.size)
		start_positions.append(button.global_position + button.pivot_offset)
		
		button.pivot_offset = button.size / 2.0
		
		button.mouse_entered.connect(func a(): AudioPlayer.play_audio("res://Assets/Audio/Effect/goal_spawned.wav", null, Vector2.ONE * (3.5 - i*0.5)))
		#button.mouse_exited.connect(func a(): AudioPlayer.play_audio("res://Assets/Audio/Effect/goal_spawned.wav", null, Vector2.ONE * (2.5 + i*0.5)))
		
	
	$Home/Buttons.gui_input.connect(on_gui_input)
	
	$Home/Buttons/Play.pressed.connect(func a():
		AudioPlayer.play_audio("res://Assets/Audio/Effect/pong.mp3")
		transition()
		)
	$Home/Buttons/Edit.pressed.connect(func a():
		GameManager.change_scene("res://MapEditor/Parts/map_editor.tscn")
		print("PRESS")
		)
	$Home/Buttons/Exit.pressed.connect(func a(): get_tree().quit())
	
	$Play/HBoxContainer/Control/Back.pressed.connect(func a(): transition(false))
	
	
	$Play/HBoxContainer/VBoxContainer/Button2.pressed.connect(func a(): GameManager.play_map("res://Scenes/Beatmaps/tutorial2.json"))
	$Play/HBoxContainer/VBoxContainer/Button.pressed.connect(func a(): GameManager.play_map("res://Scenes/Beatmaps/test_level.json"))
	$Play/HBoxContainer/VBoxContainer/Button3.pressed.connect(func a(): GameManager.play_map("res://Scenes/Beatmaps/test_level2.json"))
	$Play/HBoxContainer/VBoxContainer/Button5.pressed.connect(func a(): GameManager.play_map("res://Scenes/Beatmaps/test_level3.json"))
	$Play/HBoxContainer/VBoxContainer/Button6.pressed.connect(func a(): GameManager.play_map("res://Scenes/Beatmaps/test_level4.json"))
	$Play/HBoxContainer/VBoxContainer/Button7.pressed.connect(func a(): GameManager.play_map("res://Scenes/Beatmaps/test_level_tt.json"))
	$Play/HBoxContainer/VBoxContainer/Button4.pressed.connect(func a(): Playback.playhead = 0.0; GameManager.change_scene("res://Scenes/test_scene.tscn"))
	
	
	set_classic_label($Play/HBoxContainer/VBoxContainer/Button, "test_level")
	set_classic_label($Play/HBoxContainer/VBoxContainer/Button3, "test_level2")
	set_classic_label($Play/HBoxContainer/VBoxContainer/Button5, "test_level3")
	set_classic_label($Play/HBoxContainer/VBoxContainer/Button6, "test_level4")
	
	set_timetrial_label($Play/HBoxContainer/VBoxContainer/Button7, "test_level_tt")
	set_timetrial_label($Play/HBoxContainer/VBoxContainer/Button2, "tutorial2")


func set_timetrial_label(parent, beatmap_name):
	
	var label = $"../Control/RichTextLabel".duplicate()
	parent.add_child(label)
	label.position = Vector2.ZERO
	
	var new_text = "	unplayed"
	if LocalSave.save["scores_timetrial"].has(beatmap_name):
		new_text = "		%.2fs" % [LocalSave.save["scores_timetrial"][beatmap_name]["time"]]
	
	
	label.text = new_text

func set_classic_label(parent, beatmap_name):
	
	var label = $"../Control/RichTextLabel".duplicate()
	parent.add_child(label)
	label.position = Vector2.ZERO
	
	var new_text = "	unplayed"
	if LocalSave.save["scores_classic"].has(beatmap_name):
		new_text = """		[font_size=15]score %d
		accuracy %.2f%%
		%.2f pp
		""" % [LocalSave.save["scores_classic"][beatmap_name]["points"], LocalSave.save["scores_classic"][beatmap_name]["acc"] * 100.0, LocalSave.save["scores_classic"][beatmap_name]["pp"]]
	
	
	label.text = new_text



func transition(_play = true):
	$"../AnimationPlayer".play("transition")
	await get_tree().create_timer(.2).timeout
	
	$Play.visible = _play
	$Home.visible = !_play
	$"../Spectrum".visible = !_play



func on_gui_input(event):
	if event is InputEventMouseMotion:
		var pos = event.position
		
		for i in $Home/Buttons.get_children().size():
			var button = $Home/Buttons.get_child(i)
			var dist = pos.distance_to($Home/Points.get_child(i).global_position)
			
			var alpha = remap(dist, 200, 270, 1.0, 0.0)
			alpha = clampf(alpha, 0.0, 1.0)
			
			var beta = ease(alpha, 3)
			var gamma = max(beta, 0.5)
			
			button.scale = Vector2.ONE * remap(gamma, 0.5, 1.0, 1, 1.3)
			#button.global_position = start_positions[i]
			var start = start_positions[i]
			var end = $Home/Points.get_child(i).global_position
			button.global_position = lerp(start, end, beta) - button.pivot_offset * beta
			#print(button.scale)
			
			button.get_child(0).global_position = lerp(start, button.global_position, 0.8)
