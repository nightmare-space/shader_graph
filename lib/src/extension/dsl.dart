import 'package:path/path.dart';
import 'package:shader_graph/shader_graph.dart';

/// DSL 扩展，方便通过字符串创建 ShaderBuffer 及其链式调用。
/// DSL extension to create ShaderBuffer and chain calls via String.
extension StringDSL on String {
  ShaderBuffer get shaderBuffer => ShaderBuffer(this);

  ShaderBuffer feed(dynamic input, {WrapMode wrap = WrapMode.clamp}) {
    return shaderBuffer.feed(input, wrap: wrap);
  }

  ShaderBuffer feedback() {
    return shaderBuffer.feedback();
  }

  ShaderBuffer feedKeyboard() {
    return shaderBuffer.feedKeyboard();
  }
}

extension ShaderBufferDSL on ShaderBuffer {
  /// 在我自己比较多的使用中，发现还是有一个这样的函数比较方便
  /// 无论是给 ShaderBuffer 还是着色器资源路径，图片资源路径，可以自动判断
  /// I found it more convenient to have such a function in my own practice
  /// Whether it's a ShaderBuffer, shader asset path, or image asset path, it can automatically determine
  ShaderBuffer feed(dynamic input, {WrapMode wrap = WrapMode.clamp}) {
    if (input is ShaderBuffer) {
      return feedShader(input, wrap: wrap);
    } else if (input is String) {
      final ext = extension(input).toLowerCase();
      if (ext == '.frag') {
        return feedShaderFromAsset(input, wrap: wrap);
      } else {
        return feedImageFromAsset(input, wrap: wrap);
      }
    } else {
      throw ArgumentError('input must be ShaderBuffer or String, got ${input.runtimeType}');
    }
  }
}
