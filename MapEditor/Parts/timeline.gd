extends SubViewportContainer


var dragging := false
var prev_value_changed_value := 0.0
var prev_playback_speed := 0.0
@onready var timeline_grabber_size = $"../../../../../../..".TIMELINE_GRABBER_SIZE

var min_value := 0.0
var max_value := 30.0

var pixels_per_second := 10.0:
	set(value):
		pixels_per_second = value
		
		#%Timeline.size.x = max_value * pixels_per_second
		
		await get_tree().physics_frame
		await get_tree().process_frame
		await get_tree().physics_frame
		
		for i in %TimelineSlider.get_children():
			if i.has_meta("gizmo"):
				var x = Utility.get_position_on_timeline_from_value(i.get_meta("gizmo").pop_time)
				i.position.x = x
				print(x)
			elif "bpm" in i:
				var x = Utility.get_position_on_timeline_from_value(i.start_time)
				i.position.x = x
				var x2 = Utility.get_position_on_timeline_from_value(i.end_time) - timeline_grabber_size * 0.5
				i.get_node("%EdgeMarker").global_position.x = x2
				i.get_node("%MarkerButton").size.x = x2 - x
				i.update_ticks()

var zoom_step := 2.0
var zoom_min_max := [2.0, 100.0]

func _ready():
	%LengthEdit.text_submitted.connect(
		func _on_length_edit_text_submitted(new_text):
			var x = int(new_text)
			max_value = x
			%LengthEdit.text = str(x)
	)
	%TimelineScrollbar.scrolling.connect(
		func scroll():
			%Timeline.position.x = -%TimelineScrollbar.value
	)
	%TimelineSlider.drag_started.connect(
		func drag_started():
			dragging = true
			
			prev_playback_speed = Playback.playback_speed
			Playback.playback_speed = 0
	)
	%TimelineSlider.drag_ended.connect(
		func drag_ended(value_changed):
			dragging = false
			
			Playback.playback_speed = prev_playback_speed
	)
	%TimelineSlider.value_changed.connect(
		func value_changed(value):
			if dragging:
				var new_step = 0.01
				if Input.is_action_pressed("ctrl"):
					new_step = 1
				elif Input.is_action_pressed("shift"):
					new_step = 0.1
				%TimelineSlider.step = new_step
				Playback.playhead = value
				prev_value_changed_value = value
	)

func _gui_input(event):
	if event is InputEventMouseButton:
		if !event.ctrl_pressed or !event.pressed: return
		
		
		var zoom_sign := 0
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP: zoom_sign = 1
			MOUSE_BUTTON_WHEEL_DOWN: zoom_sign = -1
		
		pixels_per_second = clampf(pixels_per_second + zoom_sign * zoom_step, zoom_min_max[0], zoom_min_max[1])

func _process(delta):
	_update()
	%Timeline.size.x = max_value * pixels_per_second + 2.0 * timeline_grabber_size

func _update():
	%TimelineScrollbar.max_value = Utility.get_encompassing_rect(%TimelineSlider).size.x
	%TimelineScrollbar.page = self.size.x
	
	if %TimelineScrollbar.page == %TimelineScrollbar.max_value: %TimelineScrollbar.hide(); %Timeline.position.x = 0.0
	elif not %TimelineScrollbar.visible: %TimelineScrollbar.show()
	
	var ratio = %TimelineScrollbar.max_value / %TimelineScrollbar.page
	
	
	%TimelineSlider.min_value = min_value
	%TimelineSlider.max_value = max_value
	%TimelineSlider.tick_count = max_value + 1
