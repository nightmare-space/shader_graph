import 'package:flutter/cupertino.dart';
import 'package:shader_graph/shader_graph.dart';

class CustomUniformsExample extends StatefulWidget {
  const CustomUniformsExample({super.key});

  @override
  State<CustomUniformsExample> createState() => _CustomUniformsExampleState();
}

class _CustomUniformsExampleState extends State<CustomUniformsExample> with TickerProviderStateMixin {
  final buffer = 'shaders/touch_simple.frag'.shaderBuffer;
  late AnimationController liftController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  late AnimationController swapController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  // 多点触控：追踪所有活跃指针
  final Map<int, Offset> activeTouches = {};

  @override
  void initState() {
    super.initState();
    liftController.addListener(() {
      buffer.setUniform(0, liftController.value * 1.2);
    });

    swapController.addListener(() {
      buffer.setUniform(4, swapController.value);
    });
    swapController.repeat();

    // uniforms (match example/shaders/touch_simple.frag)
    buffer.setUniform(0, 0.0); // liftStrength
    buffer.setUniform(1, 0.4); // liftRadius
    buffer.setUniform(2, 48.0); // pointsPerRow
    buffer.setUniform(3, 0.2); // baseDotOpacity
    buffer.setUniform(4, 0.0); // swapProgress

    // iMouse1-4 default to "no touch"
    for (int i = 0; i < 4; i++) {
      buffer.setUniform(5 + i, [-1.0, -1.0, -1.0, -1.0]);
    }
  }

  void _syncTouchesToShader(RenderBox box) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    // 按指针 ID 排序，取前 4 个
    final touches = activeTouches.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // 传递 4 个 iMouse 位置
    // slot 5-8 对应 iMouse1-4
    for (int i = 0; i < 4; i++) {
      if (i < touches.length) {
        final pos = touches[i].value;
        buffer.setUniform(5 + i, [pos.dx * dpr, pos.dy * dpr, pos.dx * dpr, pos.dy * dpr]);
      } else {
        // 清零未使用的指针
        buffer.setUniform(5 + i, [-1.0, -1.0, -1.0, -1.0]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (innerContext) {
        return Listener(
          onPointerMove: (event) {
            final box = innerContext.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(event.position);
            activeTouches[event.pointer] = localPos;
            _syncTouchesToShader(box);
          },
          onPointerDown: (event) {
            final box = innerContext.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(event.position);
            activeTouches[event.pointer] = localPos;
            liftController.forward();
            _syncTouchesToShader(box);
          },
          onPointerUp: (event) {
            final box = innerContext.findRenderObject() as RenderBox;
            activeTouches.remove(event.pointer);

            if (activeTouches.isEmpty) {
              liftController.reverse();

              // 等回落动画完成后再清空触点，避免 liftFalloff 瞬间归零
              Future.delayed(const Duration(milliseconds: 150), () {
                if (!mounted) return;
                if (liftController.status == AnimationStatus.dismissed) {
                  _syncTouchesToShader(box);
                }
              });
            } else {
              _syncTouchesToShader(box);
            }
          },
          behavior: HitTestBehavior.translucent,
          child: ShaderSurface.auto(buffer, upSideDown: false),
        );
      },
    );
  }

  @override
  void dispose() {
    liftController.dispose();
    swapController.dispose();
    super.dispose();
  }
}
