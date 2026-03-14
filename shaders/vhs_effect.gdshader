shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float noise_strength     : hint_range(0.0, 0.3) = 0.01;
uniform float vignette_power     : hint_range(0.0, 2.0) = 0.5;
uniform float chroma_offset      : hint_range(0.0, 0.02) = 0.001;
uniform float block_noise        : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// --- Block noise (encoding error) ---
	if (block_noise > 0.0) {
		vec2 block = floor(uv * vec2(16.0, 12.0));
		float bn = hash(block + floor(TIME * 4.0));
		if (bn < block_noise * 0.3) {
			// ブロック単位で座標をずらす
			uv.x += (hash(block + 0.5) - 0.5) * block_noise * 0.08;
			uv.y += (hash(block + 1.5) - 0.5) * block_noise * 0.04;
		}
	}

	// --- Chromatic aberration (RGB split) ---
	float cr = textureLod(screen_texture, uv + vec2(chroma_offset,  0.0), 0.0).r;
	float cg = textureLod(screen_texture, uv, 0.0).g;
	float cb = textureLod(screen_texture, uv - vec2(chroma_offset,  0.0), 0.0).b;
	vec3 col = vec3(cr, cg, cb);

	// --- Scanlines ---
	float line = sin(uv.y * 500.0 * 3.14159) * 0.5 + 0.5;
	col = mix(col, col * line, scanline_intensity);

	// --- Film grain ---
	float grain = hash(uv + fract(vec2(TIME * 0.07, TIME * 0.11)));
	col += (grain - 0.5) * noise_strength;

	// --- Block color corruption ---
	if (block_noise > 0.5) {
		vec2 block2 = floor(uv * vec2(32.0, 24.0));
		float corrupt = hash(block2 + floor(TIME * 8.0));
		if (corrupt < (block_noise - 0.5) * 0.15) {
			col = mix(col, vec3(hash(block2), 0.0, hash(block2 + 3.0)), 0.7);
		}
	}

	// --- Vignette ---
	vec2 c   = uv - 0.5;
	float vig = 1.0 - dot(c, c) * vignette_power * 2.5;
	col *= clamp(vig, 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
