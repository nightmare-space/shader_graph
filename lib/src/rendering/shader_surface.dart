part of 'package:shader_graph/shader_graph.dart';

/// 最终根据 ShaderGraph 渲染的 Widget。
/// ShaderSurface 负责管理时间、帧数、鼠标和键盘输入。
///
/// The ShaderSurface widget that renders a ShaderGraph.
/// Usually created via ShaderSurfaceWrapper.
/// ShaderSurface manages time, frame count, mouse and keyboard input.
class ShaderSurface extends StatefulWidget {
  const ShaderSurface({
    required this.buffers,
    this.keyboardController,
    this.shaderController,
    // TODO: Support setting every input's upSideDown individually, use flipY.
    this.upSideDown = true,
    super.key,
  });

  /// Creates a [ShaderSurface] from a list of pre-built [ShaderBuffer]s.
  ///
  /// This is the most flexible way to create a shader surface, suitable for
  /// complex multi-pass rendering pipelines where you need explicit control
  /// over buffer dependencies and execution order.
  ///
  /// The framework automatically performs topological sorting on the buffers
  /// to ensure they execute in the correct order based on their dependencies.
  /// The last buffer in the list will be used as the final output.
  ///
  /// ## Parameters
  ///
  /// * `buffers` - The list of shader buffers to render. The last buffer will be
  ///   used as the final output. Buffers are automatically topologically sorted
  ///   based on their dependencies.
  /// * `upSideDown` - Whether to flip the Y-axis. Defaults to `true` because
  ///   Flutter's coordinate system (Y-down) differs from OpenGL/Shadertoy (Y-up).
  /// * `keyboardController` - An optional [KeyboardController] for handling
  ///   keyboard input in shaders. If provided, shaders can sample keyboard state
  ///   through `iChannel` uniforms.
  /// * `key` - The widget's [Key], used to control how one widget replaces
  ///   another widget in the tree.
  /// {@tool snippet}
  ///
  /// **Simple multi-pass example:**
  ///
  /// ```dart
  /// // Create three dependent shader buffers
  /// final bufferA = 'shaders/BufferA.frag'.shaderBuffer.feedback();
  /// final bufferB = 'shaders/BufferB.frag'.shaderBuffer.feed(bufferA);
  /// final mainBuffer = 'shaders/Main.frag'.shaderBuffer
  ///   .feed(bufferA)
  ///   .feed(bufferB);
  ///
  /// // Create the surface with explicit buffer order
  /// return ShaderSurface.buffers(
  ///   [bufferA, bufferB, mainBuffer],
  ///   upSideDown: true,
  /// );
  /// ```
  /// {@end-tool}
  ///
  /// {@tool snippet}
  /// **Game example with keyboard input:**
  ///
  /// ```dart
  /// class GameScreen extends StatelessWidget {
  ///   const GameScreen({super.key});
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final bufferA = 'shaders/game/BufferA.frag'
  ///         .shaderBuffer
  ///         .feedback()
  ///         .feedKeyboard();
  ///     bufferA.fixedOutputSize = const Size(128, 128);
  ///
  ///     final mainBuffer = 'shaders/game/Main.frag'
  ///         .shaderBuffer
  ///         .feed(bufferA);
  ///
  ///     return Scaffold(
  ///       body: ShaderSurface.buffers(
  ///         [bufferA, mainBuffer],
  ///         keyboardController: KeyboardController(),
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// {@template shader_graph.buffers_comparison}
  /// Compared to other factory constructors:
  /// - [ShaderSurface.auto]: Automatically infers the type from the parameter
  /// - [ShaderSurface.builder]: Builds buffers lazily through a callback
  /// - [ShaderSurface.buffers]: Takes pre-built buffers directly
  /// {@endtemplate}
  factory ShaderSurface.buffers(
    List<ShaderBuffer> buffers, {
    bool upSideDown = true,
    Key? key,
    KeyboardController? keyboardController,
  }) {
    return ShaderSurface(
      buffers: buffers,
      upSideDown: upSideDown,
      keyboardController: keyboardController,
      key: key,
    );
  }

  /// 支持传入 frag 的资源路径，ShaderBuffer 对象，或者 ShaderBuffer 列表
  /// 不用关心 ShaderGraph 的细节
  ///
  /// Support passing in a frag asset path, ShaderBuffer object, or a list of ShaderBuffer
  /// without caring about the details of ShaderGraph
  /// {@macro shader_graph.buffers_comparison}
  factory ShaderSurface.auto(
    dynamic param, {
    Key? key,
    KeyboardController? keyboardController,
    ShaderController? shaderController,
    bool upSideDown = true,
  }) {
    switch (param) {
      case ShaderBuffer buffer:
        return ShaderSurface(
          buffers: [buffer],
          key: key,
          upSideDown: upSideDown,
          keyboardController: keyboardController,
          shaderController: shaderController,
        );
      case List<ShaderBuffer> buffers:
        return ShaderSurface(
          buffers: buffers,
          key: key,
          upSideDown: upSideDown,
          keyboardController: keyboardController,
          shaderController: shaderController,
        );
      // ignore: pattern_never_matches_value_type
      case String assetPath:
        return ShaderSurface(
          buffers: [assetPath.shaderBuffer],
          key: key,
          upSideDown: upSideDown,
          keyboardController: keyboardController,
          shaderController: shaderController,
        );
      default:
        throw ArgumentError('buffer must be String or ShaderBuffer or List<ShaderBuffer>, got ${param.runtimeType}');
    }
  }

