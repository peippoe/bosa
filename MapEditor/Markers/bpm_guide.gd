extends Control

var dragging := false
var ticks_to_erase := []
var ticks := []:
	set(value):
		var editor = get_tree().current_scene
		
		for i in ticks_to_erase.size():
			editor.snap_points.erase(ticks_to_erase[i])
		
		ticks = value
		
		var offset = Utility.get_node_or_null_in_scene("%TimelineSubViewportContainer").global_position.x + self.global_position.x
		print(offset)
		var new_value = value.duplicate()
		if new_value != []:
			for i in new_value.size():
				new_value[i] = new_value[i] * Utility.get_node_or_null_in_scene("%TimelineSubViewportContainer").pixels_per_second + offset
			
			editor.snap_points += new_value
			ticks_to_erase = new_value
			#print(editor.snap_points)

var bpm := 0.0
var start_time := 0.0
var end_time := 0.0

const ENTITY_PROPERTIES = [
	"bpm", "start_time", "end_time"
	]


func _gui_input(event):
	queue_redraw()
	%MarkerButton.size.x = %EdgeMarker.position.x + %EdgeMarker.size.x / 2.0
	self.size.x = %MarkerButton.size.x
	
	#if event is InputEventMouseButton:
		##dragging = event.pressed
		#
		#if dragging:
			##SignalBus.marker_drag_start.emit(%EdgeMarker)
			#ticks = []
			#queue_redraw()
		#
		#elif not dragging:
			##SignalBus.marker_drag_end.emit(%EdgeMarker)
			#end_drag()
	#
	#if dragging and event is InputEventMouseMotion:
		#var x = get_global_mouse_position().x - position.x
		#%EdgeMarker.position.x = x
		#%MarkerButton.size.x = x

func end_drag():
	update_end_time()
	
	ticks = []
	var length = end_time - start_time
	var number_of_beats = length / 60.0 * bpm
	for i in range(number_of_beats+1):
		ticks.append(i / bpm * 60.0)
	
	update_ticks()
	
	queue_redraw()

func update_ticks():
	ticks = ticks

func update_end_time():
	var pixels_per_second = Utility.get_node_or_null_in_scene("%TimelineSubViewportContainer").pixels_per_second
	end_time = Utility.get_node_or_null_in_scene("%TimelineSubViewportContainer").timeline_grabber_size/2 / pixels_per_second + Utility.get_slider_value_from_position(%EdgeMarker.position + self.position, Utility.get_node_or_null_in_scene("%TimelineSlider"))

func _draw():
	for i in ticks.size():
		if i == 0: continue
		var start = Vector2(ticks[i], 0.0) * Utility.get_node_or_null_in_scene("%TimelineSubViewportContainer").pixels_per_second
		var end = start + Vector2(0.0, -10.0)
		draw_line(start, end, Color.WHITE)

func _ready():
	%EdgeMarker.button_up.connect(
		func up():
			update_ticks()
	)
	
	%MarkerButton.button_up.connect(
		func up():
			update_ticks()
	)
	
	%MarkerButton.pressed.connect(
		func pressed():
			print("PRESSSSSSSSSSSSSSSSSSSSSSSSSSSSSED")
			get_tree().current_scene.set_selected_control(self)
			Utility.get_node_or_null_in_scene("%BPMCalculator").show()
	)
	
	%EdgeMarker.gui_input.connect(_gui_input)
	
	%MarkerButton.resized.connect(
		func a():
			queue_redraw()
	)
	
	await get_tree().process_frame
	
	end_drag()


func zoom_update():
	var x = Utility.get_position_on_timeline_from_value(start_time)
	self.position.x = x
	var x2 = Utility.get_position_on_timeline_from_value(end_time) - Utility.get_node_or_null_in_scene("%TimelineSubViewportContainer").timeline_grabber_size * 0.5
	%EdgeMarker.position.x = x2 - x
	%MarkerButton.size.x = x2 - x + %EdgeMarker.size.x / 2.0
	update_ticks()


func _on_property_list_changed():
	queue_redraw()
