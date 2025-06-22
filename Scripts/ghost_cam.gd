extends Node3D

@onready var cam = $Cam


func _input(event):
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		self.rotate_y(-event.relative.x * 0.001)
		cam.rotate_x(-event.relative.y * 0.001)
		cam.rotation.x = clampf(cam.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	if Input.is_action_pressed("aim"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var speed = 2
	if Input.is_action_pressed("shift"): speed = 4
	self.global_position += cam.global_basis * Vector3(input_dir.x, 0, input_dir.y) * speed * delta
