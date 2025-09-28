extends CharacterBody3D

@onready var head = %Head
@onready var cam = %Cam



func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.use_accumulated_input = false

func _input(event):
	if event is InputEventMouseMotion:
		var relative = -event.screen_relative * Settings.config["gameplay"]["mouse_sensitivity"]/1000.0
		head.rotate_y(relative.x)
		head.orthonormalize()
		var rel_y = clampf(cam.rotation.x + relative.y, -PI/2, PI/2) - cam.rotation.x
		cam.rotate_x(rel_y)
		#cam.rotation.x = clampf(cam.rotation.x, -PI/2.0, PI/2.0)
		cam.orthonormalize()
	
	elif event is InputEventMouseButton:
		if not event.pressed: return
		
		if event.button_index == 1:
			shoot()
		
		if Input.is_action_just_pressed("quickturn"):
			head.rotate_y(PI)
	
	if event is InputEventKey:
		if Input.is_action_just_pressed("pop"):
			shoot()
		
		if Input.is_action_just_pressed("space"):
			start_wallrun()
			%JumpBuffer.start()
		
		if Input.is_action_just_pressed("shift") and %SlideCooldown.is_stopped(): %SlideBuffer.start()
		
		if Input.is_action_just_pressed("vault"):
			vault()
		
		
		
		if Input.is_action_just_released("space"):
			jump_cutoff()


func vault():
	
	%WallFinderShapecast.force_shapecast_update()
	
	if %WallFinderShapecast.is_colliding():
		
		var idx = -1
		for i in %WallFinderShapecast.get_collision_count():
			if %WallFinderShapecast.get_collider(i).is_in_group("player"):
				continue
			idx = i
		
		if idx == -1: return
		
		
		print(%WallFinderShapecast.get_collider(idx))
		
		var point = %WallFinderShapecast.get_collision_point(idx)
		
		var start = cam.global_position - Vector3.UP*cam.global_position.y
		var end = point - Vector3.UP*point.y
		var dist = end.distance_to(start)
		
		var angle = cam.rotation.x
		
		var x_dist = dist / cos(angle) + 0.1
		var x = cam.global_position + -cam.global_basis.z * x_dist
		
		
		var height = -sqrt(pow(x_dist, 2.0) - pow(dist, 2.0)) - 1.5
		
		%LedgeRaycast.global_position = x
		%LedgeRaycast.target_position.y = height
		%LedgeRaycast.force_raycast_update()
		
		if not %LedgeRaycast.is_colliding(): return
		
		vault_point = %LedgeRaycast.get_collision_point() + Vector3.UP * 1.0
		vault_start_point = global_position
		
		var floor_y = global_position.y - $CollisionShape3D.shape.height/2.0 + 0.1
		var vault_y = vault_point.y - 1.0
		print("vault_y %f\t floor_y %f" % [vault_y, floor_y])
		
		#if abs(height) > 3.8: return
		
		if vault_y <= floor_y or vault_y - floor_y > 3.0:
			vault_point = null
			return
		
		
		AudioPlayer.play_audio("res://Assets/Audio/Effect/jump2.wav", null, Vector2(2, 3))
		
		#print("STIPPPPPPPPPPPPP")
		stop_sliding()
		
		vault_stored_velocity = velocity
		
		var vault_dist = vault_point.distance_to(global_position)
		vault_speed = vault_dist / vault_time
		#var to_point = (vault_point - global_position).normalized()
		#var vel_to_point = velocity.dot(to_point)
		#vel_to_point = max(vel_to_point, 1.0)
		#var vault_efficiency = max(vel_to_point / vault_dist * 10.0, 5.0)
		#vault_speed = remap(vault_efficiency, 5.0, 30.0, 8.0, 12.0)
		
		#print("vault distance: %f\n vel_to_point: %f\n vault efficiency: %f\n vault_speed: %f" % [vault_dist, vel_to_point, vault_efficiency, vault_speed])



func shoot():
	var from = cam.global_position
	var to = from + -cam.global_basis.z * 100
	
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(from, to, 4)
	var result = space_state.intersect_ray(query)
	
	if result:
		Utility.pop_target(result.collider)
	
	
	
	
	var spawn_pos = cam.global_position - cam.global_basis.z*1 - cam.global_basis.y*0.2 + cam.global_basis.x*0.06
	var bullet_inst = preload("uid://bn3qrpqhylncu").instantiate()
	get_parent().add_child(bullet_inst)
	bullet_inst.look_at_from_position(spawn_pos, to)
	bullet_inst.rotation_degrees.x += 90
	var tween = get_tree().create_tween()
	
	tween.tween_property(bullet_inst, "global_position", to, .7)
	tween.set_parallel(false)
	tween.tween_callback(bullet_inst.queue_free)




