library shader_graph;

export 'src/extension/extension.dart';
export 'src/controller/keyboard_controller.dart';

// import '' is same as import 'shader_graph.dart'
// shader_surface will use KeyboardController
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '';
import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'src/foundation/mouse.dart';
part 'src/foundation/render_data.dart';
part 'src/shader_input.dart';
part 'src/shader_buffer.dart';
part 'src/shader_graph.dart';
part 'src/view/shader_surface.dart';
part 'src/view/shader_surface_render_object.dart';

// TOTO: 支持保留上次鼠标位置
