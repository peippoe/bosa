extends Node3D

@onready var cam = %Cam
@onready var gizmo_position = %gizmo_position
@onready var scene = %Scene

var selected : Node = null

var dragging := false
var drag_start_pos := Vector3.ZERO
var drag_start_mouse_pos := Vector2.ZERO
var drag_axis := Vector3.ZERO
var drag_delta := Vector3.ZERO



func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		self.rotate_y(-event.relative.x * 0.001)
		cam.rotate_x(-event.relative.y * 0.001)
		cam.rotation.x = clampf(cam.rotation.x, -PI/2, PI/2)
	
	if event is InputEventMouseButton and event.button_index == 1:
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
		selected = null
		return
	
	var coll = result.collider.get_parent()
	
	if coll.get_parent() == gizmo_position:
		start_drag(event, coll)
		return
	
	selected = coll

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




func _physics_process(delta):
	if Input.is_action_pressed("aim"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var speed = 2
	if Input.is_action_pressed("shift"): speed = 4
	self.global_position += cam.global_basis * Vector3(input_dir.x, 0, input_dir.y) * speed * delta
	
	
	if Input.is_action_pressed("shoot"):
		pass
