extends Node

var hit_sound_path := ""

var fadein_time := 1.0

# hidden settings
const POP_TIMING_WINDOWS = [
	0.010, #perfect
	0.050, #sick
	0.100, #great
	0.150, #ok
]

var input_delay := 0.0



func _ready():
	pass

func set_hit_sound_path(new_path : String):
	if not ResourceLoader.exists(new_path, "AudioStream"):
		print("INVALID AUDIO PATH")
		new_path = "res://Assets/Audio/osuhit.ogg"
	
	print(new_path)
	hit_sound_path = new_path
