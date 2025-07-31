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
				var x = remap(i.get_meta("gizmo").pop_time, %TimelineSlider.min_value, %TimelineSlider.max_value, timeline_grabber_size, %Timeline.size.x - timeline_grabber_size)
				i.position.x = x
				print(x)
			elif i.has_meta("bpm"):
				#print(i.get_meta("start_time"))
				var x = remap(i.get_meta("start_time"), %TimelineSlider.min_value, %TimelineSlider.max_value, timeline_grabber_size, %Timeline.size.x - timeline_grabber_size)
				i.position.x = x
				var x2 = remap(i.get_meta("end_time"), %TimelineSlider.min_value, %TimelineSlider.max_value, timeline_grabber_size, %Timeline.size.x - timeline_grabber_size) - timeline_grabber_size * 0.5
				i.get_node("TextureButton2").global_position.x = x2
				i.get_node("TextureButton").size.x = x2 - x

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
	var a = Utility.get_encompassing_rect(%TimelineSlider)
	%TimelineScrollbar.max_value = a.size.x
	%TimelineScrollbar.page = self.size.x
	print(a)
	if %TimelineScrollbar.page == %TimelineScrollbar.max_value: %TimelineScrollbar.hide(); %Timeline.position.x = 0.0
	elif not %TimelineScrollbar.visible: %TimelineScrollbar.show()
	
	var ratio = %TimelineScrollbar.max_value / %TimelineScrollbar.page
	
	
	%TimelineSlider.min_value = min_value
	%TimelineSlider.max_value = max_value
	%TimelineSlider.tick_count = max_value + 1
