extends Node


signal marker_drag_start(marker)
signal marker_drag_end(marker)

#func _ready():
	#marker_drag_start.connect(
		#func marker_drag_start(marker):
			#GameManager.dragging_marker = true
			#GameManager.dragged_marker = marker
	#)
	#
	#marker_drag_end.connect(
		#func marker_drag_end(marker):
			#GameManager.dragging_marker = false
			#GameManager.dragged_marker = null
	#)