  /// {@macro shader_graph.buffers_comparison}
  factory ShaderSurface.builder(
    List<ShaderBuffer> Function() builder, {
    Key? key,
    KeyboardController? keyboardController,
    ShaderController? shaderController,
    bool upSideDown = true,
  }) {
    final param = builder();
    return ShaderSurface(
      buffers: param,
      key: key,
      upSideDown: upSideDown,
      keyboardController: keyboardController,
      shaderController: shaderController,
    );
  }

  /// TODO:
  /// 我没有考虑好要不要由外部创建 ShaderGraph
  /// I have not decided whether to let the outside create ShaderGraph
  /// final ShaderGraph? shaderGraph;

  final List<ShaderBuffer> buffers;

  /// 用来管理键盘输入状态的控制器。
  ///
  /// Provides keyboard input state for shaders.
  final KeyboardController? keyboardController;

  /// 用来管理着色器动画的播放状态。
  ///
  /// Provides simple play/pause functionality for shader animations.
  final ShaderController? shaderController;

  /// Flutter 的坐标系是左上角为原点，Y 轴向下递增，展示的着色器会上下颠倒
  /// 所以默认翻转回来，但一些特殊的着色器是不需要翻转的
  /// TODO: 还需要针对整个 Widget 翻转吗，用 awesome_flutter_shaders 来测试一下
  /// Flutter's coordinate system has the origin at the top-left corner, with the Y-axis increasing downwards,
  /// which causes the displayed shader to be upside down.
  /// Therefore, it is flipped back by default, but some special shaders do not require flipping
  final bool upSideDown;

  @override
  State<ShaderSurface> createState() => _ShaderSurfaceState();
}

class _ShaderSurfaceState extends State<ShaderSurface> with SingleTickerProviderStateMixin {
  late final Future<ShaderGraph> _graphFuture = initGraph();
  late final Ticker _ticker;
  late ShaderGraph graph = ShaderGraph(widget.buffers);
  RenderShaderSurface? _renderObject;
  final FocusNode _focusNode = FocusNode();
  Duration _elapsed = Duration.zero;
  late final KeyboardController keyboardController = widget.keyboardController ?? KeyboardController();
  late final ShaderController shaderController = widget.shaderController ?? ShaderController();

  // 首帧已经渲染了
  // Whether the first frame has been presented
  bool firstFramePresented = false;

  // 是否可以触发下一次 tick
  // Whether the next tick can be triggered
  bool canTick = true;
  List<WidgetInput> get widgetInputs {
    final inputs = <WidgetInput>[];
    for (final buffer in graph._buffers) {
      for (final input in buffer._inputs) {
        if (input is WidgetInput) {
          inputs.add(input);
        }
      }
    }
    return inputs;
  }

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
    for (final buffer in graph._buffers) {
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
      if (canTick && !shaderController.isPaused) {
        _renderObject?.time = _elapsed.inMicroseconds / 1e6;
        // Schedule the next logical frame number for shaders.
        _renderObject?.iFrame = (_renderObject?.iFrame ?? 0) + 1;
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
    graph.dispose();
    keyboardController.dispose();
    super.dispose();
  }

  void _onFramePresented(int renderedIFrame) {
    // log('Frame $renderedIFrame presented');
    if (!firstFramePresented) firstFramePresented = true;
    canTick = true;
    // Advance keyboard one-frame pulses exactly once per presented frame.
    keyboardController.pumpKeyboardFrame(renderedIFrame);
  }

  Future<ShaderGraph> initGraph() async {
    await graph.init();
    return graph;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Support retaining last mouse position
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
          keyboardController.onKeyUp(event, _renderObject?.iFrame ?? 0);
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
            ro?.iMouse = ro.iMouse.copyWith(x: localPos.dx, y: localPos.dy);
          },
          onPointerDown: (event) {
            _focusNode.requestFocus();
            final localPos = box().globalToLocal(event.position);
            _renderObject?.iMouse = IMouse(localPos.dx, localPos.dy, localPos.dx, localPos.dy);
          },
          onPointerUp: (event) {
            final localPos = box().globalToLocal(event.position);
            final ro = _renderObject;
            ro?.iMouse = ro.iMouse.copyWith(
              x: localPos.dx,
              y: localPos.dy,
              z: 0.0,
              w: 0.0,
            );
          },
          behavior: HitTestBehavior.translucent,
          child: RepaintBoundary(
            child: ShaderSurfaceRenderObject(
              graph: graph,
              dpr: MediaQuery.devicePixelRatioOf(context),
              onRenderObjectCreated: (ro) {
                _renderObject = ro;
                // Start at frame 0; subsequent frames advance only when a render completes.
                ro.iFrame = 0;
              },
              onFramePresented: _onFramePresented,
              children: [
                for (final input in widgetInputs)
                  SnapshotSampler(
                    (image, size, canvas) {
                      // SnapshotSampler disposes `image` after the callback.
                      // Clone so ShaderGraph can keep and sample it later in the frame.
                      input.lastImage = image.clone();
                    },
                    child: SizedBox.expand(child: input.widget),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
