import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';

class ContraGame extends StatelessWidget {
  const ContraGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurfaceWrapper.builder(
      () {
        final bufferA = 'shaders/game_ported/Contra BufferA.frag'.shaderBuffer;
        final bufferB = 'shaders/game_ported/Contra BufferB.frag'.shaderBuffer;
        final bufferC = 'shaders/game_ported/Contra BufferC.frag'.shaderBuffer;
        final bufferD = 'shaders/game_ported/Contra BufferD.frag'.shaderBuffer;
        final mainBuffer = 'shaders/game_ported/Contra.frag'.shaderBuffer;

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
