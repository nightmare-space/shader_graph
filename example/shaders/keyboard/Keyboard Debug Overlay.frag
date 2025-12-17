// Keyboard Debug Overlay Shader
// 在任何着色器输出上叠加键盘调试色块

#include <../common/common_header.frag>
uniform sampler2D iChannel0;  // 输入的着色器输出
uniform sampler2D iChannel1;  // 键盘数据纹理

const vec2 keyboardSize = vec2(256.0, 3.0);

const int KEY_SPACE = 32;
const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // 获取输入纹理的颜色
    vec2 uv = fragCoord / iResolution.xy;
    vec4 baseColor = texture(iChannel0, uv);
    
    // 初始输出为输入的颜色
    fragColor = baseColor;
    
    // 检查是否在调试区域（左上角 5 个 24x24 色块）
    if (fragCoord.y < 24.0 && fragCoord.x < 24.0 * 5.0) {
        float id = floor(fragCoord.x / 24.0);

        int key = KEY_LEFT;
        vec3 base = vec3(1.0, 0.0, 0.0);
        if (id > 0.5 && id < 1.5) { key = KEY_RIGHT; base = vec3(0.0, 1.0, 0.0); }
        else if (id > 1.5 && id < 2.5) { key = KEY_UP; base = vec3(0.0, 0.0, 1.0); }
        else if (id > 2.5 && id < 3.5) { key = KEY_DOWN; base = vec3(1.0, 0.0, 1.0); }
        else if (id > 3.5) { key = KEY_SPACE; base = vec3(1.0, 1.0, 0.0); }

        // 安全地采样键盘纹理，确保坐标在有效范围内
        float keyX = float(key) / keyboardSize.x;
        
        float down = texture(iChannel1, vec2(keyX, 0.0)).x;
        float jp   = texture(iChannel1, vec2(keyX, 1.0 / keyboardSize.y)).x;
        float v = max(down, jp);
        
        fragColor = vec4(base * (0.2 + 0.8 * v), 1.0);
    }
}

#include <../common/main_shadertoy.frag>