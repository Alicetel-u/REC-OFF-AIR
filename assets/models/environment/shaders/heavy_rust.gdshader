shader_type spatial;
render_mode depth_draw_opaque;

uniform vec4 base_paint_color : source_color = vec4(0.2, 0.02, 0.02, 1.0);
uniform vec4 rust_color1 : source_color = vec4(0.1, 0.04, 0.01, 1.0);
uniform vec4 rust_color2 : source_color = vec4(0.04, 0.02, 0.01, 1.0);
uniform float rust_amount : hint_range(0.0, 1.0) = 0.5;

// PBR テクスチャ（Poly Haven CC0）
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rough_tex : filter_linear_mipmap, repeat_enable;
uniform float tex_blend : hint_range(0.0, 1.0) = 0.65;
uniform float tex_scale = 3.0;

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123); }
float noise(vec2 x) {
    vec2 p = floor(x); vec2 f = fract(x); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(p), hash(vec2(p.x + 1.0, p.y)), f.x),
               mix(hash(vec2(p.x, p.y + 1.0)), hash(vec2(p.x + 1.0, p.y + 1.0)), f.x), f.y);
}
float fbm(vec2 x) {
    float v = 0.0; float a = 0.5; vec2 shift = vec2(100.0);
    for (int i = 0; i < 5; ++i) { v += a * noise(x); x = x * 2.0 + shift; a *= 0.5; }
    return v;
}

void fragment() {
    vec2 uv = (world_position.xy + world_position.zx) * 4.0;
    vec2 tex_uv = (world_position.xy + world_position.zx) * tex_scale;

    // PBR テクスチャサンプリング
    vec3 tex_col = texture(albedo_tex, tex_uv).rgb;
    vec3 tex_nor = texture(normal_tex, tex_uv).rgb;
    float tex_rough = texture(rough_tex, tex_uv).r;

    // プロシージャルサビ
    float n1 = fbm(uv);
    float n2 = fbm(uv * 2.5 + vec2(100.0, 50.0));
    float rust_mask = smoothstep(0.8 - rust_amount, 1.2 - rust_amount, n1);
    float peeling = step(0.85 - rust_amount, n1);
    rust_mask = mix(rust_mask, 1.0, peeling * 0.5);

    vec3 rust_mix = mix(rust_color1.rgb, rust_color2.rgb, n2);
    vec3 proc_col = mix(base_paint_color.rgb, rust_mix, rust_mask);

    // テクスチャとプロシージャルをブレンド
    ALBEDO = mix(proc_col, tex_col * rust_mix * 3.0, tex_blend * rust_mask);

    float final_roughness = mix(0.7, 1.0, rust_mask);
    ROUGHNESS = mix(final_roughness, tex_rough, tex_blend);

    float final_metallic = mix(0.3, 0.0, rust_mask);
    METALLIC = final_metallic;

    // Normal Map（テクスチャベース）
    NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), tex_nor, tex_blend);
    NORMAL_MAP_DEPTH = 1.5;
}
