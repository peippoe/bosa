shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

const mat4 bayer_matrix_4x4 = mat4(
    vec4(    -0.5,       0.0,  -0.375,   0.125 ),
    vec4(    0.25,   -0.25,   0.375, - 0.125 ),
    vec4( -0.3125,  0.1875, -0.4375,  0.0625 ),
    vec4(  0.4375, -0.0625,  0.3125, -0.1875 )
);

uniform float dither_scale = 1.0;
uniform float levels = 16.0; // how many color steps per channel
uniform float dither_intensity = 1.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 frag_coord = FRAGCOORD.xy / dither_scale;
	int xi = int(mod(frag_coord.x, 4.0));
	int yi = int(mod(frag_coord.y, 4.0));
	float dither_shift = bayer_matrix_4x4[xi][yi];

	vec3 col = texture(screen_texture, SCREEN_UV).rgb;

	vec2 center = vec2(0.5);
	float dist = distance(center, UV);
	float edge_factor = smoothstep(0.0, 2.0, dist) + 0.05;

	col = col * (levels - 1.0) + dither_shift * dither_intensity * edge_factor; // add shift
	col = floor(col);                          // quantize
	col = col / (levels - 1.0);                // normalize back

	ALBEDO = col;

	//ALBEDO.r = edge_factor;
	//ALBEDO.gb = vec2(0.0);


	//ALBEDO = original_color.rgb + dither_shift;

	// Raw depth
	//ALBEDO.rgb = vec3(depth_raw);// + tex.rgb;
	// Linear depth
	//ALBEDO.rgb = vec3(fract(linear_depth));
}