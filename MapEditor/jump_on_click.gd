extends HScrollBar


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		
		value = Utility.get_scrollbar_value_from_position(event.position, self)
		scrolling.emit()
