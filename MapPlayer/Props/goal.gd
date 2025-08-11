extends Area3D

var pop_time := 0.0:
	set(value):
		pop_time = value
		
		AudioPlayer.play_audio("res://Assets/Audio/Effect/goal_spawned.wav", self.global_position, Vector2(0.9, 1.1))
		
		await get_tree().create_timer(pop_time - Playback.playhead).timeout
		
		var player_inside := false
		for i in get_overlapping_bodies():
			if i.is_in_group("player"):
				player_inside = true
				break
		
		print("PLAYER INSIDE? %s" % player_inside)
		
		if GameManager.in_editor: player_inside = true
		
		if not player_inside:
			Utility.on_miss(self.global_position)
		else:
			AudioPlayer.play_audio("res://Assets/Audio/Effect/goal_completed.wav", self.global_position, Vector2(0.9, 1.1))
		
		self.queue_free()

func setup():
	pass

func _ready():
	pass
