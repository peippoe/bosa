extends Control



var fadein_time := 1.0

# hidden settings
const POP_TIMING_WINDOWS = [
	0.010, #perfect
	0.075, #sick
	0.150, #great
	0.250, #ok
]

const POINTS_REWARDS = [
	300,
	300,
	200,
	100,
]

func get_rank(acc):
	for i in RANKS.size():
		if acc >= RANKS[i]:
			match i:
				0: return "SS"
				1: return "S"
				2: return "A"
				3: return "B"
				4: return "C"
				5: return "D"

const RANKS = [
	100.0,
	95.0,
	90.0,
	85.0,
	75.0,
	0.0
]





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
		"song_offset": 12.0,
	},
	"visual": {
		"fov": 96.0,
		"target_colors": [Color.html("0350e7"), Color.html("36ffc3")],
	},
	"miscellaneous": {
		"debug": false,
	}
}

var target_colors_index := 0:
	set(value):
		if value == config["visual"]["target_colors"].size(): value = 0
		target_colors_index = value



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
			
			var idx = 0
			
			var value = config_file.get_value(section, setting)
			config[section][setting] = value
			
			if value is Array:
				for i in value.size():
					idx = i
					var value_holder = %Settings.get_node(section).get_node(setting).get_node("ValueHolder%d" % idx)
					set_value(value_holder, value[idx])
			else:
				var value_holder = %Settings.get_node(section).get_node(setting).get_node("ValueHolder%d" % idx)
				set_value(value_holder, value)
	
	print(config)

#func config_load_subfunc():
	#

func set_value(value_holder : Node, value):
	match value_holder.get_class():
		"LineEdit":
			value_holder.text = str(value)
		"ColorPickerButton":
			value_holder.color = value
		"CheckBox":
			value_holder.button_pressed = value
		_:
			push_error("UNDEFINED DATA TYPE ERROR #1")

func get_value(value_holder : Node):
	var value = -1
	
	match value_holder.get_class():
		"LineEdit":
			value = value_holder.text
		"ColorPickerButton":
			value = value_holder.color
		"CheckBox":
			value = value_holder.button_pressed
	
	match value_holder.get_meta("data_type"):
		"float": value = float(value)
		"Color": value = value
		"bool": value = bool(value)
		_: push_error("UNDEFINED DATA TYPE ERROR #2")
	
	print(value)
	
	return value



func config_update():
	for section in config.keys():
		for setting in config[section].keys():
			
			var idx = 0
			if config[section][setting] is Array:
				for i in config[section][setting].size():
					idx = i
					var value = config_update_subfunc(setting, section, idx)
					config[section][setting][idx] = value
			else:
				var value = config_update_subfunc(setting, section, idx)
				config[section][setting] = value
	
	print(config)
	
	config_save()

func config_update_subfunc(setting, section, idx):
	var value_holder = %Settings.get_node(section).get_node(setting).get_node("ValueHolder%d" % idx)
	var value = get_value(value_holder)
	return value

func config_save():
	var config_file = ConfigFile.new()
	
	for section in config.keys():
		var section_data = config[section]
		
		for key in section_data.keys():
			var value = section_data[key]
			
			config_file.set_value(section, key, value)
	
	config_file.save("user://config.cfg")
