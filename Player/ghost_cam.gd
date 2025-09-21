extends Node3D


func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		self.rotate_y(-event.relative.x * 0.001)
		%Cam.rotate_x(-event.relative.y * 0.001)
		%Cam.rotation.x = clampf(%Cam.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	if get_tree().root.gui_get_focus_owner() is LineEdit: return
	
	if Input.is_action_pressed("alt_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.is_action_pressed("ctrl"): return
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var speed = 10
	if Input.is_action_pressed("shift"): speed = 30
	self.global_position += %Cam.global_basis * Vector3(input_dir.x, 0, input_dir.y) * speed * delta
