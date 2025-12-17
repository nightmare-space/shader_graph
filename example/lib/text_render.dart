import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';

class TextRender extends StatelessWidget {
  const TextRender({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurfaceWrapper.builder(
      () {
        final mainBuffer = 'shaders/text/Text Texture.frag'.shaderBuffer;
        mainBuffer.feedImageFromAsset('assets/codepage12.png');
        return [mainBuffer];
      },
    );
  }
}
