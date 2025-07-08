extends MeshInstance3D

var type := Utility.TargetType.TAP
var pop_time := 0.0
var marker : Node:
	set(value):
		marker = value
		marker.get_child(0).button_up.connect(func marker_up():
			var timeline = get_tree().current_scene.get_node("%Timeline")
			var marker_local = Utility.get_control_local_position(marker)
			pop_time = Utility.get_scrollbar_value_from_position(marker_local, timeline)
		)

var node_properties = ["global_position", "global_rotation"]
