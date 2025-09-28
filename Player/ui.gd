extends Control


func _ready():
	%MainMenu.pressed.connect(
		func main_menu():
			GameManager.change_scene("res://Scenes/main_menu.tscn")
	)
	
	%Retry.pressed.connect(
		func retry():
			GameManager.retry()
	)
	
	%BackToEditor.pressed.connect(func back_to_editor():
		GameManager.back_to_editor()
	)
	
	%Settings.pressed.connect(func settings():
		Settings.show()
		Settings.move_to_front()
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
		
		elif Input.is_action_just_pressed("retry"):
			GameManager.retry()

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
	var debug_text = "fps: %d \n" % Engine.get_frames_per_second()
	debug_text += "h_vel: %.2f \n" % hvel
	debug_text += "v_vel: %.2f \n" % vvel
	debug_text += "sliding: %s\n" % player.sliding
	debug_text += "on_floor: %s\n" % player.on_floor
	debug_text += "coiling: %s\n" % player.coiling
	debug_text += "coyote: %s\n" % player.get_node("%CoyoteTime").time_left
	debug_text += "wallrun_coyote: %s\n" % player.get_node("%WallrunCoyoteTime").time_left
	%DebugLabel.text = debug_text
	
	%Health.size.x = %HealthBar.size.x * GameManager.health / 100.0
	
	%Points.text = "%dpts" % GameManager.points
	var t = %Combo.get_parsed_text()
	var prev_combo = int(t.substr(0, t.length()-1))
	%Combo.text = "[font_size=25]%dx" % GameManager.combo
	if GameManager.combo != prev_combo:
		var tween = get_tree().create_tween()
		tween.tween_property(%Combo, "scale", Vector2.ONE * 1.3, .015)
		tween.set_parallel(true)
		tween.tween_property(%Combo, "modulate", Color(1, 0, 0), .015)
		tween.set_parallel(false)
		tween.tween_property(%Combo, "scale", Vector2.ONE, .1)
		tween.set_parallel(true)
		tween.tween_property(%Combo, "modulate", Color(1, 1, 1), .1)
	
	
	var inertia_vec : Vector3 = -player.velocity * player.get_node("%Cam").global_basis / 2.0
	
	%DynamicUI.scale = Vector2.ONE + Vector2.ONE * inertia_vec.z / 1200.0
	%DynamicUI.pivot_offset = size / 2.0
	%DynamicUI.position.x = inertia_vec.x
	%DynamicUI.position.y = -inertia_vec.y
	#print($DynamicUI.position)
