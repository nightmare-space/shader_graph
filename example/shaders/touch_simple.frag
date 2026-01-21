// Simplified Mesh Grid Shader
// 简化版 - 只有网格 + 基本抬起效果

#include <common/common_header.frag>

uniform float liftStrength;
uniform float liftRadius;
uniform float pointsPerRow;
uniform float baseDotOpacity;
uniform float swapProgress;

uniform vec4 iMouse1;
uniform vec4 iMouse2;
uniform vec4 iMouse3;
uniform vec4 iMouse4;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;

    float gridSize = pointsPerRow / aspect;

    float liftFalloff = 0.0;
    float maxLift = 0.0;
    vec2 mouseForNormal = vec2(0.0);

    if (iMouse1.x >= 0.0) {
        vec2 m1 = iMouse1.xy / iResolution.xy;
        m1.x *= aspect;
        float l1 = 1.0 - smoothstep(0.0, liftRadius, length(uv - m1));
        liftFalloff = max(liftFalloff, l1);
        if (l1 > maxLift) {
            maxLift = l1;
            mouseForNormal = m1;
        }
    }
    if (iMouse2.x >= 0.0) {
        vec2 m2 = iMouse2.xy / iResolution.xy;
        m2.x *= aspect;
        float l2 = 1.0 - smoothstep(0.0, liftRadius, length(uv - m2));
        liftFalloff = max(liftFalloff, l2);
        if (l2 > maxLift) {
            maxLift = l2;
            mouseForNormal = m2;
        }
    }
    if (iMouse3.x >= 0.0) {
        vec2 m3 = iMouse3.xy / iResolution.xy;
        m3.x *= aspect;
        float l3 = 1.0 - smoothstep(0.0, liftRadius, length(uv - m3));
        liftFalloff = max(liftFalloff, l3);
        if (l3 > maxLift) {
            maxLift = l3;
            mouseForNormal = m3;
        }
    }
    if (iMouse4.x >= 0.0) {
        vec2 m4 = iMouse4.xy / iResolution.xy;
        m4.x *= aspect;
        float l4 = 1.0 - smoothstep(0.0, liftRadius, length(uv - m4));
        liftFalloff = max(liftFalloff, l4);
        if (l4 > maxLift) {
            maxLift = l4;
            mouseForNormal = m4;
        }
    }

    float height = liftFalloff * liftStrength;

    // 高度场法线（用于更接近 touch.frag 的光照观感）
    vec3 normal = vec3(0.0, 0.0, 1.0);
    if (maxLift > 0.0) {
        float eps = 1.0 / iResolution.y;
        float heightX = (1.0 - smoothstep(0.0, liftRadius, length(vec2(uv.x + eps, uv.y) - mouseForNormal))) * liftStrength;
        float heightY = (1.0 - smoothstep(0.0, liftRadius, length(vec2(uv.x, uv.y + eps) - mouseForNormal))) * liftStrength;
        normal = normalize(vec3(height - heightX, height - heightY, 0.35));
    }

    // 用 height 对 UV 做轻微位移，让“顶起”可见
    vec2 uvDisp = uv;
    if (maxLift > 0.0) {
        uvDisp += (uv - mouseForNormal) * height * 0.25;
    }

    // 简单的网格：点在格子中心
    vec2 gridUv = uvDisp * gridSize;
    vec2 gridId = floor(gridUv);
    vec2 gridFrac = fract(gridUv);
    
    // 2x2 组内对角线交换（参考 touch.frag 的实现）
    // 需要在邻域中取最大值，因为点会跨格移动到当前像素所在格
    float dotRadius = 0.12;
    float dotMask = 0.0;

    for (float dy = -1.0; dy <= 1.0; dy += 1.0) {
        for (float dx = -1.0; dx <= 1.0; dx += 1.0) {
            vec2 neighborId = gridId + vec2(dx, dy);
            vec2 neighborPosInGroup = mod(neighborId, 2.0);

            // 邻居格子中点的偏移（以格子为单位）
            vec2 neighborDotOffset = vec2(0.0);

            if (swapProgress < 0.5) {
                // 第一阶段：左上 (0,1) <-> 右下 (1,0)
                float phase1Progress = swapProgress * 2.0;
                if (neighborPosInGroup.x > 0.5 && neighborPosInGroup.y < 0.5) {
                    // 右下 -> 左上
                    neighborDotOffset = vec2(-1.0, 1.0) * phase1Progress;
                } else if (neighborPosInGroup.x < 0.5 && neighborPosInGroup.y > 0.5) {
                    // 左上 -> 右下
                    neighborDotOffset = vec2(1.0, -1.0) * phase1Progress;
                }
            } else {
                // 第二阶段：右上 (1,1) <-> 左下 (0,0)
                float phase2Progress = (swapProgress - 0.5) * 2.0;

                if (neighborPosInGroup.x < 0.5 && neighborPosInGroup.y < 0.5) {
                    // 左下 -> 右上
                    neighborDotOffset = vec2(1.0, 1.0) * phase2Progress;
                } else if (neighborPosInGroup.x > 0.5 && neighborPosInGroup.y > 0.5) {
                    // 右上 -> 左下
                    neighborDotOffset = vec2(-1.0, -1.0) * phase2Progress;
                } else if (neighborPosInGroup.x > 0.5 && neighborPosInGroup.y < 0.5) {
                    // 第一阶段已完成的右下点：固定在左上
                    neighborDotOffset = vec2(-1.0, 1.0);
                } else if (neighborPosInGroup.x < 0.5 && neighborPosInGroup.y > 0.5) {
                    // 第一阶段已完成的左上点：固定在右下
                    neighborDotOffset = vec2(1.0, -1.0);
                }
            }

            // 邻居格子中点的中心位置（相对当前格子的坐标）
            vec2 neighborDotCenter = vec2(dx, dy) + 0.5 + neighborDotOffset;

            vec2 toDot = gridFrac - neighborDotCenter;
            float distDot = length(toDot);
            float mask = smoothstep(dotRadius, dotRadius - 0.02, distDot);

            // 留白带：靠近格子边界时压掉点的贡献，避免点与点连成一片
            float spacingMask = smoothstep(0.48, 0.50, max(abs(toDot.x), abs(toDot.y)));
            mask *= (1.0 - spacingMask);

            dotMask = max(dotMask, mask);
        }
    }
    
    // 光照（模拟被顶起的点阵表面）
    vec3 baseColor = vec3(0.02, 0.03, 0.05);
    vec3 dotColor = vec3(0.85, 0.92, 1.0);

    vec3 lightDir = normalize(vec3(-0.35, 0.5, 1.2));
    float diff = clamp(dot(normal, lightDir), 0.0, 1.0);
    float rim = pow(1.0 - clamp(normal.z, 0.0, 1.0), 2.0);
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 halfDir = normalize(lightDir + viewDir);
    float spec = pow(clamp(dot(normal, halfDir), 0.0, 1.0), 24.0);
    float heightShade = mix(0.75, 1.15, height);

    float intensity = 0.22 + diff * 0.9 + rim * 0.5 + height * 0.9;
    float normalizedLift = min(liftStrength / 1.2, 1.0);
    float highlightFalloff = mix(0.0, liftFalloff, normalizedLift);
    float dotOpacity = mix(baseDotOpacity, 1.0, highlightFalloff);

    vec3 color = baseColor + dotColor * dotMask * intensity * dotOpacity;
    color *= heightShade;
    color += spec * dotMask * 0.35;
    
    fragColor = vec4(color, 1.0);
}

#include <common/main_shadertoy.frag>
