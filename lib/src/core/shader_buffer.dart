part of 'package:shader_graph/shader_graph.dart';

class ShaderBuffer extends ChangeNotifier {
  ShaderBuffer(
    this.shaderAssetPath, {
    this.scale = 1.0,
    this.name,
    this.fixedOutputSize,
  });

  /// 自定义 uniform 变量，以原始着色器的顺序为准，内部会根据默认 Uniforms 之后的 slot 索引进行设置
  ///
  /// Custom uniform variables, following the order of the original shader.
  final Map<int, dynamic> _customUniforms = {};

  /// 着色器资源路径，不知道 Flutter 什么时候可以支持用 File 对象加载着色器
  ///
  /// Shader asset path. Not sure when Flutter will support loading shaders from File objects.
  final String shaderAssetPath;

  /// 缩放比例，可以以更低的分辨率渲染以提升性能
  ///
  /// Scale factor, can render at lower resolution for better performance
  double scale;
  final String? name;

  /// 当设置后，着色器输出会被渲染到这个固定的像素尺寸，
  /// 与 widget 大小 / devicePixelRatio / [scale] 无关。
  /// 这对于 Shadertoy 风格的数据 buffer（例如 14x14）以及
  /// 将虚拟像素扩展到多个物理像素的布局非常有用。
  ///
  /// When set, the shader output is rendered to this exact pixel size,
  /// independent of the widget size / devicePixelRatio / [scale].
  /// This is useful for Shadertoy-style data buffers (e.g. 14x14) and
  /// for layouts that expand virtual texels into multiple physical pixels.
  Size? fixedOutputSize;

  /// 控制 iResolution（以及 iMouse）的坐标空间。
  ///
  /// 默认（false）：iResolution 与实际渲染目标尺寸匹配
  /// （如果设置了 fixedOutputSize 则为其值，否则为表面尺寸）。
  ///
  /// 当为 true 时：即使渲染到一个很小的 fixedOutputSize
  /// （Shadertoy 风格的数据 buffer 常见），也保持 iResolution 在表面像素空间
  /// （data.logicalSize * data.dpr * scale）。
  ///
  /// Controls the coordinate space of `iResolution` (and consequently `iMouse`).
  ///
  /// Default (`false`): `iResolution` matches the actual render target size
  /// (`fixedOutputSize` if set, otherwise the surface size).
  ///
  /// When `true`: keep `iResolution` in surface pixel space
  /// (`data.logicalSize * data.dpr * scale`) even if rendering to a tiny
  /// `fixedOutputSize` (common for Shadertoy-style state buffers).
  bool useSurfaceSizeForIResolution = false;

  ui.FragmentShader? _shader;

  ui.Image? _output;
  ui.Image? _prevOutput;
  ui.Image? _blankImage;
  ByteData? frameData;
  bool _readbackInFlight = false;
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  final List<ShaderInput> _inputs = [];

  ShaderBuffer setUniform(int slot, dynamic value) {
    _customUniforms[slot] = value;
    return this;
  }

  ShaderBuffer feedWidgetInput(
    Widget widget, {
    WrapMode wrap = WrapMode.clamp,
    FilterMode filter = FilterMode.linear,
  }) {
    _inputs.add(WidgetInput(widget: widget, wrap: wrap, filter: filter));
    return this;
  }

  /// 添加一个 ShaderBuffer 作为输入，对应 shader 里的 iChannelN
  ///
  /// Adding a ShaderBuffer as input, corresponding to iChannelN in the shader
  ShaderBuffer feedShader(
    ShaderBuffer buffer, {
    WrapMode wrap = WrapMode.clamp,
    FilterMode filter = FilterMode.linear,
  }) {
    _inputs.add(ShaderBufferInput(buffer, wrap: wrap, filter: filter));
    return this;
  }

  /// 添加一个 ShaderBuffer 作为输入资源，从 assetPath 加载，对应 shader 里的 iChannelN
  ///
  /// Adding a ShaderBuffer as input resource, loading from assetPath,
  /// corresponding to iChannelN in the shader
  ShaderBuffer feedShaderFromAsset(
    String assetPath, {
    WrapMode wrap = WrapMode.clamp,
    FilterMode filter = FilterMode.linear,
  }) {
    _inputs.add(ShaderBufferInput(ShaderBuffer(assetPath), wrap: wrap, filter: filter));
    return this;
  }

