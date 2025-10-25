extends MeshInstance3D

var id : int = 0
var texture_id : int = 0:
	set(value):
		texture_id = clampi(value, 0, TEXTURES.size()-1)
		material_override.albedo_texture = TEXTURES[texture_id]
		
		#material_override.uv1_triplanar = true
		#material_override.uv1_scale = Vector3.ONE * 0.5
		#if texture_id == 4:
			#material_override.uv1_triplanar = false
			#material_override.uv1_scale = Vector3.ONE

const TEXTURES = [
	null,
	preload("res://Assets/Images/Textures/grass.png"),
	preload("res://Assets/Images/Textures/grass_checkered.png"),
	preload("res://Assets/Images/Textures/stone.png"),
	preload("res://Assets/Images/Textures/gravel.png"),
	preload("res://Assets/Images/Textures/ivy2.png"),
]

const ENTITY_PROPERTIES = {
	"_": [
		"global_position", "rotation_degrees", "scale"
	],
	"Material": [
		"albedo_color", "texture_id", "emission_enabled", "emission", "emission_energy_multiplier", "uv1_scale", "uv1_triplanar", "uv1_world_triplanar"
	],
	"hidden": [
		"id",
	]
}

var ENTITY_RESOURCES = [self, material_override]

func _ready():
	var mat = material_override.duplicate()
	material_override = mat
	
	ENTITY_RESOURCES = [self, material_override]
