import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';

class BricksGame extends StatelessWidget {
  const BricksGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurfaceWrapper.builder(
      () {
        final bufferA = 'shaders/game_ported/Bricks Game BufferA.frag'.feedback().feedKeyboard();
        final mainBuffer = 'shaders/game_ported/Bricks Game.frag'.feedShaderBuffer(bufferA);
        // Standard scheme: physical width = virtual * 4
        bufferA.fixedOutputSize = const Size(14 * 4.0, 14);

        return [bufferA, mainBuffer];
      },
    );
  }
}
