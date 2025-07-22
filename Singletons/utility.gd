extends Node



# General utility

func round_float(value : float, rounding : int):
	var r := pow(10, rounding)
	return round(value * r) / r

func get_node_or_null_in_scene(node_path : String):
	return get_tree().current_scene.get_node_or_null(node_path)


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


@onready var fd = get_node_or_null_in_scene("%FileDialog")
#func _ready():
	#if fd:
		#fd.connect("file_selected", func disconnect_all(_path):
			#await get_tree().physics_frame
			#var connections = fd.get_signal_connection_list("file_selected")
			#for conn in connections: fd.disconnect("file_selected", conn.callable)
		#)


func open_file_dialog(file_location : String, file_mode : FileDialog.FileMode, file_selected_callable : Callable, filters : PackedStringArray = []):
	# disconnect all signals bruh
	var connections = fd.get_signal_connection_list("file_selected")
	for conn in connections: fd.disconnect("file_selected", conn.callable)
	
	file_location = ProjectSettings.globalize_path(file_location)
	ensure_dir_exists(file_location)
	
	fd = get_node_or_null_in_scene("%FileDialog")
	if not fd: push_error("NO FILE DIALOG"); return
	fd.current_dir = file_location
	fd.file_mode = file_mode
	fd.filters = filters
	fd.popup_centered()
	fd.connect("file_selected", file_selected_callable)


func ensure_dir_exists(absolute_path : String):
	if not DirAccess.dir_exists_absolute(absolute_path):
		var err := DirAccess.make_dir_recursive_absolute(absolute_path)
		if err != OK: push_error("Could not create folder '%s' (error %d)" % [absolute_path, err])







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
	var new_target = spawn_entity(TARGETS[target_data["type"]], GameManager.target_parent, target_data["global_position"])
	new_target.pop_time = target_data["pop_time"]
	print("AAAAAAAAAAAAAAA")
	return new_target

func pop_target(target):
	if not target: return
	if not target.has_method("pop"): return
	target.pop()
	#AudioPlayer.play_audio("res://Assets/Audio/Effect/osuhit.ogg", target.global_position, Vector2(0.9, 1.1))

func get_pop_timing(pop_time):
	var diff = absf(Playback.playhead - pop_time)
	print(diff)
	var pop_timing = 0
	for i in Settings.POP_TIMING_WINDOWS.size():
		if diff > Settings.POP_TIMING_WINDOWS[i]:
			continue
		else:
			pop_timing = Settings.POP_TIMING_WINDOWS[i]
			break
	
	return pop_timing


func spawn_marker(target : Node):
	var new_marker = load("res://MapEditor/marker.tscn").instantiate()
	var timeline = Utility.get_node_or_null_in_scene("%Timeline")
	timeline.add_child(new_marker)
	target.marker = new_marker
	new_marker.set_meta("gizmo", target)
	new_marker.position.x = remap(target.pop_time, 0, timeline.max_value, 0, timeline.size.x)
	return new_marker

func delete_gizmo(gizmo):
	gizmo.marker.queue_free()
	gizmo.queue_free()
	get_tree().current_scene.set_selected(null)







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
