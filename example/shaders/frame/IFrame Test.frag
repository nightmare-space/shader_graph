// ============================================================================
// 迁移日志 / Migration Log:
// 项目 / Project: iFrame Counter Demo
// 文件 / File: iFrame_Counter.frag
// 
// 关键功能 / Key Features:
// 1. 使用 iFrame 显示帧计数
// 2. 创建基于帧数的动画效果
// 3. 简单的视觉反馈验证
// ============================================================================

#include <../common/common_header.frag>

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / iResolution.xy;
  
  float framePhase = mod(iFrame, 120.0) / 120.0;
  float stripes = mod(uv.x * 10.0 + framePhase * 5.0, 1.0);
  float bar = step(0.3, stripes) * step(stripes, 0.7);
  
  
  // 背景：浅灰色
  vec3 bgColor = vec3(0.15);
  
  // 条纹：基于 iFrame 变化的颜色
  vec3 barColor = vec3(0.2);
  
  vec3 finalColor = mix(bgColor, barColor, bar);
  
  // 显示帧计数（灰度条）
  // 说明：不同平台/封装里 fragCoord 的 y 方向可能相反（y-up 或 y-down）。
  // 为了避免“顶部条”被坐标系翻转后完全筛掉，这里用屏幕边缘检测：靠近任一边缘都显示。
  float topBar = step(0.95, max(uv.y, 1.0 - uv.y));
  float frameCount = mod(iFrame / 120.0, 1.0);
  float frameBar = step(uv.x, frameCount);
  
  finalColor = mix(finalColor, vec3(1.0), topBar * frameBar * 0.8);
  
  fragColor = vec4(finalColor, 1.0);
}

#include <../common/main_shadertoy.frag>