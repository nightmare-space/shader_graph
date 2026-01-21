import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shader_graph/shader_graph.dart';

class AnimationControlExample extends StatefulWidget {
  const AnimationControlExample({super.key});

  @override
  State<AnimationControlExample> createState() => _AnimationControlExampleState();
}

class _AnimationControlExampleState extends State<AnimationControlExample> {
  late final ShaderController controller;

  @override
  void initState() {
    super.initState();
    controller = ShaderController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ShaderSurface.auto(
              'shaders/frame/IFrame Test.frag',
              shaderController: controller,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            controller.toggle();
          });
        },
        child: Icon(
          controller.isPaused ? CupertinoIcons.play_fill : CupertinoIcons.pause_fill,
        ),
      ),
    );
  }
}
