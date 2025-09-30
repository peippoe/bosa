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

func _ready():
	$Fail/ColorRect/VBoxContainer/Retry.pressed.connect(retry)
	$Pass/ColorRect/HBoxContainer/VBoxContainer2/Retry.pressed.connect(retry)
	
	$Fail/ColorRect/VBoxContainer/MainMenu.pressed.connect(main_menu)
	$Pass/ColorRect/HBoxContainer/VBoxContainer2/MainMenu.pressed.connect(main_menu)
	
	self.visible = false
	$Fail.visible = false
	$Pass.visible = false
