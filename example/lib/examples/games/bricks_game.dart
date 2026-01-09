import 'package:flutter/material.dart';
import 'package:shader_graph/shader_graph.dart';

class BricksGame extends StatefulWidget {
  const BricksGame({super.key});

  @override
  State<BricksGame> createState() => _BricksGameState();
}

class _BricksGameState extends State<BricksGame> {
  KeyboardController keyboardController = KeyboardController();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, con) {
      bool needVirtualKeyboard = con.maxWidth < 400;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              double width = constraints.maxWidth;
              double height = constraints.maxHeight;
              if (width < 400) {
                height = width * 0.75;
              }
              return SizedBox(
                width: width,
                height: height,
                child: ShaderSurface.builder(
                  () {
                    final bufferA = 'shaders/game_ported/Bricks Game BufferA.frag'.feedback().feedKeyboard();
                    final mainBuffer = 'shaders/game_ported/Bricks Game.frag'.feed(bufferA);
                    // Standard scheme: physical width = virtual * 4
                    bufferA.fixedOutputSize = const Size(14 * 4.0, 14);

                    return [bufferA, mainBuffer];
                  },
                  keyboardController: keyboardController,
                ),
              );
            }),
          ),
          if (needVirtualKeyboard)
            SizedBox(
              child: Material(
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
            ),
        ],
      );
    });
  }
}
