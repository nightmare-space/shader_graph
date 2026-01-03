/// Sampler filter mode for Shadertoy-style inputs.
///
/// NOTE: Flutter runtime shaders currently don't expose per-sampler filter state
/// (linear/nearest/mipmap) directly. This library models filter choice as a
/// *shader-side* sampling strategy (see `example/shaders/common/common_header.frag`).
enum FilterMode {
  linear,
  nearest,
  mipmap,
}

extension FilterModeValue on FilterMode {
  /// Encoded as a float uniform for the shader:
  /// 0 = linear, 1 = nearest, 2 = mipmap.
  double get uniformValue {
    switch (this) {
      case FilterMode.linear:
        return 0.0;
      case FilterMode.nearest:
        return 1.0;
      case FilterMode.mipmap:
        return 2.0;
    }
  }
}
