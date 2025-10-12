extends MeshInstance3D


var id : int = Utility.EntityID["BOOST_PAD"]

const ENTITY_PROPERTIES = {
	"_": [
		"global_position", "rotation_degrees", "scale"
	],
	"hidden": [
		"id",
	]
}

var ENTITY_RESOURCES = [self]
