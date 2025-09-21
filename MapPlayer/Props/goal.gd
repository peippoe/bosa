extends Area3D

var pop_time := 0.0:
	set(value):
		pop_time = value
		
		#push_error("TRIGGERED")
		AudioPlayer.play_audio("res://Assets/Audio/Effect/goal_spawned.wav", self.global_position, Vector2(0.9, 1.1))
		
		await get_tree().create_timer(pop_time - Playback.playhead).timeout
		
		#var player_inside := false
		#if GameManager.in_editor:
			#player_inside = true
		#else:
			#for i in get_overlapping_bodies():
				#if i.is_in_group("player"):
					#player_inside = true
					#break
		
		
		#if not player_inside:
		Utility.on_miss(self.global_position)
		#else:
			#AudioPlayer.play_audio("res://Assets/Audio/Effect/goal_completed.wav", self.global_position, Vector2(0.9, 1.1))
		
		self.queue_free()


func _ready():
	body_entered.connect(func body_entered(body):
			if body.is_in_group("player"):
				AudioPlayer.play_audio("res://Assets/Audio/Effect/goal_completed.wav", self.global_position, Vector2(0.9, 1.1))
				queue_free()
			)
