import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';

class MouseView extends StatelessWidget {
  const MouseView({super.key});

  @override
  Widget build(BuildContext context) {
    // return ShaderSurface.builder(
    //   () {
    //     final sourceBuffer = 'shaders/mouse/IMouse Test.frag'.shaderBuffer;
    //     final overlayBuffer = 'shaders/keyboard/Keyboard Debug Overlay.frag'.shaderBuffer;
    //     // iChannel0 = 源着色器输出
    //     overlayBuffer.feedShader(sourceBuffer);
    //     // iChannel1 = 键盘输入
    //     overlayBuffer.feedKeyboard();

    //     return [sourceBuffer, overlayBuffer];
    //   },
    //   key: const ValueKey('mouse'),
    // );
    return ShaderSurface.builder(
      () {
        final sourceBuffer = 'shaders/mouse/Noise Lab (3D).frag'.shaderBuffer;
        final overlayBuffer = 'shaders/keyboard/Keyboard Debug Overlay.frag'.shaderBuffer;
        // iChannel0 = 源着色器输出
        overlayBuffer.feedShader(sourceBuffer);
        // iChannel1 = 键盘输入
        overlayBuffer.feedKeyboard();

        return [sourceBuffer, overlayBuffer];
      },
      key: const ValueKey('mouse'),
    );
  }
}
