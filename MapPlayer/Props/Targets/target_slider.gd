extends Node3D

@export var bpm := 120.0

var pop_time : float = 0.0:
	set(value):
		pop_time = value

var end_time : float = 0.0:
	set(value):
		end_time = value
		
		var timeout = end_time - Playback.playhead
		
		%Timeout.start(timeout)
		
		
		
		$Path3D/PathFollow3D/RigidBody3D/Rings/AnimationPlayer.play("fadein", -1, 1.0 / Settings.fadein_time)
		
		await get_tree().process_frame
		
		var z = pop_time - Playback.playhead
		await get_tree().create_timer(z).timeout
		
		%PingTimer.start(60.0/bpm)
		
		var tween = get_tree().create_tween()
		tween.tween_property($Path3D/PathFollow3D, "progress_ratio", 1.0, end_time - Playback.playhead)
		
		var end = pop_time + Settings.POP_TIMING_WINDOWS[3] - Playback.playhead + 0.04
		await get_tree().create_timer(end).timeout
		if not popped:
			Utility.on_miss(self.global_position)
		
		await %Timeout.timeout
		#if not Input.is_action_pressed("pop"):
		# slider end thingy here
		self.queue_free()


var popped := false

var points := []:
	set(value):
		points = value
		
		%Path3D.curve.clear_points()
		
		for i in points.size():
			%Path3D.curve.add_point(points[i]["pos"], points[i]["in"], points[i]["out"])


func _on_ping_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	var result = player.get_cam_ray_result()
	
	if result and result.collider == $Path3D/PathFollow3D/RigidBody3D and Input.is_action_pressed("pop"):
		Utility.ping_target(self)
	else:
		Utility.on_miss(self.global_position)
