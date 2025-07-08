extends CharacterBody3D

@onready var head = %Head
@onready var cam = %Cam

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * 0.001)
		cam.rotate_x(-event.relative.y * 0.001)
		cam.rotation.x = clampf(cam.rotation.x, -PI/2, PI/2)
	
	elif event is InputEventMouseButton:
		if event.pressed: shoot()

func shoot():
	var from = cam.global_position
	var to = from + -cam.global_basis.z * 100
	
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(from, to, 4)
	var result = space_state.intersect_ray(query)
	
	if result:
		Utility.pop_target(result.collider)



func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (cam.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
