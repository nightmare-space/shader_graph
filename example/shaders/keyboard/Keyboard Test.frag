#include <../common/common_header.frag>

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
// =======================
// Shadertoy Keyboard Test
// =======================

// Palette (sRGB-like constants)
const vec3 COLOR_BG = vec3(243.0, 244.0, 249.0) / 255.0;      // #f3f4f9
const vec3 COLOR_CARD = vec3(232.0, 233.0, 238.0) / 255.0;    // #E8E9EE
const vec3 COLOR_CARD_ON = vec3(1.0);                         // #ffffff
const vec3 COLOR_TEXT = vec3(0.0);                            // #000000

float keyDown(int key) {
    // row 0 = key down
    return texture(
        iChannel0,
        (vec2(float(key), 0.0) + 0.5) / vec2(256.0, 3.0)
    ).r;
}

// -----------------------
// Font atlas text drawing
// -----------------------
// Same idea as `Text Texture.frag`: a 16x16 codepage where `charCode` selects a tile.

vec4 GetCharFromAtlas(int charCode, vec2 charLocalUv) {
    const vec2 gridSize = vec2(16.0, 16.0);
    int gridX = int(mod(float(charCode), gridSize.x));
    int gridY = int(float(charCode) / gridSize.x);
    vec2 gridUv = vec2(float(gridX), float(gridY)) / gridSize;
    vec2 charUv = charLocalUv / gridSize;
    return texture(iChannel1, gridUv + charUv);
}

float drawCharAtlas(vec2 fragCoord, vec2 topLeftPx, vec2 charSizePx, int charCode) {
    vec2 p = fragCoord - topLeftPx;
    if (p.x < 0.0 || p.y < 0.0 || p.x >= charSizePx.x || p.y >= charSizePx.y) return 0.0;

    // Match `Text Texture.frag`: sample red channel directly from the atlas.
    vec2 charLocalUv = p / charSizePx;
    // Fix vertical mirroring: atlas cell UV origin differs from our pixel-space origin.
    charLocalUv.y = 1.0 - charLocalUv.y;
    return GetCharFromAtlas(charCode, charLocalUv).r;
}

float drawLabel5(
    vec2 fragCoord,
    vec2 centerPx,
    vec2 charSizePx,
    float gapPx,
    int c0,
    int c1,
    int c2,
    int c3,
    int c4
) {
    int count = 0;
    if (c0 >= 0) count++;
    if (c1 >= 0) count++;
    if (c2 >= 0) count++;
    if (c3 >= 0) count++;
    if (c4 >= 0) count++;
    if (count == 0) return 0.0;

    float totalW = float(count) * charSizePx.x + float(count - 1) * gapPx;
    vec2 start = centerPx - vec2(totalW * 0.5, charSizePx.y * 0.5);

    float a = 0.0;
    if (c0 >= 0) a = max(a, drawCharAtlas(fragCoord, start + vec2(0.0 * (charSizePx.x + gapPx), 0.0), charSizePx, c0));
    if (c1 >= 0) a = max(a, drawCharAtlas(fragCoord, start + vec2(1.0 * (charSizePx.x + gapPx), 0.0), charSizePx, c1));
    if (c2 >= 0) a = max(a, drawCharAtlas(fragCoord, start + vec2(2.0 * (charSizePx.x + gapPx), 0.0), charSizePx, c2));
    if (c3 >= 0) a = max(a, drawCharAtlas(fragCoord, start + vec2(3.0 * (charSizePx.x + gapPx), 0.0), charSizePx, c3));
    if (c4 >= 0) a = max(a, drawCharAtlas(fragCoord, start + vec2(4.0 * (charSizePx.x + gapPx), 0.0), charSizePx, c4));
    return a;
}

