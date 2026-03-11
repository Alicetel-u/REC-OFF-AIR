shader_type canvas_item;

// 魚眼レンズ（バレルディストーション）— ホラー演出用
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float distortion : hint_range(0.0, 2.0) = 0.0;
uniform float zoom : hint_range(0.5, 1.5) = 1.0;
uniform float chromatic : hint_range(0.0, 0.02) = 0.003;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.8;
uniform float vignette_radius : hint_range(0.0, 1.5) = 0.7;
uniform float grain : hint_range(0.0, 0.15) = 0.04;
uniform float breath : hint_range(0.0, 0.3) = 0.0;

vec2 barrel_distort(vec2 uv, float k) {
    vec2 c = uv * 2.0 - 1.0;
    float r2 = dot(c, c);
    float f = 1.0 + k * r2 + k * k * r2 * r2;
    return c * f * 0.5 + 0.5;
}

float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
    float t = TIME;
    float bp = breath * sin(t * 1.2) * 0.5;
    float d = distortion + bp;
    float z = zoom - bp * 0.3;

    vec2 uv = (SCREEN_UV - 0.5) / z + 0.5;

    // 色収差付きバレルディストーション
    vec2 uv_r = barrel_distort(uv, d + chromatic * 2.0);
    vec2 uv_g = barrel_distort(uv, d);
    vec2 uv_b = barrel_distort(uv, d - chromatic * 2.0);

    float r = texture(screen_tex, uv_r).r;
    float g = texture(screen_tex, uv_g).g;
    float b = texture(screen_tex, uv_b).b;
    vec3 col = vec3(r, g, b);

    // 周辺減光
    vec2 vig_uv = SCREEN_UV * 2.0 - 1.0;
    float vig = smoothstep(vignette_radius, vignette_radius + 0.5, length(vig_uv)) * vignette_strength;
    col *= 1.0 - vig;

    // フィルムグレイン
    col += (hash(SCREEN_UV * vec2(1920.0, 1080.0) + t * 100.0) - 0.5) * grain;

    // 範囲外を黒に
    if (uv_g.x < 0.0 || uv_g.x > 1.0 || uv_g.y < 0.0 || uv_g.y > 1.0) {
        col = vec3(0.0);
    }

    COLOR = vec4(col, 1.0);
}
