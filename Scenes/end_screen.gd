extends Control


func retry():
	GameManager.change_scene(get_tree().current_scene.scene_file_path)
func main_menu():
	GameManager.change_scene("res://Scenes/main_menu.tscn")

func end(failed = false):
	
	Playback.playback_speed = 0
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	self.visible = true
	
	var beatmap_name = Playback.beatmap_data["config"]["name"]
	
	if failed:
		$Fail.visible = true
		$AnimationPlayer.play("fail")
		AudioPlayer.play_audio("res://Assets/Audio/Effect/pong.mp3")
	else:
		$Pass.visible = true
		$AnimationPlayer.play("pass")
		
		$Pass/ColorRect/HBoxContainer/Panel/VBoxContainer/RichTextLabel.text = """
		[font_size=30]passed %s in %.2fs
		""" % [beatmap_name, Playback.playhead]
		
		var max_points = 0
		#var amount = 0
		for i in Playback.beatmap_data["beatmap"].size():
			match Playback.beatmap_data["beatmap"][i]["hidden"]["id"]:
				10:
					max_points += Settings.POINTS_REWARDS[0]
				11:
					max_points += 300
				12:
					max_points += Settings.POINTS_REWARDS[0]
		
		var acc = GameManager.points / float(max_points)
		var rank = Settings.get_rank(acc)
		var pp = GameManager.pp_accuracy_curve.sample_baked(acc) * max_points / 10.0
		
		if rank == "SS":
			AudioPlayer.play_audio("res://Assets/Audio/Effect/voice-perfect.mp3")
		elif rank == "S":
			AudioPlayer.play_audio("res://Assets/Audio/Effect/voice-nice-one.mp3")
		
		var pitch = remap(acc, .5, 1, 0.8, 1.1)
		pitch = clampf(pitch, 0.8, 1.0)
		var applause_path = "res://Assets/Audio/Effect/applause2.mp3"
		if rank == "SS" or rank == "S" or rank == "A":
			applause_path = "res://Assets/Audio/Effect/applause.mp3"
		AudioPlayer.play_audio(applause_path, null, Vector2.ONE * pitch, -5)
		
		$Pass/ColorRect/HBoxContainer/Panel/VBoxContainer/RichTextLabel2.text = """
		\t\tscore: %d\n
		\t\tcombo: %d\n
		\t\taccuracy: %.2f%%\n
		\t\tpp: [color=green]+%d\n
		""" % [GameManager.points, GameManager.combo, acc*100.0, pp]
		
		var color
		match rank:
			"D":
				color = "red"
			"C":
				color = "orange"
			"B":
				color = "yellow"
			"A":
				color = "green"
			"S":
				color = "blue"
			"SS":
				color = "purple"
			
		$Pass/ColorRect/HBoxContainer/VBoxContainer2/RichTextLabel2.text = """
		[font_size=250][color=%s]	%s[font_size=60]		[color=white]RANK
		""" % [color, rank]
		
		
		
		var data
		if Playback.beatmap_data["config"]["gamemode"] == 0:
			data = {
				"points" = GameManager.points,
				"acc" = acc,
				"pp" = pp
			}
			if LocalSave.save["scores_classic"].has(beatmap_name) and LocalSave.save["scores_classic"][beatmap_name]["pp"] > data["pp"]:
				return
			LocalSave.save["scores_classic"][beatmap_name] = data
			LocalSave._save()
		else:
			data = {
				"time" = Playback.playhead
			}
			if LocalSave.save["scores_timetrial"].has(beatmap_name) and LocalSave.save["scores_timetrial"][beatmap_name]["time"] < data["time"]:
				return
			LocalSave.save["scores_timetrial"][beatmap_name] = data
			LocalSave._save()

func _ready():
	$Fail/ColorRect/VBoxContainer/Retry.pressed.connect(retry)
	$Pass/ColorRect/HBoxContainer/VBoxContainer2/Retry.pressed.connect(retry)
	
	$Fail/ColorRect/VBoxContainer/MainMenu.pressed.connect(main_menu)
	$Pass/ColorRect/HBoxContainer/VBoxContainer2/MainMenu.pressed.connect(main_menu)
	
	self.visible = false
	$Fail.visible = false
	$Pass.visible = false
