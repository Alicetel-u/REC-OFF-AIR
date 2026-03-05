shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.8, 0.8, 0.75, 1.0);
uniform vec4 dirt_color : source_color = vec4(0.2, 0.15, 0.1, 1.0);
uniform float dirt_amount : hint_range(0.0, 1.0) = 0.5;
uniform float tile_size : hint_range(0.1, 10.0) = 2.0;

// シンプルなノイズ関数
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

void fragment() {
    // タイル模様
    vec2 grid = fract(UV * tile_size);
    float line_x = step(0.05, grid.x) * step(grid.x, 0.95);
    float line_y = step(0.05, grid.y) * step(grid.y, 0.95);
    float is_tile = line_x * line_y;
    
    // 汚れノイズ
    float n = noise(UV * 5.0) * 0.5 + noise(UV * 15.0) * 0.25;
    n = smoothstep(1.0 - dirt_amount, 1.0, n);
    
    // 下に行くほど汚れる（グラデーション）
    float bottom_dirt = smoothstep(0.5, 0.0, UV.y) * 0.8;
    float final_dirt = clamp(n + bottom_dirt, 0.0, 1.0);
    
    vec3 color = mix(vec3(0.1, 0.1, 0.1), base_color.rgb, is_tile); // 目地は黒
    color = mix(color, dirt_color.rgb, final_dirt * 0.8);
    
    ALBEDO = color;
    ROUGHNESS = mix(0.3, 0.9, final_dirt); // 汚れている部分はザラザラ
    SPECULAR = 0.1;
}
