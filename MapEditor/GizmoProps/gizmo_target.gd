extends MeshInstance3D

var id : int = Utility.EntityID["TARGET_TAP"]
var pop_time : float = 0.0
var marker : Node = null

const ENTITY_PROPERTIES = {
	"_": [
		"pop_time",
		"global_position", "global_rotation", "scale"
	],
	"hidden": [
		"id", "marker",
	]
}
