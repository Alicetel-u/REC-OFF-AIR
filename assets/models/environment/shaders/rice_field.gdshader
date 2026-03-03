shader_type spatial;
render_mode depth_draw_opaque;

uniform vec4 mud_color : source_color = vec4(0.12, 0.08, 0.05, 1.0);
uniform vec4 water_color : source_color = vec4(0.08, 0.1, 0.1, 1.0);
uniform vec4 plant_color : source_color = vec4(0.15, 0.3, 0.1, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123); }

float noise(vec2 x) {
    vec2 p = floor(x); vec2 f = fract(x); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(p), hash(vec2(p.x + 1.0, p.y)), f.x),
               mix(hash(vec2(p.x, p.y + 1.0)), hash(vec2(p.x + 1.0, p.y + 1.0)), f.x), f.y);
}

void fragment() {
    vec2 uv = UV * 150.0;
    
    // 田んぼの畝（うね）のようなパターン
    // 横方向に波打たせる
    float row = sin(UV.y * 500.0) * 0.5 + 0.5;
    
    // 植物の点々
    float plant = smoothstep(0.7, 0.8, noise(uv));
    
    // ベースは泥と水の混ざった感じ
    float wet = noise(uv * 0.1);
    vec3 base_col = mix(mud_color.rgb, water_color.rgb, wet * 0.5);
    
    // 植物を畝に沿って生やす
    float is_plant = plant * row;
    vec3 col = mix(base_col, plant_color.rgb, is_plant);
    
    ALBEDO = col;
    ROUGHNESS = mix(0.1, 0.9, is_plant); // 水部分は反射する、植物は反射しない
    METALLIC = mix(0.2, 0.0, is_plant); // 水っぽさ
}
