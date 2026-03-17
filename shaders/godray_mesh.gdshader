shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;

// ゴッドレイメッシュ用シェーダー（BAKIN方式）
// 加算ブレンドで半透明の光の筋を表現
// MeshInstance3D（円錐や板）にアタッチして使用

uniform vec4 ray_color : source_color = vec4(1.0, 0.95, 0.8, 0.15);
uniform float intensity : hint_range(0.0, 3.0) = 1.0;
uniform float fade_power : hint_range(0.1, 5.0) = 2.0;
uniform float scroll_speed : hint_range(0.0, 1.0) = 0.05;
uniform float noise_scale : hint_range(0.5, 10.0) = 3.0;

// 簡易ノイズ関数
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	// UV.y が 0（光源側）→ 1（先端）で減衰
	float fade = pow(1.0 - UV.y, fade_power);

	// ノイズで揺らめき
	float n = noise(UV * noise_scale + vec2(TIME * scroll_speed, TIME * scroll_speed * 0.7));
	float shimmer = 0.7 + 0.3 * n;

	ALBEDO = ray_color.rgb * intensity * shimmer;
	ALPHA = ray_color.a * fade * intensity * shimmer;
}
