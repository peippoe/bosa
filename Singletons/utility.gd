extends Node



# General utility

func round_float(value : float, rounding : int):
	var r := pow(10, rounding)
	return round(value * r) / r

func get_node_or_null_in_scene(node_path : String):
	if not get_tree().current_scene: return null
	var node_or_null = get_tree().current_scene.get_node_or_null(node_path)
	if not node_or_null: push_error("%s NOT FOUND IN SCENE" % node_path)
	return node_or_null


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

func spawn_entity(entity,  parent : Node = null, data = null):
	var new_entity
	if entity is String: new_entity = load(entity).instantiate()
	else: new_entity = entity.instantiate()
	
	if not parent: parent = get_tree().current_scene
	parent.add_child(new_entity)
	
	if data: apply_data(new_entity, data)
	
	return new_entity


func apply_data(entity, data):
	for section in data.keys():
		
		var section_data = data[section]
		
		if section_data is not Dictionary: section_data = data # part 1
		
		for property in section_data.keys():
			if "ENTITY_RESOURCES" in entity:
				
				for res in entity.ENTITY_RESOURCES:
					if property in res:
						res.set(property, section_data[property])
			else:
				if property in entity:
					##print("ENTITY.SET %s = %s" % [str(property), str(section_data[property])])
					entity.set(property, section_data[property])
		
		if section_data == data: break # part 2

func make_mesh_unique(mesh_instance : MeshInstance3D):
	var mesh := mesh_instance.mesh
	if not mesh: return
	
	var unique_mesh : Mesh = mesh.duplicate()
	mesh_instance.mesh = unique_mesh

func make_surface_materials_unique(mesh_instance : MeshInstance3D):
	
	make_mesh_unique(mesh_instance)
	
	var mesh = mesh_instance.mesh
	
	for surface in mesh.get_surface_count():
		var material := mesh.surface_get_material(surface)
		if material:
			var unique_material := material.duplicate()
			mesh.surface_set_material(surface, unique_material)

func get_property_ignoring_sections(data, target_property : String):
	for section in data.keys():
		for property in data[section].keys():
			if property == target_property:
				return data[section][property]

func remove_sections_from_data_array(data):
	for i in data.size():
		data[i] = Utility.remove_sections_from_data(data[i])
	return data

func remove_sections_from_data(data):
	var sectionless_data = {}
	
	for section in data.keys():
		if data[section] is not Dictionary:
			return data
		
		for property in data[section].keys():
			var value = data[section][property]
			sectionless_data[property] = value
	
	return sectionless_data


func get_entity_properties(entity : Node):
	if not entity: push_error("NULL ENTITY"); return
	if not "ENTITY_PROPERTIES" in entity: push_error("NO ENTITY_PROPERTIES"); return
	if not "ENTITY_RESOURCES" in entity: push_error("NO ENTITY_RESOURCES"); return
	
	var properties = {}
	
	var entity_resources = entity.ENTITY_RESOURCES
	var entity_properties = entity.ENTITY_PROPERTIES
	
	
	for section in entity_properties.keys():
		properties[section] = {}
	
	for res in entity_resources:
		for section in entity_properties.keys():
			
			for property in entity_properties[section]:
				if property in res:
					properties[section][property] = res[property]
	
	return properties









# Prop utility

const EntityID : Dictionary = {
	"TARGET_TAP": 10,
	"GOAL": 11,
	"SLIDER": 12,
	
	"BLOCK": 20,
	"RAMP": 21,
	"CYLINDER": 22,
	"SPHERE": 23,
	
	"BOOST_PAD": 30,
	
	"LABEL": 40,
}

const PROPS : Dictionary = {
	10: preload("res://MapPlayer/Props/Targets/target.tscn"),
	11: preload("res://MapPlayer/Props/goal.tscn"),
	12: preload("res://MapPlayer/Props/Targets/target_track.tscn"),
	
	20: "res://MapEditor/Geometry/block.tscn",
	21: "res://MapEditor/Geometry/ramp.tscn",
	22: "res://MapEditor/Geometry/cylinder.tscn",
	23: "res://MapEditor/Geometry/sphere.tscn",
	
	30: "res://MapEditor/GizmoProps/gizmo_boost_pad.tscn",
	
	40: "res://MapEditor/Geometry/label.tscn"
}


func editor_spawn_entity(data):
	data = remove_sections_from_data(data)
	
	var new_editor_entity
	var first_digit = int(str(data["id"])[0])
	match first_digit:
		1:
			match data["id"]:
				10, 11:
					new_editor_entity = Utility.spawn_gizmo(data["id"], data)
				12:
					new_editor_entity = Utility.spawn_gizmo(data["id"], data)
		2:
			new_editor_entity = Utility.spawn_geometry(data)
		3, 4:
			new_editor_entity = Utility.spawn_entity(PROPS[data["id"]], get_node_or_null_in_scene("%Geometry"), data)
	
	return new_editor_entity

func spawn_geometry(data):
	var geometry = spawn_entity(load(PROPS[data["id"]]), get_node_or_null_in_scene("%Geometry"), data)

