shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.45, 1.0);
uniform vec4 grout_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 moss_color : source_color = vec4(0.1, 0.2, 0.05, 1.0);
uniform vec4 rust_color : source_color = vec4(0.3, 0.15, 0.1, 1.0);

uniform float tile_size : hint_range(0.1, 20.0) = 5.0;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.5;
uniform float rust_amount : hint_range(0.0, 1.0) = 0.4;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.5;

varying vec3 v_world_pos;
varying vec3 v_normal;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// トライプラナー・マッピングを用いてテクスチャ情報を計算する関数
vec3 get_triplanar_color(vec3 pos, vec3 normal, float size) {
    vec3 blending = abs(normal);
    blending /= (blending.x + blending.y + blending.z);
    
    vec2 coord_x = pos.zy * size;
    vec2 coord_y = pos.xz * size;
    vec2 coord_z = pos.xy * size;
    
    // 各面でのタイル計算（簡易化のためタイルロジックをここに統合）
    float tile_x = step(0.05, fract(coord_x.x)) * step(0.05, fract(coord_x.y));
    float tile_y = step(0.05, fract(coord_y.x)) * step(0.05, fract(coord_y.y));
    float tile_z = step(0.05, fract(coord_z.x)) * step(0.05, fract(coord_z.y));
    
    return vec3(tile_x) * blending.x + vec3(tile_y) * blending.y + vec3(tile_z) * blending.z;
}

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_normal = abs((MODEL_NORMAL_MATRIX * NORMAL));
}

void fragment() {
    // トライプラナーによるタイル目地の取得（is_tileと同等）
    float is_tile = get_triplanar_color(v_world_pos, v_normal, tile_size).x;
    
    // ノイズ用の座標（トライプラナー的に3方向からサンプリング）
    float n_moss = noise(v_world_pos.xz * 0.8 + v_world_pos.y * 0.5) * 0.6 + noise(v_world_pos.xy * 3.0) * 0.3;
    float moss_mask = smoothstep(1.0 - moss_amount, 1.1 - moss_amount, n_moss);
    
    float n_rust = noise(vec2(v_world_pos.x + v_world_pos.z, v_world_pos.y * 0.2)) * 0.7 + noise(v_world_pos.xz * 5.0) * 0.3;
    float rust_mask = smoothstep(1.0 - rust_amount, 1.1 - rust_amount, n_rust);
    
    // 高さに応じた苔（床付近）
    float height_factor = smoothstep(1.0, 0.0, v_world_pos.y);
    moss_mask = clamp(moss_mask + height_factor * 0.5 * moss_amount, 0.0, 1.0);

    // 色の合成
    vec3 color = mix(grout_color.rgb, base_color.rgb, is_tile);
    color *= 0.9 + noise(v_world_pos.xz * 2.0) * 0.2;
    color = mix(color, rust_color.rgb, rust_mask * 0.7);
    color = mix(color, moss_color.rgb, moss_mask * 0.9);
    
    ALBEDO = color;
    
    float r = roughness_base;
    r = mix(r, 0.2, moss_mask);
    r = mix(r, 0.9, rust_mask);
    ROUGHNESS = r;
}
