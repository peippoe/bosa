extends Node3D

@onready var cam = %Cam
@onready var gizmo_manipulator = %gizmo_manipulator
@onready var gizmo_beatmap = %GizmoBeatmap

var selected : Node3D = null
var selected_control : Control = null

var dragging := false
var drag_start_pos := Vector3.ZERO
var drag_start_scale := Vector3.ONE
var drag_start_mouse_pos := Vector2.ZERO
var drag_axis := Vector3.ZERO
var drag_delta := Vector3.ZERO

var marker_dragged : Control = null
const TIMELINE_GRABBER_SIZE := 8.0

var snap_points := []
var snap_threshold := 10.0

var tap_buffer := []
const MAX_TAPS := 8


var save_path := ""



var save_file_selected = func save_file_selected(path : String):
	save_map(path)

func map_save_as():
	Utility.open_file_dialog("user://beatmaps", FileDialog.FILE_MODE_SAVE_FILE, save_file_selected, PackedStringArray(["*.json"]))

func save_pressed():
	print("SAVE PATH: %s" % save_path)
	if save_path != "":
		save_map(save_path)
	else:
		map_save_as()


func _ready():
	%File.pressed.connect(func file(): %FileDropdown.visible = !%FileDropdown.visible; %SettingsDropdown.hide())
	
	var song_file_selected = func song_file_selected(global_path : String):
		
		var user_path = ProjectSettings.globalize_path("user://")
		var res_path = ProjectSettings.globalize_path("res://")
		if global_path.begins_with(user_path):
			global_path = "user://" + global_path.substr(user_path.length())
		elif global_path.begins_with(res_path):
			global_path = "res://" + global_path.substr(res_path.length())
		else:
			push_error("BAD PATH"); return
		
		Playback.beatmap_data["config"]["song"] = global_path
		Playback.set_song(global_path)
	
	%ChooseSong.pressed.connect(func choose_song():
		Utility.open_file_dialog("user://songs", FileDialog.FILE_MODE_OPEN_FILE, song_file_selected, PackedStringArray(["*.mp3", "*.ogg", "*.wav"]))
	)
	
	
	
	%Settings.pressed.connect(func settings(): %SettingsDropdown.visible = !%SettingsDropdown.visible; %FileDropdown.hide())
	%UserFiles.pressed.connect(func file(): OS.shell_open(ProjectSettings.globalize_path("user://")))
	%MainMenu.pressed.connect(func main_menu(): GameManager.change_scene("res://Scenes/main_menu.tscn"))
	
	
	
	%SaveAs.pressed.connect(map_save_as)
	%Save.pressed.connect(save_pressed)
	%Load.pressed.connect(open_load_map_file_dialog)
	%Playtest.pressed.connect(func play():
		if save_path:
			GameManager.play_map(save_path)
		else:
			map_save_as()
	)
	%SpawnTarget.pressed.connect(
		func spawn(): Utility.spawn_gizmo(Enums.GizmoType.TARGET_TAP))
	%SpawnGoal.pressed.connect(
		func spawn(): Utility.spawn_gizmo(Enums.GizmoType.GOAL))
	%SpawnBPMGuide.pressed.connect(
		func spawn(): Utility.spawn_bpm_guide())
	%SpawnBlock.pressed.connect(
		func spawn(): Utility.spawn_geometry(
			{
				"type": Enums.GeometryType.BLOCK
			}
		))
	%SpawnRamp.pressed.connect(
		func spawn(): Utility.spawn_geometry(
			{
				"type": Enums.GeometryType.RAMP
			}
		))
	
	get_node("%BPMCalculator/%Confirm").pressed.connect(
		
		func confirm():
			%BPMCalculator.hide()
			var bpm = float(get_node("%BPMCalculator/%CurrentBPM").text)
			print("SELECTED CONTROLLLLLL: %s" % selected_control)
			selected_control.bpm = bpm
			selected_control.get_node("%BPMLabel").text = "[font_size=10]bpm: %.2f" % bpm
	)
	get_node("%BPMCalculator/%Tap").pressed.connect(
		func tap():
			if tap_buffer.size() == MAX_TAPS: tap_buffer.pop_front()
			
			tap_buffer.append(Time.get_ticks_msec()/1000.0)
			
			if tap_buffer.size() < 2: return
			
			var interval_sum := 0.0
			var prev_tap := 0.0
			for i in tap_buffer.size():
				var current_tap = tap_buffer[i]
				if i != 0: interval_sum += current_tap - prev_tap
				prev_tap = current_tap
			
			var avg_interval = interval_sum / (tap_buffer.size() - 1)
			var new_bpm = roundf(60.0 / avg_interval)
			get_node("%BPMCalculator/%CurrentBPM").text = str(new_bpm)
	)
	get_node("%BPMCalculator/%Clear").pressed.connect(
		func clear():
			tap_buffer = []
			get_node("%BPMCalculator/%CurrentBPM").text = ""
	)
	get_node("%BPMCalculator/%Delete").pressed.connect(
		func delete():
			%BPMCalculator.hide()
			if not selected_control: return
			selected_control.queue_free()
			set_selected(null)
	)
	get_node("%BPMCalculator/%Cancel").pressed.connect(
		func cancel():
			%BPMCalculator.hide()
	)

