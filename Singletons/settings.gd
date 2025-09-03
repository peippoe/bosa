extends Node

var hit_sound_path := ""

var fadein_time := 1.0

# hidden settings
const POP_TIMING_WINDOWS = [
	0.010, #perfect
	0.070, #sick
	0.140, #great
	0.210, #ok
]

const POINTS_REWARDS = [
	300,
	300,
	200,
	100,
]

var input_delay := 0.0

var target_color_palette := [
	Color.html("0350e7"),
	Color.html("36ffc3"),
]
var target_color_palette_index := 0:
	set(value):
		if value == target_color_palette.size(): value = 0
		target_color_palette_index = value


func _ready():
	pass

func set_hit_sound_path(new_path : String):
	if not ResourceLoader.exists(new_path, "AudioStream"):
		print("INVALID AUDIO PATH")
		new_path = "res://Assets/Audio/osuhit.ogg"
	
	print(new_path)
	hit_sound_path = new_path
