shader_type spatial;
render_mode depth_draw_opaque;

uniform vec4 base_paint_color : source_color = vec4(0.2, 0.02, 0.02, 1.0); // 暗くくすんだ赤
uniform vec4 rust_color1 : source_color = vec4(0.1, 0.04, 0.01, 1.0);      // 深いサビオレンジ
uniform vec4 rust_color2 : source_color = vec4(0.04, 0.02, 0.01, 1.0);     // 焦げ茶に近いサビ
uniform float rust_amount : hint_range(0.0, 1.0) = 0.5; // サビの広がり具合

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123); }

float noise(vec2 x) {
    vec2 p = floor(x); vec2 f = fract(x); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(p), hash(vec2(p.x + 1.0, p.y)), f.x),
               mix(hash(vec2(p.x, p.y + 1.0)), hash(vec2(p.x + 1.0, p.y + 1.0)), f.x), f.y);
}

// FBM (Fractal Brownian Motion) for highly detailed rust
float fbm(vec2 x) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    for (int i = 0; i < 5; ++i) {
        v += a * noise(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    // 座標ベースのノイズ計算（オブジェクトの回転やスケールに依存しないワールド座標ベース）
    // Triplanarの代わりに、XZとXYを足し合わせた簡易的な3DマッピングでCSGのカーブでも伸びないようにする
    vec2 uv = (world_position.xy + world_position.zx) * 4.0;
    
    // サビの分布を計算
    float n1 = fbm(uv);
    float n2 = fbm(uv * 2.5 + vec2(100.0, 50.0));
    
    // サビのしきい値を rust_amount で調整（値が大きいほどサビが広がる）
    // 0.3~0.7 のグラデーションを rust_amount でオフセット
    float rust_mask = smoothstep(0.8 - rust_amount, 1.2 - rust_amount, n1);
    
    // 塗装の剥がれ境界を強調（カリカリッと剥がれた感じ）
    float peeling = step(0.85 - rust_amount, n1);
    rust_mask = mix(rust_mask, 1.0, peeling * 0.5);
    
    // カラーミックス
    vec3 rust_mix = mix(rust_color1.rgb, rust_color2.rgb, n2);
    vec3 final_col = mix(base_paint_color.rgb, rust_mix, rust_mask);
    
    // 金属感と粗さの設定（サビ部分は全く光を反射せず、ざらざら）
    float final_roughness = mix(0.7, 1.0, rust_mask); // 塗装部分は0.7、サビは1.0
    float final_metallic = mix(0.3, 0.0, rust_mask);  // 塗装部分は0.3、サビは0.0
    
    // 凹凸の法線（バンプマップ代わり）
    NORMAL_MAP = vec3(n1*0.2 - 0.1, n1*0.2 - 0.1, 1.0);

    ALBEDO = final_col;
    ROUGHNESS = final_roughness;
    METALLIC = final_metallic;
}
