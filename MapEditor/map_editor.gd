extends Node3D

@onready var cam = %Cam
@onready var gizmo_position = %gizmo_position
@onready var map = %Map

var selected : Node = null

var dragging := false
var drag_start_pos := Vector3.ZERO
var drag_start_mouse_pos := Vector2.ZERO
var drag_axis := Vector3.ZERO
var drag_delta := Vector3.ZERO

var marker_dragged : Control = null
var marker_drag_offset := 0.0

func _ready():
	%Save.pressed.connect(save_map)
	%Play.pressed.connect(func play(): GameManager.play_map("user://beatmaps/beatmap.json"))
	%SpawnTarget.pressed.connect(
		func spawn():
			var cam = get_viewport().get_camera_3d()
			var pos = cam.global_position + -cam.global_basis.z * 2
			var new_target = UtilityFunctions.spawn_entity("res://MapEditor/gizmo_target.tscn", map, pos)
			new_target.set_meta("pop_time", Playback.playhead)
			
			var new_marker = TextureButton.new()
			%Timeline.add_child(new_marker)
			new_marker.scale = Vector2(0.2, 0.4)
			new_marker.texture_normal = load("res://Assets/Image/icon.svg")
			new_marker.set_anchors_preset(Control.PRESET_CENTER)
			#new_marker.position.y = %Timeline.size.y/2
			new_marker.position.x = remap(Playback.playhead, 0, %Timeline.max_value, 0, %Timeline.size.x)
			new_marker.button_down.connect(
				func start_drag_marker():
					marker_dragged = new_marker
					var mouse_x = get_viewport().get_mouse_position().x
					var x = marker_dragged.global_position.x
					marker_drag_offset = x - mouse_x
			)
			new_marker.button_up.connect(
				func end_drag_marker():
					marker_dragged = null
			)
	)
	%Timeline.scrolling.connect(
		func _on_timeline_scrolling():
			var new_step = 0.01
			if Input.is_action_pressed("ctrl"):
				new_step = 1
			elif Input.is_action_pressed("shift"):
				new_step = 0.1
			%Timeline.step = new_step
			%TimeLabel.text = str(%Timeline.value).pad_decimals(2)
			Playback.playhead = %Timeline.value
	)





func _input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			click(event)
		else:
			dragging = false
	
	if event is InputEventMouseMotion and marker_dragged:
		var mouse = get_viewport().get_mouse_position() #current_marker_dragged.get_local_mouse_position()
		marker_dragged.global_position.x = mouse.x + marker_drag_offset
		print(marker_dragged.global_position.x)


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
	toggle_node_process(selected)
	toggle_node_process(new_selected)
	selected = new_selected

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
		_: print("SOMETHING WONG")



func _process(delta):
	handle_gizmos()
	handle_dragging()

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


func save_map():
	var all_data = []
	for i in map.get_children():
		all_data.append(get_entity_data(i))
	
	all_data.sort_custom(func(a, b):
		return a["pop_time"] < b["pop_time"]
	)
	
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("beatmaps"): dir.make_dir("beatmaps")
	
	var path = "user://beatmaps/beatmap.json"
	write_to_json(all_data, path)

func write_to_json(data, path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	else:
		print("Failed to write to JSON")

func get_entity_data(entity : Node):
	var data = {
		"type": 0,
		"pop_time": entity.get_meta("pop_time"),
		"pos": entity.global_position,
		"rot": entity.global_rotation,
	}
	return data
