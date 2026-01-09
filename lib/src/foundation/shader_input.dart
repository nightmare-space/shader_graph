import 'dart:ui';

import 'filter_mode.dart';
import 'wrap_mode.dart';

/// 输入的抽象定义，可以让 ShaderBuffer 不用关心是具体是什么输入，只需要获取 Image 即可。
///
/// An abstract definition of input, allowing ShaderBuffer to not care about the specific input, just need to get the Image.
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
