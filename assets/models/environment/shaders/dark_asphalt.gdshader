shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 asphalt_color : source_color = vec4(0.16, 0.15, 0.14, 1.0);
uniform vec4 crack_color : source_color = vec4(0.04, 0.04, 0.03, 1.0);
uniform vec4 puddle_color : source_color = vec4(0.06, 0.06, 0.07, 1.0);
uniform float wetness : hint_range(0.0, 1.0) = 0.5;

// PBR テクスチャ（Poly Haven CC0）
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rough_tex : filter_linear_mipmap, repeat_enable;
uniform float tex_blend : hint_range(0.0, 1.0) = 0.7;
uniform float tex_scale = 4.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123); }
float noise(vec2 x) {
    vec2 p = floor(x); vec2 f = fract(x); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(p), hash(vec2(p.x + 1.0, p.y)), f.x),
               mix(hash(vec2(p.x, p.y + 1.0)), hash(vec2(p.x + 1.0, p.y + 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
    float f = 0.0; float w = 0.5;
    for (int i = 0; i < 5; i++) { f += w * noise(p); p *= 2.0; w *= 0.5; }
    return f;
}
float cracks(vec2 uv) {
    float n1 = fbm(uv * 3.0);
    float n2 = fbm(uv * 8.0 + vec2(10.0));
    float c = abs(n1 - 0.5) * 2.0;
    return smoothstep(0.02, 0.0, c) * n2;
}

void fragment() {
    vec2 uv = UV * 20.0;
    vec2 tex_uv = UV * tex_scale;

    // PBR テクスチャサンプリング
    vec3 tex_col = texture(albedo_tex, tex_uv).rgb;
    vec3 tex_nor = texture(normal_tex, tex_uv).rgb;
    float tex_rough = texture(rough_tex, tex_uv).r;

    // プロシージャルノイズ
    float base_noise = fbm(uv);
    float crack = cracks(uv * 0.5) + cracks(uv * 1.2 + vec2(5.0)) * 0.5;
    crack = clamp(crack, 0.0, 1.0);
    float puddle = smoothstep(0.5, 0.65, fbm(uv * 0.3));

    vec3 proc_col = mix(asphalt_color.rgb, asphalt_color.rgb * 0.5, base_noise * 0.5);
    proc_col = mix(proc_col, crack_color.rgb, crack);
    proc_col = mix(proc_col, puddle_color.rgb, puddle * wetness);

    // テクスチャとプロシージャルをブレンド
    ALBEDO = mix(proc_col, tex_col * asphalt_color.rgb * 2.0, tex_blend);

    // ラフネス
    float r = mix(0.9, 0.6, base_noise);
    r = mix(r, 0.1, puddle * wetness);
    ROUGHNESS = mix(r, tex_rough, tex_blend);

    METALLIC = mix(0.0, 0.3, puddle * wetness);

    // Normal Map（テクスチャベース）
    NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), tex_nor, tex_blend);
    NORMAL_MAP_DEPTH = 1.5;
}
