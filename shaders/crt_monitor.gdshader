shader_type canvas_item;

// CRTブラウン管モニター演出 — 走査線・画面湾曲・蛍光体・ちらつき
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

// 強度（0=OFF, 1=フル）
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

// 走査線
uniform float scanline_weight : hint_range(0.0, 1.0) = 0.35;
uniform float scanline_count : hint_range(200.0, 1200.0) = 480.0;

// 画面湾曲（バレルディストーション）
uniform float curvature : hint_range(0.0, 0.5) = 0.15;

// RGB分離（色収差）
uniform float chroma_shift : hint_range(0.0, 0.01) = 0.003;

// 蛍光体ブルーム（にじみ）
uniform float phosphor_blur : hint_range(0.0, 3.0) = 1.0;

// フリッカー（ちらつき）
uniform float flicker : hint_range(0.0, 0.15) = 0.04;

// ビネット（ブラウン管の角の減光）
uniform float vignette : hint_range(0.0, 2.0) = 1.2;

// 全体の色調（古いモニターの色）
uniform vec3 tint : source_color = vec3(0.9, 0.95, 0.85);

// ノイズ
uniform float noise : hint_range(0.0, 0.2) = 0.06;

// 横ずれ
uniform float jitter : hint_range(0.0, 0.01) = 0.001;


float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 crt_curve(vec2 uv, float k) {
	vec2 c = uv * 2.0 - 1.0;
	float r2 = dot(c, c);
	c *= 1.0 + k * r2;
	return c * 0.5 + 0.5;
}

void fragment() {
	if (intensity < 0.001) {
		COLOR = texture(screen_tex, SCREEN_UV);
		return;
	}

	float t = TIME;

	// --- 画面湾曲 ---
	float curv = curvature * intensity;
	vec2 uv = mix(SCREEN_UV, crt_curve(SCREEN_UV, curv), intensity);

	// 範囲外→黒
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}

	// --- 横ジッター ---
	float j = jitter * intensity * (hash12(vec2(floor(uv.y * 240.0), t * 50.0)) * 2.0 - 1.0);
	uv.x += j;

	// --- RGB色収差 ---
	float cs = chroma_shift * intensity;
	float r = texture(screen_tex, uv + vec2( cs, 0.0)).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv + vec2(-cs, 0.0)).b;
	vec3 col = vec3(r, g, b);

	// --- 蛍光体ブルーム（簡易ボックスブラー） ---
	float blur_px = phosphor_blur * intensity / 1920.0;
	if (blur_px > 0.0001) {
		vec3 bloom = vec3(0.0);
		bloom += texture(screen_tex, uv + vec2(-blur_px, 0.0)).rgb;
		bloom += texture(screen_tex, uv + vec2( blur_px, 0.0)).rgb;
		bloom += texture(screen_tex, uv + vec2(0.0, -blur_px)).rgb;
		bloom += texture(screen_tex, uv + vec2(0.0,  blur_px)).rgb;
		col = mix(col, bloom * 0.25, 0.3 * intensity);
	}

	// --- 走査線 ---
	float sl = sin(uv.y * scanline_count * 3.14159) * 0.5 + 0.5;
	sl = mix(1.0, sl, scanline_weight * intensity);
	col *= sl;

	// --- フリッカー ---
	float flick = 1.0 + flicker * intensity * sin(t * 60.0 + sin(t * 13.7) * 3.0);
	col *= flick;

	// --- ノイズ ---
	float n = (hash12(uv * vec2(1920.0, 1080.0) + t * 137.0) - 0.5) * noise * intensity;
	col += vec3(n);

	// --- 色調 ---
	col *= mix(vec3(1.0), tint, intensity);

	// --- ビネット ---
	vec2 vig_uv = uv * 2.0 - 1.0;
	float vig = dot(vig_uv, vig_uv);
	col *= mix(1.0, 1.0 - vig * vignette * 0.5, intensity);

	// 角の丸み（ブラウン管のフレーム）
	float edge = smoothstep(0.0, 0.02 * intensity, uv.x)
	           * smoothstep(0.0, 0.02 * intensity, 1.0 - uv.x)
	           * smoothstep(0.0, 0.02 * intensity, uv.y)
	           * smoothstep(0.0, 0.02 * intensity, 1.0 - uv.y);
	col *= mix(1.0, edge, intensity);

	COLOR = vec4(col, 1.0);
}
