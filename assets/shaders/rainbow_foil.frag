#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform vec2 uLightPos;   // [-1, 1]
uniform float uTime;

out vec4 fragColor;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Smooth noise for wave distortion
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i+vec2(1,0)), f.x),
        mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x),
        f.y
    );
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;

    // Light influence
    vec2 light = uLightPos * 0.5 + 0.5; // [0,1]
    float lightDist = length(uv - light);
    float lightInfluence = 1.0 - smoothstep(0.0, 1.4, lightDist);

    // ── Diagonal wave axis ──
    // The rainbow sweeps along a diagonal direction
    // Light position rotates which diagonal is used
    float angle = 0.6 + uLightPos.x * 0.4 + uLightPos.y * 0.2;
    vec2 waveDir = normalize(vec2(cos(angle), sin(angle)));
    float waveProjA = dot(uv, waveDir);
    float waveProjB = dot(uv, vec2(-waveDir.y, waveDir.x)); // perpendicular

    // ── Wave distortion (makes bands organic, not ruler-straight) ──
    float distortion = noise(uv * 5.0 + uTime * 0.20) * 0.15
                     + noise(uv * 10.0 - uTime * 0.13) * 0.06;

    // ── Primary rainbow bands ──
    // Fast when finger moves, slow idle drift
    float speed = 0.15 + lightInfluence * 0.0;
    float bands = waveProjA + waveProjB * 0.3 + distortion;

    float hue = fract(
        bands * 3.5                        // band frequency
        + uLightPos.x * 0.5               // shifts with finger X
        + uLightPos.y * 0.3               // shifts with finger Y
        + uTime * speed                    // slow drift
    );

    // ── Saturation and brightness driven by light proximity ──
    // Near the light source: bright, slightly desaturated (white-ish peak)
    // Away from light: rich saturated color
    float sat = mix(0.95, 0.55, pow(lightInfluence, 1.5));
    float val = mix(0.55, 1.0, lightInfluence * 0.7 + 0.3);

    vec3 rainbow = hsv2rgb(vec3(hue, sat, val));

    // ── Secondary shimmer layer (finer bands, perpendicular) ──
    float hue2 = fract(hue + 0.5 + waveProjB * 1.2 + uTime * 0.08);
    vec3 shimmer = hsv2rgb(vec3(hue2, 0.7, 0.4));
    rainbow = mix(rainbow, rainbow + shimmer * 0.25, 0.4);

    // ── Specular hotspot where finger is ──
    float specular = pow(max(0.0, 1.0 - lightDist * 1.8), 3.0) * 0.5;
    rainbow += vec3(specular);

    // ── Dark base card ──
    vec3 base = vec3(0.04, 0.035, 0.06);
    vec3 finalColor = mix(base, rainbow, 0.88);

    // Vignette
    float vignette = 1.0 - smoothstep(0.38, 0.88, length(uv - 0.5) * 1.5);
    finalColor *= 0.88 + vignette * 0.12;

    // Tone map
    finalColor = finalColor / (finalColor + vec3(0.6));
    finalColor = pow(finalColor, vec3(0.88));

    fragColor = vec4(finalColor, 1.0);
}