const GRAV := 16
const FAST_FALL_BOOST := 1#3.0
const SKYDIVE_GRAV_BOOST := 30.0
const DOWNSHIFT := 14.0
const WALLRUN_GRAV := 6.0
const JUMP_VELOCITY := 6.9
const JUMP_EDGE_BOOST := 0.1
const JUMP_CUTOFF := 0.3
var jump_cutoff_applied := false
const JUMP_EXTEND := 0#6.0

const MAX_SPEED := 8.0
const WISH_DIR_COMPENSATION_LIMIT := MAX_SPEED + 40.0
const AIR_SPEED_CAP := 40.0
const AIR_SPEED_CAP_MULT := 1.0
var acceleration := 0.0
const FLOOR_ACCELERATION := 140.0
const AIR_ACCELERATION := 50.0
const AIR_SLOWDOWN_ASSIST := 0.0
const FLOOR_FRICTION := 120.0
const AIR_FRICTION := 0.5

var input_dir := Vector2.ZERO
var move_dir := Vector3.ZERO

var sliding := false
const SLIDE_ACCELERATION := 10.0
const SLIDE_FRICTION := 5.0
#const SLIDE_BOOST := 1.1
const SLIDE_NERF := .5
const SLIDE_LIMIT := 3.0
const SLIDE_DOWNHILL_BOOST := 1.9

var on_floor := false
var was_on_floor := false

var vel_buffer := [] # changing physics fps will nerf/buff this
const VEL_BUFFER_SIZE := 4

var prev_y := 0.0

var coiling := false

var vault_point = null
var vault_start_point : Vector3 = Vector3.ZERO
var vault_stored_velocity
var vault_speed
@export var vault_time = 0.2
var vault_end_dist : float = 0.1
@export var vault_y_curve : Curve

var wallrunning := 0
var can_wallrun_left := true
var can_wallrun_right := true

@export var jump_extend_curve : Curve
@export var fast_fall_curve : Curve

func _physics_process(delta):
	
	if vault_point:
		
		var max_dist = (vault_start_point - vault_point).length() - vault_end_dist
		var curr_dist = (global_position - vault_point).length() - vault_end_dist
		var alpha = curr_dist/max_dist
		print(alpha)
		
		
		var start_y = vault_start_point.y + 0.75
		var end_y = vault_point.y + 0.75
		cam.global_position.y = lerpf(start_y, end_y, vault_y_curve.sample_baked(1.0-alpha))
		
		#global_position = lerp(global_position, vault_point, delta*vault_speed)
		$CollisionShape3D.disabled = true
		
		global_position = global_position.move_toward(vault_point, delta*vault_speed)
		
		if global_position.distance_to(vault_point) < vault_end_dist:
			global_position = vault_point
			var new_vel = -cam.global_basis.z * vault_stored_velocity.length() * 1.1
			velocity = new_vel
			vault_point = null
			on_floor = true
			cam.position = Vector3.ZERO
			$CollisionShape3D.disabled = false
		
		return
	
	
	autostep()
	slide()
	movement(delta)
	
	if on_floor != was_on_floor and on_floor: AudioPlayer.play_audio("res://Assets/Audio/Effect/jump3.wav", null, Vector2(0.8, 1.2))
	
	if on_floor: %CoyoteTime.start()
	
	update_variables()
	jump_extend(delta)
	can_jump()
	
	wallrun()


func autostep():
	if not move_dir or not on_floor or sliding: return
	
	%AutoStepLowRaycast.target_position = move_dir
	if not %AutoStepLowRaycast.is_colliding(): return
	
	%AutoStepHighRaycast.target_position = move_dir
	%AutoStepHighRaycast.force_raycast_update()
	if not %AutoStepHighRaycast.is_colliding():
		position.y += 0.25
		on_floor = true

func jump_extend(delta):
	if Input.is_action_pressed("space") and not %JumpExtendTime.is_stopped():
		var x = jump_extend_curve.sample_baked(1.0 - %JumpExtendTime.time_left / %JumpExtendTime.wait_time)
		velocity.y += JUMP_EXTEND * delta * x
	
func can_jump():
	var can_jump := false
	
	if sliding:
		can_jump = true
	elif not %DoubleJumpDebounce.is_stopped():
		can_jump = on_floor
	else:
		can_jump = not %CoyoteTime.is_stopped()
	
	if can_jump and not %JumpBuffer.is_stopped():
		jump()

