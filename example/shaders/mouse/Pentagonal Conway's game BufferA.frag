// --- Migrate Log ---
// 1) 添加 common_header + sg_feedback_rgba8，并用 SG_LOAD_* / sg_store* 实现 RGBA8 feedback
// 2) 替换 texelFetch 与整数 %：用 SG_TEXELFETCH* / SG_LOAD_VEC4 + mod(float) 实现
// 3) 适配 vec4 虚拟 texel 的横向 lane pack（x 方向 /4）
// 4) 显式固定 VSIZE/psize 并做像素边界保护，避免越界读写
// 5) 增加元数据行保存 prevPressed，实现长按只 toggle 一次（justPressed）
// 6) 替换 int 的 min/max 为比较运算，修复 SkSL 重载不匹配
// 7) 替换 vec4 的动态索引为 if 链，修复 SkSL 常量索引限制
//
// 1) Add common_header + sg_feedback_rgba8, use SG_LOAD_* / sg_store* for RGBA8 feedback
// 2) Replace texelFetch and integer % with SG_TEXELFETCH* / SG_LOAD_VEC4 + mod(float)
// 3) Adapt to lane-packed virtual texels (x / 4)
// 4) Pin VSIZE/psize constants and add pixel bounds checks to avoid OOB reads/writes
// 5) Add a metadata row to store prevPressed for justPressed (toggle once per press)
// 6) Replace int min/max with comparisons to satisfy SkSL overloads
// 7) Replace vec4 dynamic indexing with if-chains to satisfy SkSL constant-index rules

#include <../common/common_header.frag>
#include <../common/sg_feedback_rgba8.frag>

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
#define r3 1.73205080757

vec2 uvmap(vec2 coord, vec2 res){
    return coord/res.y*15.0;
}

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

bool gol(int n, bool s) {
    return (s && (n == 2 || n == 3)) || (!s && (n == 3 || n == 4 || n == 6));
}

int alive(float v) {
    return (v > 0.5) ? 1 : 0;
}

ivec2 clampVpos(ivec2 pos, ivec2 vsize) {
    int x = pos.x;
    int y = pos.y;
    int maxX = vsize.x - 1;
    int maxY = vsize.y - 1;
    x = (x < 0) ? 0 : x;
    y = (y < 0) ? 0 : y;
    x = (x > maxX) ? maxX : x;
    y = (y > maxY) ? maxY : y;
    return ivec2(x, y);
}

float getVec4At(vec4 v, int idx) {
    if (idx == 0) return v.x;
    if (idx == 1) return v.y;
    if (idx == 2) return v.z;
    return v.w;
}

