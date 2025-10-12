extends Path3D

@export var bpm := 120.0

var pop_time : float = 0.0:
	set(value):
		pop_time = value

var end_time : float = 0.0:
	set(value):
		end_time = value
		
		var timeout = end_time - Playback.playhead
		
		%Timeout.start(timeout)
		
		
		
		$PathFollow3D/RigidBody3D/Rings/AnimationPlayer.play("fadein", -1, 1.0 / Settings.fadein_time)
		
		await get_tree().process_frame
		
		var z = pop_time - Playback.playhead
		await get_tree().create_timer(z).timeout
		
		%PingTimer.start(60.0/bpm)
		
		$AnimationPlayer.play("follow", -1, 1.0/timeout)
		await %Timeout.timeout
		#if not Input.is_action_pressed("pop"):
		self.queue_free()


var popped := false

var points := []:
	set(value):
		points = value
		
		curve.clear_points()
		
		for i in points.size():
			curve.add_point(points[i]["pos"], points[i]["in"], points[i]["out"])


func _on_ping_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	var result = player.get_cam_ray_result()
	print(Time.get_ticks_msec())
	if result and result.collider == $PathFollow3D/RigidBody3D and Input.is_action_pressed("pop"):
		Utility.ping_target(self)
	else:
		Utility.on_miss(self.global_position)
