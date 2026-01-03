import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';

class KeyboardExample extends StatelessWidget {
  const KeyboardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurface.builder(
      () {
        final mainBuffer = 'shaders/keyboard/keyboard Test.frag'.shaderBuffer;
        mainBuffer.feedKeyboard();
        mainBuffer.feedImageFromAsset('assets/codepage12.png');

        final overlayBuffer = 'shaders/keyboard/Keyboard Debug Overlay.frag'.shaderBuffer;
        overlayBuffer.feedShader(mainBuffer);
        overlayBuffer.feedKeyboard();
        return [mainBuffer, overlayBuffer];
      },
    );
  }
}
