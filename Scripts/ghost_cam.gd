extends Node3D


func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		self.rotate_y(-event.relative.x * 0.001)
		%Cam.rotate_x(-event.relative.y * 0.001)
		%Cam.rotation.x = clampf(%Cam.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	if Input.is_action_pressed("aim"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var speed = 2
	if Input.is_action_pressed("shift"): speed = 4
	self.global_position += %Cam.global_basis * Vector3(input_dir.x, 0, input_dir.y) * speed * delta







func open_fd():
	var fd = FileDialog.new()
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = PackedStringArray(["*.mp3", "*.ogg", "*.wav"])
	add_child(fd)
	fd.popup_centered()
	fd.connect("file_selected", _on_file_selected)

func _on_file_selected(path):
	print(path)

func _on_file_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://"))


func _on_texture_button_button_down():
	print("PRE")
