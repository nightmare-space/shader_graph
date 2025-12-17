import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shader_graph/shader_graph.dart';

/// 这个例子其实是在观察 GPU 内存中的数据
/// This example visualizes float data stored in GPU memory.
class FloatTest extends StatefulWidget {
  const FloatTest({super.key});

  @override
  State<FloatTest> createState() => _FloatTestState();
}

class _FloatTestState extends State<FloatTest> {
  // Static vec4 grid display sizing
  double staticGridMaxWidth = 800.0;
  double staticGridCellHeight = 80;
  ShaderBuffer? staticVec4GridA;
  @override
  Widget build(BuildContext context) {
    // Virtual (shader): 6x4 texels, each texel is a vec4.
    // Physical (Flutter): 6*4 lanes x 4 = 24x4.
    if (staticVec4GridA == null || staticVec4GridA!.isDisposed) {
      staticVec4GridA = 'shaders/multi_pass/Static Vec4 Grid A.frag'.shaderBuffer;
      staticVec4GridA!.fixedOutputSize = const Size(6 * 4.0, 4);
      staticVec4GridA!.feedEmpty();
    }

    const virtualWidth = 6;
    const virtualHeight = 4;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Ensure the shader is rendered so byteData becomes available.
        SizedBox(
          height: 120,
          child: ShaderSurfaceWrapper.builder(
            () => [staticVec4GridA!],
            key: const ValueKey('static-vec4-grid-a'),
          ),
        ),
        ListenableBuilder(
          listenable: staticVec4GridA!,
          builder: (_, __) {
            final bd = staticVec4GridA!.byteData;
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

  static const double _kQMax = 16777215.0; // 2^24 - 1

  double _decodeSignedFromRgb(int r, int g, int b) {
    final q = (r * 65536) + (g * 256) + b;
    final u = q / _kQMax; // [0,1]
    return (u * 2.0) - 1.0; // [-1,1]
  }

  String _fmtSigned(double v, {int decimals = 3}) {
    final clamped = v.clamp(-1.0, 1.0);
    return clamped.toStringAsFixed(decimals);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.0;
    const pad = 2.0;

    final cellW = (size.width - gap * (virtualWidth - 1)) / virtualWidth;
    final cellH = (size.height - gap * (virtualHeight - 1)) / virtualHeight;

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

    for (int vy = 0; vy < virtualHeight; vy++) {
      for (int vx = 0; vx < virtualWidth; vx++) {
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

        final text = 'x: ${_fmtSigned(x)}\ny: ${_fmtSigned(y)}\n'
            'z: ${_fmtSigned(z)}\nw: ${_fmtSigned(w)}';
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