  /// 添加一个图片资源作为输入，从 assetPath 加载，对应 shader 里的 iChannelN
  ///
  /// Adding an image resource as input, loading from assetPath,
  /// corresponding to iChannelN in the shader
  ShaderBuffer feedImageFromAsset(
    String assetPath, {
    WrapMode wrap = WrapMode.clamp,
    FilterMode filter = FilterMode.linear,
  }) {
    _inputs.add(AssetInput(assetPath: assetPath, wrap: wrap, filter: filter));
    return this;
  }

  /// 添加一个键盘输入作为输入，对应 shader 里的 iChannelN
  ///
  /// Adding a keyboard input as input, corresponding to iChannelN in the shader
  ShaderBuffer feedKeyboard({WrapMode wrap = WrapMode.clamp, FilterMode filter = FilterMode.linear}) {
    _inputs.add(KeyboardInput(wrap: wrap, filter: filter));
    return this;
  }

  /// 添加反馈输入，对应 shader 里的 iChannelN
  ///
  /// Adding a feedback input, corresponding to iChannelN in the shader
  ShaderBuffer feedback({WrapMode wrap = WrapMode.clamp, FilterMode filter = FilterMode.linear}) {
    _inputs.add(ShaderBufferInput(this, usePreviousFrame: true, wrap: wrap, filter: filter));
    return this;
  }

  /// 为了测试
  ///
  /// For testing
  ShaderBuffer feedEmpty() {
    _inputs.add(EmptyInput());
    return this;
  }

  /// 初始化着色器，如果使用 ShaderBufferWrapper 可以不需要手动调用
  ///
  /// Initialize the shader. If using ShaderBufferWrapper, manual invocation is not required.
  Future<void> init() async {
    try {
      ui.FragmentProgram program;
      String shaderAssetPath = this.shaderAssetPath;
      if (kIsWeb) {
        // See https://github.com/flutter/flutter/issues/180862
        // Currently web needs the URI-encoded full path.
        shaderAssetPath = Uri.encodeFull(shaderAssetPath);
      }
      program = await ui.FragmentProgram.fromAsset(shaderAssetPath);
      _shader = program.fragmentShader();
    } catch (e) {
      log('Error loading shader program from $shaderAssetPath: $e');
      throw Exception('Failed to load shader program from $shaderAssetPath: $e');
    }
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);

