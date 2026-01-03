import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';

class IframeExample extends StatelessWidget {
  const IframeExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurface.builder(
      () {
        final sourceBuffer = 'shaders/frame/IFrame Test.frag'.shaderBuffer;
        final overlayBuffer = 'shaders/keyboard/Keyboard Debug Overlay.frag'.shaderBuffer;
        // iFrame
        // TODO: Macos haven't progress display, but Android can
        overlayBuffer.feed(sourceBuffer);
        overlayBuffer.feedKeyboard();
        return [sourceBuffer, overlayBuffer];
      },
      key: const ValueKey('iframe'),
    );
  }
}
