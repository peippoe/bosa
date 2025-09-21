extends WorldEnvironment




const ENTITY_PROPERTIES = {
	#"Background": [
		#"background_mode", "background_energy_multiplier"
	#],
	"Tonemap": [
		"tonemap_mode", "tonemap_exposure", "tonemap_white"
	],
	"Sky": [
		"sky_top_color", "sky_horizon_color", "ground_horizon_color", "ground_bottom_color"
	]
	#"Glow": [
		#"glow_enabled"
	#],
	#"Adjustments": 0
}


#func _ready():
	##print(get_property_list())
	##print(environment.get_property_list())
	#print(Utility.get_entity_properties(self, self.environment))
