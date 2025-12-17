// ============================================================================
// 迁移日志 / Migration Log:
// 项目 / Project: Mouse Interaction Demo
// 文件 / File: Mouse_Interactive.frag
// 
// 关键功能 / Key Features:
// 1. 使用 iMouse 获取鼠标位置
// 2. 在鼠标位置绘制交互效果
// 3. 显示鼠标点击状态
// ============================================================================

#include <../common/common_header.frag>


void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / iResolution.xy;
  
  // 获取鼠标位置（像素坐标转换为归一化坐标）
  vec2 mouseUV = iMouse.xy / iResolution.xy;
  
  // 计算当前像素到鼠标的距离
  float dist = distance(uv, mouseUV);
  
  // 背景颜色
  vec3 bgColor = vec3(0.1);
  
  // 绘制鼠标周围的圆形效果
  float circle = smoothstep(0.15, 0.1, dist);  // 外圆
  float innerCircle = smoothstep(0.05, 0.03, dist);  // 内圆
  
  // 判断鼠标是否按下（iMouse.z > 0 表示按下）
  float isPressed = step(0.0, iMouse.z);
  
  // 按下时颜色为红色，未按下为蓝色
  vec3 circleColor = mix(vec3(0.0, 0.3, 1.0), vec3(1.0, 0.2, 0.2), isPressed);
  
  // 合成最终颜色
  vec3 finalColor = mix(bgColor, circleColor, circle);
  finalColor = mix(finalColor, vec3(1.0), innerCircle * 0.5);
  
  // 显示网格来帮助定位
  float gridX = mod(uv.x * 10.0, 1.0);
  float gridY = mod(uv.y * 10.0, 1.0);
  float grid = (step(0.95, gridX) + step(0.95, gridY)) * 0.1;
  finalColor += vec3(grid);
  
  fragColor = vec4(finalColor, 1.0);
}

#include <../common/main_shadertoy.frag>