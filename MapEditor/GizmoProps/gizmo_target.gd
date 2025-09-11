extends MeshInstance3D

var id := Utility.EntityID["TARGET_TAP"]
var pop_time := 0.0
var marker : Node

const ENTITY_PROPERTIES = [
	"id", "pop_time", "marker",
	"global_position", "global_rotation", "scale"
	]
