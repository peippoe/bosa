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
	
	
	var spawn_time = get_spawn_time(beatmap[event_index])
	
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
			
			
			if event_index >= beatmap.size(): return
			
			if beatmap[event_index]["type"] == Enums.GizmoType.TARGET_TAP and beatmap[event_index-1]["type"] == Enums.GizmoType.TARGET_TAP:
				spawn_flow_line.call_deferred(event_index)

func get_spawn_time(entity):
	var spawn_time = -1.0
	
	match entity["type"]:
		Enums.GizmoType.TARGET_TAP:
			spawn_time = entity["pop_time"] - Settings.fadein_time
		Enums.GizmoType.GOAL:
			spawn_time = entity["start_time"]
	
	return spawn_time




const FLOW_LINE = preload("res://MapPlayer/flow_line.tscn")

func spawn_flow_line(event_index):
	
	var pos1 = beatmap_data["beatmap"][event_index-1]["global_position"]
	var pos2 = beatmap_data["beatmap"][event_index]["global_position"]
	var pos_diff = pos2 - pos1
	
	
	var t1 = beatmap_data["beatmap"][event_index-1]["pop_time"]
	var t2 = beatmap_data["beatmap"][event_index]["pop_time"]
	var start_diff = t1 - playhead
	var end_diff = t2 - t1
	
	await get_tree().create_timer(start_diff).timeout
	
	var new_flow_line : Node3D = FLOW_LINE.instantiate()
	get_tree().current_scene.add_child(new_flow_line)
	new_flow_line.get_node("AnimationPlayer").speed_scale = 1.0 / end_diff
	print(end_diff)
	
	new_flow_line.look_at_from_position(pos1 + pos_diff * 0.5, pos2)
	new_flow_line.scale = Vector3(1, 1, pos_diff.length())
	print("flow line #%d" % event_index)

func auto_pop(new_target):
	await get_tree().create_timer(new_target.pop_time - playhead).timeout
	Utility.pop_target(new_target)

func sort_beatmap_data():
	beatmap_data["beatmap"].sort_custom(func(a, b):
		return Playback.get_spawn_time(a) < Playback.get_spawn_time(b)
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



func set_song(song_path : String):
	var stream
	print(song_path)
	if song_path.begins_with("res://"):
		
		stream = ResourceLoader.load(song_path)
		if not stream: push_error("FAILED TO LOAD SONG"); return
		
	elif song_path.begins_with("user://"):
		
		var file = FileAccess.open(song_path, FileAccess.READ)
		if not file: push_error("INVALID SONG PATH"); return
		match song_path.get_extension():
			"ogg":
				stream = AudioStreamOggVorbis.load_from_file(song_path)
			"wav":
				stream = AudioStreamWAV.load_from_file(song_path)
			"mp3":
				stream = AudioStreamMP3.load_from_file(song_path)
			_:
				push_error("INVALID AUDIO FILE"); return
	else:
		push_error("UNSUPPORTED FILE PATH"); return
	
	if GameManager.in_editor: Utility.get_node_or_null_in_scene("%SongLabel").text = song_path.get_file()
	Playback.stream = stream
