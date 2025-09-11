shader_type spatial;
render_mode depth_draw_opaque, cull_back;

uniform float intensity = 0.5;
uniform int steps : hint_range(2, 8) = 3;
uniform float specular_intensity : hint_range(0.0, 2.0) = 0.5;
//uniform sampler2D albedo_texture;

//void fragment() {
	//ALBEDO = texture(albedo_texture, UV).rgb;
//}

void light() {
	
	float NdotL = max(dot(NORMAL, LIGHT), 0.0);
	
	NdotL *= ATTENUATION;
	
	float toon_step = floor(NdotL * float(steps)) / float(steps);
	
	DIFFUSE_LIGHT = toon_step * intensity * LIGHT_COLOR;
	
	
	float spec = max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0);
	spec = pow(spec, 32.0); // Sharp highlight
	spec = step(0.5, spec); // Hard cutoff for toon specular
	SPECULAR_LIGHT = specular_intensity * spec * LIGHT_COLOR;
}
