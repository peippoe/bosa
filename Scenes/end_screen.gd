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
	
	if failed:
		$Fail.visible = true
		$AnimationPlayer.play("fail")
		AudioPlayer.play_audio("res://Assets/Audio/Effect/pong.mp3")
	else:
		$Pass.visible = true
		$AnimationPlayer.play("pass")
		AudioPlayer.play_audio("res://Assets/Audio/Effect/applause.mp3")
		AudioPlayer.play_audio("res://Assets/Audio/Effect/voice-nice-one.mp3")
		
		$Pass/ColorRect/HBoxContainer/Panel/VBoxContainer/RichTextLabel.text = """
		[font_size=30]passed %s in %.2fs
		""" % [Playback.beatmap_data["config"]["name"], Playback.playhead]
		
		var amount = 0
		for i in Playback.beatmap_data["beatmap"].size():
			if Playback.beatmap_data["beatmap"][i]["hidden"]["id"] == 10: amount += 1
		
		var max = amount * Settings.POINTS_REWARDS[0]
		var acc = GameManager.points / float(max) * 100.0
		$Pass/ColorRect/HBoxContainer/Panel/VBoxContainer/RichTextLabel2.text = """
		\tscore: %d\n
		\tcombo: %d\n
		\taccuracy: %.2f%%\n
		""" % [GameManager.points, GameManager.combo, acc]
		
		$Pass/ColorRect/HBoxContainer/VBoxContainer2/RichTextLabel2.text = """
		[font_size=250][color=yellow]	%s[font_size=60]		[color=white]RANK
		""" % Settings.get_rank(acc)
		

func _ready():
	$Fail/ColorRect/VBoxContainer/Retry.pressed.connect(retry)
	$Pass/ColorRect/HBoxContainer/VBoxContainer2/Retry.pressed.connect(retry)
	
	$Fail/ColorRect/VBoxContainer/MainMenu.pressed.connect(main_menu)
	$Pass/ColorRect/HBoxContainer/VBoxContainer2/MainMenu.pressed.connect(main_menu)
	
	self.visible = false
	$Fail.visible = false
	$Pass.visible = false
