extends AudioStreamPlayer

const CURRENT_BEATMAP_VERSION := 1

var beatmap_data = {
	"config": {
		"name": null,
		"creator": null,
		"song": null,
		"version": CURRENT_BEATMAP_VERSION
	},
	"events": [],
	"beatmap": [],
	"editor": [],
}

var playhead := 0.0:
	set(value):
		playhead = value
		
		if not GameManager.in_editor: return
		
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
	
	if event_index < beatmap.size() and playhead > beatmap[event_index]["pop_time"] - Settings.fadein_time:
		var new_target = Utility.spawn_target(beatmap[event_index])
		event_index += 1
		if GameManager.in_editor:
			auto_pop.call_deferred(new_target)

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
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed: return
	print("SETUP SUCCESSFUL - beatmap_path: %s" % GameManager.beatmap_path)
	beatmap_data["beatmap"] = Utility.convert_vec3s(parsed["beatmap"])
