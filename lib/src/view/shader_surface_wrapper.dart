import 'package:flutter/material.dart';
import 'package:shader_graph/src/extension/extension.dart';
import 'package:shader_graph/src/shader_buffer.dart';
import 'package:shader_graph/src/shader_graph.dart';
import 'package:shader_graph/src/view/shader_surface.dart';

/// 一个渲染着色器的 View，可以不用关系 ShaderGraph 的细节
/// The ShaderSurfaceWrapper that creates a ShaderGraph.
/// You don't need to care about the details of ShaderGraph.
class ShaderSurfaceWrapper extends StatefulWidget {
  /// 通过单个 ShaderBuffer 对象或者着色器的字符串路径创建一个渲染着色器的 View
  /// The ShaderSurfaceWrapper that creates a ShaderGraph from a single ShaderBuffer or a shader string path.
  factory ShaderSurfaceWrapper.buffer(
    dynamic buffer, {
    bool upSideDown = true,
    Key? key,
  }) {
    if (buffer is ShaderBuffer) {
      return ShaderSurfaceWrapper.buffers(
        [buffer..scale = 0.5],
        upSideDown: upSideDown,
        key: key,
      );
    } else if (buffer is String) {
      return ShaderSurfaceWrapper.buffers(
        [buffer.shaderBuffer..scale = 0.5],
        upSideDown: upSideDown,
        key: key,
      );
    } else {
      throw ArgumentError('buffer must be String or ShaderBuffer, got ${buffer.runtimeType}');
    }
  }

  /// 通过传入一个构建函数来创建一个渲染着色器的 View
  /// The ShaderSurfaceWrapper that creates a ShaderGraph from a builder function.
  factory ShaderSurfaceWrapper.builder(
    List<ShaderBuffer> Function() builder, {
    bool upSideDown = true,
    Key? key,
  }) {
    return ShaderSurfaceWrapper.buffers(
      builder(),
      upSideDown: upSideDown,
      key: key,
    );
  }

  /// 通过多个 ShaderBuffer 对象创建一个渲染着色器的 View
  /// The ShaderSurfaceWrapper that creates a ShaderGraph from multiple ShaderBuffers.
  const ShaderSurfaceWrapper.buffers(
    this.buffers, {
    this.upSideDown = true,
    super.key,
  });

  final List<ShaderBuffer> buffers;
  final bool upSideDown;

  @override
  State<ShaderSurfaceWrapper> createState() => _ShaderSurfaceWrapperState();
}

class _ShaderSurfaceWrapperState extends State<ShaderSurfaceWrapper> {
  late final Future<ShaderGraph> _graphFuture;
  ShaderGraph? _graph;

  @override
  void initState() {
    super.initState();
    _graphFuture = () async {
      final graph = ShaderGraph(widget.buffers);
      await graph.init();
      _graph = graph;
      return graph;
    }();
  }

  @override
  void dispose() {
    _graph?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder(
            future: _graphFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final graph = snapshot.data as ShaderGraph;
              return LayoutBuilder(builder: (context, constraints) {
                return SizedBox(
                  height: constraints.maxHeight,
                  width: constraints.maxWidth,
                  child: Transform.flip(
                    flipY: widget.upSideDown,
                    child: ShaderSurface(
                      graph: graph,
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}
