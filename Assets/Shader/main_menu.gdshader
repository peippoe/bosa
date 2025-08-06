shader_type canvas_item;

uniform sampler2D noise_tex;
uniform vec2 scroll_amplitude = vec2(0.1, 0.1);
uniform float sin_frequency = 1.0;

void fragment() {
	vec2 uv = UV;
	
	vec2 scroll = vec2(0, sin(TIME * sin_frequency)) + vec2(TIME, 0);
	uv += scroll * scroll_amplitude;
	uv = fract(uv);
	COLOR = textureLod(noise_tex, uv, 0.0);
}
