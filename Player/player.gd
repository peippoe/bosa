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
const SKYDIVE_GRAV_BOOST := 15.0
const JUMP_VELOCITY := 4.0

const MAX_SPEED := 8.0
var acceleration := 0.0
const GROUND_ACCELERATION := 45.0
const AIR_ACCELERATION := 33.0
const GROUND_FRICTION := 45.0

var input_dir := Vector2.ZERO
var move_dir := Vector3.ZERO

var sliding := false
const SLIDE_ACCELERATION := 5.0
const SLIDE_FRICTION := 5.0
const SLIDE_BOOST := 1.2
const SLIDE_LIMIT := 5.0

var vel_buffer := []
const VEL_BUFFER_SIZE := 4

func _physics_process(delta):
	slide()
	
	movement(delta)
	
	if is_on_floor(): %CoyoteTime.start()
	
	if not %CoyoteTime.is_stopped() and not %JumpBuffer.is_stopped():
		%CoyoteTime.stop()
		%JumpBuffer.stop()
		velocity.y += JUMP_VELOCITY
		AudioPlayer.play_audio("res://Assets/Audio/Jump.wav", null, Vector2(0.9, 1.1))
	
	update_variables()

func update_variables():
	vel_buffer.push_front(velocity)
	if vel_buffer.size() > VEL_BUFFER_SIZE:
		vel_buffer.pop_back()

func slide():
	if Input.is_action_just_pressed("shift"): %SlideBuffer.start()
	if not %SlideBuffer.is_stopped() and is_on_floor():
		%SlideBuffer.stop()
		%Sliding.play()
		sliding = true
		$CollisionShape3D.shape.height = 0.5
		position.y -= 1
		velocity = get_real_velocity() * SLIDE_BOOST
	if (Input.is_action_just_released("shift") or not is_on_floor() or velocity.length() < SLIDE_LIMIT) and sliding:
		%Sliding.stop()
		sliding = false
		$CollisionShape3D.shape.height = 2
		position.y += 0.75

func movement(delta):
	if not is_on_floor():
		var grav = GRAV
		if velocity.y < 0: grav = FALL_GRAV
		if Input.is_action_pressed("ctrl"): grav += SKYDIVE_GRAV_BOOST
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
		var accel = AIR_ACCELERATION
		if is_on_floor(): accel = GROUND_ACCELERATION
		accel *= delta
		accel = min(accel, add_speed)
		velocity += wish_dir * accel
	
	if is_on_floor() and not sliding: # friction
		velocity += (-hvel.normalized() + wish_dir) * GROUND_FRICTION * min(hvel.length(), 1.0) * delta
	
	
	
	
	
	#if sliding:
		#print("slide")
	
	
	move_and_slide()