vec4 setVec4At(vec4 v, int idx, float value) {
    if (idx == 0) return vec4(value, v.y, v.z, v.w);
    if (idx == 1) return vec4(v.x, value, v.z, v.w);
    if (idx == 2) return vec4(v.x, v.y, value, v.w);
    return vec4(v.x, v.y, v.z, value);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    ivec2 p = ivec2(fragCoord - 0.5);

    const vec2 VSIZE = vec2(128.0, 129.0);
    const ivec2 VSIZE_I = ivec2(128, 129);
    const ivec2 SIM_I = ivec2(128, 128);
    const vec2 psize = vec2(128.0 * 4.0, 129.0);

    if (p.x < 0 || p.y < 0 || float(p.x) >= psize.x || float(p.y) >= psize.y) {
        fragColor = vec4(0.0);
        return;
    }

    ivec2 vpos = ivec2(p.x / 4, p.y);

    vec4 outState = vec4(0.0);

    bool pressed = (iMouse.z >= 0.0 && iMouse.w >= 0.0);
    if (vpos.y == 128) {
        outState = pressed ? vec4(1.0) : vec4(0.0);
        fragColor = vec4(0.0);
        sg_storeVec4(vpos, outState, fragColor, p);
        return;
    }

    if (iFrame > 0.5) {
        vec4 g0 = SG_LOAD_VEC4(iChannel0, vpos, VSIZE);
        outState = g0;

        bool spaceDown = (SG_TEXELFETCH1(ivec2(32, 2)).x > 0.0);
        bool tick = (mod(iFrame, 20.0) < 0.5);
        if (tick && spaceDown) {
            ivec2 vp0 = vpos;
            ivec2 vp1 = clampVpos(vpos + ivec2(0, -1), SIM_I);
            ivec2 vp2 = clampVpos(vpos + ivec2(1, -1), SIM_I);
            ivec2 vp3 = clampVpos(vpos + ivec2(1, 0), SIM_I);
            ivec2 vp4 = clampVpos(vpos + ivec2(1, 1), SIM_I);
            ivec2 vp5 = clampVpos(vpos + ivec2(0, 1), SIM_I);
            ivec2 vp6 = clampVpos(vpos + ivec2(-1, 1), SIM_I);
            ivec2 vp7 = clampVpos(vpos + ivec2(-1, 0), SIM_I);
            ivec2 vp8 = clampVpos(vpos + ivec2(-1, -1), SIM_I);

            vec4 s0 = g0;
            vec4 s1 = SG_LOAD_VEC4(iChannel0, vp1, VSIZE);
            vec4 s2 = SG_LOAD_VEC4(iChannel0, vp2, VSIZE);
            vec4 s3 = SG_LOAD_VEC4(iChannel0, vp3, VSIZE);
            vec4 s4 = SG_LOAD_VEC4(iChannel0, vp4, VSIZE);
            vec4 s5 = SG_LOAD_VEC4(iChannel0, vp5, VSIZE);
            vec4 s6 = SG_LOAD_VEC4(iChannel0, vp6, VSIZE);
            vec4 s7 = SG_LOAD_VEC4(iChannel0, vp7, VSIZE);
            vec4 s8 = SG_LOAD_VEC4(iChannel0, vp8, VSIZE);

            vec4 result = vec4(0.0);
            int neighbors = 0;
            neighbors = alive(s0[1]) + alive(s0[2]) + alive(s0[3]) + alive(s1[2]) + alive(s1[3]) + alive(s7[1]) + alive(s8[3]);
            result[0] = float(gol(neighbors, s0[0] > 0.5));

            neighbors = alive(s0[0]) + alive(s0[2]) + alive(s0[3]) + alive(s1[3]) + alive(s2[2]) + alive(s3[0]) + alive(s3[2]);
            result[1] = float(gol(neighbors, s0[1] > 0.5));

            neighbors = alive(s0[0]) + alive(s0[1]) + alive(s0[3]) + alive(s5[0]) + alive(s6[1]) + alive(s7[3]) + alive(s7[1]);
            result[2] = float(gol(neighbors, s0[2] > 0.5));

            neighbors = alive(s0[0]) + alive(s0[1]) + alive(s0[2]) + alive(s3[2]) + alive(s4[0]) + alive(s5[0]) + alive(s5[1]);
            result[3] = float(gol(neighbors, s0[3] > 0.5));

            outState = result;
        }
    } else {
        float initV = (vpos == ivec2(1, 1)) ? 1.0 : 0.0;
        outState = vec4(initV);
    }

    if (pressed) {
        vec4 pr = SG_LOAD_VEC4(iChannel0, ivec2(0, 128), VSIZE);
        float prevPressed = dot(pr, vec4(0.25));
        if (prevPressed < 0.5) {
            vec2 mousePx = vec2(iMouse.z, iMouse.w);
            vec2 resPx = iResolution.xy;
            ivec3 pcoord = coordtopenta(uvmap(mousePx, resPx));
            if (pcoord.xy == vpos) {
                int idx = pcoord.z;
                float oldV = getVec4At(outState, idx);
                outState = setVec4At(outState, idx, (oldV > 0.5) ? 0.0 : 1.0);
            }
        }
    }

    fragColor = vec4(0.0);
    sg_storeVec4(vpos, outState, fragColor, p);
}

#include <../common/main_shadertoy.frag>