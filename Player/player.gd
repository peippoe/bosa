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
	
	if event is InputEventKey:
		
		if Input.is_action_just_pressed("space"): %JumpBuffer.start()
		if Input.is_action_just_released("space"):
			if velocity.y > 0:
				var extra = velocity.y
				velocity.y -= extra / JUMP_CUTOFF

func shoot():
	var from = cam.global_position
	var to = from + -cam.global_basis.z * 100
	
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(from, to, 4)
	var result = space_state.intersect_ray(query)
	
	if result:
		Utility.pop_target(result.collider)






const GRAV := 12.0
const FALL_GRAV := 15.0
const SKYDIVE_GRAV_BOOST := 15.0
const JUMP_VELOCITY := 7.0
const JUMP_BOOST := 0.1
const JUMP_CUTOFF := 3.1

const MAX_SPEED := 8.0
var acceleration := 0.0
const FLOOR_ACCELERATION := 80.0
const AIR_ACCELERATION := 50.0
const FLOOR_FRICTION := 100.0

var input_dir := Vector2.ZERO
var move_dir := Vector3.ZERO

var sliding := false
const SLIDE_ACCELERATION := 10.0
const SLIDE_FRICTION := 5.0
const SLIDE_BOOST := 1.2
const SLIDE_LIMIT := 8.0
const SLIDE_DOWNHILL_BOOST := 1.7

var on_floor := false
var was_on_floor := false

var vel_buffer := []
const VEL_BUFFER_SIZE := 4

var prev_y := 0.0

func _physics_process(delta):
	slide()
	movement(delta)
	update_variables()
	
	if on_floor != was_on_floor and on_floor: AudioPlayer.play_audio("res://Assets/Audio/Effect/kick.ogg", null, Vector2(0.8, 1.2))
	
	if on_floor: %CoyoteTime.start()
	
	var can_jump := false
	if not %DoubleJumpDebounce.is_stopped():
		can_jump = on_floor
	else:
		can_jump = not %CoyoteTime.is_stopped()
	
	if can_jump and not %JumpBuffer.is_stopped():
		if sliding: stop_sliding()
		%DoubleJumpDebounce.start()
		%CoyoteTime.stop()
		%JumpBuffer.stop()
		var hvel = velocity - Vector3.UP*velocity.y
		
		
		
		%EdgeRaycast.force_raycast_update()
		if not %EdgeRaycast.is_colliding():
			velocity += velocity * JUMP_BOOST
		velocity.y = max(velocity.y, 0) + JUMP_VELOCITY
		AudioPlayer.play_audio("res://Assets/Audio/Effect/Jump.wav", null, Vector2(0.8, 1.2))
		
		
		
		var a = func a():
			print(get_real_velocity())
			await get_tree().physics_frame
			await get_tree().physics_frame
			print(get_real_velocity())
		
		a.call_deferred()



func update_variables():
	was_on_floor = on_floor
	on_floor = is_on_floor()
	
	vel_buffer.push_front(velocity)
	if vel_buffer.size() > VEL_BUFFER_SIZE:
		vel_buffer.pop_back()
	
	prev_y = global_position.y

func slide():
	if Input.is_action_just_pressed("shift"): %SlideBuffer.start()
	if not %SlideBuffer.is_stopped() and on_floor:
		%SlideBuffer.stop()
		%Sliding.play()
		sliding = true
		$CollisionShape3D.shape.height = .2
		position.y -= 1
		velocity = get_real_velocity() * SLIDE_BOOST
	
	if sliding and on_floor: %SlideOffFloorTimer.start()
	if (Input.is_action_just_released("shift") or velocity.length() < SLIDE_LIMIT or %SlideOffFloorTimer.is_stopped()) and sliding:
		stop_sliding()

func stop_sliding():
		%SlideOffFloorTimer.stop()
		%Sliding.stop()
		sliding = false
		$CollisionShape3D.shape.height = 2
		position.y += 1

func movement(delta):
	if not on_floor:
		var grav = GRAV
		if velocity.y < 0: grav = FALL_GRAV
		if Input.is_action_pressed("ctrl"): grav += SKYDIVE_GRAV_BOOST
		velocity.y += -grav * delta
		if global_position.y < -20: global_position = Vector3.UP*4; velocity.y = 0.0
	
	input_dir = Input.get_vector("a", "d", "w", "s")
	move_dir = (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var hvel := velocity
	hvel.y = 0
	
	#if on_floor:
	var floor_normal = get_floor_normal()
	if floor_normal == Vector3.ZERO: floor_normal = Vector3.UP
	#move_dir = move_dir.slide(floor_normal)
	#hvel = hvel.slide(floor_normal)
	
	
	#var target := move_dir * MAX_SPEED
	#if target == Vector3.ZERO and not on_floor: target = hvel
	#
	#if not on_floor or move_dir.dot(hvel) > 0:
		#acceleration = FLOOR_ACCELERATION
	#else:
		#acceleration = GROUND_DECELERATION
	#
	#hvel = hvel.lerp(target, acceleration * delta)
	#velocity.x = hvel.x
	#velocity.z = hvel.z
	
	## Quake-like acceleration toward move_dir
	var wish_dir = move_dir
	var current_speed = velocity.dot(wish_dir)
	var add_speed = MAX_SPEED - current_speed
	
	if add_speed > 0:
		var accel = AIR_ACCELERATION
		if sliding: accel = SLIDE_ACCELERATION
		elif on_floor: accel = FLOOR_ACCELERATION
		accel *= delta
		accel = min(accel, add_speed)
		velocity += wish_dir * accel
	
	friction(hvel, wish_dir, delta)
	
	
	move_and_slide()
	
	var current_y = global_position.y
	var y_diff = current_y - prev_y
	
	if sliding and floor_normal != Vector3.UP and y_diff > 0.0:
		velocity = velocity.slide(floor_normal)
	
	
	if sliding:
		if y_diff < 0.0:
			velocity += velocity.normalized() * -y_diff * SLIDE_DOWNHILL_BOOST

func friction(hvel, wish_dir, delta):
	var slowdown : float = min(hvel.length(), 1.0)
	var friction_vec : Vector3 = -hvel.normalized() + wish_dir
	var friction_mult := 0.0
	if sliding:
		friction_mult = SLIDE_FRICTION
	elif on_floor: # friction
		friction_mult = FLOOR_FRICTION
	
	velocity += friction_vec * friction_mult * slowdown * delta








@onready var float_shapecast = %FloatCast
@onready var ground_shapecast = %GroundCast
var float_distance := 0.0
func _float(delta):
	on_floor = float_shapecast.is_colliding()
	
	#if velocity.y > 1.0:
		#return
	
	if not on_floor:
		return
	
	var point = float_shapecast.get_collision_point(0)
	var dist = abs(float_shapecast.global_position.y - point.y)
	
	if not sliding: float_distance = 0.5
	else: float_distance = 0.0
	var diff = (float_distance - dist)
	
	
	const DOWN_DRIVER := 200.0
	const UP_DRIVER := 50.0
	velocity.y += (diff * DOWN_DRIVER - (velocity.y * UP_DRIVER)) * delta



func _process(delta):
	if velocity.length() > 25:
		%Wind.volume_linear = remap(velocity.length(), 25, 50, 0, .4)
		%Wind.pitch_scale = remap(velocity.length(), 25, 50, 0.8, 1.4)
		if not %Wind.playing: %Wind.play()
	else:
		if %Wind.playing: %Wind.stop()
