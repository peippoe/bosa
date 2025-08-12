extends AudioStreamPlayer

var beatmap_data = {
	"config": {
		"name": null,
		"creator": null,
		"song": null,
		"duration": 0.0,
		"version": 1
	},
	"events": [],
	"beatmap": [],
	"editor": [],
}

var playhead := 0.0:
	set(value):
		playhead = value
		
		if not GameManager.in_editor:
			if playhead >= beatmap_data["config"]["duration"]:
				#print(beatmap_data)
				playback_speed = 0
				get_tree().paused = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				var player = get_tree().get_first_node_in_group("player")
				var end_screen = player.get_node("%UI/%EndScreen")
				end_screen.get_node("AnimationPlayer").play("end")
			return
		
		var timeline = Utility.get_node_or_null_in_scene("%TimelineSlider")
		if timeline: timeline.value = playhead
		
		if playback_speed == 0: # Paused Scrubbing
			play(playhead)
			await get_tree().create_timer(.2).timeout
			if playback_speed == 0: stop()
		#else:
			#if not playing or abs(playhead - get_playback_position()) > 0.05: # Scrubbing/Jumping during playback
				#seek(playhead)
				#recalculate_event_index()


var playback_speed := 0.0:
	set(value):
		playback_speed = value
		
		if playback_speed == 0:
			stop()
			if GameManager.in_editor:
				for i in GameManager.target_parent.get_children(): i.queue_free()
		else:
			recalculate_event_index()
			pitch_scale = playback_speed
			if not playing: play(playhead)
			else: seek(playhead)

var event_index = 0

var pop_times = []
var targets = []

func _process(delta):
	if playback_speed == 0.0: return
	
	var playback_delta = playback_speed * delta
	playhead += playback_delta
	
	var beatmap = beatmap_data["beatmap"]
	
	
	if event_index >= beatmap.size(): return
	
	
	var spawn_time = beatmap[event_index].pop_time - Settings.fadein_time
	if "start_time" in beatmap[event_index]: spawn_time = beatmap[event_index].start_time
	
	
	if playhead > spawn_time:
		if "type" in beatmap[event_index]:
			
			var new_prop
			match beatmap[event_index]["type"]:
				Enums.GizmoType.TARGET_TAP:
					new_prop = Utility.spawn_target(beatmap[event_index])
					if GameManager.in_editor:
						auto_pop.call_deferred(new_prop)
				Enums.GizmoType.GOAL:
					new_prop = Utility.spawn_entity(Utility.PROPS[1], GameManager.target_parent, beatmap[event_index])
			
			event_index += 1

func auto_pop(new_target):
	await get_tree().create_timer(new_target.pop_time - playhead).timeout
	Utility.pop_target(new_target)

func sort_beatmap_data():
	beatmap_data["beatmap"].sort_custom(func(a, b):
		return a["pop_time"] < b["pop_time"]
	)

func precompute_pop_times():
	sort_beatmap_data()
	pop_times = [0]
	for i in beatmap_data["beatmap"].size():
		pop_times.append(beatmap_data["beatmap"][i]["pop_time"])

func get_event_index():
	precompute_pop_times()
	for i in pop_times.size() - 1:
		if playhead >= pop_times[i] and playhead < pop_times[i+1]:
			return i
	if playhead >= pop_times[-1]:
		return pop_times.size() - 1

func recalculate_event_index():
	event_index = get_event_index()

func setup():
	var file = FileAccess.open(GameManager.beatmap_path, FileAccess.READ)
	if not file: push_error("INVALID BEATMAP PATH"); return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed: return
	print("SETUP SUCCESSFUL - beatmap_path: %s" % GameManager.beatmap_path)
	
	beatmap_data = parsed
	beatmap_data["beatmap"] = Utility.convert_vec3s(parsed["beatmap"])
	beatmap_data["beatmap"] = Utility.convert_ints(parsed["beatmap"])
	
	set_song(beatmap_data["config"]["song"])
	
	#await get_tree().process_frame
	
	GameManager.combo = 0
	GameManager.points = 0
	GameManager.health = 50
	
	playhead = 0.0
	playback_speed = 1.0
	
	if GameManager.beatmap_path == "res://Scenes/Beatmaps/tutorial.json":
		get_tree().get_first_node_in_group("player").get_node("%UI/%TempTutorialText/AnimationPlayer").play("tutorial_text")
	
	#print(get_playback_position())
	#print(playhead)
	#seek(playhead)



func set_song(song_path):
	if GameManager.in_editor: Utility.get_node_or_null_in_scene("%SongLabel").text = song_path.get_file()
	
	if not FileAccess.file_exists(song_path): song_path = "res://Assets/Audio/Music/" + song_path.get_file()
	var extension = song_path.get_extension()
	var file = FileAccess.open(song_path, FileAccess.READ)
	if not file: push_error("INVALID SONG PATH"); return
	var stream
	match extension:
		"ogg":
			stream = AudioStreamOggVorbis.load_from_file(song_path)
		"wav":
			stream = AudioStreamWAV.load_from_file(song_path)
		"mp3":
			stream = AudioStreamMP3.load_from_file(song_path)
		_:
			push_error("INVALID AUDIO FILE")
	
	Playback.stream = stream
