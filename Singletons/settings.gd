extends Node

var hit_sound_path := ""

var fadein_time := 0.6

# hidden settings
const POP_TIMING_WINDOWS = [
	0.002, #perfect 0-1
	0.040, #sick 1-20
	0.080, #good 20-50
	0.160, #ok 50-100
]

func _ready():
	pass

func set_hit_sound_path(new_path : String):
	if not ResourceLoader.exists(new_path, "AudioStream"):
		print("INVALID AUDIO PATH")
		new_path = "res://Assets/Audio/osuhit.ogg"
	
	print(new_path)
	hit_sound_path = new_path
