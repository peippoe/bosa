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
	
	%Apply.pressed.connect(config_update)
	%Close.pressed.connect(func close(): hide())
	
	config_load()

func config_load():
	var config_file = ConfigFile.new()
	var err = config_file.load("user://config.cfg")
	
	if err != OK: push_error("CONFIG LOAD ERROR"); return
	
	
	for section in config.keys():
		for setting in config[section].keys():
			
			var value = config_file.get_value(section, setting)
			config[section][setting] = value
			
			var value_holder = %Settings.get_node(section).get_node(setting).get_node("ValueHolder")
			set_value(value_holder, value)
	
	print(config)


func set_value(value_holder : Node, value):
	match value_holder.get_class():
		"LineEdit":
			value_holder.text = str(value)
		_: push_error("UNDEFINED DATA TYPE ERROR #1")

func get_value(value_holder : Node):
	var value = -1
	
	match value_holder.get_class():
		"LineEdit":
			value = value_holder.text
	
	match value_holder.get_meta("data_type"):
		"float": value = float(value)
		_: push_error("UNDEFINED DATA TYPE ERROR #2")
	
	print(value)
	
	return value



func config_update():
	#for child in %Settings.get_children():
		#if child.name.begins_with("/"): continue
		#
		#var value_holder = child.get_node("ValueHolder")
		#var value = get_value(value_holder)
		#
		#config["gameplay"][child.name] = value
	
	for section in config.keys():
		for setting in config[section].keys():
			
			var value_holder = %Settings.get_node(section).get_node(setting).get_node("ValueHolder")
			var value = get_value(value_holder)
			print(value_holder)
			config[section][setting] = value
	
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
