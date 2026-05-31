#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;   // card size in pixels
uniform vec2 uLightPos;     // normalized [-1, 1] finger position
uniform float uTime;        // elapsed seconds for animation

out vec4 fragColor;

// ── Pseudo-random noise ──
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// ── Smooth noise ──
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1,0)), f.x),
        mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x),
        f.y
    );
}

// ── Fractal noise (several octaves) ──
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// ── HSV to RGB ──
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    // UV coordinates [0,1]
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;

    // Light direction from finger position
    vec2 lightDir = uLightPos * 0.5 + 0.5; // remap to [0,1]

    // ── Procedural normal map via fbm noise ──
    // Each pixel gets a unique "tilt" direction from noise
    float noiseScale = 9.0;
    float nx = fbm(uv * noiseScale + vec2(uTime * 0.13, 0.0));
    float ny = fbm(uv * noiseScale + vec2(0.0, uTime * 0.13) + vec2(5.2, 1.3));

    // Simulated surface normal per pixel
    vec2 surfaceNormal = vec2(nx, ny);

    // ── Diffraction angle per pixel ──
    // Dot product of light direction with unique surface normal
    float diffraction = dot(normalize(lightDir - uv + surfaceNormal * 0.3), vec2(0.5));

    // ── Hue rotation based on diffraction + position ──
    float hue = fract(
        diffraction * 2.5
        + nx * 0.8
        + ny * 0.5
        + uTime * 0.10
        + length(uv - lightDir) * 1.2
    );

    float saturation = 0.85;
    float brightness = 0.75 + diffraction * 0.4;

    vec3 holoColor = hsv2rgb(vec3(hue, saturation, brightness));

    // ── Specular highlight where light hits directly ──
    float dist = length(uv - lightDir);
    float specular = smoothstep(0.5, 0.0, dist) * 0.6;
    holoColor += vec3(specular);

    // ── Rainbow bands (the signature holo lines) ──
    float bands = sin((uv.x * 6.0 + uv.y * 4.0 + diffraction * 3.0 + uTime * 0.25) * 3.14159 * 8.0);
    bands = bands * 0.5 + 0.5;
    holoColor = mix(holoColor, holoColor * vec3(bands * 1.3, bands * 0.9, bands * 1.1), 0.25);

    // Alpha drives how much holo shows — specular punches it up locally
    float alpha = 0.55 + specular * 0.35;

    fragColor = vec4(holoColor, alpha);
}
