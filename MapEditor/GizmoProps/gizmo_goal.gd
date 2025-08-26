extends MeshInstance3D

var start_time := 0.0
var pop_time := 1.0
var type := Enums.GizmoType.GOAL
var marker : Node:
	set(value):
		marker = value
		init()

var start_marker
var end_marker

func init():
	marker.set_meta("gizmo", self)
	
	marker.position.x = 0
	marker.position.y = 40
	
	start_marker = marker.get_child(0)
	var start_marker_button = start_marker.get_node("%MarkerButton")
	end_marker = marker.get_child(1)
	var end_marker_button = end_marker.get_node("%MarkerButton")
	
	var a = Utility.get_position_on_timeline_from_value(start_time)
	var b = Utility.get_position_on_timeline_from_value(pop_time)
	start_marker.position.x = a
	end_marker.position.x = b
	
	update_markers()
	
	
	var pressed = func pressed(): get_tree().current_scene.set_selected(marker.get_meta("gizmo"))
	start_marker_button.pressed.connect(pressed)
	end_marker_button.pressed.connect(pressed)
	
	
	start_marker_button.button_down.connect(
		func button_down():
			get_tree().current_scene.marker_dragged = start_marker
			SignalBus.marker_drag_start.emit(start_marker)
	)
	end_marker_button.button_down.connect(
		func button_down():
			get_tree().current_scene.marker_dragged = end_marker
			SignalBus.marker_drag_start.emit(end_marker)
	)
	
	var button_up = func button_up():
		get_tree().current_scene.marker_dragged = null
		update_markers()
	start_marker_button.button_up.connect(button_up)
	end_marker_button.button_up.connect(button_up)

func update_markers():
	var timeline = Utility.get_node_or_null_in_scene("%TimelineSlider")
	start_time = Utility.get_slider_value_from_position(start_marker.global_position - timeline.global_position, timeline)
	pop_time = Utility.get_slider_value_from_position(end_marker.global_position - timeline.global_position, timeline)

const ENTITY_PROPERTIES = [
	"start_time", "pop_time", "marker", "type",
	"global_position", "global_rotation"
	]
