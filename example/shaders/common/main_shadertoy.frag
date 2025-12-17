void main() {
    // 保留uniform变量，防止着色器编译器优化移除它们
    // 使用更简洁的方式：确保每个uniform至少被访问一次
    float unused = iFrame + iMouse.x + iTime + iResolution.x;
    
    vec2 fragCoord = FlutterFragCoord().xy;
    
    // 只在必要时才使用unused变量，避免条件判断
    mainImage(fragColor, fragCoord * (unused / unused));
}