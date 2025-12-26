part of 'package:shader_graph/shader_graph.dart';

/// 最终根据 ShaderGraph 渲染的 Widget。
/// ShaderSurface 负责管理时间、帧数、鼠标和键盘输入。
///
/// The ShaderSurface widget that renders a ShaderGraph.
/// Usually created via ShaderSurfaceWrapper.
/// ShaderSurface manages time, frame count, mouse and keyboard input.
class ShaderSurface extends StatefulWidget {
  const ShaderSurface({
    required this.graph,
    this.keyboardController,
    this.upSideDown = true,
    super.key,
  });

  factory ShaderSurface.buffers(
    List<ShaderBuffer> buffers, {
    bool upSideDown = true,
    Key? key,
    KeyboardController? keyboardController,
  }) {
    final graph = ShaderGraph(buffers);
    return ShaderSurface(
      graph: graph,
      upSideDown: upSideDown,
      keyboardController: keyboardController,
      key: key,
    );
  }

  /// 支持传入 frag 的资源路径，ShaderBuffer 对象，或者 ShaderBuffer 列表
  /// 不用关心 ShaderGraph 的细节
  /// Support passing in a frag asset path, ShaderBuffer object, or a list of ShaderBuffer
  /// without caring about the details of ShaderGraph
  factory ShaderSurface.auto(
    dynamic param, {
    Key? key,
    KeyboardController? keyboardController,
    bool upSideDown = true,
  }) {
    switch (param) {
      case ShaderBuffer buffer:
        return ShaderSurface.buffers(
          [buffer],
          key: key,
          upSideDown: upSideDown,
          keyboardController: keyboardController,
        );
      case List<ShaderBuffer> buffers:
        return ShaderSurface.buffers(
          buffers,
          key: key,
          upSideDown: upSideDown,
          keyboardController: keyboardController,
        );
      // ignore: pattern_never_matches_value_type
      case String assetPath:
        return ShaderSurface.buffers(
          [assetPath.shaderBuffer],
          key: key,
          upSideDown: upSideDown,
          keyboardController: keyboardController,
        );
      default:
        throw ArgumentError('buffer must be String or ShaderBuffer or List<ShaderBuffer>, got ${param.runtimeType}');
    }
  }

  /// See also [ShaderSurface.auto] which supports a builder function.
  factory ShaderSurface.builder(
    dynamic Function() builder, {
    Key? key,
    KeyboardController? keyboardController,
    bool upSideDown = true,
  }) {
    final param = builder();
    return ShaderSurface.auto(
      param,
      upSideDown: upSideDown,
      key: key,
      keyboardController: keyboardController,
    );
  }

  final ShaderGraph graph;
  final KeyboardController? keyboardController;

  /// Flutter 的坐标系是左上角为原点，Y 轴向下递增，展示的着色器会上下颠倒
  /// 所以默认翻转回来，但一些特殊的着色器是不需要翻转的
  /// Flutter's coordinate system has the origin at the top-left corner, with the Y-axis increasing downwards,
  /// which causes the displayed shader to be upside down.
  /// Therefore, it is flipped back by default, but some special shaders do not require flipping
  final bool upSideDown;

  @override
  State<ShaderSurface> createState() => _ShaderSurfaceState();
}

class _ShaderSurfaceState extends State<ShaderSurface> with SingleTickerProviderStateMixin {
  late final Future<ShaderGraph> _graphFuture;
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
    BackdropFilterLayer a;
    _graphFuture = () async {
      await widget.graph.init();
      return widget.graph;
    }();
    // 遍历所有 buffer 的所有 input，给所有 KeyboardInput 设置 imageProvider
    // For each buffer, set imageProvider for all KeyboardInput
    for (final buffer in widget.graph._buffers) {
      for (final input in buffer._inputs) {
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
    widget.graph.dispose();
    keyboardController.dispose();
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
    return FutureBuilder(
      future: _graphFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // TODO: Support custom loading widget
          return const Center(child: CircularProgressIndicator());
        }
        return LayoutBuilder(builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: Transform.flip(
              flipY: widget.upSideDown,
              child: buildFocusView(),
            ),
          );
        });
      },
    );
  }

  Focus buildFocusView() {
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
      child: Builder(builder: (innerContext) {
        RenderBox box() => innerContext.findRenderObject() as RenderBox;
        return Listener(
          onPointerMove: (event) {
            final localPos = box().globalToLocal(event.position);
            final ro = _renderObject;
            if (ro == null) return;
            ro.iMouse = ro.iMouse.copyWith(x: localPos.dx, y: localPos.dy);
          },
          onPointerDown: (event) {
            _focusNode.requestFocus();
            final localPos = box().globalToLocal(event.position);
            _renderObject?.iMouse = IMouse(localPos.dx, localPos.dy, localPos.dx, localPos.dy);
          },
          onPointerUp: (event) {
            final localPos = box().globalToLocal(event.position);
            final ro = _renderObject;
            if (ro == null) return;
            ro.iMouse = ro.iMouse.copyWith(
              x: localPos.dx,
              y: localPos.dy,
              z: 0.0,
              w: 0.0,
            );
          },
          behavior: HitTestBehavior.translucent,
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
        );
      }),
    );
  }
}
