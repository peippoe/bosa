extends Control



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

var target_color_palette := [
	Color.html("0350e7"),
	Color.html("36ffc3"),
]
var target_color_palette_index := 0:
	set(value):
		if value == target_color_palette.size(): value = 0
		target_color_palette_index = value



var hit_sound_path := ""

func set_hit_sound_path(new_path : String):
	if not ResourceLoader.exists(new_path, "AudioStream"):
		print("INVALID AUDIO PATH")
		new_path = "res://Assets/Audio/osuhit.ogg"
	
	print(new_path)
	hit_sound_path = new_path









var config : Dictionary = {
	"gameplay": {
		"mouse_sensitivity": 1.0,
	}
}

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			hide()

func _ready():
	hide()
	
	%Apply.pressed.connect(update_config)
	%Close.pressed.connect(func close(): hide())
	
	# load

func update_config():
	for child in %Settings.get_children():
		if child.name.begins_with("/"): continue
		
		var line_edit = child.get_node("LineEdit")
		var value = line_edit.text
		
		match line_edit.get_meta("data_type"):
			"float": value = float(value)
			_: push_error("UNDEFINED LINE EDIT DATA TYPE")
		
		config["gameplay"][child.name] = value
	
	print(config)
	
	config_save()

func config_save():
	var config_file = ConfigFile.new()
	
	
	for section in config.keys():
		
		var section_data = config[section]
		
		for key in section_data.keys():
			var value = section_data[key]
			
			config_file.set_value(section, key, value)
	
	config_file.save("user://config.cfg")

func config_load():
	pass
