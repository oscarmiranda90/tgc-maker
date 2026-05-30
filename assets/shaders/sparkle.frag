#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform vec2 uLightPos;   // normalized [-1, 1]
uniform float uTime;

out vec4 fragColor;

// ── Hash functions ──
float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// ── HSV to RGB ──
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// ── Single sparkle point ──
// cellUV:    position within the cell [0,1]
// seed:      unique random seed for this cell
// L:         3-D light direction (already normalized)
float sparkle(vec2 cellUV, float seed, vec3 L) {
    // Random position within cell
    vec2 pointPos = hash22(vec2(seed, seed * 1.7)) * 0.7 + 0.15;

    // Each point has a unique 3-D mirror normal (hemisphere)
    vec2 r = hash22(vec2(seed * 3.1, seed * 0.9));
    float tiltMag   = r.x * 0.97;
    float tiltAngle = r.y * 6.28318;
    float mx = cos(tiltAngle) * tiltMag;
    float my = sin(tiltAngle) * tiltMag;
    float mz = sqrt(max(0.001, 1.0 - mx*mx - my*my));
    vec3 N = vec3(mx, my, mz);

    // Blinn-Phong: half-vector between light and viewer (0,0,1)
    vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
    float spec = dot(N, H);

    // Narrow threshold — only facets nearly aligned with H light up
    float threshold = 0.76 + hash11(seed) * 0.14;
    float spark = smoothstep(threshold, 1.0, spec);

    // Distance from pixel to sparkle point center
    float dist = length(cellUV - pointPos);

    // Point size varies per sparkle
    float radius = 0.04 + hash11(seed * 7.3) * 0.06;

    // Shape: tight gaussian falloff (sharp point)
    float shape = exp(-dist * dist / (radius * radius) * 6.0);

    // Cross flare on bright sparkles
    float crossH = exp(-abs(cellUV.y - pointPos.y) * 40.0) * 0.3;
    float crossV = exp(-abs(cellUV.x - pointPos.x) * 40.0) * 0.3;
    float cross  = (crossH + crossV) * spark;

    return (shape + cross) * spark;
}

// ── Sparkle color ──
vec3 sparkleColor(float seed, vec3 L, float intensity) {
    float hue = hash11(seed * 2.3);
    vec3 tinted = hsv2rgb(vec3(hue, 0.7, 1.0));
    vec3 white  = vec3(1.0, 0.98, 0.95);
    return mix(tinted, white, pow(intensity, 2.0)) * intensity;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;

    // ── 3-D overhead light direction ──
    // Z=0.8 ensures light is always "above" the card — no dead zone.
    // uLightPos shifts it laterally as the phone tilts.
    vec3 L = normalize(vec3(uLightPos.x, uLightPos.y, 0.8));

    // ── Idle orbit light ──
    // Sweeps a virtual light in a slow ellipse for at-rest animation.
    vec3 idleL = normalize(vec3(
        sin(uTime * 0.65) * 0.5,
        cos(uTime * 0.48) * 0.5,
        0.8
    ));

    // ── SPARKLE LAYERS ──
    vec3 sparkleResult = vec3(0.0);

    // Layer 1: Fine sparkles (high density)
    float gridSize1 = 50.0;
    vec2 cell1 = floor(uv * gridSize1);
    vec2 cellUV1 = fract(uv * gridSize1);
    float seed1 = hash21(cell1);
    float s1 = sparkle(cellUV1, seed1, L);
    sparkleResult += sparkleColor(seed1, L, s1) * 1.2;

    // Layer 2: Medium sparkles
    float gridSize2 = 31.0;
    vec2 cell2 = floor(uv * gridSize2 + vec2(0.5));
    vec2 cellUV2 = fract(uv * gridSize2 + vec2(0.5));
    float seed2 = hash21(cell2 + vec2(100.0));
    float s2 = sparkle(cellUV2, seed2, L);
    sparkleResult += sparkleColor(seed2, L, s2) * 1.5;

    // Layer 3: Large rare sparkles (the "hero" ones)
    float gridSize3 = 17.0;
    vec2 cell3 = floor(uv * gridSize3 + vec2(1.3, 0.7));
    vec2 cellUV3 = fract(uv * gridSize3 + vec2(1.3, 0.7));
    float seed3 = hash21(cell3 + vec2(200.0));
    float s3 = sparkle(cellUV3, seed3, L);
    sparkleResult += sparkleColor(seed3, L, s3) * 2.5;

    // Layer 4: Idle ghost layer — alive even when phone is still
    vec2 cell4 = floor(uv * 40.0 + vec2(0.25, 0.75));
    vec2 cellUV4 = fract(uv * 40.0 + vec2(0.25, 0.75));
    float seed4 = hash21(cell4 + vec2(300.0));
    float s4 = sparkle(cellUV4, seed4, idleL) * 0.5;
    sparkleResult += sparkleColor(seed4, idleL, s4);

    // ── Combine ──
    vec3 finalColor = sparkleResult;

    // ── Vignette ──
    float vignette = 1.0 - smoothstep(0.35, 0.85, length(uv - 0.5) * 1.5);
    finalColor *= 0.85 + vignette * 0.15;

    // ── Tone mapping: prevent blown out whites ──
    finalColor = finalColor / (finalColor + vec3(0.8));
    finalColor = pow(finalColor, vec3(0.9)); // slight gamma lift

    fragColor = vec4(finalColor, 1.0);
}
