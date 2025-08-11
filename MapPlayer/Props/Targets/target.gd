extends RigidBody3D

var pop_time := 0.0:
	set(value):
		pop_time = value
		
		var true_pop_time = Playback.playhead + 1.0 - $AnimationPlayer.current_animation_position
		#print("pop_time: %f, \t true pop time: %f" % [pop_time, true_pop_time])
		
		var pop_time_diff = true_pop_time - pop_time
		$AnimationPlayer.seek($AnimationPlayer.current_animation_position + pop_time_diff)
		
		#print("pop_time: %f, \t true pop time: %f" % [pop_time, Playback.playhead + 1.0 - $AnimationPlayer.current_animation_position])
		
		var timeout = pop_time - Playback.playhead + Settings.POP_TIMING_WINDOWS[3]
		
		#await get_tree().create_timer(timeout).timeout
		%Timeout.start(timeout)
		await %Timeout.timeout
		
		if $waterbloon.visible:
			Utility.on_miss(self.global_position)
			self.queue_free()

func _ready():
	var mat1 = $ShrinkingRing.get_active_material(0).duplicate()
	$ShrinkingRing.set_surface_override_material(0, mat1)
	var mat2 = $ConstantRing.get_active_material(0).duplicate()
	$ConstantRing.set_surface_override_material(0, mat2)
	
	$AnimationPlayer.play("fadein")


func pop():
	$AnimationPlayer.play("pop")
	freeze = true
	$waterbloon.hide()
	$ShrinkingRing.hide()
	$ConstantRing.hide()
	$CollisionShape3D.disabled = true
	await $AnimationPlayer.animation_finished
	queue_free()
