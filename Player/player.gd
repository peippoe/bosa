extends CharacterBody3D

@onready var head = %Head
@onready var cam = %Cam




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





const GRAV := 9.5
const FALL_GRAV := 10.0
const JUMP_VELOCITY := 4.0
const MAX_SPEED := 8.0
var acceleration := 0.0
const GROUND_ACCELERATION := 20.0
const AIR_ACCELERATION := 1.0
const GROUND_DECELERATION := 7.0

var input_dir := Vector2.ZERO
var move_dir := Vector3.ZERO

var sliding := false

func _physics_process(delta):
	movement(delta)
	
	if is_on_floor() and not %JumpBuffer.is_stopped():
		%JumpBuffer.stop()
		velocity.y += JUMP_VELOCITY
		AudioPlayer.play_audio("res://Assets/Audio/Jump.wav", null, Vector2(0.9, 1.1))
		#%Jump.play()

func movement(delta):
	if not is_on_floor():
		var grav = GRAV
		if velocity.y < 0: grav = FALL_GRAV
		velocity.y += -grav * delta
		if global_position.y < -20: global_position = Vector3.UP*4; velocity.y = 0.0
	
	if Input.is_action_just_pressed("space"): %JumpBuffer.start()
	
	input_dir = Input.get_vector("a", "d", "w", "s")
	move_dir = (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var hvel := velocity
	hvel.y = 0
	
	#var target := move_dir * MAX_SPEED
	#if target == Vector3.ZERO and not is_on_floor(): target = hvel
	#
	#if not is_on_floor() or move_dir.dot(hvel) > 0:
		#acceleration = GROUND_ACCELERATION
	#else:
		#acceleration = GROUND_DECELERATION
	#
	#hvel = hvel.lerp(target, acceleration * delta)
	#
	#velocity.x = hvel.x
	#velocity.z = hvel.z
	
	## Quake-like acceleration toward move_dir
	var wish_dir = move_dir
	var current_speed = velocity.dot(wish_dir)
	var add_speed = MAX_SPEED - current_speed
	
	if add_speed > 0:
		var accel = 40 * delta
		if is_on_floor(): accel = 0.9
		accel = min(accel, add_speed)
		velocity += wish_dir * accel
	
	if is_on_floor() and not sliding: # friction
		velocity += (-hvel.normalized() + wish_dir) * 45.0 * min(hvel.length(), 1.0) * delta
	
	
	if Input.is_action_just_pressed("shift") and is_on_floor():
		sliding = true
		$CollisionShape3D.shape.height = 0.5
		position.y -= 1
	if Input.is_action_just_released("shift"):
		sliding = false
		$CollisionShape3D.shape.height = 2
		position.y += 0.75
	
	if sliding:
		print("slide")
	
	
	move_and_slide()
