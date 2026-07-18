shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.024;
uniform float scanline_strength : hint_range(0.0, 0.08) = 0.018;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.28;
uniform float vhs_strength : hint_range(0.0, 1.0) = 0.42;
uniform float fear_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float base_vignette_strength : hint_range(0.0, 0.3) = 0.085;
uniform float fear_vignette_strength : hint_range(0.0, 0.6) = 0.34;

float random_noise(vec2 coordinate) {
	return fract(sin(dot(coordinate, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float tracking_noise = random_noise(vec2(floor(SCREEN_UV.y * 96.0), floor(TIME * 8.0)));
	float tracking_band = smoothstep(0.94, 1.0, tracking_noise);
	float horizontal_jitter = (tracking_noise - 0.5) * 0.0012 + tracking_band * sin(TIME * 18.0) * 0.0025;
	vec2 sample_uv = SCREEN_UV + vec2(horizontal_jitter * vhs_strength, 0.0);
	sample_uv = clamp(sample_uv, SCREEN_PIXEL_SIZE * 0.5, vec2(1.0) - SCREEN_PIXEL_SIZE * 0.5);
	vec3 screen_color = texture(screen_texture, sample_uv).rgb;

	vec2 dither_cell = mod(floor(FRAGCOORD.xy), 2.0);
	float dither_threshold = dither_cell.y < 0.5
		? (dither_cell.x < 0.5 ? 0.0 : 2.0)
		: (dither_cell.x < 0.5 ? 3.0 : 1.0);
	vec3 dithered_color = floor(screen_color * 48.0 + dither_threshold * 0.25) / 48.0;
	screen_color = mix(screen_color, dithered_color, dither_strength);

	float noise = random_noise(FRAGCOORD.xy + vec2(TIME * 37.0, TIME * 19.0));
	float scanline = 0.5 + 0.5 * sin(FRAGCOORD.y * 3.14159);
	screen_color += (noise - 0.5) * grain_strength;
	screen_color *= 1.0 - scanline * scanline_strength;
	screen_color *= vec3(0.96, 0.985, 1.025);

	vec2 centered_uv = (SCREEN_UV - 0.5) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float edge = smoothstep(0.34, 0.9, length(centered_uv));
	float fear_pulse = 0.86 + 0.14 * sin(TIME * 5.5);
	screen_color *= 1.0 - edge * (base_vignette_strength + fear_intensity * fear_vignette_strength * fear_pulse);
	screen_color = mix(screen_color, screen_color * vec3(1.16, 0.72, 0.7), edge * fear_intensity * 0.18);
	COLOR = vec4(clamp(screen_color, vec3(0.0), vec3(1.0)), 1.0);
}
