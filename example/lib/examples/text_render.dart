import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';
import 'package:shader_graph_example/assets.dart';

class TextRenderExample extends StatelessWidget {
  const TextRenderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurface.builder(
      () {
        final mainBuffer = Assets.textTexture.shaderBuffer;
        mainBuffer.feedImage(AssetImage(Assets.codepage12));
        return [mainBuffer];
      },
    );
  }
}
