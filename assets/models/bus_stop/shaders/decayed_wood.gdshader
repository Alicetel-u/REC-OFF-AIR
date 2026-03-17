shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 wood_base_color : source_color = vec4(0.12, 0.09, 0.06, 1.0);
uniform vec4 wood_highlight_color : source_color = vec4(0.22, 0.19, 0.15, 1.0);
uniform vec4 moss_color : source_color = vec4(0.1, 0.25, 0.05, 1.0);
uniform float decay_amount : hint_range(0.0, 1.0) = 0.85;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.6;
uniform float uv_scale = 10.0;

// PBR テクスチャ（Poly Haven CC0）
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rough_tex : filter_linear_mipmap, repeat_enable;
uniform float tex_blend : hint_range(0.0, 1.0) = 0.6;
uniform float tex_scale = 3.0;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
float noise(vec2 x) {
    vec2 p = floor(x); vec2 f = fract(x); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(p), hash(vec2(p.x + 1.0, p.y)), f.x),
               mix(hash(vec2(p.x, p.y + 1.0)), hash(vec2(p.x + 1.0, p.y + 1.0)), f.x), f.y);
}
float cracks(vec2 uv) {
    uv *= 5.0; vec2 p = floor(uv); vec2 f = fract(uv);
    float crack_val = 1.0;
    for(int j=-1; j<=1; j++)
    for(int i=-1; i<=1; i++){
        vec2 g = vec2(float(i), float(j));
        float d = dot(g + vec2(hash(p + g)) - f, g + vec2(hash(p + g)) - f);
        crack_val = min(crack_val, d);
    }
    return 1.0 - smoothstep(0.0, 0.02, crack_val);
}

void fragment() {
    vec2 uv = UV * uv_scale;
    vec2 tex_uv = UV * tex_scale;

    // PBR テクスチャサンプリング
    vec3 tex_col = texture(albedo_tex, tex_uv).rgb;
    vec3 tex_nor = texture(normal_tex, tex_uv).rgb;
    float tex_rough = texture(rough_tex, tex_uv).r;

    // プロシージャルノイズ（苔・割れ目）
    float crack = cracks(uv * vec2(1.0, 5.0));
    float moss_noise = smoothstep(0.6, 0.9, hash(floor(uv * 3.0)) + hash(uv * 10.0) * 0.5) * moss_amount;

    // プロシージャル色
    vec3 proc_col = mix(wood_base_color.rgb, wood_highlight_color.rgb, 0.5);
    proc_col = mix(proc_col, proc_col * 0.2, crack * decay_amount);

    // テクスチャとプロシージャルをブレンド
    vec3 blended = mix(proc_col, tex_col * wood_base_color.rgb * 3.0, tex_blend);

    // 苔を最後に適用
    ALBEDO = mix(blended, moss_color.rgb, moss_noise);
    METALLIC = 0.0;

    // ラフネス
    float proc_rough = mix(0.7, 1.0, moss_noise + crack);
    ROUGHNESS = mix(proc_rough, tex_rough, tex_blend * 0.5);

    // Normal Map（テクスチャベース）
    NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), tex_nor, tex_blend);
    NORMAL_MAP_DEPTH = 1.2;
}
