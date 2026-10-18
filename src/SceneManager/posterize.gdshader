shader_type canvas_item;

// Full-screen pass drawn on top of the game SubViewport. Quantizes the
// already-rendered game image, so the CRT shader on the container always
// receives a posterized source.

uniform int posterize_mode : hint_enum("256 colors (8x8x4)", "6 bits per channel") = 1;
uniform float posterize_amount : hint_range(0.0, 1.0) = 1.0;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

vec3 posterize_color(vec3 c) {
	if (posterize_mode == 1) {
		// 64 levels per channel = 6 bits per channel
		return round(c * 63.0) / 63.0;
	}
	// 8 x 8 x 4 = 256 colors (VGA 3-3-2 style)
	vec3 levels = vec3(7.0, 7.0, 3.0);
	return round(c * levels) / levels;
}

void fragment() {
	vec3 col = texture(screen_texture, SCREEN_UV).rgb;
	COLOR = vec4(mix(col, posterize_color(col), posterize_amount), 1.0);
}
