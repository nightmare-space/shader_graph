/// Sampler wrap mode for Shadertoy-style inputs.
///
/// NOTE: Flutter runtime shaders currently don't expose per-sampler wrap state
/// (repeat/clamp) directly, so this library models wrap as a *shader-side* UV
/// transform (see `example/shaders/common/common_header.frag`).
enum WrapMode {
  clamp,
  repeat,
  mirror,
}

extension WrapModeValue on WrapMode {
  /// Encoded as a float uniform for the shader:
  /// 0 = clamp, 1 = repeat, 2 = mirror.
  double get uniformValue {
    switch (this) {
      case WrapMode.clamp:
        return 0.0;
      case WrapMode.repeat:
        return 1.0;
      case WrapMode.mirror:
        return 2.0;
    }
  }
}
