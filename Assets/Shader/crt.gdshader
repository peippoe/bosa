shader_type canvas_item;

uniform int quantize_groups : hint_range(1, 8) = 2;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D gradient_tex;
uniform sampler2D posterize_tex;
uniform int dither_size : hint_range(1.0, 8.0) = 1;
uniform float dither_mult : hint_range(0.0, 4.0) = 1.0;


//const int DITHER_SIZE = 2;
//const float DITHER_PATTERN[DITHER_SIZE * DITHER_SIZE] = {
	//0.5 / 4.0, 2.5 / 4.0,
	//3.5 / 4.0, 1.5 / 4.0 };

//const int DITHER_SIZE = 4;
//const float DITHER_PATTERN[DITHER_SIZE * DITHER_SIZE] = {
     //0.5 / 16.0,  8.5 / 16.0,  2.5 / 16.0, 10.5 / 16.0,
    //12.5 / 16.0,  4.5 / 16.0, 14.5 / 16.0,  6.5 / 16.0,
     //3.5 / 16.0, 11.5 / 16.0,  1.5 / 16.0,  9.5 / 16.0,
    //15.5 / 16.0,  7.5 / 16.0, 13.5 / 16.0,  5.5 / 16.0 };

const int DITHER_SIZE = 8;
const float DITHER_PATTERN[DITHER_SIZE * DITHER_SIZE] = {
	 0.5 / 64.0, 48.5 / 64.0, 12.5 / 64.0, 60.5 / 64.0,  3.5 / 64.0, 51.5 / 64.0, 15.5 / 64.0, 63.5 / 64.0,
	32.5 / 64.0, 16.5 / 64.0, 44.5 / 64.0, 28.5 / 64.0, 35.5 / 64.0, 19.5 / 64.0, 47.5 / 64.0, 31.5 / 64.0,
	 8.5 / 64.0, 56.5 / 64.0,  4.5 / 64.0, 52.5 / 64.0, 11.5 / 64.0, 59.5 / 64.0,  7.5 / 64.0, 55.5 / 64.0,
	40.5 / 64.0, 24.5 / 64.0, 36.5 / 64.0, 20.5 / 64.0, 43.5 / 64.0, 27.5 / 64.0, 39.5 / 64.0, 23.5 / 64.0,
	 2.5 / 64.0, 50.5 / 64.0, 14.5 / 64.0, 62.5 / 64.0,  1.5 / 64.0, 49.5 / 64.0, 13.5 / 64.0, 61.5 / 64.0,
	34.5 / 64.0, 18.5 / 64.0, 46.5 / 64.0, 30.5 / 64.0, 33.5 / 64.0, 17.5 / 64.0, 45.5 / 64.0, 29.5 / 64.0,
	10.5 / 64.0, 58.5 / 64.0,  6.5 / 64.0, 54.5 / 64.0,  9.5 / 64.0, 57.5 / 64.0,  5.5 / 64.0, 53.5 / 64.0,
	42.5 / 64.0, 26.5 / 64.0, 38.5 / 64.0, 22.5 / 64.0, 41.5 / 64.0, 25.5 / 64.0, 37.5 / 64.0, 21.5 / 64.0 };


void fragment()
{
	vec4 original_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	ivec2 p = ivec2(SCREEN_UV / SCREEN_PIXEL_SIZE) / dither_size % ivec2(DITHER_SIZE);
	float g = float(quantize_groups);
	float t = DITHER_PATTERN[p.y * DITHER_SIZE + p.x];
	
	vec4 dithered_color = (step(t, fract(original_color * g)) + floor(original_color * g)) / g;
	
	float value = (original_color.r + original_color.g + original_color.b) / 3.0;
	
	vec4 value_color = original_color * texture(posterize_tex, vec2(value, 0.5));
	
	value = (value_color.r + value_color.g + value_color.b) / 3.0;
	
	vec4 grad = texture(gradient_tex, vec2(value, 0.5));
	float aleph = grad.a;
	
	//COLOR = dithered_color * (1.0 - a) + original_color * a;
	
	
	float diff_r = dithered_color.r - original_color.r;
	float diff_g = dithered_color.g - original_color.g;
	float diff_b = dithered_color.b - original_color.b;
	vec4 diff = vec4(diff_r, diff_g, diff_b, 1.0);
	
	
	
	COLOR = original_color + diff * aleph * dither_mult;
	//COLOR = texture(posterize_tex, vec2(value, 0.5));
}