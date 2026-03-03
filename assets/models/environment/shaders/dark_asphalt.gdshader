shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 asphalt_color : source_color = vec4(0.08, 0.08, 0.09, 1.0);
uniform vec4 crack_color : source_color = vec4(0.02, 0.02, 0.02, 1.0);
uniform vec4 puddle_color : source_color = vec4(0.05, 0.05, 0.05, 1.0);
uniform float wetness : hint_range(0.0, 1.0) = 0.5;

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
float cracks(vec2 uv) {
    float n1 = fbm(uv * 3.0);
    float n2 = fbm(uv * 8.0 + vec2(10.0));
    float c = abs(n1 - 0.5) * 2.0;
    return smoothstep(0.02, 0.0, c) * n2;
}

void fragment() {
    vec2 uv = UV * 20.0;
    
    // Base macro noise for asphalt
    float base_noise = fbm(uv);
    float fine_noise = fbm(uv * 10.0);
    
    // Cracks
    float crack = cracks(uv * 0.5) + cracks(uv * 1.2 + vec2(5.0)) * 0.5;
    crack = clamp(crack, 0.0, 1.0);
    
    // Puddles
    float puddle = smoothstep(0.5, 0.65, fbm(uv * 0.3));
    
    vec3 col = mix(asphalt_color.rgb, asphalt_color.rgb * 0.5, base_noise * 0.5);
    col = mix(col, crack_color.rgb, crack);
    col = mix(col, puddle_color.rgb, puddle * wetness);
    
    ALBEDO = col;
    
    // Water puddles are smooth and reflective
    float r = mix(0.9, 0.6, base_noise);
    r = mix(r, 0.1, puddle * wetness); // Puddles are very smooth
    ROUGHNESS = r;
    
    METALLIC = mix(0.0, 0.3, puddle * wetness);
    
    vec3 n = vec3(fine_noise * 0.1, crack * -0.5, 1.0);
    NORMAL = (VIEW_MATRIX * vec4(normalize(n), 0.0)).xyz;
}