func connect_marker_signals(marker):
	var marker_button = marker.get_node("%MarkerButton")
	if marker.name == "EdgeMarker":
		marker_button = marker
	
	marker_button.button_down.connect(
		func start_drag_marker():
			SignalBus.marker_drag_start.emit(marker)
			marker_dragged = marker
			
			record(marker_dragged.get_meta("gizmo"), "pop_time", marker_dragged.get_meta("gizmo").pop_time)
			
			if marker.name == "EdgeMarker":
				marker.get_parent().ticks = []
				marker.get_parent().queue_redraw()
	)
	marker_button.button_up.connect(
		func end_drag_marker():
			SignalBus.marker_drag_end.emit(marker)
			marker_dragged = null
			
			var timeline = Utility.get_node_or_null_in_scene("%TimelineSlider")
			if marker.has_meta("gizmo"):
				var gizmo = marker.get_meta("gizmo")
				gizmo.pop_time = Utility.get_slider_value_from_position(marker.position, timeline)
			if "bpm" in marker:
				marker.start_time = Utility.get_slider_value_from_position(marker.position, timeline)
				marker_button.get_parent().update_end_time()
			if marker.name == "EdgeMarker":
				marker.get_parent().end_drag()
	)
	marker_button.pressed.connect(
		func pressed_marker():
			if marker.has_meta("gizmo"): set_selected(marker.get_meta("gizmo"))
	)
	var edge_marker = marker.get_node_or_null("%EdgeMarker")
	if edge_marker and marker.name != "EdgeMarker":
		connect_marker_signals(edge_marker)



func _input(event):
	if event is InputEventMouseMotion and marker_dragged:
		var mouse_x = event.global_position.x
		var min_value = %TimelineSlider.global_position.x + TIMELINE_GRABBER_SIZE
		var max_value = %TimelineSlider.global_position.x + %TimelineSlider.size.x - TIMELINE_GRABBER_SIZE
		if snap_points and Input.is_action_pressed("ctrl"):
			mouse_x = get_snapped_x(mouse_x)
		marker_dragged.global_position.x = clampf(mouse_x - %TimelineSubViewportContainer.global_position.x, min_value, max_value)

func get_snapped_x(pos : float):
	if snap_points == []: return pos
	
	var closest : float
	var closest_distance := 999.0
	for i in snap_points.size():
		var distance = absf(snap_points[i] - pos)
		if distance < closest_distance:
			closest_distance = distance
			closest = snap_points[i]
	
	if not closest: push_error("ERROR GETTING CLOSEST"); return pos
	
	var distance_to_closest = absf(closest - pos)
	if distance_to_closest < snap_threshold:
		#print("CLOSESTTTTTTTTTTT: %f" % closest)
		return closest
	else:
		#print("DISTANCE TO CLOSEST NOT CLOSE ENOUGH: %f" % distance_to_closest)
		return pos