func jump():
	var hvel = velocity - Vector3.UP*velocity.y
	
	%DoubleJumpDebounce.start(%CoyoteTime.wait_time + 0.05)
	%CoyoteTime.stop()
	%JumpBuffer.stop()
	%JumpExtendTime.start()
	
	AudioPlayer.play_audio("res://Assets/Audio/Effect/jump2.wav", null, Vector2(0.8, 1.2))
	
	velocity.y = max(velocity.y, 0) + JUMP_VELOCITY
	
	if wallrunning:
		velocity.y -= 1.2
		#hvel = velocity - Vector3.UP*velocity.y
		#var dot = hvel.normalized().dot(move_dir)
		#print(dot)
		var dir = move_dir
		if not dir: dir = -head.global_basis.z
		velocity = dir * get_max_from_vel_buffer() * 1.4 + Vector3.UP * velocity.y
		return
	
	if sliding:
		stop_sliding()
		velocity = (move_dir + hvel.normalized()).normalized() * hvel.length() + Vector3.UP * velocity.y
	
	%EdgeRaycast.force_raycast_update()
	if not %EdgeRaycast.is_colliding():
		velocity += velocity * JUMP_EDGE_BOOST
		AudioPlayer.play_audio("res://Assets/Audio/Effect/jump3.wav", null, Vector2(2, 3), 10)
	
	
	jump_cutoff_applied = false
	#if not Input.is_action_pressed("space"): jump_cutoff()
	
	#var a = func a():
		#print(get_real_velocity())
		#await get_tree().physics_frame
		#await get_tree().physics_frame
		#print(get_real_velocity())
	#
	#a.call_deferred()

func jump_cutoff():
	if jump_cutoff_applied: return
	
	print("CUTOFFFFFFFFFFFFFF FR")
	
	if velocity.y > 0:
		var extra = velocity.y
		velocity.y -= extra * JUMP_CUTOFF
	
	jump_cutoff_applied = true

func wallrun():
	if wallrunning:
		if on_floor:
			stop_wallrunning()
		if not Input.is_action_pressed("space"):
			jump()
			stop_wallrunning()
	
	if wallrunning == 1:
		%RightWallRaycast.force_raycast_update()
		if not %RightWallRaycast.is_colliding() and %WallrunCoyoteTime.is_stopped(): %WallrunCoyoteTime.start()
	elif wallrunning == -1:
		%LeftWallRaycast.force_raycast_update()
		if not %LeftWallRaycast.is_colliding() and %WallrunCoyoteTime.is_stopped(): %WallrunCoyoteTime.start()


func start_wallrun():
	if on_floor: return
	
	var coll
	if can_wallrun_right:
		%RightWallRaycast.force_raycast_update()
		if %RightWallRaycast.is_colliding():
			coll = %RightWallRaycast.get_collider()
			wallrunning = 1
			can_wallrun_right = false
	
	if can_wallrun_left and not coll:
		%LeftWallRaycast.force_raycast_update()
		if %LeftWallRaycast.is_colliding():
			coll = %LeftWallRaycast.get_collider()
			wallrunning = -1
			can_wallrun_left = false
	
	if wallrunning:
		#if not %WallrunCoyoteTime.is_stopped(): %WallrunCoyoteTime.stop()
		%Sliding.play()

func _on_wallrun_coyote_time_timeout():
	stop_wallrunning()

func stop_wallrunning():
	if not wallrunning: return
	
	wallrunning = 0
	%Sliding.stop()


func update_variables():
	was_on_floor = on_floor
	on_floor = is_on_floor()
	
	coiling = Input.is_action_pressed("shift") and not on_floor
	
	if on_floor:
		can_wallrun_right = true
		can_wallrun_left = true
	
	prev_y = global_position.y
	
	#if sliding:
		#cam.rotation.z = -.05
	#else:
		#cam.rotation.z = 0
	
	update_vel_buffer()

func update_vel_buffer():
	vel_buffer.push_front(velocity)
	if vel_buffer.size() > VEL_BUFFER_SIZE:
		vel_buffer.pop_back()

func get_max_from_vel_buffer():
	var max = -1
	for i in vel_buffer:
		var v = i.length()
		if v > max: max = v
	return max

func slide():
	if not %SlideBuffer.is_stopped() and (was_on_floor or on_floor):
		
		%SlideCooldown.start()
		%SlideBuffer.stop()
		
		sliding = true
		$CollisionShape3D.shape.height = .2
		position.y -= 0.31
		var vel = get_real_velocity()
		var dir = move_dir
		if not dir: dir = -head.global_basis.z
		
		var buffer_max = get_max_from_vel_buffer()
		var max = max(buffer_max, vel.length())
		var diff = max - vel.length()
		var speed = vel.length() + diff * SLIDE_NERF
		velocity = dir * speed
		
		%Slide.pitch_scale = clampf(remap(velocity.length(), 0, 50, 0.8, 1.6), 0.8, 1.6)
		%Slide.play()
		%Sliding.play()
	
	if sliding and on_floor: %SlideOffFloorTimer.start()
	if (Input.is_action_just_released("shift") or velocity.length() < SLIDE_LIMIT or %SlideOffFloorTimer.is_stopped()) and sliding:
		stop_sliding()

