part of 'package:shader_graph/shader_graph.dart';

class ShaderSurfaceRenderObject extends MultiChildRenderObjectWidget {
  const ShaderSurfaceRenderObject({
    super.key,
    required this.graph,
    required this.dpr,
    this.onRenderObjectCreated,
    this.onFramePresented,
    super.children,
  });

  final ShaderGraph graph;
  final double dpr;
  final void Function(RenderShaderSurface renderObject)? onRenderObjectCreated;
  final void Function(int renderedIFrame)? onFramePresented;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final ro = RenderShaderSurface(graph: graph, dpr: dpr, onFramePresented: onFramePresented);
    onRenderObjectCreated?.call(ro);
    return ro;
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderShaderSurface renderObject) {
    renderObject.devicePixelRatio = dpr;
    renderObject.onFramePresented = onFramePresented;
    renderObject.graph = graph;
  }
}

class _ShaderSurfaceParentData extends ContainerBoxParentData<RenderBox> {}

abstract class _ShaderSurfaceBase extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ShaderSurfaceParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ShaderSurfaceParentData> {}

class RenderShaderSurface extends _ShaderSurfaceBase {
  RenderShaderSurface({
    required ShaderGraph graph,
    required double dpr,
    void Function(int renderedIFrame)? onFramePresented,
  })  : _graph = graph,
        _devicePixelRatio = dpr,
        _onFramePresented = onFramePresented;

  ShaderGraph _graph;

  set graph(ShaderGraph v) {
    if (_graph == v) return;
    _graph = v;
    markNeedsCompositedLayerUpdate();
  }

  double _time = 0.0;
  int _iFrame = 0;
  double _devicePixelRatio;
  IMouse _iMouse = IMouse(0.0, 0.0, -1.0, -1.0);
  void Function(int renderedIFrame)? _onFramePresented;

  set onFramePresented(void Function(int renderedIFrame)? v) {
    _onFramePresented = v;
    markNeedsCompositedLayerUpdate();
  }

  set iMouse(IMouse v) {
    _iMouse = v;
    markNeedsCompositedLayerUpdate();
  }

  IMouse get iMouse => _iMouse;

  set time(double v) {
    if (_time == v) return;
    _time = v;
    markNeedsCompositedLayerUpdate();
  }

  set iFrame(int v) {
    if (_iFrame == v) return;
    _iFrame = v;
    markNeedsCompositedLayerUpdate();
  }

  int get iFrame => _iFrame;

  set devicePixelRatio(double v) {
    if (_devicePixelRatio == v) return;
    _devicePixelRatio = v;
    markNeedsCompositedLayerUpdate();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ShaderSurfaceParentData) {
      child.parentData = _ShaderSurfaceParentData();
    }
  }

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    if (!size.isFinite) {
      size = constraints.constrain(Size.zero);
    }

    final childConstraints = BoxConstraints.tight(size);
    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: false);
      final childParentData = child.parentData! as _ShaderSurfaceParentData;
      childParentData.offset = Offset.zero;
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  ShaderSurfaceLayer updateCompositedLayer({required covariant ShaderSurfaceLayer? oldLayer}) {
    return (oldLayer ?? ShaderSurfaceLayer(_graph))
      ..size = size
      ..iFrame = _iFrame
      ..time = _time
      ..devicePixelRatio = _devicePixelRatio
      ..iMouse = _iMouse
      ..onFramePresented = _onFramePresented;
  }
}

class ShaderSurfaceLayer extends OffsetLayer {
  ShaderSurfaceLayer(this.graph);

  final ShaderGraph graph;

  // 使用 Impeller 渲染，开启同步不会内存泄露，Skia 则会。
  // Using Impeller for rendering, enabling sync won't leak memory, Skia will.
  final bool _useSyncRender = false;
  Size _size = Size.zero;
  double _devicePixelRatio = 1.0;
  double _time = 0.0;
  int _iFrame = 0;
  bool _rendering = false;
  IMouse _iMouse = IMouse(0.0, 0.0, -1.0, -1.0);
  void Function(int renderedIFrame)? onFramePresented;

  set iMouse(IMouse v) {
    _iMouse = v;
    markNeedsAddToScene();
  }

  set size(Size v) {
    if (_size == v) return;
    _size = v;
    markNeedsAddToScene();
  }

  set devicePixelRatio(double v) {
    if (_devicePixelRatio == v) return;
    _devicePixelRatio = v;
    markNeedsAddToScene();
  }

  set time(double v) {
    _time = v;
    markNeedsAddToScene();
  }

  set iFrame(int v) {
    _iFrame = v;
    markNeedsAddToScene();
  }

  @override
  void dispose() {
    _lastPicture?.dispose();
    super.dispose();
  }

  // OffsetLayer.addToScene() ≠ 立即渲染
  // OffsetLayer.addToScene() ≠ immediate render
  @override
  void addToScene(ui.SceneBuilder builder) {
    if (_size.isEmpty) {
      return;
    }

    // Ensure child layers (e.g. SnapshotSampler) are added first so they can
    // capture their images before the shader graph renders.
    addChildrenToScene(builder);

    final img = graph.mainNode._output ?? graph.mainNode._prevOutput;

    if (!_rendering) {
      _rendering = true;
      final size = _size;
      final time = _time;
      final dpr = _devicePixelRatio;
      final iFrame = _iFrame;
      final iMouse = _iMouse;
      RenderData data = RenderData(
        logicalSize: size,
        dpr: dpr,
        iFrame: iFrame.toDouble(),
        time: time,
        devicePixelRatio: dpr,
        iMouse: iMouse,
      );

      if (_useSyncRender) {
        graph._renderFrameSync(data: data);
        _rendering = false;
        onFramePresented?.call(iFrame.toInt());
      } else {
        graph._renderFrame(data: data).catchError((e, st) {
          // Keep the scheduler alive, but do log the error so callers can
          // diagnose blank frames on specific backends.
          debugPrint('ShaderGraph render error: $e');
          debugPrint('$st');
          return null;
        }).whenComplete(() {
          _rendering = false;
          // Release the next tick even if this render produced no image.
          onFramePresented?.call(iFrame.toInt());
        });
      }
    }

    if (img == null) {
      return;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    Paint paint = Paint();
    paint.filterQuality = FilterQuality.none;
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(0, 0, _size.width, _size.height),
      paint,
    );

    final picture = recorder.endRecording();
    _lastPicture = picture;
    builder.addPicture(offset, picture);
  }

  ui.Picture? _lastPicture;
}