func _unhandled_input(event):
	
	if event is InputEventMouseButton:
		
		if event.button_index == 1:
			if event.pressed:
				click(event)
			else:
				dragging = false
	
	if event is InputEventKey:
		if not event.pressed: return
		
		if event.ctrl_pressed:
			match event.keycode:
				KEY_S: save_pressed()
				KEY_Z: undo()
		else:
			match event.keycode:
				KEY_1:
					gizmo_manipulator.get_child(0).show()
					gizmo_manipulator.get_child(1).hide()
				KEY_2:
					gizmo_manipulator.get_child(0).hide()
					gizmo_manipulator.get_child(1).show()


func click(event):
	var from = cam.project_ray_origin(event.position)
	var to = from + cam.project_ray_normal(event.position) * 200
	
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collision_mask = 8
	var gizmo_manipulator_result = space_state.intersect_ray(query)
	
	
	if gizmo_manipulator_result:
		var coll = gizmo_manipulator_result.collider
		
		if coll.get_parent() == gizmo_manipulator:
			if gizmo_manipulator.get_child(0).visible:
				start_drag(event, coll)
			elif gizmo_manipulator.get_child(1).visible:
				start_drag(event, coll)
		
		return
	
	
	
	query.collide_with_bodies = true
	query.collision_mask = 1
	var result = space_state.intersect_ray(query)
	
	if not result:
		set_selected(null)
		return
	
	set_selected(result.collider.get_parent())


func set_selected(new_selected):
	if selected: selected.process_mode = Node.PROCESS_MODE_INHERIT
	if new_selected: new_selected.process_mode = Node.PROCESS_MODE_DISABLED
	
	selected = new_selected
	if not selected:
		gizmo_manipulator.process_mode = Node.PROCESS_MODE_DISABLED
		%SelectionProperties.hide()
	else:
		gizmo_manipulator.process_mode = Node.PROCESS_MODE_INHERIT
		%SelectionProperties.show()

func set_selected_control(new_selected_control):
	selected_control = new_selected_control



func start_drag(event, coll):
	
	if gizmo_manipulator.get_child(0).visible:
		record(selected, "global_position", selected.global_position)
	elif gizmo_manipulator.get_child(1).visible:
		record(selected, "scale", selected.scale)
	
	
	dragging = true
	drag_start_pos = coll.get_parent().global_position
	drag_start_scale = selected.scale
	drag_start_mouse_pos = event.position
	
	match str(coll.name)[0]:
		"X": drag_axis = Vector3.RIGHT
		"Y": drag_axis = Vector3.UP
		"Z": drag_axis = Vector3.BACK


func _process(delta):
	handle_gizmos()
	handle_dragging()
	fade_gizmos()
	%TimeLabel.text = str(Playback.playhead).pad_decimals(2)# + " -- " + str(%Timeline.value - Playback.playhead).pad_decimals(2)


func fade_gizmos():
	for i in gizmo_beatmap.get_children().size():
		var target_gizmo : MeshInstance3D = gizmo_beatmap.get_child(i)
		
		var fadein = Settings.fadein_time
		if "start_time" in target_gizmo:
			fadein = target_gizmo.pop_time - target_gizmo.start_time
		
		var start = target_gizmo.pop_time - fadein
		var playhead_relative = maxf(Playback.playhead - start, 0)
		
		var alpha = 0
		if playhead_relative > 0 and playhead_relative < fadein:
			alpha = playhead_relative / fadein
		target_gizmo.get_active_material(0).albedo_color.a = alpha
		
		var coll : CollisionShape3D = target_gizmo.get_node("GizmoHitbox").get_child(0)
		if alpha == 0:
			if not coll.disabled: coll.disabled = true
		else:
			if coll.disabled: coll.disabled = false

