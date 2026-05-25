import 'package:flutter/material.dart';
import 'package:shader_graph/shader_graph.dart';

import 'package:shader_graph_example/assets.dart';
import 'package:shader_graph_example/main.dart';

/// 这个游戏在 Android 上球的轨迹不正常，待研究，应该是 float 精度问题
///
/// This game has an issue with ball trajectory on Android, needs investigation, probably a float precision issue.
class BricksGame extends StatefulWidget {
  const BricksGame({super.key});

  @override
  State<BricksGame> createState() => _BricksGameState();
}

class _BricksGameState extends State<BricksGame> {
  KeyboardController keyboardController = KeyboardController();
  ShaderController shaderController = ShaderController();

  @override
  void initState() {
    super.initState();
    // For test
    // shaderController.pause();
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
                  final bufferA = Assets.bricksGameBufferA.shaderBuffer.feedback().feedKeyboard();
                  final mainBuffer = Assets.bricksGame.shaderBuffer.feed(bufferA);
                  // Standard scheme: physical width = virtual * 4
                  bufferA.fixedOutputSize = const Size(14 * 4.0, 14);

                  return [bufferA, mainBuffer];
                },
                keyboardController: keyboardController,
                shaderController: shaderController,
              ),
            ),
            if (isNarrow)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: VirtualButton(keyboardController: keyboardController),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class VirtualButton extends StatefulWidget {
  const VirtualButton({super.key, required this.keyboardController});
  final KeyboardController keyboardController;

  @override
  State<VirtualButton> createState() => _VirtualButtonState();
}

class _VirtualButtonState extends State<VirtualButton> {
  late KeyboardController keyboardController = widget.keyboardController;
  Material buildButton(int keyCode, {Widget? child}) {
    return Material(
      // withOpacity(0.15) but use withAlpha to avoid anti-aliasing issue
      color: Theme.of(context).colorScheme.primary.withAlpha(0x26),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 40,
        height: 40,
        child: InkWell(
          onTapDown: (_) {
            keyboardController.pressKey(keyCode);
          },
          onTapUp: (_) {
            keyboardController.releaseKey(keyCode, 0);
          },
          onTapCancel: () {
            keyboardController.releaseKey(keyCode, 0);
          },
          borderRadius: BorderRadius.circular(20),
          child: IconTheme(
            data: IconThemeData(color: Theme.of(context).colorScheme.primary),
            child: child ?? SizedBox(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Material(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 24,
          children: [
            Material(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  keyboardController.pressKey(32);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    keyboardController.releaseKey(32, 0);
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8.0),
                  child: Text(
                    'Space',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Container(
            //   width: 100,
            //   height: 20,
            //   color: Colors.red,
            // ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 4,
              children: [
                // up
                buildButton(38, child: const Icon(Icons.arrow_upward, size: 32)),
                Row(
                  spacing: 10,
                  children: [
                    // left
                    buildButton(37, child: const Icon(Icons.arrow_back, size: 32)),
                    // down
                    buildButton(40, child: const Icon(Icons.arrow_downward, size: 32)),
                    // right
                    buildButton(39, child: const Icon(Icons.arrow_forward, size: 32)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
