shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float zoom_amount : hint_range(0.0, 1.0) = 0.0;
uniform float zoom_scale : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	vec2 zoom_uv = SCREEN_UV - vec2(0.5);

	zoom_uv *= vec2(1.0 - zoom_scale * zoom_amount);

	zoom_uv += vec2(0.5);

    COLOR = textureLod(screen_texture, zoom_uv, 0.0);
}