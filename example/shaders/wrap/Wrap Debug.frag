#include <../common/common_header.frag>

// Bind via ShaderBuffer inputs: iChannel0 uses the first input.
uniform sampler2D iChannel0;

vec3 grid(vec2 uv) {
    // draw a faint grid in UV space to see wrapping
    vec2 g = abs(fract(uv) - 0.5);
    float line = smoothstep(0.48, 0.50, max(g.x, g.y));
    return mix(vec3(0.05), vec3(0.15), line);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    // Intentionally sample outside [0,1] to make wrap visible.
    // Center at 0,0 and scale up.
    vec2 suv = (uv - 0.5) * 4.0;

    // Map to a more obvious range: [-1.5, 2.5]
    vec2 texUv = suv + 0.5;

    // Use shader-side wrap macro for channel 0.
    vec4 tex = SG_TEX0(iChannel0, texUv);

    // Overlay UV grid to visualize repeats.
    vec3 g = grid(texUv);

    fragColor = vec4(mix(g, tex.rgb, 0.85), 1.0);
}

#include <../common/main_shadertoy.frag>
