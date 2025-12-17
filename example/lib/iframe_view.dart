import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';

class IframeView extends StatelessWidget {
  const IframeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurfaceWrapper.builder(
      () {
        final sourceBuffer = 'shaders/frame/IFrame Test.frag'.shaderBuffer;
        final overlayBuffer = 'shaders/keyboard/Keyboard Debug Overlay.frag'.shaderBuffer;
        // iChannel0 = 源着色器输出
        overlayBuffer.feedShader(sourceBuffer);
        // iChannel1 = 键盘输入
        overlayBuffer.feedKeyboard();

        return [sourceBuffer, overlayBuffer];
      },
      key: const ValueKey('iframe'),
    );
  }
}
