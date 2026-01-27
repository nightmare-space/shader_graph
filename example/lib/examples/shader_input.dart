import 'dart:ui';
import 'dart:ui' as ui;

import 'package:example/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:shader_graph/shader_graph.dart';

class ShaderInputExample extends StatefulWidget {
  const ShaderInputExample({super.key});

  @override
  State<ShaderInputExample> createState() => _ShaderInputExampleState();
}

class _ShaderInputExampleState extends State<ShaderInputExample> {
  int currentIndex = 0;
  final tabTitles = [
    'WidgetInput',
    'Keyboard Input',
    'Mouse Input',
  ];
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CupertinoNavigationBar(
          middle: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: CupertinoSlidingSegmentedControl(
              // isMomentary: true,
              proportionalWidth: true,
              groupValue: currentIndex,
              onValueChanged: (int? value) {
                if (value != null) {
                  currentIndex = value;
                  setState(() {});
                }
              },
              children: {
                for (var i = 0; i < tabTitles.length; i++) i: Text(tabTitles[i]),
              },
            ),
          ),
        ),
        Expanded(
          child: [
            buildWidgetInput(),
            buildKeyboardInput(),
            buildMouseInput(),
          ][currentIndex],
        ),
      ],
    );
  }

  Widget buildMouseInput() {
    return ShaderSurface.builder(
      () {
        // Virtual grid size (simulation texels): VSIZE
        // Physical size (RGBA8 packed): (VSIZE.x*4, VSIZE.y)
        const virtualSize = Size(128, 128);
        final physicalSize = Size(virtualSize.width * 4.0, virtualSize.height + 1.0);

        final bufferA = "shaders/mouse/Pentagonal Conway's game BufferA.frag".shaderBuffer
          ..fixedOutputSize = physicalSize
          // BufferA uses a fixed-size lane-packed render target, but mouse input should
          // match the on-screen surface size. We map surface-space iMouse -> VSIZE inside
          // the shader, and keep the physical lane packing for storage.
          ..useSurfaceSizeForIResolution = true
          ..feedback()
          ..feedKeyboard();

        final main = "shaders/mouse/Pentagonal Conway's game.frag".shaderBuffer..feedShader(bufferA);

        return [bufferA, main];
      },
      key: const ValueKey('pentagonal_conway'),
    );
  }

  Widget buildKeyboardInput() {
    return ShaderSurface.builder(
      () {
        final mainBuffer = 'shaders/keyboard/Keyboard Test.frag'.shaderBuffer;
        mainBuffer.feedKeyboard();
        mainBuffer.feedImageFromAsset('assets/codepage12.png');

        final overlayBuffer = 'shaders/keyboard/Keyboard Debug Overlay.frag'.shaderBuffer;
        overlayBuffer.feedShader(mainBuffer);
        overlayBuffer.feedKeyboard();
        return [mainBuffer, overlayBuffer];
      },
    );
  }

  Widget buildWidgetInput() {
    final imageWidget = Image.asset(
      'assets/textures/Rock Tiles.jpg',
      fit: BoxFit.cover,
    );
    final widgets = [
      Expanded(
        child: Column(
          spacing: 4,
          children: [
            Text('feedWidgetInput', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Expanded(
              child: ShaderSurface.auto(
                'shaders/wrap/Inverse Bilinear.frag'.feed(imageWidget),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: Column(
          spacing: 4,
          children: [
            Text(
              'ImageFilter.shader(Impeller)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: WidgetInputTest(
                child: SizedBox.expand(
                  child: imageWidget,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < narrowWidthThreshold) {
          return Column(
            children: [
              widgets[0],
              const SizedBox(height: 16),
              widgets[1],
            ],
          );
        } else {
          return Row(
            children: [
              widgets[0],
              const SizedBox(width: 16),
              widgets[1],
            ],
          );
        }
      },
    );
  }
}

class ReactionDiffusionView extends StatelessWidget {
  const ReactionDiffusionView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderSurface.builder(
      () {
        final bufferA = 'shaders/multi_pass/expansive reaction-diffusion BufferA.frag'.shaderBuffer;
        final bufferB = 'shaders/multi_pass/expansive reaction-diffusion BufferB.frag'.shaderBuffer;
        final bufferC = 'shaders/multi_pass/expansive reaction-diffusion BufferC.frag'.shaderBuffer;
        final bufferD = 'shaders/multi_pass/expansive reaction-diffusion BufferD.frag'.shaderBuffer;
        final mainBuffer = 'shaders/multi_pass/expansive reaction-diffusion.frag'.shaderBuffer;

        bufferA.feedback(filter: .linear).feed(bufferC, filter: .linear).feed(bufferD, filter: .linear);
        bufferA.feed('assets/textures/RGBA Noise Medium.png', wrap: .repeat, filter: .linear);

        bufferB.feed(bufferA, filter: .linear);
        bufferC.feed(bufferB, filter: .linear);

        // Scheme B: keep Dart feed order; shader remaps channel slots.
        mainBuffer.feed(bufferA, filter: .linear);
        mainBuffer.feed(bufferC, filter: .linear);
        mainBuffer.feed('assets/textures/RGBA Noise Medium.png', wrap: .repeat, filter: .linear);
        return [bufferA, bufferB, bufferC, bufferD, mainBuffer];
      },
      key: ValueKey('reaction_diffusion'),
    );
  }
}

/// 这是另一种可以将 Widget 作为输入的方式，关键 API 是 ImageFilter.shader
/// 但是这个仅仅适用于 Impeller，而且对着色器的宏定义有要求
///
/// This is an alternative way to use a Widget as input, the key API is ImageFilter.shader
/// However, this only works with Impeller and has certain requirements on the shader's macro definitions
class WidgetInputTest extends StatefulWidget {
  const WidgetInputTest({required this.child, super.key});

  final Widget child;

  @override
  State<WidgetInputTest> createState() => _WidgetInputTestState();
}

class _WidgetInputTestState extends State<WidgetInputTest> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ShaderBuilder(
      assetKey: 'shaders/wrap/Inverse Bilinear.frag',
      (context, shader, child) {
        return _RawMinimalGlass(
          shader: shader,
          vsync: this,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

class _RawMinimalGlass extends SingleChildRenderObjectWidget {
  const _RawMinimalGlass({
    required this.shader,
    required this.vsync,
    required Widget super.child,
  });

  final FragmentShader shader;
  final TickerProvider vsync;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMinimalGlass(shader: shader, ticker: vsync);
  }

  @override
  void updateRenderObject(BuildContext context, RenderMinimalGlass renderObject) {
    renderObject
      ..shader = shader
      ..ticker = vsync;
  }
}

class RenderMinimalGlass extends RenderProxyBox {
  RenderMinimalGlass({
    required FragmentShader shader,
    required TickerProvider ticker,
  }) : _shader = shader,
       _tickerProvider = ticker {
    _ticker = _tickerProvider.createTicker((elapsed) {
      _time = elapsed.inMilliseconds / 1000.0;
      if (layer != null) layer!.markNeedsAddToScene();
      markNeedsPaint();
    })..start();
  }

  FragmentShader _shader;
  set shader(FragmentShader value) {
    if (_shader == value) return;
    _shader = value;
    layer = null;
    markNeedsPaint();
  }

  TickerProvider _tickerProvider;
  set ticker(TickerProvider value) {
    if (_tickerProvider == value) return;
    _tickerProvider = value;
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = _tickerProvider.createTicker((elapsed) {
      _time = elapsed.inMilliseconds / 1000.0;
      if (layer != null) layer!.markNeedsAddToScene();
      markNeedsPaint();
    })..start();
  }

  double _time = 0.0;
  Ticker? _ticker;

  @override
  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }

  @override
  MinimalShaderLayer? get layer => super.layer as MinimalShaderLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    layer ??= MinimalShaderLayer(offset: Offset.zero, shader: _shader);
    final child = this.child;
    Rect childRect = Rect.zero;
    if (child is RenderBox) {
      final pd = child.parentData;
      if (pd is BoxParentData) {
        childRect = Rect.fromLTWH(
          pd.offset.dx,
          pd.offset.dy,
          child.size.width,
          child.size.height,
        );
      } else {
        childRect = Rect.fromLTWH(0, 0, child.size.width, child.size.height);
      }
    }

    layer!
      ..offset = offset
      ..shader = _shader
      ..time = _time
      ..size = size
      ..childRect = childRect;

    context.pushLayer(
      layer!,
      (context, offset) {
        super.paint(context, offset);
      },
      Offset.zero,
    );
  }
}

class MinimalShaderLayer extends OffsetLayer {
  MinimalShaderLayer({
    required super.offset,
    required FragmentShader shader,
  }) : _shader = shader;
  Rect _childRect = Rect.zero;
  set childRect(Rect r) {
    if (_childRect == r) return;
    _childRect = r;
    markNeedsAddToScene();
  }

  FragmentShader _shader;
  set shader(FragmentShader value) {
    if (_shader == value) return;
    _shader = value;
    markNeedsAddToScene();
  }

  double _time = 0.0;
  set time(double t) {
    if (_time == t) return;
    _time = t;
    markNeedsAddToScene();
  }

  Size _size = Size.zero;
  set size(Size s) {
    if (_size == s) return;
    _size = s;
    markNeedsAddToScene();
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    final offsetLayer = builder.pushOffset(
      offset.dx,
      offset.dy,
      oldLayer: engineLayer as ui.OffsetEngineLayer?,
    );
    engineLayer = offsetLayer;
    {
      // NOTE ABOUT FILTER TYPES
      // - ImageFilter (foreground): filters *this layer's child*.
      // - BackdropFilter (background): filters *whatever has already been painted
      //   behind this layer* (the scene backdrop), not this layer's child.
      //
      // Why did you observe that `pushBackdropFilter` “inputs the whole Row”?
      // In a `Row`, the left `Expanded` is typically painted before the right.
      // When the right side's layer is added, the backdrop already contains the
      // left side, so your shader can sample it.
      //
      // Also: ClipRect here clips the *output region*, but it does NOT crop the
      // backdrop texture itself. If the shader shifts sampling coords (distortion
      // / resampling), it can still read outside this region and “see” the left.
      builder.pushClipRect(Offset.zero & _size);

      _shader.setFloat(2, _time);

      // ImageFilter version: the child is the filtered content.
      builder.pushImageFilter(ui.ImageFilter.shader(_shader));
      final childLayer = firstChild;
      childLayer?.addToScene(builder);
      builder.pop(); // pop image filter

      // BackdropFilter version (kept for reference):
      // builder.pushBackdropFilter(ui.ImageFilter.shader(_shader));
      // final childLayer = firstChild;
      // childLayer?.addToScene(builder);
      // builder.pop(); // pop backdrop filter

      builder.pop(); // pop clip rect
    }
    builder.pop();
  }
}
