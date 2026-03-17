shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha, depth_draw_opaque;

uniform vec4 foliage_color : source_color = vec4(0.05, 0.12, 0.05, 1.0); // 非常に暗い緑
uniform vec4 darkness_color : source_color = vec4(0.01, 0.02, 0.01, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123); }

float noise(vec2 x) {
    vec2 p = floor(x); vec2 f = fract(x); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(p), hash(vec2(p.x + 1.0, p.y)), f.x),
               mix(hash(vec2(p.x, p.y + 1.0)), hash(vec2(p.x + 1.0, p.y + 1.0)), f.x), f.y);
}

void vertex() {
    // 不気味な風の揺れ（複数波の重ね合わせで不規則に）
    float t = TIME;
    float wind = sin(t * 1.5 + VERTEX.x * 0.5 + VERTEX.z * 0.3) * 0.15
               + sin(t * 3.7 + VERTEX.z * 0.8) * 0.06
               + sin(t * 0.4 + VERTEX.x * 0.2) * 0.20; // ゆっくりした大きな揺れ
    float height_factor = VERTEX.y * 0.25; // 高いところほど揺れる
    VERTEX.x += wind * height_factor;
    VERTEX.z += sin(t * 2.3 + VERTEX.x * 0.6) * 0.04 * height_factor; // Z軸にも少し揺れ
}

void fragment() {
    vec2 p = UV * 5.0;
    float n = noise(p) * 0.5 + noise(p * 2.0) * 0.25;
    
    // Simple oval silhouette with rough edges
    float d = distance(UV, vec2(0.5, 0.5));
    float alpha = 1.0;
    if (d + n * 0.2 > 0.45) {
        alpha = 0.0;
    }
    
    ALBEDO = foliage_color.rgb + vec3(0.05); // A bit brighter to catch light
    ALPHA = alpha;
    ALPHA_SCISSOR_THRESHOLD = 0.5;
    
    ROUGHNESS = 1.0;
    SPECULAR = 0.0;
}
