import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';

class TextRenderExample extends StatelessWidget {
  const TextRenderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurface.builder(
      () {
        final mainBuffer = 'shaders/text/Text Texture.frag'.shaderBuffer;
        mainBuffer.feedImageFromAsset('assets/codepage12.png');
        return [mainBuffer];
      },
    );
  }
}