func stop_sliding():
	if not sliding: return
	
	%SlideOffFloorTimer.stop()
	%Sliding.stop()
	sliding = false
	position.y += 1
	$CollisionShape3D.shape.height = 2

func movement(delta):
	if not on_floor:
		if was_on_floor: %FastFallTime.start()
		
		var grav = GRAV
		if wallrunning:
			grav = WALLRUN_GRAV
		else:
			#if not Input.is_action_pressed("space"):
				#var x = fast_fall_curve.sample_baked(1.0 - %FastFallTime.time_left / %FastFallTime.wait_time)
				#grav += FAST_FALL_BOOST * x
			if velocity.y < 0.0: grav += FAST_FALL_BOOST
			#if Input.is_action_pressed("ctrl"): grav += SKYDIVE_GRAV_BOOST
			if Input.is_action_just_pressed("ctrl"): velocity.y -= DOWNSHIFT; AudioPlayer.play_audio("res://Assets/Audio/Effect/roll.wav", null, Vector2(2, 3))
		velocity.y += -grav * delta
	
	input_dir = Input.get_vector("a", "d", "w", "s")
	move_dir = (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var hvel := velocity
	hvel.y = 0
	
	#if on_floor:
	var floor_normal = get_floor_normal()
	if floor_normal == Vector3.ZERO: floor_normal = Vector3.UP
	#move_dir = move_dir.slide(floor_normal)
	#hvel = hvel.slide(floor_normal)
	
	
	## Quake-like acceleration toward move_dir
	var wish_dir = move_dir
	var current_speed = velocity.dot(wish_dir)
	var add_speed = MAX_SPEED - current_speed
	
	if add_speed > 0:
		var accel := 0.0
		if sliding:
			accel = SLIDE_ACCELERATION
		elif on_floor:
			accel = FLOOR_ACCELERATION
		else:
			var air_slowdown_assist = 1.0 + AIR_SLOWDOWN_ASSIST * max(-hvel.normalized().dot(wish_dir), 0.0)
			accel = AIR_ACCELERATION * air_slowdown_assist
		
		accel *= delta
		accel = min(accel, add_speed)
		velocity += wish_dir * accel
	
	friction(hvel, wish_dir, delta)
	
	
	move_and_slide()
	
	var current_y = global_position.y
	var y_diff = current_y - prev_y
	
	if sliding and floor_normal != Vector3.UP and y_diff > 0.0:
		velocity = velocity.slide(floor_normal)
		#print("SLIDE %d" % Time.get_ticks_msec())
	
	
	if sliding:
		if y_diff < 0.0:
			velocity += velocity.normalized() * -y_diff * SLIDE_DOWNHILL_BOOST

func friction(hvel : Vector3, wish_dir : Vector3, delta : float):
	
	var wish_dir_compensation = clampf(remap(hvel.length(), MAX_SPEED, WISH_DIR_COMPENSATION_LIMIT, 1, 0), 0, 1)
	#print("wish_dir_compensation: %.2f" % wish_dir_compensation)
	var friction_vec : Vector3 = -hvel.normalized() + wish_dir * wish_dir_compensation
	var friction_amount := 0.0
	
	if not on_floor:
		friction_amount = AIR_FRICTION
	elif sliding:
		friction_amount = SLIDE_FRICTION
	else:
		friction_amount = FLOOR_FRICTION
	
	
	var jitter_fix_max = 2.0
	var too_much_friction_jitter_fix : float = clampf(remap(hvel.length(), 0.0, jitter_fix_max, 0.0, 1.0), 0.0, 1.0)
	velocity += friction_vec * friction_amount * delta * too_much_friction_jitter_fix
	
	
	var extra = hvel.length() - AIR_SPEED_CAP
	if extra > 0.0:
		velocity += friction_vec * extra * AIR_SPEED_CAP_MULT * delta





func _process(delta):
	
	$GPUTrail3D.global_position = lerp($GPUTrail3D.global_position, global_position + cam.global_basis.z * 1, delta*30)
	
	if velocity.length() > 25:
		%Wind.volume_linear = remap(velocity.length(), 25, 50, 0, .4)
		%Wind.pitch_scale = remap(velocity.length(), 25, 50, 0.8, 1.4)
		if not %Wind.playing: %Wind.play()
	else:
		if %Wind.playing: %Wind.stop()
	
	if global_position.y < -20: global_position = Vector3.UP*4; velocity.y = 0.0
