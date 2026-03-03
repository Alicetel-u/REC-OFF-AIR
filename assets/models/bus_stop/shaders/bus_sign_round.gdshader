shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 top_blue : source_color = vec4(0.15, 0.45, 0.75, 1.0);
uniform vec4 mid_white : source_color = vec4(0.85, 0.88, 0.85, 1.0);
uniform vec4 bot_blue : source_color = vec4(0.15, 0.45, 0.75, 1.0);
uniform vec4 rust_color : source_color = vec4(0.25, 0.1, 0.05, 1.0);
uniform float rust_amount : hint_range(0.0, 2.0) = 1.0;

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
    float y = UV.y;
    // adding noise to the boundary lines
    float wob_y = y + (fbm(UV * 20.0) - 0.5) * 0.02;
    
    vec3 base_col = top_blue.rgb;
    if (wob_y > 0.35 && wob_y < 0.65) {
        base_col = mid_white.rgb;
    } else if (wob_y >= 0.65) {
        base_col = bot_blue.rgb;
    }
    
    // Rust around edges and scattered spots
    // Use centered UV for radial mask
    vec2 cuv = UV - vec2(0.5);
    float dist = length(cuv);
    
    // Make edge peeling rough
    float edge_rust = smoothstep(0.42, 0.5, dist + fbm(UV * 15.0) * 0.08);
    
    float n1 = fbm(UV * 12.0);
    float spots = smoothstep(0.45, 0.8, n1 * noise(UV * 8.0 + vec2(10.0)));
    
    float total_rust = clamp((edge_rust + spots) * rust_amount, 0.0, 1.0);
    
    // Add overall dirt
    float dirt = fbm(UV * 4.0);
    vec3 dirty_col = mix(base_col, vec3(0.2, 0.15, 0.1), dirt * 0.4);
    
    ALBEDO = mix(dirty_col, rust_color.rgb, total_rust);
    METALLIC = 0.0;
    ROUGHNESS = mix(0.5, 0.95, total_rust);
}
