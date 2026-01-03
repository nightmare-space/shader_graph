import 'dart:ui';

import 'filter_mode.dart';
import 'wrap_mode.dart';

abstract class ShaderInput {
  Image? resolve();

  /// UV wrap semantics expected by the shader.
  ///
  /// Defaults to clamp for compatibility.
  WrapMode get wrap => WrapMode.clamp;

  /// Filter semantics expected by the shader.
  ///
  /// Defaults to linear for compatibility.
  FilterMode get filter => FilterMode.linear;
}
