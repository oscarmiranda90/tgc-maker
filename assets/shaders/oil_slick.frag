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

// FBM for organic oil surface
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
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 6; i++) {
        v += a * noise(p);
        p = p * 2.1 + vec2(1.3, 0.7);
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;

    // ── Oil surface normal via FBM ──
    // The "oil film" has a wrinkled, organic surface
    // We compute it by sampling FBM at tiny offsets (gradient approximation)
    float eps = 0.008;
    float fbmC  = fbm(uv * 5.5 + uTime * 0.045);
    float fbmR  = fbm((uv + vec2(eps, 0.0)) * 5.5 + uTime * 0.045);
    float fbmU  = fbm((uv + vec2(0.0, eps)) * 5.5 + uTime * 0.045);

    // Surface normal from gradient
    vec2 surfaceNormal = normalize(vec2(fbmR - fbmC, fbmU - fbmC) / eps);

    // ── Light direction ──
    vec2 lightDir = normalize(uLightPos + vec2(0.0001));

    // ── Thin film interference ──
    // Real oil slick: light reflects at TWO surfaces (top and bottom of film)
    // The path difference creates constructive/destructive interference per wavelength
    // We simulate this as: each point has a "film thickness" from fbm
    // Thickness determines which wavelengths constructively interfere

    float thickness = fbmC; // [0,1] — film thickness varies across surface

    // Interference: different wavelengths (R,G,B) peak at different thicknesses
    // We compute per-channel using classic thin film formula approximation
    float viewAngle = dot(lightDir, surfaceNormal) * 0.5 + 0.5;

    // Phase shift per channel (different wavelengths = different phase)
    float phaseR = thickness * 6.28 * 3.2 + viewAngle * 3.14;
    float phaseG = thickness * 6.28 * 4.6 + viewAngle * 3.14;
    float phaseB = thickness * 6.28 * 6.0 + viewAngle * 3.14;

    // Interference intensity per channel
    float r = cos(phaseR) * 0.5 + 0.5;
    float g = cos(phaseG) * 0.5 + 0.5;
    float b = cos(phaseB) * 0.5 + 0.5;

    vec3 interference = vec3(r, g, b);

    // ── Oil slick is DARK — colors only appear at specific angles ──
    // The base is near-black, colors emerge from interference only
    float lightAlignment = dot(lightDir, surfaceNormal);
    float angleFactor = smoothstep(-0.3, 0.8, lightAlignment);

    // Color intensity: subtle normally, vivid only when angle is right
    float intensity = angleFactor * (0.5 + viewAngle * 0.5);

    // ── Finger proximity boost ──
    float lightDist = length(uv - (uLightPos * 0.5 + 0.5));
    float proximity = 1.0 - smoothstep(0.0, 0.9, lightDist);
    intensity = mix(intensity, intensity * 1.6, proximity * 0.5);

    // ── Idle subtle animation ──
    // Even at rest the oil surface shifts very slowly
    float idleShift = uTime * 0.030;
    float idleFbm = fbm(uv * 5.5 + idleShift);
    float idleColor = idleFbm * 0.06;

    // ── Final color assembly ──
    // Oil slick palette: deep blacks, dark purples, dark teals
    // The interference adds R/G/B but always dark
    vec3 darkBase = vec3(0.02, 0.015, 0.03); // near black with purple hint

    // The interference colors — keep them dark, never go full bright
    vec3 oilColor = interference * intensity * 0.7;

    // Add very subtle purple/teal ambient to sell the "oil" feeling
    vec3 ambient = vec3(0.04, 0.02, 0.06) * fbmC * 0.8;

    vec3 finalColor = darkBase + oilColor + ambient + idleColor;

    // ── Specular: tiny bright point only exactly at finger ──
    float specular = pow(max(0.0, 1.0 - lightDist * 3.5), 5.0) * 0.4;
    finalColor += vec3(specular * 0.8, specular * 0.9, specular);

    // Subtle vignette
    float vignette = 1.0 - smoothstep(0.3, 0.9, length(uv - 0.5) * 1.5);
    finalColor *= 0.85 + vignette * 0.15;

    // NO aggressive tone mapping — oil slick stays dark intentionally
    // Just a gentle gamma
    finalColor = pow(clamp(finalColor, 0.0, 1.0), vec3(0.92));

    fragColor = vec4(finalColor, 1.0);
}
