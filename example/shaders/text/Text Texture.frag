// Text Nightmare Display
// 显示 "Nightmare" 或 "Laurie" 单词

#include <../common/common_header.frag>
uniform sampler2D iChannel0;  // 字体纹理图集

// 字体图集是 16x16 的网格，每个字符占据一个格子
const vec2 gridSize = vec2(16.0, 16.0);
const vec2 charPixelSize = vec2(8.0, 8.0);  // 每个字符的像素大小

// 从图集中获取指定字符
vec4 GetCharFromAtlas(int charCode, vec2 charLocalUv)
{
    // 计算字符在网格中的位置
    int gridX = int(mod(float(charCode), gridSize.x));
    int gridY = int(float(charCode) / gridSize.x);
    
    // 计算采样坐标
    vec2 gridUv = vec2(float(gridX), float(gridY)) / gridSize;
    vec2 charUv = charLocalUv / gridSize;
    
    return texture(iChannel0, gridUv + charUv);
}

// 获取 Nightmare 的字符代码
int GetNightmareCharCode(int index)
{
    // N=78, i=105, g=103, h=104, t=116, m=109, a=97, r=114, e=101
    if (index == 0) return 78;   // N
    if (index == 1) return 105;  // i
    if (index == 2) return 103;  // g
    if (index == 3) return 104;  // h
    if (index == 4) return 116;  // t
    if (index == 5) return 109;  // m
    if (index == 6) return 97;   // a
    if (index == 7) return 114;  // r
    if (index == 8) return 101;  // e
    return 32;  // 空格
}

// 获取 Laurie 的字符代码
int GetLaurieCharCode(int index)
{
    // L=76, a=97, u=117, r=114, i=105, e=101
    if (index == 0) return 76;   // L
    if (index == 1) return 97;   // a
    if (index == 2) return 117;  // u
    if (index == 3) return 114;  // r
    if (index == 4) return 105;  // i
    if (index == 5) return 101;  // e
    return 32;  // 空格
}

// 绘制 Nightmare
vec3 displayNightmare(vec2 textPos, float charWidth, float charHeight)
{
    vec3 col = vec3(0.0);  // 黑色背景
    int charCount = 9;
    float totalWidth = charWidth * float(charCount);
    vec2 startPos = vec2(-totalWidth * 0.5, 0.0);
    
    for (int i = 0; i < 9; i++) {
        vec2 charPos = textPos - startPos - vec2(float(i) * charWidth, 0.0);
        
        if (charPos.x > 0.0 && charPos.x < charWidth &&
            charPos.y > -charHeight && charPos.y < 0.0) {
            
            vec2 charLocalUv = vec2(charPos.x / charWidth, (-charPos.y - charHeight) / charHeight);
            charLocalUv = fract(charLocalUv);
            
            int charCode = GetNightmareCharCode(i);
            vec4 charCol = GetCharFromAtlas(charCode, charLocalUv);
            
            col = mix(col, vec3(1.0), charCol.x);
        }
    }
    
    return col;
}

// 绘制 Laurie
vec3 displayLaurie(vec2 textPos, float charWidth, float charHeight)
{
    vec3 col = vec3(0.0);  // 黑色背景
    int charCount = 6;
    float totalWidth = charWidth * float(charCount);
    vec2 startPos = vec2(-totalWidth * 0.5, 0.0);
    
    for (int i = 0; i < 6; i++) {
        vec2 charPos = textPos - startPos - vec2(float(i) * charWidth, 0.0);
        
        if (charPos.x > 0.0 && charPos.x < charWidth &&
            charPos.y > -charHeight && charPos.y < 0.0) {
            
            vec2 charLocalUv = vec2(charPos.x / charWidth, (-charPos.y - charHeight) / charHeight);
            charLocalUv = fract(charLocalUv);
            
            int charCode = GetLaurieCharCode(i);
            vec4 charCol = GetCharFromAtlas(charCode, charLocalUv);
            
            col = mix(col, vec3(1.0), charCol.x);
        }
    }
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    
    // 设置文字显示区域（屏幕中央）
    vec2 textPos = uv - vec2(0.5, 0.5);
    
    // 单个字符的尺寸（根据屏幕分辨率调整）
    float charWidth = charPixelSize.x / iResolution.x * 10.0;  // 缩放因子
    float charHeight = charPixelSize.y / iResolution.y * 10.0;
    
    // 调用 displayLaurie 显示 Laurie
    vec3 col = displayLaurie(textPos, charWidth, charHeight);
    
    fragColor = vec4(col, 1.0);
}

#include <../common/main_shadertoy.frag>