extends MeshInstance3D

var type := Enums.GizmoType.TARGET_TAP
var pop_time := 0.0
var marker : Node

const ENTITY_PROPERTIES = [
	"type", "pop_time", "marker",
	"global_position", "global_rotation", "scale"
	]
