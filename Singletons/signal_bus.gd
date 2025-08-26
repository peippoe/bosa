extends Node


signal marker_drag_start(marker)
signal marker_drag_end(marker)

func _ready():
	marker_drag_start.connect(
		func marker_drag_start(marker):
			
			if marker.has_meta("gizmo"):
				get_tree().current_scene.record(marker.get_meta("gizmo"), "pop_time", marker.get_meta("gizmo").pop_time)
			
			elif marker.get_parent().has_meta("gizmo"):
				if marker.name == "Start":
					get_tree().current_scene.record(marker.get_parent().get_meta("gizmo"), "start_time", marker.get_parent().get_meta("gizmo").start_time)
				else:
					get_tree().current_scene.record(marker.get_parent().get_meta("gizmo"), "pop_time", marker.get_parent().get_meta("gizmo").pop_time)
	)
	
	#marker_drag_end.connect(
		#func marker_drag_end(marker):
			#
	#)
