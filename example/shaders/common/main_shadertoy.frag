void main() {
    // Keep uniforms alive to prevent the compiler from removing them.
    // IMPORTANT: Do NOT use `u/u` or any expression that perturbs `fragCoord`.
    // On some mobile GPUs (mediump / fast-math), `u/u` may not be exactly 1.0
    // and can even produce NaNs, causing frame-to-frame pixel coordinate drift.
    float keep = iFrame + iMouse.x + iTime + iResolution.x;

    vec2 fragCoord = FlutterFragCoord().xy;
    mainImage(fragColor, fragCoord);

    // Never true in practice, but depends on a uniform so it won't be optimized away.
    if (keep < -1e20) {
        fragColor += vec4(keep);
    }
}