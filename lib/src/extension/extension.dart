import 'package:shader_graph/src/shader_buffer.dart';

/// DSL 扩展，方便通过字符串创建 ShaderBuffer 及其链式调用。
/// DSL extension to create ShaderBuffer and chain calls via String.
extension StringDSL on String {
  ShaderBuffer get shaderBuffer => ShaderBuffer(this);

  ShaderBuffer feedShaderBuffer(ShaderBuffer buffer) {
    return shaderBuffer.feedShader(buffer);
  }

  ShaderBuffer feedShaderBufferAsset(String assetPath) {
    return shaderBuffer.feedShaderFromAsset(assetPath);
  }

  ShaderBuffer feedImageBufferFromAsset(String assetPath) {
    return shaderBuffer.feedImageFromAsset(assetPath);
  }

  ShaderBuffer feedback() {
    return shaderBuffer.feedback();
  }

  ShaderBuffer feedKeyboard() {
    return shaderBuffer.feedKeyboard();
  }
}
