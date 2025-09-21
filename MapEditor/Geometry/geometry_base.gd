extends MeshInstance3D

var id : int = 0
var texture_id : int = 0:
	set(value):
		texture_id = clampi(value, 0, TEXTURES.size()-1)
		material_override.albedo_texture = TEXTURES[texture_id]
		
		material_override.uv1_triplanar = true
		material_override.uv1_scale = Vector3.ONE * 0.5
		if texture_id == 4:
			material_override.uv1_triplanar = false
			material_override.uv1_scale = Vector3.ONE

const TEXTURES = [
	null,
	preload("uid://bc4cnwonssqlp"),
	preload("uid://cvf4fy2ibfg6w"),
	preload("uid://cxh5y86sxb1dr"),
	preload("uid://jjf1fq65nebn")
]

const ENTITY_PROPERTIES = {
	"_": [
		"global_position", "rotation_degrees", "scale", "texture_id"
	],
	"Material": [
		"albedo_color"
	],
	"hidden": [
		"id",
	]
}
