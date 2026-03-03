shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_paint : source_color = vec4(0.4, 0.45, 0.5, 1.0); // くすんだグレーブルー
uniform vec4 rust_color : source_color = vec4(0.3, 0.1, 0.02, 1.0);  // 乾いたサビ
uniform vec4 bright_rust : source_color = vec4(0.6, 0.25, 0.05, 1.0); // 生っぽいサビ
uniform float rust_level : hint_range(0.0, 1.0) = 0.8;
uniform float scale = 15.0;

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
float fbm(vec2 p) {
    float f = 0.0; float w = 0.5;
    for (int i = 0; i < 4; i++) { f += w * noise(p); p *= 2.0; w *= 0.5; }
    return f;
}
void fragment() {
    vec2 uv = UV * scale;
    
    // 表面のボツボツと剥がれ
    float n1 = fbm(uv);
    float n2 = fbm(uv * 3.0 + vec2(42.1, 13.5));
    
    // 雨だれ状のサビ
    float drips = smoothstep(0.4, 0.8, noise(vec2(uv.x * 2.0, uv.y * 0.1) * 10.0));
    
    float rust_mask = (n1 * 0.5 + drips * 0.5) * rust_level;
    rust_mask = smoothstep(0.3, 0.7, rust_mask + (1.0 - UV.y)*0.3); // 下の方がより錆びる
    
    float edge = smoothstep(0.45, 0.55, rust_mask);
    vec3 rust_mix = mix(rust_color.rgb, bright_rust.rgb, n2);
    
    ALBEDO = mix(base_paint.rgb, rust_mix, edge);
    METALLIC = mix(0.6, 0.0, edge);
    ROUGHNESS = mix(mix(0.4, 0.8, n1), 0.95, edge);
    
    // サビ部分が少し盛り上がる（膨張）ようにノーマルマップ
    vec3 n_vec = vec3(dFdx(rust_mask), dFdy(rust_mask), 1.0) * vec3(2.0, 2.0, 1.0);
    NORMAL = (VIEW_MATRIX * vec4(normalize(n_vec), 0.0)).xyz;
}
