extends Node



# General utility

func round_float(value : float, rounding : int):
	var r := pow(10, rounding)
	return round(value * r) / r



func get_scrollbar_value_from_position(pos, scrollbar : ScrollBar, axis := 0):
	if axis == 0:
		pos = pos.x
		var length = scrollbar.size.x
		var grabber_size = scrollbar.get_theme_stylebox("grabber").get_minimum_size().x
		var click_ratio = clamp((pos - grabber_size * 0.5) / (length - grabber_size), 0.0, 1.0)
		var value = lerp(scrollbar.min_value, scrollbar.max_value, click_ratio)
		return value
	else:
		print("Y axis unsupported")



func get_control_local_position(control):
	return control.global_position - control.get_parent().global_position


func open_fd():
	var fd = FileDialog.new()
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = PackedStringArray(["*.mp3", "*.ogg", "*.wav"])
	add_child(fd)
	fd.popup_centered()
	fd.connect("file_selected", _on_file_selected)

func _on_file_selected(path):
	print(path)








# Entity utility

func spawn_entity(entity := "", parent : Node = null, pos := Vector3.ZERO, randomness := 0.0):
	if not parent: parent = get_tree().current_scene
	
	var new_entity = load(entity).instantiate()
	parent.add_child(new_entity)
	
	var x = Vector3(
		randf_range(-randomness, randomness),
		randf_range(-randomness, randomness),
		randf_range(-randomness, randomness)
	)
	new_entity.global_position = pos + x
	
	return new_entity



func get_entity_properties(entity : Node):
	if not entity: print("NULL ENTITY"); return
	
	var properties = {}
	# Get script properties
	if entity.get_script():
		for property in entity.get_script().get_script_property_list():
			if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE): continue
			if property.name == "node_properties": continue
			properties[property.name] = entity.get(property.name)
	
	# Get specified node properties
	if "node_properties" in entity:
		for key in entity.node_properties:
			if key in entity:
				properties[key] = entity.get(key)
	
	return properties









# Targets utility

const TARGETS = [
	"res://Targets/target.tscn",
]
func spawn_target(target_data):
	return spawn_entity(TARGETS[target_data["type"]], GameManager.target_parent, target_data["global_position"])

func pop_target(target : Node):
	target.queue_free()
	AudioPlayer.play_audio("res://Assets/Audio/osuhit.ogg", target.global_position, Vector2(0.9, 1.1))


func spawn_marker(target : Node):
	var new_marker = load("res://MapEditor/marker.tscn").instantiate()
	var timeline = get_tree().current_scene.get_node("%Timeline")
	timeline.add_child(new_marker)
	target.marker = new_marker
	new_marker.position.x = remap(target.pop_time, 0, timeline.max_value, 0, timeline.size.x)
	return new_marker










# JSON utility

func convert_vec3s(data):
	for target_data in data:
		for key in target_data:
			var value = target_data[key]
			if value is not String: continue
			if not value.begins_with("("): continue
			target_data[key] = str_to_var("Vector3"+value)
	return data

func convert_ints(data):
	for target_data in data:
		for key in target_data:
			if key == "type": target_data[key] = int(target_data[key])
	return data






# Enums

enum TargetType {
	TAP,
	HOLD,
}
