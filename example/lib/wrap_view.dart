import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shader_graph/shader_graph.dart';

class WrapView extends StatelessWidget {
  const WrapView({super.key});

  static const String _shader = 'shaders/wrap/Wrap Debug.frag';
  static const String _texture = 'assets/Rock Tiles.jpg';

  @override
  Widget build(BuildContext context) {
    final clamp = _shader.shaderBuffer..feedImageFromAsset(_texture, wrap: WrapMode.clamp);

    final repeat = _shader.shaderBuffer..feedImageFromAsset(_texture, wrap: WrapMode.repeat);

    final mirror = _shader.shaderBuffer..feedImageFromAsset(_texture, wrap: WrapMode.mirror);

    Widget panel(String title, ShaderBuffer buffer) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x22000000)),
                ),
                child: ShaderSurface.auto(buffer, upSideDown: true),
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          if (isNarrow) {
            return Column(
              spacing: 8,
              children: [
                panel('Clamp (default)', clamp),
                panel('Repeat', repeat),
              ],
            );
          }
          return Row(
            spacing: 8,
            children: [
              panel('Clamp (default)', clamp),
              panel('Repeat', repeat),
              panel('Mirror', mirror),
            ],
          );
        },
      ),
    );
  }
}
