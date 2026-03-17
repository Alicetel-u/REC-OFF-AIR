shader_type spatial;
render_mode depth_draw_opaque;

uniform vec4 mud_color : source_color = vec4(0.12, 0.08, 0.05, 1.0);
uniform vec4 water_color : source_color = vec4(0.08, 0.1, 0.1, 1.0);
uniform vec4 plant_color : source_color = vec4(0.15, 0.3, 0.1, 1.0);

// PBR テクスチャ（Poly Haven CC0）
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rough_tex : filter_linear_mipmap, repeat_enable;
uniform float tex_blend : hint_range(0.0, 1.0) = 0.4;
uniform float tex_scale = 8.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123); }

float noise(vec2 x) {
    vec2 p = floor(x); vec2 f = fract(x); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(p), hash(vec2(p.x + 1.0, p.y)), f.x),
               mix(hash(vec2(p.x, p.y + 1.0)), hash(vec2(p.x + 1.0, p.y + 1.0)), f.x), f.y);
}

void fragment() {
    vec2 uv = UV * 150.0;
    vec2 tex_uv = UV * tex_scale;

    // PBR テクスチャサンプリング
    vec3 tex_col = texture(albedo_tex, tex_uv).rgb;
    vec3 tex_nor = texture(normal_tex, tex_uv).rgb;
    float tex_rough = texture(rough_tex, tex_uv).r;

    // 田んぼの畝パターン
    float row = sin(UV.y * 500.0) * 0.5 + 0.5;
    float plant = smoothstep(0.7, 0.8, noise(uv));
    float wet = noise(uv * 0.1);
    vec3 base_col = mix(mud_color.rgb, water_color.rgb, wet * 0.5);

    // テクスチャとブレンド
    base_col = mix(base_col, tex_col * mud_color.rgb * 2.5, tex_blend);

    float is_plant = plant * row;
    vec3 col = mix(base_col, plant_color.rgb, is_plant);

    ALBEDO = col;
    ROUGHNESS = mix(mix(0.1, tex_rough, tex_blend), 0.9, is_plant);
    METALLIC = mix(0.2, 0.0, is_plant);

    // Normal Map
    NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), tex_nor, tex_blend * (1.0 - is_plant));
    NORMAL_MAP_DEPTH = 0.8;
}
