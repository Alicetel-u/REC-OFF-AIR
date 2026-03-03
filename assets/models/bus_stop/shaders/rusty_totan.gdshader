shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.15, 0.2, 0.25, 1.0);
uniform vec4 rust_color : source_color = vec4(0.2, 0.05, 0.02, 1.0);
uniform vec4 bright_rust_color : source_color = vec4(0.4, 0.1, 0.02, 1.0);

uniform float rust_amount : hint_range(0.0, 1.0) = 0.85;
uniform float wetness : hint_range(0.0, 1.0) = 0.8;
uniform float uv_scale = 10.0;

vec2 random2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}
float worley(vec2 p) {
    vec2 n = floor(p); vec2 f = fract(p); float res = 8.0;
    for(int j=-1; j<=1; j++)
    for(int i=-1; i<=1; i++) {
        vec2 g = vec2(float(i), float(j));
        vec2 r = g + random2(n + g) - f;
        res = min(res, dot(r,r));
    }
    return sqrt(res);
}
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

void fragment() {
    // 隙間ができないように頂点変形を削除。ノーマルマップで波板をシミュレート。
    vec2 uv = UV * uv_scale;
    float corrugation = sin(uv.x * 20.0);
    vec3 normal_map = normalize(vec3(corrugation * 0.4, 0.0, 1.0));
    NORMAL = (VIEW_MATRIX * vec4(normal_map, 0.0)).xyz;
    
    float dirt = fbm(uv * 1.5);
    float spots = smoothstep(0.4, 0.7, 1.0 - worley(uv * 3.0)) * fbm(uv * 5.0);
    float drips = smoothstep(0.6, 0.9, noise(vec2(uv.x * 2.0, uv.y * 0.2) * 15.0)) * (1.0 - UV.y); 
    float bottom_rust = smoothstep(0.7, 1.0, fract(UV.y) + noise(uv*2.0)*0.1);
    
    // 参照画像に基づく抑えめのサビ
    float final_rust = clamp((spots*0.5 + drips*0.3 + bottom_rust*0.8) * rust_amount, 0.0, 1.0);
    
    vec3 paint_col = mix(base_color.rgb, base_color.rgb * 0.5, dirt);
    vec3 rust_mix = mix(bright_rust_color.rgb, rust_color.rgb, smoothstep(0.2, 0.8, final_rust));
    
    ALBEDO = mix(paint_col, rust_mix, final_rust);
    METALLIC = mix(0.5, 0.0, final_rust); 
    ROUGHNESS = mix(mix(0.6, 0.95, final_rust), 0.3, wetness * (1.0 - final_rust)); 
}
