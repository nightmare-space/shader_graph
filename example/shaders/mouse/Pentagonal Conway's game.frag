// --- Migrate Log ---
// 1) 添加 common_header + sg_feedback_rgba8，并用 SG_LOAD_VEC4 读取 Buffer 状态
// 2) 替换 texelFetch：保持“一个虚拟 texel = vec4”的语义
// 3) 适配 BufferA 额外的元数据行（仅采样模拟区域，忽略最后一行）
// 4) 替换 vec4 的动态索引为 if 链，修复 SkSL 常量索引限制
//
// 1) Add common_header + sg_feedback_rgba8, read state via SG_LOAD_VEC4
// 2) Replace texelFetch while preserving "one virtual texel = vec4" semantics
// 3) Adapt to BufferA metadata row (sample simulation area only, ignore the last row)
// 4) Replace vec4 dynamic indexing with if-chains to satisfy SkSL constant-index rules

float getVec4At(vec4 v, int idx) {
    if (idx == 0) return v.x;
    if (idx == 1) return v.y;
    if (idx == 2) return v.z;
    return v.w;
}

#include <../common/common_header.frag>
#include <../common/sg_feedback_rgba8.frag>

uniform sampler2D iChannel0;

// Inlined from "Pentagonal Conway's game Common.frag" (avoid local #include parsing issues).
#define r3 1.73205080757

vec2 uvmap(vec2 coord, vec2 res){
    return coord/res.y*15.0;
}

//gets texture coords + index of a pixel
ivec3 coordtopenta(vec2 uv){
    uv = mat2(1,-1,1,1)*uv;
    vec2 cuv = floor(uv);
    uv = fract(uv) - 0.5;
    
    vec2 puv = cuv;
    int idx = 0;
    if (mod(cuv.x,2.0) == mod(cuv.y,2.0)){
        vec2 ruv = mat2(-r3,-1,1,-r3)*uv;
        idx = int(ruv.x < 0.0) + 2*int(ruv.y < 0.0);
    } else {
        vec2 ruv = mat2(r3,1,1,-r3)*uv;
        bool a = ruv.x < 0.0;
        bool b = ruv.y < 0.0;
        idx = 2*int(a) + int(b);
        puv += sign(ruv.x)*vec2(a == b, a != b);
    }
    puv = mat2(1,1,-1,1)*puv/2.0;
    
    return ivec3(puv, idx);
}

float sdLine(vec2 a, vec2 b, vec2 p){
    vec2 ab = b - a;
    float t = dot(p - a, ab)/dot(ab, ab);
    vec2 p2 = a + clamp(t,0.0,1.0)*ab;
    return length(p - p2);
}

//draws the lines between the pentagons
float pentagrid(vec2 uv){
    uv = mat2(1,-1,1,1)*uv*r3;
    vec2 cuv = floor(uv/r3);
    uv = fract(uv/r3)*r3;
    float d = 1e20;
    if (mod(cuv.x,2.0) == mod(cuv.y,2.0)){
        d = min(d, sdLine(vec2(r3/2.0 - 0.5, 0),vec2(r3/2.0 + 0.5, r3),uv));
        d = min(d, sdLine(vec2(0, r3/2.0 + 0.5),vec2(r3, r3/2.0 - 0.5),uv));
        d = min(d, sdLine(vec2(0, 0),vec2(r3/2.0 - 0.5, 0),uv));
        d = min(d, sdLine(vec2(r3, r3),vec2(r3/2.0 + 0.5, r3),uv));
        d = min(d, sdLine(vec2(0, r3),vec2(0, r3/2.0 + 0.5),uv));
        d = min(d, sdLine(vec2(r3, 0),vec2(r3, r3/2.0 - 0.5),uv));
    } else {
        d = min(d, sdLine(vec2(0, r3/2.0 - 0.5),vec2(r3, r3/2.0 + 0.5),uv));
        d = min(d, sdLine(vec2(r3/2.0 + 0.5, 0),vec2(r3/2.0 - 0.5, r3),uv));
        d = min(d, sdLine(vec2(0, 0),vec2(0, r3/2.0 - 0.5),uv));
        d = min(d, sdLine(vec2(r3, r3),vec2(r3, r3/2.0 + 0.5),uv));
        d = min(d, sdLine(vec2(r3, 0),vec2(r3/2.0 + 0.5, 0),uv));
        d = min(d, sdLine(vec2(0, r3),vec2(r3/2.0 - 0.5, r3),uv));
    }
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = uvmap(fragCoord, iResolution.xy);
    float pxunit = uvmap(vec2(0, 1), iResolution.xy).y;

    ivec3 pcoord = coordtopenta(uv);

    vec2 VSIZE = vec2(iChannelResolution0.x / 4.0, iChannelResolution0.y);
    vec2 SIMSIZE = vec2(VSIZE.x, VSIZE.y - 1.0);
    ivec2 SIM_I = ivec2(SIMSIZE);

    float cell = 0.0;
    if (pcoord.x >= 0 && pcoord.y >= 0 && pcoord.x < SIM_I.x && pcoord.y < SIM_I.y) {
        vec4 s = SG_LOAD_VEC4(iChannel0, pcoord.xy, VSIZE);
        float v = getVec4At(s, pcoord.z);
        cell = (v > 0.5) ? 1.0 : 0.0;
    }

    vec4 c0 = vec4(0.337, 0.404, 0.443, 1.0);
    vec4 c1 = vec4(0.580, 0.608, 0.573, 1.0);
    fragColor = mix(c0, c1, cell) * smoothstep(0.0, pxunit * 4.0, pentagrid(uv) - 0.01);
}

#include <../common/main_shadertoy.frag>