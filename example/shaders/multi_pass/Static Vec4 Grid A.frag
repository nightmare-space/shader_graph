// Static Vec4 Grid A (3x2 virtual texels)
//
// Goal:
// - Minimal demo to verify the RGBA8 feedback packing scheme (signed [-1,1] -> RGB 24-bit)
// - Keep Shadertoy's "one texel = vec4" semantics by lane expansion:
//     lane0=x, lane1=y, lane2=z, lane3=w
//
// Virtual size (shader-layer): (3,2)
// Physical size (Flutter-layer): (3*4,2) = (12,2)
// Dart side must use: fixedOutputSize = Size(12, 2)

#include <../common/common_header.frag>

#include <../common/sg_feedback_rgba8.frag>
// Optional feedback input.
// By default this shader only WRITES a static packed grid.
// If you wire feedback and press the mouse, it will READ via the new macro API:
//   SG_LOAD_VEC4(iChannel0, vpos, VSIZE)
uniform sampler2D iChannel0;

const ivec2 VSIZE_I = ivec2(3, 2);
const vec2 VSIZE = vec2(3.0, 2.0);

vec4 valueForTexel(ivec2 vpos) {
    float fx = (VSIZE_I.x <= 1) ? 0.0 : float(vpos.x) / float(VSIZE_I.x - 1); // 0..1
    float fy = (VSIZE_I.y <= 1) ? 0.0 : float(vpos.y) / float(VSIZE_I.y - 1); // 0..1

    float x = fx * 2.0 - 1.0;
    float y = fy * 2.0 - 1.0;
    float z = clamp((fx - fy) * 2.0, -1.0, 1.0);
    float w = clamp(sin((fx + fy) * 6.28318530718) * 0.8, -1.0, 1.0);

    return vec4(x, y, z, w);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    ivec2 p = ivec2(fragCoord - 0.5);
    vec2 psize = sg_physicalSize(VSIZE);

    if (p.x < 0 || p.y < 0 || float(p.x) >= psize.x || float(p.y) >= psize.y) {
        fragColor = vec4(0.0);
        return;
    }

    ivec2 vpos = ivec2(p.x / 4, p.y);

    vec4 v = valueForTexel(vpos);

    // Demo: use the macro API added to sg_feedback_rgba8.frag.
    // This *looks like* passing sampler2D, but is macro expansion (SkSL-safe).
    // Only active while mouse button is down, so default output stays unchanged.
    if (iMouse.z > 0.5) {
        v = SG_LOAD_VEC4(iChannel0, vpos, VSIZE);
    }

    // Write the vec4 into expanded lanes.
    fragColor = vec4(0.0);
    sg_storeVec4(vpos, v, fragColor, p);
}

#include <../common/main_shadertoy.frag>
