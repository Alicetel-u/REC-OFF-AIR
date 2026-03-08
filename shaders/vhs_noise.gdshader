shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float shake_intensity : hint_range(0.0, 0.05) = 0.01;
uniform float noise_intensity : hint_range(0.0, 0.5) = 0.1;

// ── 動的ホラー演出パラメータ ──
uniform float chroma_boost : hint_range(0.0, 0.05) = 0.0;      // 色収差追加量
uniform float distortion : hint_range(0.0, 0.1) = 0.0;         // 画面歪み（波状）
uniform float desaturation : hint_range(0.0, 1.0) = 0.0;       // 彩度低下 (0=通常, 1=モノクロ)
uniform float vignette_boost : hint_range(0.0, 0.5) = 0.0;     // ビネット追加量 (内円を狭める)
uniform float glitch_strength : hint_range(0.0, 1.0) = 0.0;    // グリッチバー強度

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    float time = TIME * 2.0;

    // ── 画面歪み（水波） ──
    if (distortion > 0.001) {
        uv.x += sin(uv.y * 20.0 + TIME * 3.0) * distortion;
        uv.y += cos(uv.x * 15.0 + TIME * 2.5) * distortion * 0.6;
    }

    // ── グリッチバー（横縞ずれ） ──
    if (glitch_strength > 0.01) {
        float bar = step(0.97 - glitch_strength * 0.15, rand(vec2(floor(time * 8.0), floor(uv.y * 30.0))));
        uv.x += bar * (rand(vec2(time, uv.y)) - 0.5) * glitch_strength * 0.08;
    }

    // ── Scanline & Jitter ──
    uv.x += (rand(vec2(time, uv.y)) - 0.5) * shake_intensity;

    // ── 色収差（ベース + boost） ──
    float chroma = 0.002 + chroma_boost;
    vec4 col;
    col.r = texture(screen_texture, uv + vec2(chroma, 0.0)).r;
    col.g = texture(screen_texture, uv).g;
    col.b = texture(screen_texture, uv - vec2(chroma, 0.0)).b;
    col.a = 1.0;

    // ── ノイズ ──
    float n = (rand(uv + time) - 0.5) * noise_intensity;
    col.rgb += n;

    // ── 彩度低下 ──
    if (desaturation > 0.001) {
        float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
        col.rgb = mix(col.rgb, vec3(luma), desaturation);
    }

    // ── ビネット ──
    float dist = distance(uv, vec2(0.5));
    float vig_inner = 0.4 - vignette_boost;
    col.rgb *= smoothstep(0.8, max(vig_inner, 0.1), dist);

    COLOR = col;
}
