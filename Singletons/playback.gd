extends AudioStreamPlayer

var beatmap_data = []
var playback_speed := 0.0
var playhead := 0.0

var event_index = 0
var fadein_index = 0
var fadein_time := 0.4

var targets = []
var fadeins = []

func _process(delta):
	if playback_speed == 0.0: return
	
	var playback_delta = playback_speed * delta
	playhead += playback_delta
	if not playing: play(playhead)
	
	
	if event_index < beatmap_data.size() and playhead > beatmap_data[event_index]["pop_time"]:
		UtilityFunctions.spawn_target(beatmap_data[event_index])
		event_index += 1
	elif fadein_index < beatmap_data.size() and playhead > beatmap_data[fadein_index]["pop_time"] - fadein_time:
		var new_fadein = UtilityFunctions.spawn_entity("res://MapPlayer/fadein_target.tscn", null, beatmap_data[fadein_index]["pos"])
		new_fadein.set_meta("start", playhead)
		new_fadein.set_meta("end", playhead + fadein_time)
		fadein_index += 1
		fadeins.append(new_fadein)
	
	for i in fadeins:
		var alpha = remap(playhead, i.get_meta("start"), i.get_meta("end"), 0, 1)
		i.scale = Vector3.ONE * alpha
		if alpha > 1: i.queue_free(); fadeins.remove_at(0)


func setup_signals():
	if not GameManager.in_editor: return
	print("SETUP SIGNA")
	get_tree().current_scene.get_node("%Timeline").scrolling.connect(timeline_scrolling)

func timeline_scrolling():
	print(Time.get_ticks_msec())

func setup():
	var file = FileAccess.open(GameManager.beatmap_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed: return
	beatmap_data = convert_vec3s(parsed)

func convert_vec3s(data):
	for target_data in data:
		for key in target_data:
			var value = target_data[key]
			if value is not String: continue
			if not value.begins_with("("): continue
			target_data[key] = str_to_var("Vector3"+value)
	return data
