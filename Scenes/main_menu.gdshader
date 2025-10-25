shader_type canvas_item;

uniform float speed = 1.0;

uniform vec4 color1 : source_color = vec4(1.0, 1.0, 1.0, 1.0); 
uniform vec4 color2 : source_color = vec4(0.7, 0.7, 0.7, 1.0);

uniform float direction_x : hint_range(-1.0, 1.0) = 1.0; // Horizontal movement
uniform float direction_y : hint_range(-1.0, 1.0) = 1.0; // Vertical movement

uniform float size : hint_range(0.02, 1.0) = 2.0;

void fragment() {
	float time_offset = TIME * speed;
	
	vec2 pos = UV.xy / size;
	
	vec2 direction = normalize(vec2(direction_x, direction_y));
    vec2 movement = direction * time_offset;
	
	pos -= movement;
	pos = floor(pos);
	
	float pattern_mask = mod(pos.x + mod(pos.y, 2.0), 2.0);
	
	COLOR = mix(color1, color2, pattern_mask);
}