float sdRoundRect(vec2 p, vec2 b, float r) {
    // Standard rounded-rect SDF
    vec2 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec4 drawKeyChip(
    vec2 fragCoord,
    vec2 centerPx,
    vec2 halfSizePx,
    float radiusPx,
    float pressed,
    float labelAlpha
) {
    vec2 p = fragCoord - centerPx;
    float d = sdRoundRect(p, halfSizePx, radiusPx);
    float fill = 1.0 - smoothstep(0.0, 1.0, d);
    float border = 1.0 - smoothstep(1.0, 2.0, abs(d));

    vec3 bgOff = COLOR_CARD;
    vec3 bgOn = COLOR_CARD_ON;
    vec3 fg = COLOR_TEXT;

    vec3 bg = mix(bgOff, bgOn, pressed);

    float label = labelAlpha * fill;

    vec3 chip = COLOR_BG;
    chip = mix(chip, bg, fill);
    // Border is a subtle mix of card and text colors (derived, no new hard-coded color).
    vec3 borderCol = mix(bg, fg, 0.12);
    chip = mix(chip, borderCol, border * 0.55);
    chip = mix(chip, fg, label);

    float a = clamp(fill + border * 0.8, 0.0, 1.0);
    return vec4(chip, a);
}


void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Background
    vec3 col = COLOR_BG;

    // Keys we care about (Shadertoy key codes)
    float kLeft  = keyDown(37);
    float kUp    = keyDown(38);
    float kRight = keyDown(39);
    float kDown  = keyDown(40);
    float kSpace = keyDown(32);
    // Letters come from `event.character` in KeyboardController: usually lowercase.
    float kW = max(keyDown(119), keyDown(87));
    float kA = max(keyDown(97), keyDown(65));
    float kS = max(keyDown(115), keyDown(83));
    float kD = max(keyDown(100), keyDown(68));

    // Layout (pixel space). Simulate a keyboard-like arrangement.
    vec2 c = iResolution.xy * 0.5;
    float minDim = min(iResolution.x, iResolution.y);

    // A single "key unit" in pixels; even bigger so the layout occupies more of the screen.
    float u = clamp(minDim / 8.3, 52.0, 112.0);
    // Character size in pixels for the atlas (approx 8x8 codepage cell).
    // Match the perceived size from `Text Texture.frag` (roughly 8px * 10 = 80px per glyph).
    float glyphPx = clamp(u * 0.80, 64.0, 92.0);
    vec2 charSize = vec2(glyphPx, glyphPx);
    float charGap = max(2.0, glyphPx * 0.20);

    vec2 keyHalf = vec2(u * 0.50, u * 0.34);
    float radius = 0.18 * u;

    // Use a single consistent edge-to-edge gap for both horizontal and vertical spacing.
    float edgeGap = u * 0.45;
    float stepX = 2.0 * keyHalf.x + edgeGap;
    float stepY = 2.0 * keyHalf.y + edgeGap;

    // Base anchors: WASD on the left, arrows on the right, space below.
    // Separation between WASD cluster and arrow cluster.
    float sep = min(iResolution.x * 0.36, u * 3.10);
    vec2 wasdBase = c + vec2(-sep, 0.0);
    vec2 arrBase  = c + vec2(sep, 0.0);

    // WASD (W above, A S D row)
    {
        vec2 center = wasdBase + vec2(0.0, stepY);
        float a = drawLabel5(fragCoord, center, charSize, charGap, 87, -1, -1, -1, -1);
        vec4 chip = drawKeyChip(fragCoord, center, keyHalf, radius, kW, a);
        col = mix(col, chip.rgb, chip.a);
    }
    {
        vec2 center = wasdBase + vec2(-stepX, 0.0);
        float a = drawLabel5(fragCoord, center, charSize, charGap, 65, -1, -1, -1, -1);
        vec4 chip = drawKeyChip(fragCoord, center, keyHalf, radius, kA, a);
        col = mix(col, chip.rgb, chip.a);
    }
    {
        vec2 center = wasdBase;
        float a = drawLabel5(fragCoord, center, charSize, charGap, 83, -1, -1, -1, -1);
        vec4 chip = drawKeyChip(fragCoord, center, keyHalf, radius, kS, a);
        col = mix(col, chip.rgb, chip.a);
    }
    {
        vec2 center = wasdBase + vec2(stepX, 0.0);
        float a = drawLabel5(fragCoord, center, charSize, charGap, 68, -1, -1, -1, -1);
        vec4 chip = drawKeyChip(fragCoord, center, keyHalf, radius, kD, a);
        col = mix(col, chip.rgb, chip.a);
    }

    // Arrows (Up above, Left/Down/Right row)
    {
        vec2 center = arrBase + vec2(0.0, stepY);
        float a = drawLabel5(fragCoord, center, charSize, charGap, 94, -1, -1, -1, -1); // '^'
        vec4 chip = drawKeyChip(fragCoord, center, keyHalf, radius, kUp, a);
        col = mix(col, chip.rgb, chip.a);
    }
    {
        vec2 center = arrBase + vec2(-stepX, 0.0);
        float a = drawLabel5(fragCoord, center, charSize, charGap, 60, -1, -1, -1, -1); // '<'
        vec4 chip = drawKeyChip(fragCoord, center, keyHalf, radius, kLeft, a);
        col = mix(col, chip.rgb, chip.a);
    }
    {
        vec2 center = arrBase;
        float a = drawLabel5(fragCoord, center, charSize, charGap, 118, -1, -1, -1, -1); // 'v'
        vec4 chip = drawKeyChip(fragCoord, center, keyHalf, radius, kDown, a);
        col = mix(col, chip.rgb, chip.a);
    }
    {
        vec2 center = arrBase + vec2(stepX, 0.0);
        float a = drawLabel5(fragCoord, center, charSize, charGap, 62, -1, -1, -1, -1); // '>'
        vec4 chip = drawKeyChip(fragCoord, center, keyHalf, radius, kRight, a);
        col = mix(col, chip.rgb, chip.a);
    }

    // Space (centered below)
    {
        vec2 center = c + vec2(0.0, -u * 1.85);
        vec2 spaceHalf = vec2(u * 1.65, u * 0.34);
        float a = drawLabel5(fragCoord, center, charSize, charGap, 83, 80, -1, -1, -1); // "SP"
        vec4 chip = drawKeyChip(fragCoord, center, spaceHalf, radius, kSpace, a);
        col = mix(col, chip.rgb, chip.a);
    }

    fragColor = vec4(col, 1.0);
}

// 测试多个键同时按下是否正常
// void mainImage(out vec4 fragColor, in vec2 fragCoord) {
//     float r = keyDown(38); // Up
//     float g = keyDown(37); // Left
//     float b = keyDown(39); // Right

//     // Space 当亮度
//     float a = 0.3 + 0.7 * keyDown(32);

//     fragColor = vec4(r, g, b, a);
// }
// 测试单个键按下
// void mainImage(out vec4 fragColor, in vec2 fragCoord) {
//     vec2 uv = fragCoord / iResolution.xy;

//     float v = 0.0;

//     if (uv.y > 0.8)      v = keyDown(32); // Space
//     else if (uv.y > 0.6) v = keyDown(38); // Up
//     else if (uv.y > 0.4) v = keyDown(40); // Down
//     else if (uv.y > 0.2) v = keyDown(37); // Left
//     else                 v = keyDown(39); // Right

//     fragColor = vec4(vec3(v), 1.0);
// }

#include <../common/main_shadertoy.frag>
