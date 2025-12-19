part of 'package:shader_graph/shader_graph.dart';

/// 简单的数据类
/// A simple data class
class RenderData {
  RenderData({
    required this.logicalSize,
    required this.dpr,
    required this.iFrame,
    required this.time,
    required this.devicePixelRatio,
    required this.iMouse,
  });
  Size logicalSize;
  double dpr;
  double iFrame;
  double time;
  double devicePixelRatio;
  IMouse iMouse;
}
