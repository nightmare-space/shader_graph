library shader_graph;

export 'src/extension/dsl.dart';
export 'src/controller/keyboard_controller.dart';
export 'src/foundation/wrap_mode.dart';

// import '' is same as import 'shader_graph.dart'
// shader_surface will use KeyboardController
import '';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:shader_graph/src/foundation/shader_input.dart';

import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'src/foundation/mouse_data.dart';
part 'src/foundation/render_data.dart';
part 'src/inputs/shader_input.dart';
part 'src/core/shader_buffer.dart';
part 'src/core/shader_graph.dart';
part 'src/rendering/shader_surface.dart';
part 'src/rendering/render_shader_surface.dart';

// TOTO: 支持保留上次鼠标位置
