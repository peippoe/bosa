extends Node


var music_bus_index = AudioServer.get_bus_index("Music")
@onready var parent = get_parent()
func _ready():
	parent.pivot_offset = parent.size / 2.0

var current_scale := Vector2.ONE
var current_loudness := 0.0
const SMOOTHING := 25.0

func _process(delta):
	var peak_db = max(AudioServer.get_bus_peak_volume_left_db(music_bus_index, 0), AudioServer.get_bus_peak_volume_right_db(music_bus_index, 0))
	
	var peak_linear = db_to_linear(peak_db)
	current_loudness = lerp(current_loudness, peak_linear, delta * SMOOTHING)
	
	#var exp := 2.0
	#var mult := 2.0
	#var adjusted = pow(peak_linear * mult, exp) / pow(mult, exp)
	
	var target_scale = lerp(0.95, 1.0, current_loudness)
	#current_scale = current_scale.lerp(Vector2.ONE * target_scale, delta * SMOOTHING)
	
	#print("%.2f, %.2f" % [current_loudness, peak_linear])
	parent.scale = Vector2.ONE * target_scale
