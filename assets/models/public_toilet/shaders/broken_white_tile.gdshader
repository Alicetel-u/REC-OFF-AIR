shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 tile_color : source_color = vec4(0.9, 0.9, 0.85, 1.0); // 汚れた白タイル
uniform vec4 grout_color : source_color = vec4(0.05, 0.05, 0.05, 1.0); // 黒ずんだ目地
uniform vec4 brick_color : source_color = vec4(0.3, 0.1, 0.05, 1.0); // 露出した煉瓦の色

uniform float tile_size : hint_range(0.1, 20.0) = 8.0;
uniform float broken_amount : hint_range(0.0, 1.0) = 0.3; // タイルが剥がれている割合
uniform float dirt_intensity : hint_range(0.0, 1.0) = 0.5;

varying vec3 v_world_pos;
varying vec3 v_normal;

// ノイズ関数
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

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_normal = abs(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
    // トライプラナーUV計算
    vec3 blending = abs(v_normal);
    blending /= (blending.x + blending.y + blending.z);
    
    vec2 uv_x = v_world_pos.zy * tile_size;
    vec2 uv_y = v_world_pos.xz * tile_size;
    vec2 uv_z = v_world_pos.xy * tile_size;
    
    // タイル目地計算
    float line_x = (step(0.05, fract(uv_x.x)) * step(0.05, fract(uv_x.y))) * blending.x;
    float line_y = (step(0.05, fract(uv_y.x)) * step(0.05, fract(uv_y.y))) * blending.y;
    float line_z = (step(0.05, fract(uv_z.x)) * step(0.05, fract(uv_z.y))) * blending.z;
    float is_tile = step(0.1, line_x + line_y + line_z);
    
    // タイルが剥がれているかどうかの判定（マス目状に判定）
    vec2 cell_id_x = floor(uv_x);
    vec2 cell_id_y = floor(uv_y);
    vec2 cell_id_z = floor(uv_z);
    float h_x = hash(cell_id_x) * blending.x;
    float h_y = hash(cell_id_y) * blending.y;
    float h_z = hash(cell_id_z) * blending.z;
    float h = h_x + h_y + h_z;
    
    // 画像のような「大きな剥落エリア」を作るためのノイズ
    float area_noise = noise(v_world_pos.xy * 0.5 + v_world_pos.z * 0.5);
    bool is_broken = (h < broken_amount) || (area_noise < broken_amount - 0.1);
    
    // --- 色の決定 ---
    vec3 color;
    if (is_broken) {
        // 剥がれた場所: 煉瓦とコンクリートの混じった色
        float brick_noise = noise(v_world_pos.xy * 20.0 + v_world_pos.z * 20.0);
        color = mix(brick_color.rgb, vec3(0.2, 0.2, 0.2), brick_noise);
        // わずかに煉瓦の目地を出す
        float brick_grid = step(0.15, fract(v_world_pos.x * 15.0)) * step(0.1, fract(v_world_pos.y * 30.0));
        color = mix(vec3(0.05), color, brick_grid);
    } else {
        // 残っているタイル: 基本色 + 汚れ
        color = mix(grout_color.rgb, tile_color.rgb, is_tile);
        // タイル表面の汚れ・ひび割れ
        float tile_noise = noise(v_world_pos.xz * 15.0 + v_world_pos.y * 15.0);
        color *= 0.85 + tile_noise * 0.2;
        // 画像にあるようなひび割れ（細いノイズ）
        float crack = smoothstep(0.48, 0.5, noise(v_world_pos.xy * 40.0));
        color = mix(color, grout_color.rgb, (1.0 - crack) * 0.3);
    }
    
    // 全体的な煤け（スス）汚れ
    float soot = noise(v_world_pos.xy * 2.0) * noise(v_world_pos.zy * 1.5);
    color = mix(color, vec3(0.0), soot * dirt_intensity);
    
    ALBEDO = color;
    ROUGHNESS = is_broken ? 1.0 : mix(0.2, 0.9, soot); // タイルは少し反射、壊れたところはガサガサ
    SPECULAR = is_broken ? 0.0 : 0.2;
    NORMAL = normalize(NORMAL + (vec3(noise(v_world_pos.xy * 50.0), noise(v_world_pos.zy * 50.0), 0.0) - 0.5) * 0.02);
}
