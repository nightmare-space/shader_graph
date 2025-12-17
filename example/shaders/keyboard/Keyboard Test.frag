#include <../common/common_header.frag>

uniform sampler2D iChannel0;
// =======================
// Shadertoy Keyboard Test
// =======================

float keyDown(int key) {
    // row 0 = key down
    return texture(
        iChannel0,
        (vec2(float(key), 0.0) + 0.5) / vec2(256.0, 3.0)
    ).r;
}


void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    float x = floor(uv.x * 256.0);
    float v = keyDown(int(x));

    fragColor = vec4(vec3(v), 1.0);
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
