extends Node


func play_audio(audio_path, pos = null, min_max := Vector2(1.0, 1.0), volume := 0.0):
	var stream = load(audio_path)
	
	var new_audio
	if pos:
		new_audio = AudioStreamPlayer3D.new()
	else:
		new_audio = AudioStreamPlayer.new()
	
	get_tree().current_scene.add_child(new_audio)
	if pos: new_audio.global_position = pos
	new_audio.stream = stream
	new_audio.pitch_scale = randf_range(min_max.x, min_max.y)
	new_audio.volume_db = volume
	new_audio.play()
	
	call_deferred("delayed_free", new_audio)



func delayed_free(audio):
	await audio.finished
	audio.queue_free()



var music_bus_index = AudioServer.get_bus_index("Music")
var current_loudness := 0.0
const SMOOTHING := 30.0

func _process(delta):
	var peak_db = max(AudioServer.get_bus_peak_volume_left_db(music_bus_index, 0), AudioServer.get_bus_peak_volume_right_db(music_bus_index, 0))
	
	var peak_linear = db_to_linear(peak_db)
	current_loudness = lerp(current_loudness, peak_linear, delta * SMOOTHING)
