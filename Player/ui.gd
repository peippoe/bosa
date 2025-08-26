extends Control


func _ready():
	%MainMenu.pressed.connect(
		func main_menu():
			GameManager.change_scene("res://Scenes/main_menu.tscn")
	)
	
	%Retry.pressed.connect(
		func retry():
			GameManager.change_scene(get_tree().current_scene.scene_file_path)
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
	var debug_text = "h_vel: %.2f \n" % hvel
	debug_text += "v_vel: %.2f \n" % vvel
	debug_text += "sliding: %s\n" % player.sliding
	debug_text += "on_floor: %s\n" % player.on_floor
	debug_text += "coiling: %s\n" % player.coiling
	debug_text += "coyote: %s\n" % player.get_node("%CoyoteTime").time_left
	%DebugLabel.text = debug_text
	
	$Control2/ColorRect/ColorRect.size.x = $Control2/ColorRect.size.x * GameManager.health / 100.0
	
	$Control2/RichTextLabel.text = "%dpts\n[font_size=25]%dx" % [GameManager.points, GameManager.combo]
