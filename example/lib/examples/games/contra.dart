import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';
import 'package:shader_graph_example/assets.dart';

/// 没移植成功
/// Contra Game ported failed currently
class ContraGame extends StatelessWidget {
  const ContraGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurface.builder(
      () {
        final bufferA = Assets.contraBufferA.shaderBuffer;
        final bufferB = Assets.contraBufferB.shaderBuffer;
        final bufferC = Assets.contraBufferC.shaderBuffer;
        final bufferD = Assets.contraBufferD.shaderBuffer;
        final mainBuffer = Assets.contra.shaderBuffer;

        // Standard scheme: physical width = virtual * 4
        bufferA.fixedOutputSize = const Size(21 * 4.0, 6.0);
        bufferA.feedback().feedKeyboard();

        bufferB.feedShader(bufferA);
        bufferC.feedShader(bufferA).feedShader(bufferB);
        bufferD.feedShader(bufferA).feedShader(bufferC);
        mainBuffer.feedShader(bufferD);

        return [bufferA, bufferB, bufferC, bufferD, mainBuffer];
      },
    );
  }
}
