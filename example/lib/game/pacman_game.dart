import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shader_graph/shader_graph.dart';

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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          double width = constraints.maxWidth;
          double height = constraints.maxHeight;
          if (width < 400) {
            height = width * 0.75;
          }
          return SizedBox(
            width: width,
            height: height,
            child: ShaderSurfaceWrapper.builder(
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
          );
        }),
        Material(
          color: Colors.transparent,
          child: Column(
            children: [
              Row(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // left
                  InkWell(
                    onTapDown: (_) {
                      keyboardController.pressKey(37);
                    },
                    onTapUp: (_) {
                      keyboardController.releaseKey(37, 0);
                    },
                    onTapCancel: () {
                      keyboardController.releaseKey(37, 0);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.arrow_back,
                        size: 32,
                      ),
                    ),
                  ),
                  // up
                  InkWell(
                    onTapDown: (_) {
                      keyboardController.pressKey(38);
                    },
                    onTapUp: (_) {
                      keyboardController.releaseKey(38, 0);
                    },
                    onTapCancel: () {
                      keyboardController.releaseKey(38, 0);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 32,
                      ),
                    ),
                  ),
                  // down
                  InkWell(
                    onTapDown: (_) {
                      keyboardController.pressKey(40);
                    },
                    onTapUp: (_) {
                      keyboardController.releaseKey(40, 0);
                    },
                    onTapCancel: () {
                      keyboardController.releaseKey(40, 0);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.arrow_downward,
                        size: 32,
                      ),
                    ),
                  ),
                  // right
                  InkWell(
                    onTapDown: (_) {
                      keyboardController.pressKey(39);
                    },
                    onTapUp: (_) {
                      keyboardController.releaseKey(39, 0);
                    },
                    onTapCancel: () {
                      keyboardController.releaseKey(39, 0);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  keyboardController.pressKey(32);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    keyboardController.releaseKey(32, 0);
                  });
                },
                child: Text(
                  'Space',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
