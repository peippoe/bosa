extends Control

var dragging := false
var ticks := []

func _gui_input(event):
	if event is InputEventMouseButton:
		dragging = event.pressed
		
		if dragging:
			ticks = []
			queue_redraw()
		
		elif not dragging:
			set_meta("end_time", Utility.get_node_or_null_in_scene("%TimelineSubViewportContainer").timeline_grabber_size/2 / Utility.get_node_or_null_in_scene("%TimelineSubViewportContainer").pixels_per_second + Utility.get_slider_value_from_position($TextureButton2.global_position, Utility.get_node_or_null_in_scene("%TimelineSlider")))
			
			ticks = []
			var length = get_meta("end_time") - get_meta("start_time")# + 6 / Utility.get_node_or_null_in_scene("%TimelineSubViewportContainer").pixels_per_second
			var number_of_beats = length / 60.0 * get_meta("bpm")
			for i in range(number_of_beats+1):
				if i == 0: continue
				ticks.append(i / get_meta("bpm") * 60.0)
			
			queue_redraw()
	
	if dragging and event is InputEventMouseMotion:
		var x = get_global_mouse_position().x - position.x
		$TextureButton2.position.x = x
		$TextureButton.size.x = x

func _draw():
	for i in ticks.size():
		var start = Vector2(ticks[i], 0.0) * Utility.get_node_or_null_in_scene("%TimelineSubViewportContainer").pixels_per_second
		var end = start + Vector2(0.0, -10.0)
		draw_line(start, end, Color.WHITE)

func _ready():
	$TextureButton2.gui_input.connect(_gui_input)
	
	$TextureButton.resized.connect(
		func a():
			queue_redraw()
	)




func _on_property_list_changed():
	queue_redraw()
