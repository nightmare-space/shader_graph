import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';

class MouseExample extends StatelessWidget {
  const MouseExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurface.builder(
      () {
        final sourceBuffer = 'shaders/mouse/Noise Lab (3D).frag'.shaderBuffer;
        final overlayBuffer = 'shaders/keyboard/Keyboard Debug Overlay.frag'.shaderBuffer;
        overlayBuffer.feedShader(sourceBuffer);
        overlayBuffer.feedKeyboard();
        return [sourceBuffer, overlayBuffer];
      },
      key: const ValueKey('mouse'),
    );
  }
}
