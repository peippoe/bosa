extends Control


func _ready():
	
	%PauseMenu.hide()
	
	%MainMenu.pressed.connect(
		func main_menu():
			GameManager.change_scene("res://Scenes/main_menu.tscn")
	)
	
	%Retry.pressed.connect(
		func retry():
			GameManager.retry()
	)
	
	%Help.pressed.connect(
		func help():
			OS.shell_open("https://peippoe.github.io/bob/")
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


var lerped_points : int = 0

var current_loudness := 0.0
const SMOOTHING := 25.0

func _process(delta):
	var player = $".."
	
	if Settings.config["miscellaneous"]["debug"] == true:
		%Debug.show()
		
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
	else:
		%Debug.hide()
	
	%Health.size.x = %HealthBar.size.x * GameManager.health / 100.0
	$DynamicUI/Control2/DownshiftCharges/Progress/Bar.size.x = $DynamicUI/Control2/DownshiftCharges/Progress.size.x * player.downshift_charges / 2.0
	
	#lerped_points = lerp(lerped_points, int(GameManager.points * 1.2), delta*5)
	#lerped_points = min(lerped_points, GameManager.points)
	lerped_points = move_toward(lerped_points, GameManager.points, delta*1500)
	%Points.text = "%dpts" % lerped_points
	
	$DynamicUI/left.visible = !player.can_wallrun_left
	$DynamicUI/right.visible = !player.can_wallrun_right
	
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
	
	
	var a = remap(GameManager.health, 25, 10, 0, 1)
	$Vignette.modulate.a = min(a, 1.0)
