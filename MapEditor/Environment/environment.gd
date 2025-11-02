extends WorldEnvironment




const ENTITY_PROPERTIES = {
	#"Background": [
		#"background_mode", "background_energy_multiplier"
	#],
	"Tonemap": [
		"tonemap_mode", "tonemap_exposure", "tonemap_white"
	],
	"Adjustments": [
		"adjustment_brightness", "adjustment_contrast", "adjustment_saturation"
	],
	"Sky": [
		"sky_top_color", "sky_horizon_color", "ground_horizon_color", "ground_bottom_color", "sky_cover_modulate", "sky_curve"
	],
	"Fog": [
		"fog_enabled", "fog_light_color", "fog_light_energy", "fog_density", "fog_sky_affect"
	]
	#"Glow": [
		#"glow_enabled"
	#],
	#"Adjustments": 0
}

var ENTITY_RESOURCES = [environment, environment.sky, environment.sky.sky_material]


#func _ready():
	##print(get_property_list())
	##print(environment.get_property_list())
	#print(Utility.get_entity_properties(self, self.environment))
