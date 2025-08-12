extends Node3D

@onready var cam = %Cam
@onready var gizmo_position = %gizmo_position
@onready var map = %Map

var selected : Node3D = null
var selected_control : Control = null

var dragging := false
var drag_start_pos := Vector3.ZERO
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
	%Save.pressed.connect(
		func save():
			print("SAVE PATH: %s" % save_path)
			if save_path != "":
				save_map(save_path)
			else:
				map_save_as()
	)
	%Load.pressed.connect(open_load_map_file_dialog)
	%Playtest.pressed.connect(func play():
		if save_path:
			GameManager.play_map(save_path)
		else:
			map_save_as()
	)
	%SpawnTarget.pressed.connect(
		func spawn():
			Utility.spawn_gizmo(Enums.GizmoType.TARGET_TAP)
	)
	
	%SpawnGoal.pressed.connect(
		func spawn():
			Utility.spawn_gizmo(Enums.GizmoType.GOAL)
	)
	
	
	%SpawnBPMGuide.pressed.connect(
		func spawn():
			Utility.spawn_bpm_guide()
	)
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
		#edge_marker.button_down.connect(
			#func edge_marker_button_down():
				#print("start_drag")
				#
		#)



func _input(event):
	if event is InputEventMouseMotion and marker_dragged:
		var mouse_x = event.global_position.x
		var min = %TimelineSlider.global_position.x + TIMELINE_GRABBER_SIZE
		var max = %TimelineSlider.global_position.x + %TimelineSlider.size.x - TIMELINE_GRABBER_SIZE
		if snap_points and Input.is_action_pressed("ctrl"):
			mouse_x = get_snapped_x(mouse_x)
		marker_dragged.global_position.x = clampf(mouse_x - %TimelineSubViewportContainer.global_position.x, min, max)

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


func click(event):
	var from = cam.project_ray_origin(event.position)
	var to = from + cam.project_ray_normal(event.position) * 200
	
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = false
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	
	if not result:
		
		set_selected(null)
		return
	
	var coll = result.collider.get_parent()
	
	if coll.get_parent() == gizmo_position:
		start_drag(event, coll)
		return
	
	set_selected(coll)


func set_selected(new_selected):
	if selected: toggle_node_process(selected)
	toggle_node_process(new_selected)
	
	selected = new_selected
	if not selected:
		%SelectionProperties.hide()
	else:
		%SelectionProperties.show()

func set_selected_control(new_selected_control):
	selected_control = new_selected_control




func toggle_node_process(node : Node):
	if not node: return
	if not node.is_in_group("gizmo_single_select"): return
	
	if node.process_mode == Node.PROCESS_MODE_DISABLED:
		node.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		node.process_mode = Node.PROCESS_MODE_DISABLED



func start_drag(event, coll):
	dragging = true
	drag_start_pos = coll.global_position
	drag_start_mouse_pos = event.position
	match coll.name:
		"X": drag_axis = Vector3.RIGHT
		"Y": drag_axis = Vector3.UP
		"Z": drag_axis = Vector3.BACK
		_: push_error("SOMETHING WONG")



func _process(delta):
	handle_gizmos()
	handle_dragging()
	fade_gizmos()
	%TimeLabel.text = str(Playback.playhead).pad_decimals(2)# + " -- " + str(%Timeline.value - Playback.playhead).pad_decimals(2)


func fade_gizmos():
	for i in %Map.get_children().size():
		var target_gizmo : MeshInstance3D = %Map.get_child(i)
		
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
		gizmo_position.hide()
		return
	
	gizmo_position.global_position = selected.global_position
	gizmo_position.show()
	
	var distance = cam.global_position.distance_to(gizmo_position.global_position)
	var fov = cam.fov
	var screen_height = get_viewport().get_visible_rect().size.y
	
	# Calculate scale so gizmo appears constant size in pixels
	var size_factor = 2.0 * distance * tan(fov * 0.5 * deg_to_rad(1.0)) / screen_height
	gizmo_position.scale = Vector3.ONE * 80 * size_factor

func handle_dragging():
	if not selected or not dragging: return
	
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	var pos_delta = drag_axis
	
	var plane_normal = Vector3.UP
	var drag_start_delta = selected.global_position#drag_start_pos + drag_delta
	var d = drag_start_delta.y
	if drag_axis == Vector3.UP:
		plane_normal = Vector3(cam.global_basis.z.x, 0, cam.global_basis.z.z)
		d = Vector3(drag_start_delta.x, 0, drag_start_delta.z)
	
	var plane = Plane(plane_normal, d)
	var a = get_mouse_position_on_plane(mouse_pos, plane)
	var b = get_mouse_position_on_plane(drag_start_mouse_pos, plane)
	drag_delta = (a - b) * drag_axis
	drag_delta = drag_delta.normalized() * min(drag_delta.length(), 100)
	var new_pos = drag_start_pos + drag_delta
	
	if Input.is_action_pressed("ctrl"):
		var axis_pos = new_pos * drag_axis
		new_pos = new_pos - axis_pos + Vector3(Vector3i(axis_pos))
	
	selected.global_position = new_pos


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
	for i in map.get_children(): Utility.delete_gizmo(i)
	for i in Utility.get_node_or_null_in_scene("%TimelineSlider").get_children(): i.queue_free()
	
	save_path = path
	print(path)
	
	var file = FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed: push_error("PARSE FAILED"); return
	parsed["beatmap"] = Utility.convert_vec3s(parsed["beatmap"])
	parsed["beatmap"] = Utility.convert_ints(parsed["beatmap"])
	
	Playback.beatmap_data = parsed
	
	if Playback.beatmap_data["config"]["song"]: Playback.set_song(Playback.beatmap_data["config"]["song"])
	var length_edit : LineEdit = Utility.get_node_or_null_in_scene("%LengthEdit")
	length_edit.text_submitted.emit(str(Playback.beatmap_data["config"]["duration"]))
	
	
	for i in Playback.beatmap_data["beatmap"].size():
		
		var gizmo_data = Playback.beatmap_data["beatmap"][i]
		match gizmo_data["type"]:
			Enums.GizmoType.TARGET_TAP:
				Utility.spawn_gizmo(Enums.GizmoType.TARGET_TAP, gizmo_data)
			Enums.GizmoType.GOAL:
				Utility.spawn_gizmo(Enums.GizmoType.GOAL, gizmo_data)
		
	
	for i in Playback.beatmap_data["editor"].size():
		var data = Playback.beatmap_data["editor"][i]
		Utility.spawn_bpm_guide(data)


func compile_map():
	Playback.beatmap_data["beatmap"] = []
	for i in map.get_children():
		Playback.beatmap_data["beatmap"].append(Utility.get_entity_properties(i))
	Playback.sort_beatmap_data()
	
	Playback.beatmap_data["editor"] = []
	for i in %TimelineSlider.get_children():
		if i.has_meta("gizmo"): continue
		print(i)
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
		print("Saved successfully to " + path)
	else:
		push_error("Failed to write to JSON")







func _on_play_pressed():
	# save objects as beatmap_data
	# playback the beatmap_data
	
	compile_map()
	
	Playback.playback_speed = 1
	%Map.hide()

func _on_pause_pressed():
	Playback.playback_speed = 0
	%Map.show()
