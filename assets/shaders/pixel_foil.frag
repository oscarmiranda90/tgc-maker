#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform vec2 uLightPos;   // [-1, 1]
uniform float uTime;

out vec4 fragColor;

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
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv        = fragCoord / uResolution;
    vec2 tileCoord = floor(fragCoord);

    // Each pixel is a unique mirror facet with a random 3-D normal
    vec2  rng      = hash22(tileCoord) * 2.0 - 1.0;
    float tiltMag  = 0.55 + hash21(tileCoord + vec2(3.1, 9.7)) * 0.35;
    vec3  N        = normalize(vec3(rng * tiltMag, 1.0));

    float tileHue  = hash21(tileCoord + vec2(7.3, 2.1));

    // ── 3-D Blinn-Phong light ──
    // Z=1 means the light never collapses to a zero vector, so no drift hack needed.
    vec3 L = normalize(vec3(uLightPos * 2.2, 1.0));
    const vec3 V = vec3(0.0, 0.0, 1.0);          // viewer is straight ahead
    vec3 H = normalize(L + V);

    float NdotH  = max(dot(N, H), 0.0);
    float specular = pow(NdotH, 28.0);            // tight mirror flash

    // Hue comes from the half-vector angle so it sweeps the full rainbow as you tilt
    float angleHue   = atan(H.y, H.x) / 6.28318 + 0.5;
    float hue        = fract(tileHue * 0.35 + angleHue * 0.9 + uTime * 0.025);
    vec3  primaryColor = hsv2rgb(vec3(hue, 0.90, specular));

    // Idle layer: slow orbiting light so the foil shimmers even at rest
    vec2 sw     = vec2(sin(uTime * 0.55) * 0.7, cos(uTime * 0.38) * 0.7);
    vec3 Lidle  = normalize(vec3(sw, 1.0));
    vec3 Hidle  = normalize(Lidle + V);
    float idleSpec = pow(max(dot(N, Hidle), 0.0), 22.0) * 0.65;
    float idleHue  = fract(tileHue * 0.35 + atan(Hidle.y, Hidle.x) / 6.28318 + 0.5 + uTime * 0.04);
    vec3  idleColor = hsv2rgb(vec3(idleHue, 0.85, idleSpec));

    // No opaque base — black stays transparent through screen blend
    vec3 finalColor = primaryColor + idleColor;

    float vignette = 1.0 - smoothstep(0.35, 0.85, length(uv - 0.5) * 1.5);
    finalColor *= 0.85 + vignette * 0.15;

    fragColor = vec4(finalColor, 1.0);
}
