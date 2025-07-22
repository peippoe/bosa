extends Control


func _ready():
	$PauseMenu/MarginContainer/VBoxContainer/BackToEditor.pressed.connect(func back_to_editor():
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
	var debug_text = "vel: %.2s \n" % str(vel)
	debug_text += "sliding: %s" % player.sliding
	%DebugLabel.text = debug_text
	