func spawn_target(target_data):
	var new_target = spawn_entity(Utility.PROPS[target_data["id"]], GameManager.target_parent, target_data)
	print("SPAWNED TARGET")
	var mesh_instance : MeshInstance3D = new_target.get_node("Mesh/MeshInstance3D")
	#make_mesh_unique(mesh_instance)
	mesh_instance.material_override = mesh_instance.material_override.duplicate()
	
	mesh_instance.material_override.albedo_color = Settings.config["visual"]["target_colors"][Settings.target_colors_index]
	Settings.target_colors_index += 1
	
	var scale = target_data["scale"]
	if scale.x != scale.y or scale.x != scale.z or scale.y != scale.z:
		
		new_target.scale = Vector3.ONE
		
		var original_mesh : SphereMesh = mesh_instance.mesh
		var shape = ConvexPolygonShape3D.new()
		var points: PackedVector3Array = PackedVector3Array()
		var radius = original_mesh.radius
		var height_segments = original_mesh.rings
		var radial_segments = original_mesh.radial_segments
		
		for i in range(height_segments + 1):
			var theta = float(i) / height_segments * PI
			for j in range(radial_segments):
				var phi = float(j) / radial_segments * TAU
				var x = radius * sin(theta) * cos(phi)
				var y = radius * cos(theta)
				var z = radius * sin(theta) * sin(phi)
				points.append(Vector3(x, y, z) * target_data["scale"])
		
		shape.points = points
		new_target.get_child(0).shape = shape
		mesh_instance.scale = target_data["scale"]
	
	return new_target


func ping_target(target):
	AudioPlayer.play_audio("res://Assets/Audio/Effect/hitsound.wav", null, Vector2(0.6, 1.4))
	
	GameManager.health += 1
	GameManager.combo += 1
	GameManager.points += 10

func pop_target(target):
	if not target: return
	
	
	var delta = Playback.playhead - target.pop_time
	#print("DELTA: %f" % delta)
	if absf(delta) > Settings.POP_TIMING_WINDOWS[3]:
		Utility.on_miss(target.global_position)
		if not "bpm" in target:
			target.queue_free()
		return
	
	if target.has_method("pop"): target.pop()
	#AudioPlayer.play_audio("res://Assets/Audio/Effect/hitsound.wav", null, Vector2(0.6, 1.4))
	#AudioPlayer.play_audio("res://Assets/Audio/Effect/splash.wav", target.global_position, Vector2(1.5, 2.5))
	
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var timing_indicator = player.get_node("%UI/%TimingIndicator")
	timing_indicator.display_point_on_indicator(delta)
	
	var new_pop_up := Label3D.new()
	get_tree().current_scene.add_child(new_pop_up)
	new_pop_up.text = "%dms" % int(delta * 1000)
	#new_pop_up.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	new_pop_up.look_at_from_position(target.global_position + Vector3.UP*.5, player.global_position, Vector3.UP, true)
	new_pop_up.rotation.z = randf_range(-1,1)
	new_pop_up.scale = Vector3.ONE * 0.1
	new_pop_up.no_depth_test = true
	new_pop_up.double_sided = false
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_ELASTIC)
	
	tween.tween_property(new_pop_up, "scale", Vector3.ONE * 1.0, .1).set_trans(Tween.TRANS_BOUNCE)
	
	tween.tween_property(new_pop_up, "position", new_pop_up.position + Vector3(0, .2, 0), .5)
	tween.set_parallel(true)
	#tween.tween_property(new_pop_up, "modulate", Color(1, 1, 1, 0), .5)
	tween.tween_property(new_pop_up, "scale", Vector3.ZERO, .5)
	tween.tween_property(new_pop_up, "rotation", new_pop_up.rotation + Vector3.FORWARD * randf_range(-1,1), .5).set_trans(Tween.TRANS_BOUNCE)
	tween.set_parallel(false)
	tween.tween_callback(new_pop_up.queue_free)
	
	GameManager.health += 5
	GameManager.combo += 1
	GameManager.points += Settings.POINTS_REWARDS[get_pop_timing(target.pop_time)]
	
	var pop_timing = get_pop_timing(target.pop_time)
	if pop_timing <= 1:
		AudioPlayer.play_audio("res://Assets/Audio/Effect/osuhit.ogg", null, Vector2(2, 4), -10)
		if target.get_node("Effect"): target.get_node("Effect").show()
	print("POP_TIMING %d" % pop_timing)

func on_miss(pos):
	GameManager.health -= 10
	GameManager.combo = 0
	AudioPlayer.play_audio("res://Assets/Audio/Effect/miss.wav", pos, Vector2(0.9, 1.1))


func get_pop_timing(pop_time):
	var delta = Playback.playhead - pop_time
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

