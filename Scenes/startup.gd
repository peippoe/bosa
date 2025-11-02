extends Control


var pressed = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: return
	
	if pressed: return
	

	if event is InputEventKey and !(event.keycode == KEY_SPACE): return

	pressed = true
	
	$AnimationPlayer.play("hide")

	await get_tree().create_timer(.5).timeout

	GameManager.change_scene("res://Scenes/main_menu.tscn")
