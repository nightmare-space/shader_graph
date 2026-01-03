import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';

class MultiPassExample extends StatelessWidget {
  const MultiPassExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurface.builder(
      () {
        final mainBuffer = 'shaders/multi_pass/MacOS Monterey wallpaper.frag'.shaderBuffer;
        final bufferA = 'shaders/multi_pass/MacOS Monterey wallpaper BufferA.frag'.shaderBuffer;
        mainBuffer.feedShader(bufferA);
        return [mainBuffer, bufferA];
      },
    );
  }
}
