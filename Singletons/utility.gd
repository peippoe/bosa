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

func get_position_on_timeline_from_value(value):
	var timeline_grabber_size = get_tree().current_scene.TIMELINE_GRABBER_SIZE
	var timeline_slider = get_node_or_null_in_scene("%TimelineSlider")
	var timeline = get_node_or_null_in_scene("%Timeline")
	return remap(value, timeline_slider.min_value, timeline_slider.max_value, timeline_grabber_size, timeline.size.x - timeline_grabber_size)

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

func spawn_entity(entity := "",  parent : Node = null, data = null):
	if not parent: parent = get_tree().current_scene
	
	var new_entity = load(entity).instantiate()
	parent.add_child(new_entity)
	
	if data: apply_data(new_entity, data)
	
	return new_entity

func apply_data(entity, data):
	for key in data:
		if key in entity:
			entity.set(key, data[key])

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
	#if entity.get_script():
		#for property in entity.get_script().get_script_property_list():
			#if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE): continue
			#if property.name == "node_properties" or property.name == "script_properties": continue
			#properties[property.name] = entity.get(property.name)
	
	# Get specified node properties
	if "ENTITY_PROPERTIES" in entity:
		for key in entity.ENTITY_PROPERTIES:
			if key in entity:
				properties[key] = entity.get(key)
	
	return properties









# Prop utility

const TARGETS = [
	"res://MapPlayer/Props/Targets/target.tscn",
]
func spawn_target(target_data):
	var new_target = spawn_entity(TARGETS[target_data["type"]], GameManager.target_parent, target_data)
	
	var mesh_instance = new_target.get_node("waterbloon/Icosphere")
	make_materials_unique(mesh_instance)
	mesh_instance.mesh.surface_get_material(0).albedo_color = Settings.target_color_palette[Settings.target_color_palette_index]
	Settings.target_color_palette_index += 1
	if Settings.target_color_palette_index == Settings.target_color_palette.size(): Settings.target_color_palette_index = 0
	
	return new_target

func pop_target(target):
	if not target: return
	if not target.has_method("pop"): return
	
	var delta = Playback.playhead - target.pop_time
	
	if delta < -Settings.POP_TIMING_WINDOWS[3]:
		Utility.on_miss(target.global_position)
		target.queue_free()
		return
	
	target.pop()
	AudioPlayer.play_audio("res://Assets/Audio/Effect/hitsound.wav", null, Vector2(0.6, 1.4))
	AudioPlayer.play_audio("res://Assets/Audio/Effect/splash.wav", target.global_position, Vector2(1.5, 2.5))
	
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var timing_indicator = player.get_node("%UI/%TimingIndicator")
	timing_indicator.display_point_on_indicator(delta)
	
	GameManager.health += 5
	GameManager.combo += 1
	GameManager.points += Settings.POINTS_REWARDS[get_pop_timing(target.pop_time)]

func on_miss(pos):
	GameManager.health -= 10
	GameManager.combo = 0
	AudioPlayer.play_audio("res://Assets/Audio/Effect/miss.wav", pos, Vector2(0.9, 1.1))


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

func spawn_gizmo(type, data := {}):
	if not GameManager.in_editor: push_error("NOT IN EDITOR"); return
	var spawned_without_data := data == {}
	
	var gizmo_scene_path
	var new_marker_func : Callable
	var new_gizmo
	match type:
		Enums.GizmoType.TARGET_TAP:
			gizmo_scene_path = "res://MapEditor/GizmoProps/gizmo_target.tscn"
			new_marker_func = Utility.spawn_marker
		Enums.GizmoType.GOAL:
			gizmo_scene_path = "res://MapEditor/GizmoProps/gizmo_goal.tscn"
			new_marker_func = Utility.spawn_start_end_markers
	
	new_gizmo = Utility.spawn_entity(gizmo_scene_path, get_tree().current_scene.get_node("%Map"), data)
	if spawned_without_data:
		var cam = get_viewport().get_camera_3d()
		new_gizmo.global_position = cam.global_position + -cam.global_basis.z * 2.0
		
		if "start_time" in new_gizmo:
			new_gizmo.start_time = Playback.playhead
			new_gizmo.pop_time = Playback.playhead + 1.0
		else:
			new_gizmo.pop_time = Playback.playhead
	
	
	var new_marker = new_marker_func.bind(new_gizmo).call()
	
	
	make_materials_unique(new_gizmo)


func spawn_marker(gizmo : Node):
	var timeline = Utility.get_node_or_null_in_scene("%TimelineSlider")
	var new_marker = load("res://MapEditor/Markers/marker.tscn").instantiate()
	timeline.add_child(new_marker)
	gizmo.marker = new_marker
	new_marker.set_meta("gizmo", gizmo)
	new_marker.position.x = Utility.get_position_on_timeline_from_value(gizmo.pop_time)
	new_marker.position.y = 36
	get_tree().current_scene.connect_marker_signals(new_marker)
	return new_marker

func spawn_start_end_markers(gizmo : Node):
	var timeline = Utility.get_node_or_null_in_scene("%TimelineSlider")
	var new_marker = load("res://MapEditor/Markers/start_end_markers.tscn").instantiate()
	timeline.add_child(new_marker)
	gizmo.marker = new_marker
	#get_tree().current_scene.connect_marker_signals(new_marker.get_child(0))
	#get_tree().current_scene.connect_marker_signals(new_marker.get_child(1))
	return new_marker

func delete_gizmo(gizmo):
	gizmo.marker.queue_free()
	gizmo.queue_free()
	get_tree().current_scene.set_selected(null)


func spawn_gizmo_goal(goal_data = null):
	if not GameManager.in_editor: push_error("NOT IN EDITOR"); return
	


func spawn_bpm_guide(data = null):
	var timeline = Utility.get_node_or_null_in_scene("%TimelineSlider")
	var new_bpm_guide = load("res://MapEditor/Markers/bpm_guide.tscn").instantiate()
	timeline.add_child(new_bpm_guide)
	
	new_bpm_guide.start_time = Playback.playhead
	new_bpm_guide.end_time = new_bpm_guide.start_time + 1.0
	new_bpm_guide.bpm = 60.0
	
	if data: apply_data(new_bpm_guide, data)
	
	new_bpm_guide.position.x = Utility.get_position_on_timeline_from_value(new_bpm_guide.start_time)
	new_bpm_guide.position.y = 50
	get_tree().current_scene.connect_marker_signals(new_bpm_guide)
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
