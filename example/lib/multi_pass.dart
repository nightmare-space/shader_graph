import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';

class MacWallpaperView extends StatelessWidget {
  const MacWallpaperView({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderSurfaceWrapper.builder(
      () {
        final mainBuffer = 'shaders/multi_pass/MacOS Monterey wallpaper.frag'.shaderBuffer;
        final bufferA = 'shaders/multi_pass/MacOS Monterey wallpaper BufferA.frag'.shaderBuffer;
        mainBuffer.feedShader(bufferA);
        // 这里可以自动拓扑排序，无需手动指定顺序
        // Here the topological sorting can be done automatically, no need to specify the order manually
        return [mainBuffer, bufferA];
      },
    );
  }
}
