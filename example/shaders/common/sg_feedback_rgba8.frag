#ifndef SG_FEEDBACK_RGBA8
#define SG_FEEDBACK_RGBA8

// ------------------------------------------------------------
// IMPORTANT (Flutter/SkSL limitation)
// ------------------------------------------------------------
// Flutter RuntimeEffect 会把 sampler2D 翻译为 SkSL 的 `shader`。
// SkSL 不允许在函数参数里传递 `shader` 类型，因此我们不能写：
//   vec4 f(sampler2D tex, ...)
// 必须直接引用全局的 uniform sampler2D。
//
// 默认使用 iChannel0；如需切换通道，可以在 include 前写：
//   #define SG_FEEDBACK_TEX iChannel1

#ifndef SG_FEEDBACK_TEX
#define SG_FEEDBACK_TEX iChannel0
#endif

// ============================================================
// ShaderGraph 通用反馈方案（适配 Flutter 的 RGBA8 feedback）
//
// 背景：Flutter RuntimeEffect 的 feedback 链路基本是
//   Shader(float) -> RGBA8 -> ui.Image -> 下一帧 sampler
// 因此如果你在 Shadertoy 里把 buffer 当 float texture 用（texelFetch 读写任意 float），
// 在 Flutter 里直接读写会变成 8bit/通道，导致精度严重损失。
//
// 约束：Flutter/SkSL 环境常常缺少 uint/bit ops/floatBitsToUint/uintBitsToFloat。
//
// 方案：
// - 用纯 float 算术，把一个 [-1,1] 的值打包到 RGB 三通道（≈24bit），A 固定为 1。
// - 为了保留 Shadertoy 的“一个 texel = vec4”语义，我们把每个虚拟 texel 展开成 4 个物理像素：
//     lane0 = x, lane1 = y, lane2 = z, lane3 = w
//   这样原 shader 里的寄存器地址（txBallPosVel 等）不用重排，只需要替换 load/store。
// - 物理纹理尺寸 = vec2(virtualSize.x*4, virtualSize.y)
//
// 你需要在 Dart 侧把该 buffer 的输出尺寸固定为物理尺寸（见 ShaderBuffer.fixedOutputSize）。
// ============================================================

// --- layout helpers ---
ivec2 sg_lanePos(ivec2 vpos, int lane) {
    return ivec2(vpos.x * 4 + lane, vpos.y);
}

vec2 sg_physicalSize(vec2 virtualSize) {
    return vec2(virtualSize.x * 4.0, virtualSize.y);
}

// --- packing (no bit ops) ---
// v01 in [0,1] -> RGB
vec3 sg_pack01ToRGB(float v01) {
    // IMPORTANT: Use a true 24-bit (base-256) mapping.
    // Each channel stores an integer byte in [0..255] as (byte/255).
    // We avoid large multipliers like 65025/16581375 that can amplify precision
    // issues on some mobile GPUs.
    float v = clamp(v01, 0.0, 1.0 - (1.0 / 16777216.0));

    float x = floor(v * 256.0);
    v = v * 256.0 - x;
    float y = floor(v * 256.0);
    v = v * 256.0 - y;
    float z = floor(v * 256.0);

    return vec3(x, y, z) / 255.0;
}

float sg_unpack01FromRGB(vec3 rgb) {
    // Recover bytes and reconstruct v01 in [0..1) using a base-256 fraction:
    //   v01 = x/256 + y/256^2 + z/256^3
    // This avoids large (1.6e7) integer-like multipliers that can lose precision
    // on some mobile GPUs.
    vec3 c = floor(rgb * 255.0 + 0.5);
    return clamp(
        c.x / 256.0 + c.y / 65536.0 + c.z / 16777216.0,
        0.0,
        1.0
    );
}

vec4 sg_packSigned(float vSigned) {
    vSigned = clamp(vSigned, -1.0, 1.0);
    float v01 = vSigned * 0.5 + 0.5;
    return vec4(sg_pack01ToRGB(v01), 1.0);
}

float sg_unpackSigned(vec4 rgba) {
    float v01 = sg_unpack01FromRGB(rgba.rgb);
    return v01 * 2.0 - 1.0;
}

