extends AudioStreamPlayer

var beatmap_data = []

var playhead := 0.0:
	set(value):
		playhead = value
		
		if not GameManager.in_editor: return
		
		var timeline = get_tree().current_scene.get_node_or_null("%Timeline")
		if timeline: timeline.value = playhead
		
		if playback_speed == 0: # Paused Scrubbing
			play(playhead)
			await get_tree().create_timer(.2).timeout
			if playback_speed == 0: stop()
		else:
			if not playing or abs(playhead - get_playback_position()) > 0.05: # Scrubbing/Jumping during playback
				seek(playhead)
				recalculate_event_index()


var playback_speed := 0.0:
	set(value):
		playback_speed = value
		
		if playback_speed == 0:
			stop()
		else:
			recalculate_event_index()
			pitch_scale = playback_speed
			if not playing: play(playhead)
			else: seek(playhead)

var event_index = 0
var fadein_index = 0
var fadein_time := 0.6

var pop_times = []
var targets = []
var fadeins = []

func _process(delta):
	if playback_speed == 0.0: return
	
	var playback_delta = playback_speed * delta
	playhead += playback_delta
	
	if event_index < beatmap_data.size() and playhead > beatmap_data[event_index]["pop_time"]:
		var new_target = Utility.spawn_target(beatmap_data[event_index])
		event_index += 1
		if GameManager.in_editor:
			Utility.pop_target(new_target)
		
	elif fadein_index < beatmap_data.size() and playhead > beatmap_data[fadein_index]["pop_time"] - fadein_time:
		var new_fadein = Utility.spawn_entity("res://MapPlayer/fadein_target.tscn", null, beatmap_data[fadein_index]["global_position"])
		new_fadein.set_meta("start", playhead)
		new_fadein.set_meta("end", playhead + fadein_time)
		fadein_index += 1
		fadeins.append(new_fadein)
	
	for i in fadeins:
		var alpha = remap(playhead, i.get_meta("start"), i.get_meta("end"), 0, 1)
		i.scale = Vector3.ONE * alpha
		if alpha > 1: i.queue_free(); fadeins.remove_at(0)

func sort_beatmap_data():
	beatmap_data.sort_custom(func(a, b):
		return a["pop_time"] < b["pop_time"]
	)

func precompute_pop_times():
	sort_beatmap_data()
	pop_times = [0]
	for i in beatmap_data.size():
		pop_times.append(beatmap_data[i]["pop_time"])

func get_event_index():
	precompute_pop_times()
	for i in pop_times.size() - 1:
		if playhead >= pop_times[i] and playhead < pop_times[i+1]:
			return i
	if playhead >= pop_times[-1]:
		return pop_times.size() - 1

func recalculate_event_index():
	event_index = get_event_index()
	fadein_index = event_index

func setup():
	var file = FileAccess.open(GameManager.beatmap_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed: return
	beatmap_data = Utility.convert_vec3s(parsed)
