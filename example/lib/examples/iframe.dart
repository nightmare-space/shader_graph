import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';
import 'package:shader_graph_example/assets.dart';

class IframeExample extends StatelessWidget {
  const IframeExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurface.builder(
      () {
        final sourceBuffer = Assets.iFrameTestShader.shaderBuffer;
        final overlayBuffer = Assets.keyboardDebugOverlay.shaderBuffer;
        overlayBuffer.feed(sourceBuffer);
        overlayBuffer.feedKeyboard();
        return [sourceBuffer, overlayBuffer];
      },
      key: const ValueKey('iframe'),
    );
  }
}
