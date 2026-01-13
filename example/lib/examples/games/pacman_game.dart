import 'dart:math';

import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:shader_graph/shader_graph.dart';

import 'bricks_game.dart';

// 不知道为什啥，之前这个游戏在 macOS 上跑是正常的
class PacmanGame extends StatefulWidget {
  const PacmanGame({super.key});

  @override
  State<PacmanGame> createState() => _PacmanGameState();
}

class _PacmanGameState extends State<PacmanGame> {
  KeyboardController keyboardController = KeyboardController();
  late final List<int> _order;

  @override
  void initState() {
    super.initState();
    _order = [0, 1, 2]..shuffle(Random(DateTime.now().microsecondsSinceEpoch));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        double height = constraints.maxHeight;
        final isNarrow = constraints.maxWidth < narrowWidthThreshold;
        if (isNarrow) {
          height = width * 0.75;
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: width,
              height: height,
              child: ShaderSurface.builder(
                () {
                  final bufferA = 'shaders/game_ported/Pacman Game BufferA.frag'.shaderBuffer;
                  final bufferB = 'shaders/game_ported/Pacman Game BufferB.frag'.shaderBuffer;
                  final mainBuffer = 'shaders/game_ported/Pacman Game.frag'.shaderBuffer;
                  bufferA.fixedOutputSize = const Size(32 * 4.0, 32);
                  bufferA.feedback().feedKeyboard();
                  bufferB.feedShader(bufferA);
                  mainBuffer.feedShader(bufferA).feedShader(bufferB);

                  final buffers = [bufferA, bufferB, mainBuffer];
                  return _order.map((i) => buffers[i]).toList(growable: false);
                },
                keyboardController: keyboardController,
              ),
            ),
            if (isNarrow)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: VirtualButtoon(keyboardController: keyboardController),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
