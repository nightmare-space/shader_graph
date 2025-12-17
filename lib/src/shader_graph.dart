// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:ui' as ui;
import 'package:shader_graph/src/foundation/render_data.dart';
import 'package:shader_graph/src/shader_buffer.dart';

class ShaderGraph {
  ShaderGraph(this.buffers);

  final List<ShaderBuffer> buffers;
  late final List<ShaderBuffer> _orderedBuffers;
  void _buildExecutionOrder() {
    final visited = <ShaderBuffer>{};
    final visiting = <ShaderBuffer>{};
    final result = <ShaderBuffer>[];
    bool hasCycle = false;

    void visit(ShaderBuffer node) {
      if (visited.contains(node)) return;

      if (visiting.contains(node)) {
        hasCycle = true;
        return;
      }

      visiting.add(node);

      // 递归访问非自身的依赖
      for (final dep in node.dependencies) {
        if (dep != node) {
          visit(dep);
        }
      }

      visiting.remove(node);
      visited.add(node);
      result.add(node);
    }

    // 尝试拓扑排序
    for (final node in buffers) {
      visit(node);
    }

    // 如果有循环依赖，直接使用 buffers 列表的原始顺序
    if (hasCycle) {
      print('⚠️ Cycle detected! Using buffers list order instead of topological sort');
      _orderedBuffers = buffers;
    } else {
      _orderedBuffers = result;
    }

    print('\n📋 Final Execution Order:');
    for (int i = 0; i < _orderedBuffers.length; i++) {
      print('  $i: ${_orderedBuffers[i].shaderAssetPath}');
    }
  }

  Future<void> init() async {
    for (final node in buffers) {
      await node.init();
    }

    _buildExecutionOrder();
  }

  Future<ui.Image?> renderFrame({required RenderData data}) async {
    // --- 关键点：反馈语义（Shadertoy 风格） ---
    // 任意标记为 `usePreviousFrame` 的输入必须采样上一帧的输出。
    // 如果我们在每个节点的 render() 结束时推进 prevOutput，那么在
    // 单个帧内其他节点仍将看到更早的 prevOutput，使得反馈实际上变成“延迟两帧”且依赖渲染顺序。
    // 这种不稳定性会积累并表现为状态分歧/分裂。
    // 解决方法：在帧开始时对所有缓冲区推进反馈一次，
    // --- CRITICAL: feedback semantics (Shadertoy-style) ---
    // Any input marked `usePreviousFrame` must sample the *last frame*'s output.
    // If we advance prevOutput at the end of each node's render(), then within
    // a single frame other nodes will still see an older prevOutput, making
    // feedback become effectively “two-frame delayed” and render-order dependent.
    // That instability can accumulate and manifest as state divergence/splitting.
    //
    // Fix: advance feedback for ALL buffers once at the start of the frame,
    // before resolving any shader inputs.
    for (final node in _orderedBuffers) {
      node.beginFrame();
    }
    for (final node in _orderedBuffers) {
      await node.render(data: data);
    }

    return mainNode.output ?? mainNode.prevOutput;
  }

  void renderFrameSync({required RenderData data}) {
    // Same as renderFrame(): keep usePreviousFrame stable & order-independent.
    for (final node in _orderedBuffers) {
      node.beginFrame();
    }
    for (final node in _orderedBuffers) {
      node.renderSync(data: data);
    }
  }

  ShaderBuffer get mainNode => _orderedBuffers.last;

  void dispose() {
    for (final node in buffers) {
      node.dispose();
    }
  }
}