// --- texel-like fetch (nearest at pixel center) ---
vec4 sg_fetchRaw(ivec2 ipos, vec2 sizePx) {
    // Sample at texel centers. Some mobile GPUs (or fast-math paths) can
    // introduce tiny UV errors that cause linear filtering to mix neighbors.
    // Snap UV back to the nearest texel center to keep packed state stable.
    vec2 uv = (vec2(ipos) + 0.5) / sizePx;
    uv = (floor(uv * sizePx) + 0.5) / sizePx;
    return texture(SG_FEEDBACK_TEX, uv);
}

// --- load virtual texel (vec4) from expanded physical texture ---
float sg_loadFloat(ivec2 vpos, vec2 virtualSize) {
    vec2 psize = sg_physicalSize(virtualSize);
    return sg_unpackSigned(sg_fetchRaw(sg_lanePos(vpos, 0), psize));
}

vec2 sg_loadVec2(ivec2 vpos, vec2 virtualSize) {
    vec2 psize = sg_physicalSize(virtualSize);
    return vec2(
        sg_unpackSigned(sg_fetchRaw(sg_lanePos(vpos, 0), psize)),
        sg_unpackSigned(sg_fetchRaw(sg_lanePos(vpos, 1), psize))
    );
}

vec3 sg_loadVec3(ivec2 vpos, vec2 virtualSize) {
    vec2 psize = sg_physicalSize(virtualSize);
    return vec3(
        sg_unpackSigned(sg_fetchRaw(sg_lanePos(vpos, 0), psize)),
        sg_unpackSigned(sg_fetchRaw(sg_lanePos(vpos, 1), psize)),
        sg_unpackSigned(sg_fetchRaw(sg_lanePos(vpos, 2), psize))
    );
}

vec4 sg_loadVec4(ivec2 vpos, vec2 virtualSize) {
    vec2 psize = sg_physicalSize(virtualSize);
    return vec4(
        sg_unpackSigned(sg_fetchRaw(sg_lanePos(vpos, 0), psize)),
        sg_unpackSigned(sg_fetchRaw(sg_lanePos(vpos, 1), psize)),
        sg_unpackSigned(sg_fetchRaw(sg_lanePos(vpos, 2), psize)),
        sg_unpackSigned(sg_fetchRaw(sg_lanePos(vpos, 3), psize))
    );
}

// --- store helpers ---
// 当前 fragment 对应的物理像素坐标 p = ivec2(fragCoord - 0.5)
// 这些 store* 会在 “p 命中 re 对应 lane” 时写入 fragColor。

void sg_storeVec4(ivec2 re, vec4 vaSigned, inout vec4 fragColor, ivec2 p) {
    ivec2 vpos = ivec2(p.x / 4, p.y);
    if (vpos != re) return;
    int lane = p.x - vpos.x * 4;

    float v = 0.0;
    if (lane == 0) v = vaSigned.x;
    else if (lane == 1) v = vaSigned.y;
    else if (lane == 2) v = vaSigned.z;
    else if (lane == 3) v = vaSigned.w;

    fragColor = sg_packSigned(v);
}

void sg_storeVec4Range(ivec4 re, vec4 vaSigned, inout vec4 fragColor, ivec2 p) {
    ivec2 vpos = ivec2(p.x / 4, p.y);
    if (vpos.x < re.x || vpos.y < re.y || vpos.x > re.z || vpos.y > re.w) return;
    int lane = p.x - vpos.x * 4;

    float v = 0.0;
    if (lane == 0) v = vaSigned.x;
    else if (lane == 1) v = vaSigned.y;
    else if (lane == 2) v = vaSigned.z;
    else if (lane == 3) v = vaSigned.w;

    fragColor = sg_packSigned(v);
}

// --- optional range mapping helpers ---
float sg_encode01ToSigned(float v01) { return v01 * 2.0 - 1.0; }
float sg_decodeSignedTo01(float vs) { return vs * 0.5 + 0.5; }

float sg_encodeRangeToSigned(float v, float vMin, float vMax) {
    float v01 = (v - vMin) / (vMax - vMin);
    return sg_encode01ToSigned(clamp(v01, 0.0, 1.0));
}

float sg_decodeSignedToRange(float vs, float vMin, float vMax) {
    float v01 = clamp(sg_decodeSignedTo01(vs), 0.0, 1.0);
    return vMin + v01 * (vMax - vMin);
}

#endif
