extends AudioStreamPlayer

var beatmap_data = {
	"config": {
		"name": null,
		"creator": null,
		"song": null,
		"duration": 0.0,
		"gamemode": 0,
		"version": 1
	},
	"environment": {
		"environment": [],
		"directional_light": []
	},
	"events": [],
	"beatmap": [],
	"editor": [],
	"geometry": [],
}

var playhead := 0.0:
	set(value):
		playhead = value
		
		if not GameManager.in_editor:
			if playhead >= beatmap_data["config"]["duration"]:
				beatmap_ended()
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

func beatmap_ended(failed = false):
	
	var player = get_tree().get_first_node_in_group("player")
	var end_screen = player.get_node("%UI/%EndScreen")
	end_screen.end(failed)


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

func print_color(target):
	await get_tree().create_timer(.1).timeout
	print("COLOR: %s" % str(target.get_node("Mesh/MeshInstance3D").material_override.albedo_color))

func _process(delta):
	if playback_speed == 0.0: return
	
	if playhead > 0.01 and beatmap_data["config"]["gamemode"] == 1:
		if Utility.get_node_or_null_in_scene("%Beatmap").get_child_count() == 0:
			beatmap_ended()
	
	var playback_delta = playback_speed * delta
	playhead += playback_delta
	
	var beatmap = beatmap_data["beatmap"]
	if event_index >= beatmap.size(): return
	
	
	var spawn_time = get_spawn_time(beatmap[event_index])
	
	if playhead > spawn_time:
		
		var event_data = Utility.remove_sections_from_data(beatmap[event_index])
		
		if "id" in event_data:
			
			var new_prop
			match event_data["id"]:
				Utility.EntityID["TARGET_TAP"]:
					new_prop = Utility.spawn_target(event_data)
					print_color.call_deferred(new_prop)
					
					if GameManager.in_editor:
						auto_pop.call_deferred(new_prop)
				Utility.EntityID["GOAL"]:
					new_prop = Utility.spawn_entity(Utility.PROPS[Utility.EntityID["GOAL"]], GameManager.target_parent, event_data)
			
			event_index += 1
			
			
			
			if event_index >= beatmap.size(): return
			
			if event_data["id"] == Utility.EntityID["TARGET_TAP"] and Utility.remove_sections_from_data(beatmap[event_index-1])["id"] == Utility.EntityID["TARGET_TAP"]:
				spawn_flow_line.call_deferred(event_index)

func get_spawn_time(entity):
	var spawn_time = -1.0
	
	entity = Utility.remove_sections_from_data(entity)
	
	match entity["id"]:
		Utility.EntityID["TARGET_TAP"]:
			spawn_time = entity["pop_time"] - Settings.fadein_time
		Utility.EntityID["GOAL"]:
			spawn_time = entity["start_time"]
	
	return spawn_time




const FLOW_LINE = preload("res://MapPlayer/flow_line.tscn")

