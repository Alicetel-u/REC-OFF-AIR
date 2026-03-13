shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_disabled;

// ---- Uniforms ----
uniform vec3 ghost_color : source_color = vec3(0.9, 0.35, 0.3);
uniform float base_alpha : hint_range(0.0, 1.0) = 0.7;
uniform float rim_power : hint_range(0.5, 8.0) = 2.5;
uniform float rim_strength : hint_range(0.0, 3.0) = 1.2;
uniform float rage : hint_range(0.0, 1.0) = 0.0;        // 0=patrol, 1=chase
uniform float wobble_amp : hint_range(0.0, 0.15) = 0.03;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;     // 0=visible, 1=gone
uniform sampler2D ghost_texture : hint_default_white;

void vertex() {
	// ---- vertex wobble (ghostly wavering) ----
	float wobble = wobble_amp * (1.0 + rage * 2.0);
	float wave = sin(TIME * 2.0 + VERTEX.y * 4.0 + VERTEX.x * 1.5) * wobble;
	float wave2 = cos(TIME * 1.7 + VERTEX.z * 3.0) * wobble * 0.6;
	VERTEX += NORMAL * wave;
	VERTEX.x += wave2;
}

void fragment() {
	// ---- テクスチャをしっかり見せる ----
	vec3 tex_col = texture(ghost_texture, UV).rgb;
	vec3 rage_color = vec3(1.0, 0.12, 0.05);
	vec3 tint = mix(ghost_color, rage_color, rage * 0.7);
	// テクスチャ主体（0.85）に薄くゴーストカラーを乗せる
	vec3 col = mix(tex_col, tex_col * tint, 0.2 + rage * 0.15);
	ALBEDO = col;

	// ---- Fresnel rim glow ----
	float fresnel = pow(1.0 - abs(dot(NORMAL, VIEW)), rim_power);
	vec3 rim_col = mix(ghost_color, rage_color, rage);
	EMISSION = rim_col * fresnel * rim_strength * (1.0 + rage * 1.5);
	// ---- constant inner glow (暗闇で見えるように) ----
	EMISSION += tint * 0.2 * (1.0 + rage * 0.5);

	// ---- pulsating alpha ----
	float pulse = sin(TIME * 1.2) * 0.06 + sin(TIME * 3.7) * 0.03;
	float alpha = base_alpha + pulse;
	alpha += fresnel * 0.3;  // rim is more opaque
	alpha *= (1.0 + rage * 0.4);  // chase = more visible
	alpha = clamp(alpha, 0.0, 1.0);

	// ---- dissolve ----
	if (dissolve > 0.01) {
		float noise_val = fract(sin(dot(UV, vec2(12.9898, 78.233))) * 43758.5453);
		if (noise_val < dissolve) {
			discard;
		}
		alpha *= (1.0 - dissolve * 0.5);
	}

	ALPHA = alpha;
}