func handle_gizmos():
	if not selected:
		gizmo_manipulator.hide()
		return
	
	gizmo_manipulator.global_position = selected.global_position
	gizmo_manipulator.show()
	
	var distance = cam.global_position.distance_to(gizmo_manipulator.global_position)
	var fov = cam.fov
	var screen_height = get_viewport().get_visible_rect().size.y
	
	# Calculate scale so gizmo appears constant size in pixels
	var size_factor = 2.0 * distance * tan(fov * 0.5 * deg_to_rad(1.0)) / screen_height
	gizmo_manipulator.scale = Vector3.ONE * 80 * size_factor

func handle_dragging():
	if not selected or not dragging: return
	
	
	var mouse_pos = get_viewport().get_mouse_position()
	var pos_delta = drag_axis
	
	var plane_normal = Vector3.UP
	var drag_start_delta = selected.global_position
	var d = drag_start_delta.y
	if drag_axis == Vector3.UP:
		plane_normal = Vector3(cam.global_basis.z.x, 0, cam.global_basis.z.z)
		d = Vector3(drag_start_delta.x, 0, drag_start_delta.z)
	
	var plane = Plane(plane_normal, d)
	var a = get_mouse_position_on_plane(mouse_pos, plane)
	var b = get_mouse_position_on_plane(drag_start_mouse_pos, plane)
	drag_delta = (a - b) * drag_axis
	drag_delta = drag_delta.normalized() * min(drag_delta.length(), 100)
	
	
	if gizmo_manipulator.get_child(0).visible:
		var new_pos = drag_start_pos + drag_delta
		
		if Input.is_action_pressed("ctrl"):
			var axis_pos = new_pos * drag_axis
			new_pos = new_pos - axis_pos + Vector3(Vector3i(axis_pos))
		
		selected.global_position = new_pos
	
	elif gizmo_manipulator.get_child(1).visible:
		var new_scale = drag_start_scale + drag_delta
		
		if Input.is_action_pressed("ctrl"):
			var axis_scale = new_scale * drag_axis
			new_scale = new_scale - axis_scale + Vector3(Vector3i(axis_scale))
		
		selected.scale = new_scale


func get_mouse_position_on_plane(mouse_pos, plane) -> Vector3:
	var ray_origin = cam.project_ray_origin(mouse_pos)
	var ray_direction = cam.project_ray_normal(mouse_pos)
	
	var hit_point = plane.intersects_ray(ray_origin, ray_direction)
	
	
	return hit_point if hit_point else Vector3.ZERO




func open_load_map_file_dialog():
	var load_map_file_selected = func load_map_file_selected(path : String):
		load_map(path)
	
	Utility.open_file_dialog("user://beatmaps", FileDialog.FILE_MODE_OPEN_FILE, load_map_file_selected, PackedStringArray(["*.json"]))

func load_map(path):
	for i in gizmo_beatmap.get_children(): Utility.delete_gizmo(i)
	for i in %Geometry.get_children(): i.queue_free()
	for i in Utility.get_node_or_null_in_scene("%TimelineSlider").get_children(): i.queue_free()
	
	save_path = path
	print(path)
	
	var file = FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed: push_error("PARSE FAILED"); return
	parsed["beatmap"] = Utility.convert_vec3s(parsed["beatmap"])
	parsed["beatmap"] = Utility.convert_ints(parsed["beatmap"])
	parsed["geometry"] = Utility.convert_vec3s(parsed["geometry"])
	
	Playback.beatmap_data = parsed
	
	if Playback.beatmap_data["config"]["song"]: Playback.set_song(Playback.beatmap_data["config"]["song"])
	var length_edit : LineEdit = Utility.get_node_or_null_in_scene("%LengthEdit")
	length_edit.text_submitted.emit(str(Playback.beatmap_data["config"]["duration"]))
	
	
	for i in Playback.beatmap_data["beatmap"].size():
		
		var gizmo_data = Playback.beatmap_data["beatmap"][i]
		Utility.spawn_gizmo(gizmo_data["type"], gizmo_data)
	
	
	for i in Playback.beatmap_data["geometry"].size():
		var geometry_data = Playback.beatmap_data["geometry"][i]
		Utility.spawn_geometry(geometry_data)
	
	
	for i in Playback.beatmap_data["editor"].size():
		var data = Playback.beatmap_data["editor"][i]
		Utility.spawn_bpm_guide(data)
	
	await get_tree().create_timer(.1).timeout
	
	%TimelineSubViewportContainer.pixels_per_second = -1