func spawn_flow_line(event_index):
	
	var event_data_1 = Utility.remove_sections_from_data(beatmap_data["beatmap"][event_index-1])
	var event_data_2 = Utility.remove_sections_from_data(beatmap_data["beatmap"][event_index])
	
	var pos1 = event_data_1["global_position"]
	var pos2 = event_data_2["global_position"]
	var pos_diff = pos2 - pos1
	
	
	var t1 = event_data_1["pop_time"]
	var t2 = event_data_2["pop_time"]
	var start_diff = t1 - playhead
	var end_diff = t2 - t1
	
	await get_tree().create_timer(start_diff).timeout
	
	var new_flow_line : Node3D = FLOW_LINE.instantiate()
	get_tree().current_scene.add_child(new_flow_line)
	new_flow_line.get_node("AnimationPlayer").speed_scale = 1.0 / end_diff
	#print(end_diff)
	
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
		var value = Utility.get_property_ignoring_sections(beatmap_data["beatmap"][i], "pop_time")
		pop_times.append(value)

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
	#print("SETUP SUCCESSFUL - beatmap_path: %s" % GameManager.beatmap_path)
	
	for i in parsed["beatmap"].size():
		parsed["beatmap"][i] = Utility.convert_vec3s(parsed["beatmap"][i])
		parsed["beatmap"][i] = Utility.convert_ints(parsed["beatmap"][i])
	
	for i in parsed["geometry"].size():
		parsed["geometry"][i] = Utility.convert_colors(parsed["geometry"][i])
		parsed["geometry"][i] = Utility.convert_vec3s(parsed["geometry"][i])
		parsed["geometry"][i] = Utility.convert_ints(parsed["geometry"][i])
	
	parsed["environment"] = Utility.convert_ints(parsed["environment"])
	
	#beatmap_data["beatmap"] = Utility.convert_vec3s(parsed["beatmap"])
	#beatmap_data["beatmap"] = Utility.convert_ints(parsed["beatmap"])
	#beatmap_data["geometry"] = Utility.convert_vec3s(parsed["geometry"])
	#beatmap_data["geometry"] = Utility.convert_ints(parsed["geometry"])
	#beatmap_data["environment"] = Utility.convert_ints(parsed["environment"])
	
	var idxs_to_remove = []
	if parsed["config"]["gamemode"] == 1:
		for i in parsed["beatmap"].size():
			var id = parsed["beatmap"][i]["hidden"]["id"]
			if id == 11:
				parsed["beatmap"][i]["_"]["start_time"] = 0.0
				#parsed["beatmap"][i]["_"]["pop_time"] = 1000.0
			else:
				idxs_to_remove.append(i)
	
	for i in idxs_to_remove:
		parsed["beatmap"].remove_at(i)
	
	
	beatmap_data = parsed
	
	var env_data = beatmap_data["environment"]["environment"]
	var env = Utility.get_node_or_null_in_scene("%Environment")
	Utility.apply_data(env.environment, env_data)
	env.environment.sky.sky_material.set("sky_top_color", str_to_var("Color"+env_data["Sky"]["sky_top_color"]))
	env.environment.sky.sky_material.set("sky_horizon_color", str_to_var("Color"+env_data["Sky"]["sky_horizon_color"]))
	env.environment.sky.sky_material.set("ground_bottom_color", str_to_var("Color"+env_data["Sky"]["ground_bottom_color"]))
	env.environment.sky.sky_material.set("ground_horizon_color", str_to_var("Color"+env_data["Sky"]["ground_horizon_color"]))
	
	for i in beatmap_data["geometry"].size():
		var geometry_data = beatmap_data["geometry"][i]
		Utility.editor_spawn_entity(geometry_data)
	
	if beatmap_data["config"]["song"]: set_song(beatmap_data["config"]["song"])
	
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
	var stream : AudioStream
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
	
	
	if stream != AudioStreamWAV: return
	
	if stream.format != AudioStreamWAV.FORMAT_16_BITS: push_error("NOT 16-BIT"); return
	
	
	# generate waveform
	var waveform_display : TextureRect = Utility.get_node_or_null_in_scene("%Waveform")
	
	waveform_display.show()
	
	var timeline = Utility.get_node_or_null_in_scene("%TimelineSubViewportContainer")
	waveform_display.size.y = timeline.size.y
	waveform_display.size.x = stream.get_length() * timeline.pixels_per_second
	waveform_display.position.x = timeline.timeline_grabber_size
	
	var width := waveform_display.size.x
	var height := waveform_display.size.y
	
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	
	var bytes = stream.get_data()
	var samples_per_pixel = stream.mix_rate / timeline.pixels_per_second
	
	
	for x in range(width):
		var start = int(x * samples_per_pixel) * 2 * (2 if stream.stereo else 1)
		var end = int((x+1) * samples_per_pixel) * 2 * (2 if stream.stereo else 1)
		var max_amp = 0.0
		
		for i in range(start, end, 4 if stream.stereo else 2):
			
			if i >= bytes.size(): continue
			
			# i = start index of left sample
			var left = bytes[i] | (bytes[i+1] << 8)
			if left >= 32768: left -= 65536
			left = abs(left / 32768.0)
			
			var right = 0.0
			if stream.stereo:
				right = bytes[i+2] | (bytes[i+3] << 8)
				if right >= 32768: right -= 65536
				right = abs(right / 32768.0)
			
			var amp = max(left, right) if stream.stereo else left
			if amp > max_amp: max_amp = amp
		
		var loudness = max_amp
		
		var y = (1.0 - loudness) / 2.0 * height
		var h = loudness * height
		
		img.fill_rect(Rect2i(x, y, 1, h), Color(0.9, 0.95, 1, .1))
	
	waveform_display.texture = ImageTexture.create_from_image(img)
