shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 wood_base_color : source_color = vec4(0.1, 0.08, 0.05, 1.0); // 黒ずんだ腐朽木
uniform vec4 wood_highlight_color : source_color = vec4(0.2, 0.18, 0.15, 1.0); // 色褪せた表面
uniform vec4 moss_color : source_color = vec4(0.1, 0.25, 0.05, 1.0); // 濃い不気味な苔
uniform float decay_amount : hint_range(0.0, 1.0) = 0.85; 
uniform float moss_amount : hint_range(0.0, 1.0) = 0.6;
uniform float uv_scale = 10.0;

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
float woodPattern(vec2 uv) {
    uv.x *= 15.0; uv.y *= 2.0;
    float n = sin(uv.x + hash(floor(uv)) * 2.0);
    return clamp(smoothstep(-1.0, 1.0, n) + hash(uv * 10.0) * 0.1, 0.0, 1.0);
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
    float wood_grain = woodPattern(uv);
    vec3 base_col = mix(wood_base_color.rgb, wood_highlight_color.rgb, wood_grain * (1.0 - decay_amount*0.5));
    
    float crack = cracks(uv * vec2(1.0, 5.0));
    vec3 cracked_wood = mix(base_col, base_col * 0.2, crack * decay_amount);

    float moss_noise = smoothstep(0.6, 0.9, hash(floor(uv * 3.0)) + hash(uv * 10.0) * 0.5) * moss_amount;
    
    ALBEDO = mix(cracked_wood, moss_color.rgb, moss_noise);
    METALLIC = 0.0;
    ROUGHNESS = mix(0.7, 1.0, moss_noise + crack); 
    
    vec3 n = vec3(crack * 0.1, wood_grain * -0.05, 1.0);
    NORMAL = (VIEW_MATRIX * vec4(normalize(n), 0.0)).xyz;
}
