shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.35, 0.35, 0.33);
uniform vec3 moss_color : source_color = vec3(0.08, 0.12, 0.04);
uniform float moss_strength : hint_range(0.0, 1.0) = 0.6;
uniform float stone_roughness : hint_range(0.0, 1.0) = 0.95;

// PBR テクスチャ（Poly Haven CC0）
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rough_tex : filter_linear_mipmap, repeat_enable;
uniform float tex_blend : hint_range(0.0, 1.0) = 0.5;
uniform float tex_scale = 3.0;

float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
                   mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
                   mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

void fragment() {
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec2 tex_uv = world_pos.xz * tex_scale;

    // PBR テクスチャサンプリング
    vec3 tex_col = texture(albedo_tex, tex_uv).rgb;
    vec3 tex_nor = texture(normal_tex, tex_uv).rgb;
    float tex_rough = texture(rough_tex, tex_uv).r;

    // 石の質感を出すための細かなノイズ
    float detail_n = noise(world_pos * 50.0);
    float large_n = noise(world_pos * 5.0);

    // 基本色に変化をつける（汚れや色のムラ）
    vec3 final_base = base_color * (0.8 + 0.4 * large_n);
    final_base -= (1.0 - detail_n) * 0.1;

    // テクスチャとプロシージャルをブレンド
    final_base = mix(final_base, tex_col * base_color * 2.5, tex_blend);

    // 苔の計算 (上を向いている面 + 大きなノイズの塊)
    float up_factor = clamp(exp(8.0 * (NORMAL.y - 0.4)), 0.0, 1.0);
    float moss_mask = up_factor * moss_strength;
    moss_mask *= (0.5 + 0.5 * noise(world_pos * 3.0));

    ALBEDO = mix(final_base, moss_color * (0.8 + 0.4 * detail_n), clamp(moss_mask, 0.0, 1.0));

    // ラフネス
    float proc_rough = stone_roughness - detail_n * 0.1;
    ROUGHNESS = mix(proc_rough, tex_rough, tex_blend);

    // Normal Map（テクスチャベース）
    NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), tex_nor, tex_blend);
    NORMAL_MAP_DEPTH = 1.2;
}