func compile_map():
	Playback.beatmap_data["beatmap"] = []
	for i in gizmo_beatmap.get_children():
		Playback.beatmap_data["beatmap"].append(Utility.get_entity_properties(i))
	Playback.sort_beatmap_data()
	
	Playback.beatmap_data["geometry"] = []
	for i in %Geometry.get_children():
		
		var type = 0
		
		var scene_path = i.scene_file_path
		if scene_path.ends_with("block.tscn"):
			type = Enums.GeometryType.BLOCK
		elif scene_path.ends_with("ramp.tscn"):
			type = Enums.GeometryType.RAMP
		
		var data = {}
		data["type"] = type
		data["global_position"] = i.global_position
		data["global_rotation"] = i.global_rotation
		data["scale"] = i.scale
		Playback.beatmap_data["geometry"].append(data)
	
	Playback.beatmap_data["editor"] = []
	for i in %TimelineSlider.get_children():
		if i.has_meta("gizmo"): continue
		Playback.beatmap_data["editor"].append(Utility.get_entity_properties(i))
	

func save_map(path):
	save_path = path
	
	compile_map()
	
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("beatmaps"): dir.make_dir("beatmaps")
	
	Playback.beatmap_data["config"]["duration"] = float(Utility.get_node_or_null_in_scene("%LengthEdit").text)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(Playback.beatmap_data, "\t"))
		file.close()
		%FloatingTextManager.spawn_floating_text("Saved successfully to " + path)
	else:
		push_error("Failed to write to JSON")







func _on_play_pressed():
	# save objects as beatmap_data
	# playback the beatmap_data
	
	compile_map()
	
	Playback.playback_speed = 1
	gizmo_beatmap.hide()

func _on_pause_pressed():
	Playback.playback_speed = 0
	gizmo_beatmap.show()




var recorded = null

func set_and_record(node : Node, property : String, value):
	
	record(node, property, value)
	
	node.set(property, value)
	#update_visuals

func record(node : Node, property : String = "", value = null):
	if not property and not value:
		recorded = Utility.get_entity_properties(node)
	else:
		recorded = {
			"node": node,
			"property": property,
			"value": node.get(property)
		}
	#print("RECORD, RECORDED: %s" % recorded)


func undo():
	if not recorded: return
	
	if recorded.has("type"):
		var recorded_instance = Utility.spawn_gizmo(recorded["type"], recorded)
		%FloatingTextManager.spawn_floating_text("UNDO: delete gizmo")
		recorded = null
		return
	
	%FloatingTextManager.spawn_floating_text("UNDO: %s (%s)" % [recorded["property"], recorded["node"].name])
	
	set_and_record(recorded["node"], recorded["property"], recorded["value"])
	
	match recorded["property"]:
		"pop_time":
			if "start_time" in recorded["node"]:
				recorded["node"].marker.get_child(1).position.x = Utility.get_position_on_timeline_from_value(recorded["node"].pop_time)
			else:
				recorded["node"].marker.position.x = Utility.get_position_on_timeline_from_value(recorded["node"].pop_time)
		"start_time":
			if "pop_time" in recorded["node"]:
				recorded["node"].marker.get_child(0).position.x = Utility.get_position_on_timeline_from_value(recorded["node"].start_time)
