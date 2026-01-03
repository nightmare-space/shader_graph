import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shader_graph/shader_graph.dart';

/// 这个例子其实是在观察 GPU 内存中的数据
/// This example visualizes float data stored in GPU memory.
class FloatExample extends StatefulWidget {
  const FloatExample({super.key});

  @override
  State<FloatExample> createState() => _FloatExampleState();
}

class _FloatExampleState extends State<FloatExample> {
  // Static vec4 grid display sizing
  double staticGridMaxWidth = 800.0;
  double staticGridCellHeight = 80;
  ShaderBuffer? staticVec4GridA;
  @override
  Widget build(BuildContext context) {
    // Virtual (shader): 3x2 texels, each texel is a vec4.
    // Physical (Flutter): 3*4 lanes x 2 = 12x2.
    if (staticVec4GridA == null || staticVec4GridA!.isDisposed) {
      staticVec4GridA = 'shaders/multi_pass/Static Vec4 Grid A.frag'.shaderBuffer;
      staticVec4GridA!.fixedOutputSize = const Size(3 * 4.0, 2);
      staticVec4GridA!.feedEmpty();
    }

    const virtualWidth = 3;
    const virtualHeight = 2;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Ensure the shader is rendered so byteData becomes available.
        SizedBox(
          height: 120,
          child: ShaderSurface.builder(
            () => [staticVec4GridA!],
            key: const ValueKey('static-vec4-grid-a'),
          ),
        ),
        ListenableBuilder(
          listenable: staticVec4GridA!,
          builder: (_, __) {
            final bd = staticVec4GridA!.frameData;
            if (bd == null) {
              return const Center(child: Text('Waiting GPU readback...'));
            }

            final bytes = bd.buffer.asUint8List();

            final painter = _Vec4GridPainter(
              data: bytes,
              virtualWidth: virtualWidth,
              virtualHeight: virtualHeight,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = staticGridMaxWidth;
                  final availableW = constraints.maxWidth.isFinite ? constraints.maxWidth : maxW;
                  // On phones, the grid is too narrow and text won't fit.
                  // Keep a fixed grid width and allow horizontal scrolling.
                  final gridW = availableW < maxW ? maxW : availableW.clamp(0.0, maxW);
                  final cellH = staticGridCellHeight;
                  final gridH = cellH * virtualHeight;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: gridW,
                        height: gridH,
                        child: CustomPaint(painter: painter),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Vec4GridPainter extends CustomPainter {
  _Vec4GridPainter({
    required this.data,
    required this.virtualWidth,
    required this.virtualHeight,
  });

  final Uint8List data;
  final int virtualWidth;
  final int virtualHeight;

  // Display a smaller subset to avoid text overlap.
  // This does NOT change the underlying buffer layout (still 6x4 virtual -> 24x4 physical).
  static const int _kDisplayVirtualWidth = 3;
  static const int _kDisplayVirtualHeight = 2;

  // Match `sg_unpack01FromRGB` in `sg_feedback_rgba8.frag` (base-256 fraction).
  // r,g,b are bytes in [0..255].
  double _decodeSignedFromRgb(int r, int g, int b) {
    final v01 = (r / 256.0) + (g / 65536.0) + (b / 16777216.0);
    final u = v01.clamp(0.0, 1.0);
    return (u * 2.0) - 1.0; // [-1,1]
  }

  double _clampSigned(double v) => v.clamp(-1.0, 1.0);

  // Mirror `valueForTexel()` in `Static Vec4 Grid A.frag`.
  // Virtual size is fixed to 6x4 in that shader; here we compute based on
  // current virtualWidth/virtualHeight so the painter stays generic.
  ({double x, double y, double z, double w}) _expectedForTexel(int vx, int vy) {
    final fx = (virtualWidth <= 1) ? 0.0 : vx / (virtualWidth - 1);
    final fy = (virtualHeight <= 1) ? 0.0 : vy / (virtualHeight - 1);

    final x = fx * 2.0 - 1.0;
    final y = fy * 2.0 - 1.0;
    final z = _clampSigned((fx - fy) * 2.0);
    final w = _clampSigned(
      (math.sin((fx + fy) * 2.0 * math.pi) * 0.8),
    );

    return (x: x, y: y, z: z, w: w);
  }

  String _fmtSigned(double v, {int decimals = 3}) {
    final clamped = v.clamp(-1.0, 1.0);
    return clamped.toStringAsFixed(decimals);
  }

  String _fmtDelta(double v, {int decimals = 4}) {
    final clamped = v.clamp(-2.0, 2.0);
    return clamped.toStringAsFixed(decimals);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.0;
    const pad = 2.0;

    final displayW = math.min(virtualWidth, _kDisplayVirtualWidth);
    final displayH = math.min(virtualHeight, _kDisplayVirtualHeight);

    final cellW = (size.width - gap * (displayW - 1)) / displayW;
    final cellH = (size.height - gap * (displayH - 1)) / displayH;

    final physicalWidth = virtualWidth * 4;

    final fill = Paint()..style = PaintingStyle.fill;
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..color = Color(0xfff3f4f9)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int vy = 0; vy < displayH; vy++) {
      for (int vx = 0; vx < displayW; vx++) {
        final rect = Rect.fromLTWH(
          vx * (cellW + gap),
          vy * (cellH + gap),
          cellW,
          cellH,
        );

        // Always draw a neutral background + grid. No color mapping.
        fill.color = Colors.white;
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, grid);

        // On small screens, cells can be narrow. Still render text with
        // smaller fonts so the data is visible.
        if (cellW < 28 || cellH < 20) continue;

        double laneValue(int laneIndex) {
          final px = vx * 4 + laneIndex;
          final i = (vy * physicalWidth + px) * 4;
          if (i + 2 >= data.length) return 0.0;
          return _decodeSignedFromRgb(data[i], data[i + 1], data[i + 2]);
        }

        final x = laneValue(0);
        final y = laneValue(1);
        final z = laneValue(2);
        final w = laneValue(3);

        final exp = _expectedForTexel(vx, vy);
        final dx = x - exp.x;
        final dy = y - exp.y;
        final dz = z - exp.z;
        final dw = w - exp.w;

        final text =
            'x e:${_fmtSigned(exp.x)} d:${_fmtSigned(x)} Δ:${_fmtDelta(dx)}\n'
            'y e:${_fmtSigned(exp.y)} d:${_fmtSigned(y)} Δ:${_fmtDelta(dy)}\n'
            'z e:${_fmtSigned(exp.z)} d:${_fmtSigned(z)} Δ:${_fmtDelta(dz)}\n'
            'w e:${_fmtSigned(exp.w)} d:${_fmtSigned(w)} Δ:${_fmtDelta(dw)}';
        // Tuned for compact cells (e.g. 48px height)
        // 字体大小限制到 9-16 之间
        final fontSize = (cellH * 0.30).clamp(7.0, 16.0);

        textPainter.text = TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        );
        final textW = (rect.width - pad * 2).clamp(0.0, rect.width);
        // Use fixed paragraph width so TextAlign.center actually centers lines.
        textPainter.layout(minWidth: textW, maxWidth: textW);
        textPainter.paint(
          canvas,
          Offset(
            rect.left + pad,
            rect.top + (cellH - textPainter.height) * 0.5,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Vec4GridPainter oldDelegate) => true;
}
