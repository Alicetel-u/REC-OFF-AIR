shader_type canvas_item;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.10;
uniform float noise_strength     : hint_range(0.0, 0.15) = 0.035;
uniform float vignette_power     : hint_range(0.0, 2.0) = 0.9;
uniform float chroma_offset      : hint_range(0.0, 0.008) = 0.0025;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// --- Chromatic aberration (RGB split) ---
	float cr = textureLod(SCREEN_TEXTURE, uv + vec2(chroma_offset,  0.0), 0.0).r;
	float cg = textureLod(SCREEN_TEXTURE, uv, 0.0).g;
	float cb = textureLod(SCREEN_TEXTURE, uv - vec2(chroma_offset,  0.0), 0.0).b;
	vec3 col = vec3(cr, cg, cb);

	// --- Scanlines ---
	float line = sin(uv.y * 500.0 * 3.14159) * 0.5 + 0.5;
	col = mix(col, col * line, scanline_intensity);

	// --- Film grain ---
	float grain = hash(uv + fract(vec2(TIME * 0.07, TIME * 0.11)));
	col += (grain - 0.5) * noise_strength;

	// --- Vignette ---
	vec2 c   = uv - 0.5;
	float vig = 1.0 - dot(c, c) * vignette_power * 2.5;
	col *= clamp(vig, 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
