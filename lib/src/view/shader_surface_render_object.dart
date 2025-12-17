import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shader_graph/shader_graph.dart';
import 'package:shader_graph/src/foundation/mouse.dart';
import 'package:shader_graph/src/foundation/render_data.dart';

class ShaderSurfaceRenderObject extends LeafRenderObjectWidget {
  const ShaderSurfaceRenderObject({
    super.key,
    required this.graph,
    required this.dpr,
    this.onRenderObjectCreated,
    this.onFramePresented,
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
  }
}

class RenderShaderSurface extends RenderBox {
  RenderShaderSurface({
    required ShaderGraph graph,
    required double dpr,
    void Function(int renderedIFrame)? onFramePresented,
  })  : _graph = graph,
        _devicePixelRatio = dpr,
        _onFramePresented = onFramePresented;

  final ShaderGraph _graph;
  double _time = 0.0;
  int _iFrame = 0;
  double _devicePixelRatio;
  IMouse _iMouse = IMouse(0.0, 0.0, 0.0, 0.0);
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
  void performLayout() {
    if (constraints.biggest.isInfinite) {
      size = Size.zero;
      return;
    }
    size = constraints.biggest;
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

  // 测试代码
  // This flag is for testing purposes only
  final bool _useSyncRender = false;
  Size _size = Size.zero;
  double _devicePixelRatio = 1.0;
  double _time = 0.0;
  int _iFrame = 0;
  bool _rendering = false;
  IMouse _iMouse = IMouse(0.0, 0.0, 0.0, 0.0);
  ui.Image? _lastImage;
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

  // OffsetLayer.addToScene() ≠ 立即渲染
  @override
  void addToScene(ui.SceneBuilder builder) {
    if (_size.isEmpty) return;

    final img = graph.mainNode.output ?? graph.mainNode.prevOutput;

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
        graph.renderFrameSync(data: data);
        _rendering = false;
        onFramePresented?.call(iFrame.toInt());
      } else {
        graph.renderFrame(data: data).catchError((_) {
          // Swallow render errors here so we can keep the scheduler alive.
          // The last frame (if any) will remain on screen.
          return null;
        }).whenComplete(() {
          _rendering = false;
          // Release the next tick even if this render produced no image.
          onFramePresented?.call(iFrame.toInt());
        });
      }
    }

    // If the image isn't ready yet, keep drawing the last frame to avoid flicker.
    if (img == null) {
      final last = _lastPicture;
      if (last != null) {
        builder.addPicture(offset, last);
      }
      return;
    }

    // If the image hasn't changed, reuse the last recorded picture.
    if (identical(img, _lastImage)) {
      final last = _lastPicture;
      if (last != null) {
        builder.addPicture(offset, last);
        return;
      }
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    Paint paint = Paint();
    // TODO: 要不要设置 filterQuality?
    paint.filterQuality = FilterQuality.none;
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(0, 0, _size.width, _size.height),
      paint,
    );

    final picture = recorder.endRecording();
    _lastPicture = picture;
    _lastImage = img;
    builder.addPicture(offset, picture);
  }

  ui.Picture? _lastPicture;
}