func spawn_gizmo(id, data := {}):
	if not GameManager.in_editor: push_error("NOT IN EDITOR"); return
	var spawned_without_data := data == {}
	
	var gizmo_scene_path
	var new_marker_func : Callable
	var new_gizmo
	match id:
		EntityID["TARGET_TAP"]:
			gizmo_scene_path = "res://MapEditor/GizmoProps/gizmo_target.tscn"
			new_marker_func = Utility.spawn_marker
		EntityID["GOAL"]:
			gizmo_scene_path = "res://MapEditor/GizmoProps/gizmo_goal.tscn"
			new_marker_func = Utility.spawn_start_end_markers
		EntityID["SLIDER"]:
			gizmo_scene_path = "res://MapEditor/GizmoProps/gizmo_slider.tscn"
			new_marker_func = Utility.spawn_start_end_markers
	
	new_gizmo = Utility.spawn_entity(gizmo_scene_path, get_node_or_null_in_scene("%GizmoBeatmap"), data)
	if spawned_without_data:
		var cam = get_viewport().get_camera_3d()
		new_gizmo.global_position = cam.global_position + -cam.global_basis.z * 2.0
		
		if "start_time" in new_gizmo:
			new_gizmo.start_time = Playback.playhead
			new_gizmo.pop_time = Playback.playhead + 1.0
		else:
			new_gizmo.pop_time = Playback.playhead
	
	
	var new_marker = new_marker_func.bind(new_gizmo).call()
	if id == 11:
		new_marker.modulate.b = 1.0
		new_marker.modulate.g = randf_range(0.0, 1.0)
	elif id == 12:
		new_marker.modulate.r = 1.0
		new_marker.modulate.b = randf_range(0.0, 1.0)
	
	if new_gizmo.get_child_count() >= 2 and new_gizmo.get_child(1).get_surface_override_material(0):
		new_gizmo.get_child(1).set_surface_override_material(0, new_gizmo.get_child(1).get_surface_override_material(0).duplicate())
	else:
		make_surface_materials_unique(new_gizmo)



func spawn_marker(gizmo : Node):
	var timeline = Utility.get_node_or_null_in_scene("%TimelineSlider")
	var new_marker = load("res://MapEditor/Markers/marker.tscn").instantiate()
	timeline.add_child(new_marker)
	gizmo.marker = new_marker
	new_marker.set_meta("gizmo", gizmo)
	new_marker.position.x = Utility.get_position_on_timeline_from_value(gizmo.pop_time)
	new_marker.position.y = 38
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


func spawn_gizmo_goal(goal_data = null):
	if not GameManager.in_editor: push_error("NOT IN EDITOR"); return
	


func spawn_bpm_guide(data = null):
	var timeline = Utility.get_node_or_null_in_scene("%TimelineSlider")
	var new_bpm_guide = load("res://MapEditor/Markers/bpm_guide.tscn").instantiate()
	timeline.add_child(new_bpm_guide)
	
	if data:
		apply_data(new_bpm_guide, data)
	else:
		new_bpm_guide.start_time = Playback.playhead
		new_bpm_guide.end_time = new_bpm_guide.start_time + 4.0
		new_bpm_guide.bpm = 60.0
	
	#new_bpm_guide.position.x = Utility.get_position_on_timeline_from_value(new_bpm_guide.start_time)
	new_bpm_guide.zoom_update()
	new_bpm_guide.position.y = 64
	get_tree().current_scene.connect_marker_signals(new_bpm_guide)
	
	new_bpm_guide.get_node("%BPMLabel").text = "[font_size=10]bpm: %.2f" % new_bpm_guide.bpm
	
	#await get_tree().create_timer(2).timeout
	
	print(data)
	
	#new_bpm_guide.end_time = data["_"]["end_time"]
	#new_bpm_guide.ticks = new_bpm_guide.ticks
	#new_bpm_guide.end_drag()
	
	return new_bpm_guide








# JSON utility

func convert_vec3s(data):
	
	for section in data.keys():
		data[section] = convert_vec3s_subfunc(data[section])
	return data

func convert_vec3s_subfunc(data):
	for property in data.keys():
		var value = data[property]
		
		if value is Array:
			for i in value.size():
				data[property][i] = convert_vec3s_subfunc(value[i])
		if value is not String: continue
		if not value.begins_with("("): continue
		
		data[property] = str_to_var("Vector3"+value)
	
	return data

func convert_ints(data):
	
	# group data
	
	for section in data.keys():
		if data[section] is not Dictionary: continue
		
		for property in data[section].keys():
			
			if property == "id" or property == "gamemode": data[section][property] = int(data[section][property]); print("ID CONVERTED TO %d" % data[section][property])
	
	return data

func convert_colors(data):
	for section in data.keys():
		if data[section] is not Dictionary: continue
		
		for property in data[section].keys():
			
			if property == "albedo_color":
				var value = str_to_var("Color"+data[section][property])
				data[section][property] = value
				print("COLOR CONVERTED TO %s" % data[section][property])
	
	return data

func _unhandled_input(event):

	if event is InputEventKey and event.pressed and event.keycode == KEY_0:
		get_window().size -= Vector2i(16, 9) * 4
		get_window().move_to_center()
