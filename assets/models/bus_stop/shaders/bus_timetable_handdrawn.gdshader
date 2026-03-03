shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 paper_color : source_color = vec4(0.85, 0.82, 0.78, 1.0);
uniform vec4 ink_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform float line_thickness = 0.015;

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
    for (int i = 0; i < 3; i++) { f += w * noise(p); p *= 2.0; w *= 0.5; }
    return f;
}
void fragment() {
    // Add micro-noise to UV to make straight math lines look hand-drawn with marker
    vec2 wob_uv = UV + (vec2(fbm(UV * 20.0), fbm(UV * 20.0 + 10.0)) - 0.5) * 0.015;
    
    float marker = 0.0;
    
    // Outer bounding rectangle
    if (wob_uv.x < 0.04 || wob_uv.x > 0.96) marker = 1.0;
    if (wob_uv.y < 0.03 || wob_uv.y > 0.97) marker = 1.0;
    
    // Vertical separator between hour and minute
    float v_dist = abs(wob_uv.x - 0.35);
    if (v_dist < line_thickness + fbm(UV * 40.0) * 0.005) marker = 1.0;
    
    // Horizontal rows
    float start_y = 0.12;
    float end_y = 0.88;
    float num_rows = 9.0;
    
    float row_h = (end_y - start_y) / num_rows;
    if (wob_uv.y > start_y && wob_uv.y < end_y) {
        float local_y = wob_uv.y - start_y;
        float frac_y = fract(local_y / row_h);
        // Only draw lines at row boundaries, checking distance
        float row_idx = floor(local_y / row_h);
        float line_center_y = start_y + row_idx * row_h;
        if (abs(wob_uv.y - line_center_y) < line_thickness) marker = 1.0;
    }
    
    // Bottom line of the grid
    if (abs(wob_uv.y - end_y) < line_thickness) marker = 1.0;
    // Top line under header
    if (abs(wob_uv.y - start_y) < line_thickness) marker = 1.0;

    marker = clamp(marker, 0.0, 1.0);
    
    // Add paper dirt
    float dirt = fbm(UV * 5.0);
    vec3 bg = mix(paper_color.rgb, vec3(0.4, 0.35, 0.25), dirt * 0.4);
    
    // Heavy rust drips on white board
    float stain = smoothstep(0.5, 0.8, fbm(UV * 2.0 + 5.0));
    bg = mix(bg, vec3(0.5, 0.3, 0.15), stain * 0.5);
    
    // Vary marker opacity slightly like fading ink
    ALBEDO = mix(bg, ink_color.rgb, marker * (0.8 + 0.2*noise(UV*100.0)));
    ROUGHNESS = 0.95;
    METALLIC = 0.0;
}
