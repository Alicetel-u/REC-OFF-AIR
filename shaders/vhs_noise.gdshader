shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float shake_intensity : hint_range(0.0, 0.05) = 0.01;
uniform float noise_intensity : hint_range(0.0, 0.5) = 0.1;

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Scanline & Jitter
    float time = TIME * 2.0;
    uv.x += (rand(vec2(time, uv.y)) - 0.5) * shake_intensity;
    
    // Simple color aberration
    vec4 col;
    col.r = texture(screen_texture, uv + vec2(0.002, 0.0)).r;
    col.g = texture(screen_texture, uv).g;
    col.b = texture(screen_texture, uv - vec2(0.002, 0.0)).b;
    col.a = 1.0;
    
    // Add noise
    float n = (rand(uv + time) - 0.5) * noise_intensity;
    col.rgb += n;
    
    // Vignette (dark edges)
    float dist = distance(uv, vec2(0.5));
    col.rgb *= smoothstep(0.8, 0.4, dist);
    
    COLOR = col;
}
