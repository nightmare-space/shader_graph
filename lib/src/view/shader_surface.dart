import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shader_graph/src/foundation/mouse.dart';
import 'package:shader_graph/src/shader_graph.dart';
import 'package:shader_graph/src/shader_input.dart';

import 'keyboard_controller.dart';
import 'shader_surface_render_object.dart';

/// 最终根据 ShaderGraph 渲染的 Widget。
/// 通常通过 ShaderSurfaceWrapper 创建。
/// ShaderSurface 负责管理时间、帧数、鼠标和键盘输入。
///
/// The ShaderSurface widget that renders a ShaderGraph.
/// Usually created via ShaderSurfaceWrapper.
/// ShaderSurface manages time, frame count, mouse and keyboard input.
class ShaderSurface extends StatefulWidget {
  const ShaderSurface({
    super.key,
    required this.graph,
    this.keyboardController,
  });

  final ShaderGraph graph;
  final KeyboardController? keyboardController;

  @override
  State<ShaderSurface> createState() => _ShaderSurfaceState();
}

class _ShaderSurfaceState extends State<ShaderSurface> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  RenderShaderSurface? _renderObject;
  final FocusNode _focusNode = FocusNode();
  late final KeyboardController keyboardController = widget.keyboardController ?? KeyboardController();

  /// 首帧已经渲染了
  /// Whether the first frame has been presented
  bool firstFramePresented = false;
  bool canTick = true;

  @override
  void reassemble() {
    super.reassemble();
    canTick = true;
  }

  @override
  void initState() {
    super.initState();
    // 遍历所有 buffer 的所有 input，给所有 KeyboardInput 设置 imageProvider
    // For each buffer, set imageProvider for all KeyboardInput
    for (final buffer in widget.graph.buffers) {
      for (final input in buffer.inputs) {
        if (input is KeyboardInput) {
          input.imageProvider = () => keyboardController.keyboardImage;
          keyboardController.hasKeyBoardInput = true;
        }
      }
    }
    _ticker = createTicker((elapsed) {
      // 这里之前踩了了一个坑，由于 toImageSync 在 3.38.5 上仍然内存泄露
      // 在 Mac 上，运行一会会吃掉所有的物理 Ram，然后吃完所有的 Swap，最终占用内存几乎是磁盘上限
      // 在我的测试中是 200Gb，所以改成了异步的 toImage()。但又不能让每一帧都触发更新
      // 所以 Ticker 只在新的一帧准备好了后再触发更新
      //
      // A previous pitfall: toImageSync still leaks memory in 3.38.5.
      // On Mac, after running for a while, it would consume all physical RAM,
      // then all swap space, eventually using up to nearly the disk limit (200GB in my test).
      // So I switched to the async toImage(). But we can't trigger updates every frame,
      // so the Ticker only triggers updates when a new frame is ready.
      // https://github.com/flutter/flutter/issues/138627
      _elapsed = elapsed;
      if (canTick) {
        _renderObject?.time = _elapsed.inMicroseconds / 1e6;
        // Schedule the next logical frame number for shaders.
        _renderObject?.iFrame = _renderObject!.iFrame + 1;
        canTick = false;
      }
    });
    _ticker.start();
    keyboardController.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFramePresented(int renderedIFrame) {
    if (!firstFramePresented) firstFramePresented = true;
    canTick = true;
    // Advance keyboard one-frame pulses exactly once per presented frame.
    keyboardController.pumpKeyboardFrame(renderedIFrame);
  }

  @override
  Widget build(BuildContext context) {
    // TODO 可以自定义鼠标按下后，是否保留位置
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          keyboardController.onKeyDown(event);
        } else if (event is KeyUpEvent) {
          keyboardController.onKeyUp(event, _renderObject!.iFrame);
        }
        return KeyEventResult.handled;
      },
      autofocus: true,
      child: Listener(
        onPointerMove: (event) {
          final localPos = (context.findRenderObject() as RenderBox).globalToLocal(event.position);
          _renderObject?.iMouse = _renderObject!.iMouse.copyWith(
            x: localPos.dx,
            y: localPos.dy,
          );
        },
        onPointerDown: (event) {
          _focusNode.requestFocus();
          final localPos = (context.findRenderObject() as RenderBox).globalToLocal(event.position);
          _renderObject?.iMouse = IMouse(localPos.dx, localPos.dy, localPos.dx, localPos.dy);
        },
        onPointerUp: (event) {
          final localPos = (context.findRenderObject() as RenderBox).globalToLocal(event.position);
          _renderObject?.iMouse = _renderObject!.iMouse.copyWith(
            x: localPos.dx,
            y: localPos.dy,
            z: 0.0,
            w: 0.0,
          );
        },
        onPointerCancel: (event) {
          _renderObject?.iMouse = _renderObject!.iMouse.copyWith(
            z: 0.0,
            w: 0.0,
          );
        },

        behavior: HitTestBehavior.translucent,
        // TODO: RepaintBoundary
        child: RepaintBoundary(
          child: ShaderSurfaceRenderObject(
            graph: widget.graph,
            dpr: MediaQuery.devicePixelRatioOf(context),
            onRenderObjectCreated: (ro) {
              _renderObject = ro;
              // Start at frame 0; subsequent frames advance only when a render completes.
              ro.iFrame = 0;
            },
            onFramePresented: _onFramePresented,
          ),
        ),
      ),
    );
  }
}