      // 绘制一个 16x16 的黑色矩形
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 16, 16),
        Paint()..color = const Color(0xFF000000),
      );

      final picture = pictureRecorder.endRecording();
      _blankImage = await picture.toImage(16, 16);
      picture.dispose();
    } on Exception catch (e) {
      debugPrint('Cannot load blankImage! $e');
    }
  }

  /// 在每一帧开始时推进一次 feedback 链：
  /// prevOutput <- output
  ///
  /// 注意：这一步需要在渲染任何 buffer 之前完成，否则 usePreviousFrame
  /// 可能会读到“上上帧”（两帧延迟），进而导致反馈发散。
  ///
  /// 这里之前花了很长的时间，去调试着色器渲染异常的问题
  /// 之前在 render 中将 _prevOutput 推进，这样会导致同一帧中读到当前帧序列的输入，
  /// 一些着色器拿到的是当前的输入，而对于 BufferX->BufferX 的反馈
  /// 是需要 PingPong 机制的。就像乒乓球
  /// 最简单的验证，就是把 _beginFrame 注释掉，把 Render(_Sync) 中对应的代码放开注释
  /// 然后运行 Brick Game 这个游戏
  ///
  /// Beginning of each frame, advance the feedback chain:
  /// prevOutput <- output
  ///
  /// Note: This step must be done before rendering any buffers,
  /// otherwise usePreviousFrame may read from "the frame before last"
  /// (two-frame delay), leading to feedback divergence.
  ///
  /// Previously, I spent a long time debugging shader rendering issues.
  /// By advancing _prevOutput in render, it caused some shaders
  /// to read the current frame's input within the same frame sequence.
  /// For BufferX->BufferX feedback, a PingPong mechanism is needed,
  /// like in table tennis.
  /// The simplest test is to comment out _beginFrame,
  /// and uncomment the corresponding code in Render(_Sync),
  /// then run the Brick Game.
  void _beginFrame() {
    // 避免 dispose 同一个 image 两次
    // 当 widget 在 beginFrame() 和下一次 render 之间被 dispose 时，
    // `_prevOutput` 可能暂时与 `_output` 别名化。
    //
    // Avoid disposing the same image twice.
    // When the widget is disposed between beginFrame() and the next render,
    // `_prevOutput` may temporarily alias `_output`.
    final prev = _prevOutput;
    final out = _output;
    if (prev != null && !identical(prev, out)) {
      prev.dispose();
    }
    _prevOutput = out;
  }

  Future<void> _render({required RenderData data}) async {
    if (_shader == null) return;

    final realSize = fixedOutputSize ?? (data.logicalSize * data.dpr * scale);
    renderShader(data: data);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();
    try {
      paint.shader = _shader;
    } catch (e) {
      log('Error applying shader for $shaderAssetPath: $e');
      throw Exception('Failed to apply shader for $shaderAssetPath: $e');
    }
    paint.filterQuality = FilterQuality.none;

    canvas.drawRect(Offset.zero & realSize, paint);
    final picture = recorder.endRecording();
    final img = await picture.toImage(realSize.width.ceil(), realSize.height.ceil());

    picture.dispose();

    // prevOutput 的推进由 ShaderGraph 在“每帧开始”统一调用 beginFrame() 处理，
    // 从而保证 usePreviousFrame 语义稳定（=上一帧）且与 buffer 执行顺序无关。
    // 这里保留旧逻辑（注释）便于对照/回滚：
    // Avoid advancing prevOutput here; it's handled uniformly by ShaderGraph
    // at the "beginning of each frame", ensuring stable semantics for
    // usePreviousFrame (= previous frame) regardless of buffer execution order.
    // _prevOutput?.dispose();
    // _prevOutput = _output;

    _output = img;
    if (hasListeners) notifyListeners();

    // `toByteData()` is an expensive GPU->CPU readback. Only do it when
    // somebody is actually listening.
    if (hasListeners && !_readbackInFlight) {
      _readbackInFlight = true;
      img.toByteData(format: ui.ImageByteFormat.rawRgba).then((bd) {
        if (_isDisposed) return;
        _readbackInFlight = false;
        if (bd == null) return;
        frameData = bd;
        notifyListeners();
      }).catchError((_) {
        _readbackInFlight = false;
      });
    }
  }

  void renderSync({
    required RenderData data,
    ui.Image? keyboardChannel,
  }) {
    if (_shader == null) return;

    final realSize = fixedOutputSize ?? (data.logicalSize * data.dpr * scale);
    renderShader(data: data);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Offset.zero & realSize, Paint()..shader = _shader!);
    final picture = recorder.endRecording();
    // picture.toImage(realSize.width.ceil(), realSize.height.ceil()).then((img) {
    //   _prevOutput = _output;
    //   _output = img;
    //   notifyListeners();
    //   picture.dispose();
    // });
    final img = picture.toImageSync(realSize.width.ceil(), realSize.height.ceil());

    picture.dispose();

    // prevOutput 的推进由 ShaderGraph 在“每帧开始”统一调用 beginFrame() 处理，
    // 从而保证 usePreviousFrame 语义稳定（=上一帧）且与 buffer 执行顺序无关。
    // 这里保留旧逻辑（注释）便于对照/回滚：
    // Avoid advancing prevOutput here; it's handled uniformly by ShaderGraph
    // at the "beginning of each frame", ensuring stable semantics for
    // usePreviousFrame (= previous frame) regardless of buffer execution order.
    // _prevOutput?.dispose();
    // _prevOutput = _output;
    _output = img;
    if (hasListeners) notifyListeners();

    // `toByteData()` is an expensive GPU->CPU readback. Only do it when
    // somebody is actually listening.
    if (hasListeners && frameData == null && !_readbackInFlight) {
      _readbackInFlight = true;
      img.toByteData(format: ui.ImageByteFormat.rawRgba).then((bd) {
        if (_isDisposed) return;
        _readbackInFlight = false;
        if (bd == null) return;
        frameData = bd;
        notifyListeners();
      }).catchError((_) {
        _readbackInFlight = false;
      });
    }
  }

  int index = 0;
  void renderShader({required RenderData data}) {
    index = 0;
    // Render target size.
    final renderSize = fixedOutputSize ?? (data.logicalSize * data.dpr * scale);

    // Uniform space (Shadertoy semantics): iResolution / iMouse coordinate system.
    final surfaceSize = data.logicalSize * data.dpr * scale;
    final uniformSize = useSurfaceSizeForIResolution ? surfaceSize : renderSize;
    Stopwatch stopwatch = Stopwatch()..start();
    _shader!
      ..setFloat(index++, uniformSize.width)
      ..setFloat(index++, uniformSize.height);

    // ShaderStoy 语义下的 iMouse 需要基于 buffer 的 iResolution 坐标系进行调整。
    // 我们的 pointer 事件是基于 widget 逻辑像素的，但 buffer 可能有 fixedOutputSize（例如 112x14）。
    // 将 iMouse 重映射到每个 buffer 的 iResolution，以保持游戏逻辑稳定，避免反馈发散。
    //
    // Shadertoy semantics: iMouse is in the same pixel space as iResolution.
    // Our pointer events are in widget logical pixels, but buffers can have a
    // fixedOutputSize (e.g. 112x14). Remap iMouse into each buffer's iResolution
    // to keep gameplay logic stable and avoid feedback divergence.
    final sx = (data.logicalSize.width == 0) ? 0.0 : (uniformSize.width / data.logicalSize.width);
    final sy = (data.logicalSize.height == 0) ? 0.0 : (uniformSize.height / data.logicalSize.height);
    final mx = data.iMouse.x * sx;
    final my = data.iMouse.y * sy;
    final mz = data.iMouse.z * sx;
    final mw = data.iMouse.w * sy;

    _shader!
      ..setFloat(index++, data.time)
      ..setFloat(index++, data.iFrame)
      ..setFloat(index++, mx)
      ..setFloat(index++, my)
      ..setFloat(index++, mz)
      ..setFloat(index++, mw);

    // Optional Shadertoy-style per-channel wrap modes.
    // Encoded into a vec4 `iChannelWrap` (x/y/z/w == channel 0..3).
    // This is implemented shader-side as a UV transform, not as a real GPU sampler state.
    _setChannelUniforms();
    _setCustomUniforms();
    stopwatch.stop();
    // print('Setup uniforms took: ${stopwatch.elapsedMicroseconds} µs');
    int samplerIndex = 0;
    try {
      for (final input in _inputs) {
        final image = input.resolve();
        if (image == null) {
          // 在 Ping-Pong 反馈场景下，第一帧是没有 prevOutput 的，此时传入一个空白图像
          // 并且大部分 Ping-Pong 的代码中，基本都会对第一帧做特殊处理
          // In Ping-Pong feedback scenarios, the first frame has no prevOutput,
          // so we pass in a blank image. Most Ping-Pong code handles the first frame specially.
          if (_blankImage != null) {
            _shader!.setImageSampler(samplerIndex, _blankImage!);
            samplerIndex++;
          }
          continue;
        }
        _shader!.setImageSampler(samplerIndex, image);
        samplerIndex++;
      }
    } catch (e) {
      log('Error setting up shader samplers for $shaderAssetPath: $e');
      throw Exception('Failed to set up shader samplers for $shaderAssetPath: $e');
    }
  }

  void _setCustomUniforms() {
    final sortedSlots = _customUniforms.keys.toList()..sort();
    int offset = index;

    for (final slot in sortedSlots) {
      final value = _customUniforms[slot]!;

      if (value is double) {
        _shader!.setFloat(offset, value);
        offset += 1;
      } else if (value is int) {
        _shader!.setFloat(offset, value.toDouble());
        offset += 1;
      } else if (value is bool) {
        _shader!.setFloat(offset, value ? 1.0 : 0.0);
        offset += 1;
      } else if (value is Offset) {
        _shader!
          ..setFloat(offset, value.dx)
          ..setFloat(offset + 1, value.dy);
        offset += 2;
      } else if (value is Size) {
        _shader!
          ..setFloat(offset, value.width)
          ..setFloat(offset + 1, value.height);
        offset += 2;
      } else if (value is Color) {
        _shader!
          ..setFloat(offset, value.r)
          ..setFloat(offset + 1, value.g)
          ..setFloat(offset + 2, value.b)
          ..setFloat(offset + 3, value.a);
        offset += 4;
      } else if (value is List<double>) {
        for (int i = 0; i < value.length; i++) {
          _shader!.setFloat(offset + i, value[i]);
        }
        offset += value.length;
      }
    }
  }

  void _setChannelUniforms() {
    // Layout contract (in shader source, after iMouse):
    // - iChannelWrap   : vec4  -> 4 floats
    // - iChannelFilter : vec4  -> 4 floats
    // - iChannelResolution0..3 : vec2 * 4 -> 8 floats
    // Start index: 8 (iResolution=2, iTime=1, iFrame=1, iMouse=4).

    // Defaults.
    final wrapModes = <double>[0.0, 0.0, 0.0, 0.0];
    final filterModes = <double>[0.0, 0.0, 0.0, 0.0];
    final sizes = <double>[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    for (int i = 0; i < _inputs.length && i < 4; i++) {
      final input = _inputs[i];
      wrapModes[i] = input.wrap.uniformValue;
      filterModes[i] = input.filter.uniformValue;

      final image = input.resolve() ?? _blankImage;
      if (image == null) continue;
      sizes[i * 2] = image.width.toDouble();
      sizes[i * 2 + 1] = image.height.toDouble();
    }

    // Each block is try/catch for compatibility with shaders that don't declare these uniforms.
    try {
      _shader!
        ..setFloat(index++, wrapModes[0])
        ..setFloat(index++, wrapModes[1])
        ..setFloat(index++, wrapModes[2])
        ..setFloat(index++, wrapModes[3]);
    } catch (_) {
      // Intentionally ignored.
    }
    try {
      _shader!
        ..setFloat(index++, filterModes[0])
        ..setFloat(index++, filterModes[1])
        ..setFloat(index++, filterModes[2])
        ..setFloat(index++, filterModes[3]);
    } catch (_) {
      // Intentionally ignored.
    }

    try {
      _shader!
        ..setFloat(index++, sizes[0])
        ..setFloat(index++, sizes[1])
        ..setFloat(index++, sizes[2])
        ..setFloat(index++, sizes[3])
        ..setFloat(index++, sizes[4])
        ..setFloat(index++, sizes[5])
        ..setFloat(index++, sizes[6])
        ..setFloat(index++, sizes[7]);
    } catch (_) {
      // Intentionally ignored.
    }
  }

  /// 只需要返回着色器的输入，用来构建依赖图
  /// Only need to return shader inputs, used to build the dependency graph
  Iterable<ShaderBuffer> get _dependencies sync* {
    for (final input in _inputs) {
      if (input is ShaderBufferInput && !input.usePreviousFrame) {
        yield input.buffer;
      }
    }
  }

  @override
  void dispose() {
    log('Disposing ShaderBuffer: $shaderAssetPath');
    // Dispose images by identity to avoid double-dispose assertions.
    final images = Set<ui.Image>.identity();
    if (_output != null) images.add(_output!);
    if (_prevOutput != null) images.add(_prevOutput!);
    if (_blankImage != null) images.add(_blankImage!);
    for (final img in images) {
      img.dispose();
    }
    _output = null;
    _prevOutput = null;
    _blankImage = null;
    _isDisposed = true;
    super.dispose();
  }

  @override
  String toString() {
    return 'ShaderBuffer(name: $name, shaderAssetPath: $shaderAssetPath)';
  }
}
