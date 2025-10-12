extends RigidBody3D

var pop_time := 0.0:
	set(value):
		pop_time = value
		
		var true_pop_time = Playback.playhead + 1.0 - $Rings/AnimationPlayer.current_animation_position
		var pop_time_diff = true_pop_time - pop_time
		$Rings/AnimationPlayer.seek($Rings/AnimationPlayer.current_animation_position + pop_time_diff)
		
		print("pop_time: %f, \t true pop time: %f" % [pop_time, Playback.playhead + 1.0 - $Rings/AnimationPlayer.current_animation_position])
		
		#var a : AudioStreamPlayer
		print("SPAWNED")
		print(Playback.playhead)
		print(Playback.get_playback_position())
		print(AudioServer.get_output_latency())
		
		var timeout = pop_time - Playback.playhead + Settings.POP_TIMING_WINDOWS[3]
		
		#await get_tree().create_timer(timeout).timeout
		%Timeout.start(timeout)
		await %Timeout.timeout
		
		if $Mesh.visible:
			Utility.on_miss(self.global_position)
			self.queue_free()


func _ready():
	var mat1 = %ShrinkingRing.get_active_material(0).duplicate()
	%ShrinkingRing.set_surface_override_material(0, mat1)
	var mat2 = %ConstantRing.get_active_material(0).duplicate()
	%ConstantRing.set_surface_override_material(0, mat2)
	
	$Rings/AnimationPlayer.play("fadein", -1, 1.0 / Settings.fadein_time)
	
	await get_tree().process_frame
	
	var s = (scale.x+scale.y+scale.z)/3.0 * 2
	%ShrinkingRing.mesh.size = Vector2.ONE * s
	%ConstantRing.mesh.size = Vector2.ONE * s


func pop():
	$Rings/AnimationPlayer.play("pop")
	freeze = true
	
	$Mesh.hide()
	%ShrinkingRing.hide()
	%ConstantRing.hide()
	$CollisionShape3D.disabled = true
	await $Rings/AnimationPlayer.animation_finished
	queue_free()
