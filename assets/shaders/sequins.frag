#include <flutter/runtime_effect.glsl>

// ─── Uniforms ─────────────────────────────────────────────────────────────────
uniform vec2  uResolution;
uniform vec2  uLightPos;   // [-1, 1]  driven by accelerometer / finger drag
uniform float uTime;
uniform float uPalette;    // -1 = random per disc, 0-6 = force one palette slot

out vec4 fragColor;

// ── Helpers ───────────────────────────────────────────────────────────────────

float rand(vec2 seed) {
    return fract(sin(dot(seed, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 rand2(vec2 seed) {
    return vec2(rand(seed), rand(seed + vec2(17.3, 41.7)));
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 sequinsPalette(float idx) {
    if (idx < 0.5) return vec3(0.13, 0.85, 0.88);  // gold
    if (idx < 1.5) return vec3(0.97, 0.70, 0.82);  // rose-gold
    if (idx < 2.5) return vec3(0.60, 0.55, 0.90);  // silver-blue
    if (idx < 3.5) return vec3(0.42, 0.90, 0.75);  // emerald
    if (idx < 4.5) return vec3(0.02, 0.85, 0.78);  // ruby
    if (idx < 5.5) return vec3(0.78, 0.80, 0.85);  // violet
    return vec3(0.07, 0.75, 0.92);                 // copper
}

// ── Main ──────────────────────────────────────────────────────────────────────
void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv        = fragCoord / uResolution;

    // ── Hexagonal staggered grid ───────────────────────────────────────────────
    // Alternating rows offset by 0.5 — exactly how real sequins are sewn.
    // This packs discs tighter than a square grid and lets them nearly touch.
    const float density = 58.0;  // sequins per row (higher = smaller)
    float aspect  = uResolution.x / uResolution.y;
    vec2  gridPos = vec2(uv.x * aspect, uv.y) * density;

    // Stagger every other row
    float rowIndex  = floor(gridPos.y);
    float stagger   = mod(rowIndex, 2.0) * 0.5;
    gridPos.x      += stagger;

    vec2 cellID    = floor(gridPos);
    vec2 cellLocal = fract(gridPos) - 0.5;   // [-0.5, 0.5], centred on disc

    // ── Per-sequin identity ────────────────────────────────────────────────────
    vec2  rng      = rand2(cellID);

    // ONE fixed hue per sequin picked from a palette of 7 colours.
    // Real sequins come in batches of the same dye-lot — only a handful
    // of distinct colours appear across the garment.
    // Palette: gold, rose-gold, silver-blue, emerald, ruby, violet, copper
    float paletteIdx = uPalette >= 0.0
        ? floor(clamp(uPalette, 0.0, 6.0))
        : floor(rand(cellID + vec2(5.1, 2.3)) * 7.0);
    vec3 chosenHSV = sequinsPalette(paletteIdx);
    vec3 discBase  = hsv2rgb(vec3(chosenHSV.x, chosenHSV.y, chosenHSV.z * 0.30));

    // ── Random micro-tilt per sequin ──────────────────────────────────────────
    // Real sequins hang from a single centre hole and tilt slightly differently
    // from each other — this is what scatters the flash across the surface.
    vec2 bias = (rng - 0.5) * 0.60;

    // ── Light & surface normal ────────────────────────────────────────────────
    // Overhead light at elevation Z=0.8 — no dead zone when phone is upright.
    vec3 L = normalize(vec3(uLightPos + bias * 0.22, 0.8));
    // Each disc tilts by its own bias + global tilt pressure
    vec3 N = normalize(vec3(bias * 0.50 + uLightPos * 0.50, 1.0));
    vec3 V = vec3(0.0, 0.0, 1.0);

    // ── Tilt-driven specular (Blinn-Phong) ────────────────────────────────────
    // High power (48) = very narrow, sharp mirror reflection — like real metal.
    vec3  H      = normalize(L + V);
    float spec   = pow(max(dot(N, H), 0.0), 48.0);

    // ── Idle sweep ────────────────────────────────────────────────────────────
    // A slow elliptical virtual light so the surface shimmers even at rest.
    vec2  sweep     = vec2(sin(uTime * 0.45) * 0.70, cos(uTime * 0.31) * 0.70);
    vec3  sweepL    = normalize(vec3(sweep + bias * 0.22, 0.8));
    vec3  sweepH    = normalize(sweepL + V);
    float phase     = rng.x * 6.28318;
    float env       = max(sin(uTime * 1.4 + phase) * 0.5 + 0.5, 0.0);
    float sweepSpec = pow(max(dot(N, sweepH), 0.0), 28.0) * env * 0.65;

    float totalSpec = clamp(spec + sweepSpec, 0.0, 1.0);

    // ── Disc shape ─────────────────────────────────────────────────────────────
    // radius 0.47 → almost fills the cell, discs nearly touch / slightly overlap
    const float radius = 0.47;
    float dist     = length(cellLocal);
    float edgeFade = 1.0 - smoothstep(radius - 0.04, radius + 0.01, dist);

    // Thin specular rim — the edge of a metal disc catches light at a
    // different angle than the face, giving the characteristic bright outline.
    float rimMask   = smoothstep(radius - 0.07, radius - 0.03, dist)
                    * (1.0 - smoothstep(radius - 0.01, radius + 0.01, dist));
    vec2  rimNorm   = (dist > 0.001) ? normalize(cellLocal) : vec2(0.0, 1.0);
    float rimFacing = max(dot(rimNorm, normalize(uLightPos + sweep * 0.4)), 0.0);
    float rimGlow   = rimMask * rimFacing * 0.6;

    // ── Compose ────────────────────────────────────────────────────────────────
    // The disc is its own fixed colour, brightened toward white by specular.
    // Black gaps between discs → transparent under screen blend mode.
    vec3 faceColor  = mix(discBase, vec3(1.0), totalSpec);
    vec3 finalColor = (faceColor + vec3(rimGlow)) * edgeFade;

    fragColor = vec4(finalColor, 1.0);
}

