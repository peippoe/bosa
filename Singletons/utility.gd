extends Node



# General utility

func round_float(value : float, rounding : int):
	var r := pow(10, rounding)
	return round(value * r) / r

func get_node_or_null_in_scene(node_path : String):
	return get_tree().current_scene.get_node_or_null(node_path)


func get_slider_value_from_position(pos, slider : Control, axis := 0):
	if slider is not ScrollBar and slider is not Slider: return
	if axis == 0:
		pos = pos.x
		var grabber_size = slider.get_theme_stylebox("grabber").get_minimum_size().x * 2.0
		var value = remap(pos - grabber_size * 0.5, 0, slider.size.x - grabber_size, slider.min_value, slider.max_value)
		return value
	else:
		push_error("Y axis unsupported")


func get_encompassing_rect(control : Control):
	var rect := Rect2()
	var first := true
	
	var children := control.find_children("*", "Control", true, false)
	children.append(control)
	
	for child in children:
		if child is not Control or not child.visible: continue
		
		var child_rect = child.get_global_rect()
		if first:
			rect = child_rect
			first = false
		else:
			rect = rect.merge(child_rect)
	
	return rect



#func _ready():
	#if fd:
		#fd.connect("file_selected", func disconnect_all(_path):
			#await get_tree().physics_frame
			#var connections = fd.get_signal_connection_list("file_selected")
			#for conn in connections: fd.disconnect("file_selected", conn.callable)
		#)


func open_file_dialog(file_location : String, file_mode : FileDialog.FileMode, file_selected_callable : Callable, filters : PackedStringArray = []):
	# disconnect all signals bruh
	var fd = get_node_or_null_in_scene("%FileDialog")
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

func make_materials_unique(mesh_instance : MeshInstance3D):
	var mesh := mesh_instance.mesh
	if not mesh: return
	
	var unique_mesh : Mesh = mesh.duplicate()
	mesh_instance.mesh = unique_mesh
	
	for surface in unique_mesh.get_surface_count():
		var material := unique_mesh.surface_get_material(surface)
		if material:
			var unique_material := material.duplicate()
			unique_mesh.surface_set_material(surface, unique_material)
			print(unique_mesh)



func get_entity_properties(entity : Node):
	if not entity: push_error("NULL ENTITY"); return
	
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
	return new_target

func pop_target(target):
	if not target: return
	if not target.has_method("pop"): return
	target.pop()
	AudioPlayer.play_audio("res://Assets/Audio/Effect/osuhit.ogg", target.global_position, Vector2(0.9, 1.1))
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var timing_indicator = player.get_node("%UI/%TimingIndicator")
	var delta = Playback.playhead - target.pop_time
	timing_indicator.display_point_on_indicator(delta)

func get_pop_timing(pop_time):
	var delta = Playback.playhead - pop_time
	print(delta)
	var abs_delta = absf(delta)
	var pop_timing = 0
	if abs_delta > Settings.POP_TIMING_WINDOWS[Settings.POP_TIMING_WINDOWS.size()-1]: pop_timing = -1
	else:
		for i in Settings.POP_TIMING_WINDOWS.size():
			if abs_delta > Settings.POP_TIMING_WINDOWS[i]:
				continue
			else:
				pop_timing = i
				break
	return pop_timing

func spawn_gizmo(target_data = null):
	
	if not GameManager.in_editor: push_error("NOT IN EDITOR"); return
	
	var map = get_tree().current_scene.get_node("%Map")
	var pos
	var pop_time
	if target_data:
		pos = target_data["global_position"]
		pop_time = target_data["pop_time"]
	else:
		var cam = get_viewport().get_camera_3d()
		pos = cam.global_position + -cam.global_basis.z * 2.0
		pop_time = Playback.playhead
	
	var new_gizmo = Utility.spawn_entity("res://MapEditor/gizmo_target.tscn", map, pos)
	new_gizmo.pop_time = pop_time
	
	var new_marker = Utility.spawn_marker(new_gizmo)
	
	make_materials_unique(new_gizmo)
	
	return [new_gizmo, new_marker]

func spawn_marker(target : Node):
	var new_marker = load("res://MapEditor/marker.tscn").instantiate()
	var timeline = Utility.get_node_or_null_in_scene("%TimelineSlider")
	timeline.add_child(new_marker)
	target.marker = new_marker
	new_marker.set_meta("gizmo", target)
	new_marker.position.x = remap(target.pop_time, 0, timeline.max_value, 0, timeline.size.x)
	new_marker.position.y = 36
	return new_marker

func delete_gizmo(gizmo):
	gizmo.marker.queue_free()
	gizmo.queue_free()
	get_tree().current_scene.set_selected(null)


func spawn_bpm_guide(bpm : float):
	var new_bpm_guide = load("res://MapEditor/bpm_guide.tscn").instantiate()
	var timeline = Utility.get_node_or_null_in_scene("%TimelineSlider")
	timeline.add_child(new_bpm_guide)
	new_bpm_guide.set_meta("start_time", 0.0)
	new_bpm_guide.set_meta("end_time", 1.0)
	new_bpm_guide.set_meta("bpm", bpm)
	new_bpm_guide.position.x = remap(Playback.playhead, 0, timeline.max_value, 0, timeline.size.x)
	new_bpm_guide.position.y = 50
	return new_bpm_guide








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
