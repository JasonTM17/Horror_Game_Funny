shader_type canvas_item;
render_mode unshaded;

uniform float grain_strength : hint_range(0.0, 0.08) = 0.024;
uniform float scanline_strength : hint_range(0.0, 0.06) = 0.012;

float random_noise(vec2 coordinate) {
	return fract(sin(dot(coordinate, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float noise = random_noise(FRAGCOORD.xy + vec2(TIME * 37.0, TIME * 19.0));
	float scanline = 0.5 + 0.5 * sin(FRAGCOORD.y * 3.14159);
	float alpha = grain_strength * (0.35 + noise * 0.65) + scanline_strength * scanline;
	vec3 cold_grain = mix(vec3(0.02, 0.025, 0.035), vec3(0.32, 0.36, 0.42), noise);
	COLOR = vec4(cold_grain, alpha);
}
