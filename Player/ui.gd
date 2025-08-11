extends Control


func _ready():
	%MainMenu.pressed.connect(func main_menu():
		get_tree().paused = false
		GameManager.change_scene("res://Scenes/main_menu.tscn")
		Playback.playback_speed = 0.0
		)
	
	%BackToEditor.pressed.connect(func back_to_editor():
		GameManager.back_to_editor()
	)

func _unhandled_input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("ui_cancel"):
			if !%PauseMenu.visible:
				%PauseMenu.show()
				get_tree().paused = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				%AnimationPlayer.play("pause")
			else:
				%PauseMenu.hide()
				get_tree().paused = false
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				%PauseMusic.stop()

func _input(event):
	if not %PauseMenu.visible: return
	#if event is InputEventMouseMotion:
		
		#var offset = (event.position - get_viewport().size/2.0) / 100
		#print(offset)
		#$PauseMenu/MarginContainer.global_position = Vector2.ZERO + offset


func _process(delta):
	var player = $".."
	var vel = player.velocity
	var hvel = (vel - Vector3.UP * vel.y).length()
	var vvel = vel.y
	var debug_text = "hvel: %.2f \n" % hvel
	debug_text += "vvel: %.2f \n" % vvel
	debug_text += "sliding: %s" % player.sliding
	%DebugLabel.text = debug_text
	
	$Control2/ColorRect/ColorRect.size.x = $Control2/ColorRect.size.x * (1.0 - GameManager.health / 100.0)
	
	$Control2/RichTextLabel.text = "points: %d\ncombo: %d" % [GameManager.points, GameManager.combo]
