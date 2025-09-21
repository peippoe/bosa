extends PanelContainer

@onready var editor = $"../.."
@onready var cam = %Cam

var anchored := false
var dragging := false
var drag_mouse_start := Vector2.ZERO
var drag_mouse := Vector2.ZERO
var old_unanchored_offset := Vector2.ZERO + Vector2(100, -50)
var new_unanchored_offset := Vector2.ZERO


func _ready():
	hide()
	%Anchor.pressed.connect(
		func anchor():
			if anchored:
				anchored = false
				$Control/Anchor.text = "anchor"
				old_unanchored_offset = global_position - cam.unproject_position(editor.selected.global_position)
				new_unanchored_offset = Vector2.ZERO
			else:
				anchored = true
				$Control/Anchor.text = "unanchor"
				drag_mouse_start = Vector2.ZERO
				drag_mouse = global_position
	)
	%Delete.pressed.connect(
		func delete():
			if not editor.selected: return
			
			get_tree().current_scene.record(editor.selected)
			
			if "marker" in editor.selected:
				Utility.delete_gizmo(editor.selected)
			else:
				editor.selected.queue_free()
			
			get_tree().current_scene.set_selected(null)
	)


func _process(delta):
	update_selection_properties()


func update_selection_properties():
	if !editor.selected: return
	
	if !anchored:
		var selected_pos = cam.unproject_position(editor.selected.global_position)
		global_position = selected_pos + old_unanchored_offset + new_unanchored_offset
	else:
		global_position = drag_mouse - drag_mouse_start
	
	update_selection_property_list()

func update_selection_property_list():
	var properties = Utility.get_entity_properties(editor.selected)
	var new_text = "[color=black][i]"
	for key in properties:
		var value = properties[key]
		if value is Vector3:
			value.x = Utility.round_float(value.x, 2)
			value.y = Utility.round_float(value.y, 2)
			value.z = Utility.round_float(value.z, 2)
		new_text += str(key)+": "+str(value)+"\n"
	
	%Properties.text = new_text



func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		dragging = event.pressed
		if dragging:
			if anchored:
				drag_mouse_start = event.position
			else:
				drag_mouse_start = get_viewport().get_mouse_position()
			
			drag_mouse = get_viewport().get_mouse_position()
		else:
			old_unanchored_offset += new_unanchored_offset
			new_unanchored_offset = Vector2.ZERO
	
	if event is InputEventMouseMotion and dragging:
		drag_mouse = get_viewport().get_mouse_position()
		new_unanchored_offset = drag_mouse - drag_mouse_start
