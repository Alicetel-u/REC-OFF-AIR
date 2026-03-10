shader_type spatial;
render_mode depth_draw_opaque;

// ====================================================
// 案山子の着物用シェーダー
// 藍染めの古い布地を再現する
// - 織り目（縦糸・横糸）のパターン
// - しわ・折り目のノーマルマッピング
// - 藍染めの色むら・経年変化
// - 布特有のラフネスばらつき
// ====================================================

// 基本色（藍色）
uniform vec4 fabric_color : source_color = vec4(0.22, 0.28, 0.4, 1.0);
// 色褪せた部分の色
uniform vec4 faded_color : source_color = vec4(0.35, 0.38, 0.48, 1.0);
// 織り目のスケール（大きいほど細かい）
uniform float weave_scale : hint_range(10.0, 200.0) = 80.0;
// しわの強さ
uniform float wrinkle_strength : hint_range(0.0, 1.0) = 0.6;
// 色褪せの強さ
uniform float fade_amount : hint_range(0.0, 1.0) = 0.3;
// 汚れの強さ
uniform float dirt_amount : hint_range(0.0, 1.0) = 0.15;
// ほんのり発光（暗闘でシルエットが浮かぶ程度）
uniform vec4 glow_color : source_color = vec4(0.3, 0.35, 0.5, 1.0);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.25;

// ハッシュ関数（ランダム値生成）
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

// スムーズノイズ
float noise(vec2 x) {
	vec2 p = floor(x);
	vec2 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(p), hash(vec2(p.x + 1.0, p.y)), f.x),
		mix(hash(vec2(p.x, p.y + 1.0)), hash(vec2(p.x + 1.0, p.y + 1.0)), f.x),
		f.y
	);
}

// フラクタルブラウン運動（自然な凹凸を生成）
float fbm(vec2 uv) {
	float val = 0.0;
	float amp = 0.5;
	vec2 p = uv;
	for (int i = 0; i < 4; i++) {
		val += amp * noise(p);
		p *= 2.1;
		amp *= 0.5;
	}
	return val;
}

void fragment() {
	vec2 uv = UV;

	// ============================
	// 1. 織り目パターン（縦糸・横糸）
	// ============================
	vec2 weave_uv = uv * weave_scale;

	// 縦糸の筋
	float warp = sin(weave_uv.x * PI * 2.0) * 0.5 + 0.5;
	// 横糸の筋（少し太さが違う → リアルな織物感）
	float weft = sin(weave_uv.y * PI * 2.0 * 0.8) * 0.5 + 0.5;

	// 織り交差パターン（市松模様的な交互パターン）
	float checker = step(0.5, fract(weave_uv.x * 0.5)) *
	                step(0.5, fract(weave_uv.y * 0.5));
	float weave_pattern = mix(warp, weft, checker);
	// 織り目の微妙な凹凸
	float weave_bump = weave_pattern * 0.08;

	// ============================
	// 2. しわ・折り目（大きなスケール）
	// ============================
	// 大きなしわ（布全体のたるみ）
	float wrinkle_large = fbm(uv * 5.0) * wrinkle_strength;
	// 小さなしわ（細かいシワ）
	float wrinkle_small = fbm(uv * 18.0 + 3.7) * wrinkle_strength * 0.4;
	float wrinkle = wrinkle_large + wrinkle_small;

	// ============================
	// 3. ノーマルマップ生成（織り目 + しわ）
	// ============================
	float bump = weave_bump + wrinkle * 0.15;
	// 微小なオフセットでノーマルを計算
	float eps = 0.002;
	float bump_x = weave_bump + fbm((uv + vec2(eps, 0.0)) * 5.0) * wrinkle_strength * 0.15;
	float bump_y = weave_bump + fbm((uv + vec2(0.0, eps)) * 5.0) * wrinkle_strength * 0.15;
	vec3 normal_offset = normalize(vec3(
		(bump - bump_x) / eps * 0.5,
		(bump - bump_y) / eps * 0.5,
		1.0
	));
	NORMAL_MAP = normal_offset * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.8;

	// ============================
	// 4. 藍染めの色むら・経年変化
	// ============================
	// 大きな色むら（染めムラ）
	float dye_variation = fbm(uv * 3.0 + 1.5);
	// 色褪せ（日焼けなど）— 上部ほど色褪せやすい
	float sun_fade = smoothstep(0.3, 0.8, uv.y) * fade_amount;

	vec3 base = fabric_color.rgb;
	// 染めムラを加える
	base = mix(base, base * 0.85, dye_variation * 0.3);
	// 色褪せた部分を混ぜる
	base = mix(base, faded_color.rgb, sun_fade);

	// ============================
	// 5. 汚れ・経年変化
	// ============================
	float dirt = fbm(uv * 8.0 + 7.3);
	float dirt_mask = smoothstep(0.4, 0.7, dirt) * dirt_amount;
	// 汚れは暗い茶色系
	vec3 dirt_color = vec3(0.12, 0.1, 0.07);
	base = mix(base, dirt_color, dirt_mask);

	// ============================
	// 6. 織り目による微妙な色のばらつき
	// ============================
	base *= mix(0.92, 1.05, weave_pattern);

	ALBEDO = base;

	// ほんのり発光 — 暗闇でシルエットが不気味に浮かぶ
	EMISSION = glow_color.rgb * glow_strength;

	// 布は比較的粗い表面、しわ部分はよりマットに
	ROUGHNESS = mix(0.75, 0.95, wrinkle * 0.5 + weave_bump * 2.0);
	// 布は金属感なし
	METALLIC = 0.0;
	// 微妙なサブサーフェス散乱（布の半透明感）
	SPECULAR = 0.3;
}
