part of 'package:shader_graph/shader_graph.dart';

class ShaderBuffer extends ChangeNotifier {
  ShaderBuffer(
    this.shaderAssetPath, {
    this.scale = 1.0,
    this.name,
    this.fixedOutputSize,
  });

  /// 着色器资源路径，不知道 Flutter 什么时候可以支持用 File 对象加载着色器
  /// Shader asset path. Not sure when Flutter will support loading shaders from File objects.
  final String shaderAssetPath;

  /// 缩放比例，可以以更低的分辨率渲染以提升性能
  /// Scale factor, can render at lower resolution for better performance
  double scale;
  final String? name;

  /// 当设置后，着色器输出会被渲染到这个固定的像素尺寸，
  /// 与 widget 大小 / devicePixelRatio / [scale] 无关。
  /// 这对于 Shadertoy 风格的数据 buffer（例如 14x14）以及
  /// 将虚拟像素扩展到多个物理像素的布局非常有用。

  /// When set, the shader output is rendered to this exact pixel size,
  /// independent of the widget size / devicePixelRatio / [scale].
  /// This is useful for Shadertoy-style data buffers (e.g. 14x14) and
  /// for layouts that expand virtual texels into multiple physical pixels.
  Size? fixedOutputSize;

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

  /// 添加一个 ShaderBuffer 作为输入，对应 shader 里的 iChannelN
  /// Adding a ShaderBuffer as input, corresponding to iChannelN in the shader
  ShaderBuffer feedShader(ShaderBuffer buffer, {WrapMode wrap = WrapMode.clamp}) {
    _inputs.add(ShaderBufferInput(buffer, wrap: wrap));
    return this;
  }

  /// 添加一个 ShaderBuffer 作为输入资源，从 assetPath 加载，对应 shader 里的 iChannelN
  /// Adding a ShaderBuffer as input resource, loading from assetPath,
  /// corresponding to iChannelN in the shader
  ShaderBuffer feedShaderFromAsset(String assetPath, {WrapMode wrap = WrapMode.clamp}) {
    _inputs.add(ShaderBufferInput(ShaderBuffer(assetPath), wrap: wrap));
    return this;
  }

  /// 添加一个图片资源作为输入，从 assetPath 加载，对应 shader 里的 iChannelN
  /// Adding an image resource as input, loading from assetPath,
  /// corresponding to iChannelN in the shader
  ShaderBuffer feedImageFromAsset(String assetPath, {WrapMode wrap = WrapMode.clamp}) {
    _inputs.add(AssetInput(assetPath: assetPath, wrap: wrap));
    return this;
  }

  /// 添加一个键盘输入作为输入，对应 shader 里的 iChannelN
  /// Adding a keyboard input as input, corresponding to iChannelN in the shader
  ShaderBuffer feedKeyboard({WrapMode wrap = WrapMode.clamp}) {
    _inputs.add(KeyboardInput(wrap: wrap));
    return this;
  }

  /// 添加反馈输入，对应 shader 里的 iChannelN
  /// Adding a feedback input, corresponding to iChannelN in the shader
  ShaderBuffer feedback({WrapMode wrap = WrapMode.clamp}) {
    _inputs.add(ShaderBufferInput(this, usePreviousFrame: true, wrap: wrap));
    return this;
  }

  /// 为了测试
  /// For testing
  ShaderBuffer feedEmpty() {
    _inputs.add(EmptyInput());
    return this;
  }

  /// 初始化着色器，如果使用 ShaderBufferWrapper 可以不需要手动调用
  /// Initialize the shader. If using ShaderBufferWrapper, manual invocation is not required.
  Future<void> init() async {
    try {
      ui.FragmentProgram program = await ui.FragmentProgram.fromAsset(shaderAssetPath);
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
  /// 这里之前花了很长的时间，去调试着色器渲染异常的问题
  /// 之前在 render 中将 _prevOutput 推进，这样会导致同一帧中
  /// 一些着色器拿到的是当前的输入，而对于 BufferX->BufferX 的反馈
  /// 是需要 PingPong 机制的。就像乒乓球
  /// 最简单的验证，就是把这段注释掉，然后运行 Brick Game 这个游戏
  ///
  /// Beginning of each frame, advance the feedback chain:
  /// prevOutput <- output
  ///
  /// Note: This must be done before rendering any buffers,
  /// or usePreviousFrame may read from "two frames ago", causing feedback divergence.
  /// This previously took a long time to debug shader rendering issues.
  /// Previously, _prevOutput was advanced in render(), which caused some shaders
  /// in the same frame to receive current inputs, while feedback for BufferX->BufferX
  /// requires a PingPong mechanism, like table tennis.
  void _beginFrame() {
    _prevOutput?.dispose();
    _prevOutput = _output;
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

    // `toByteData()` is an expensive GPU->CPU readback. Only do it when
    // somebody is actually listening (e.g. debug UI like Data Grid).
    if (hasListeners) {
      frameData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    }
    picture.dispose();

    // prevOutput 的推进由 ShaderGraph 在“每帧开始”统一调用 beginFrame() 处理，
    // 从而保证 usePreviousFrame 语义稳定（=上一帧）且与 buffer 执行顺序无关。
    // 这里保留旧逻辑（注释）便于对照/回滚：
    // _prevOutput?.dispose();
    // _prevOutput = _output;

    _output = img;
    if (hasListeners) notifyListeners();
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
    // 这里不能把 _output dispose 掉，下一帧还需呀把这个作为 prevOutput 使用
    // prevOutput 的推进由 beginFrame() 统一处理（每帧一次）。
    // 这里保留旧代码（注释）便于对照：
    // _prevOutput?.dispose();
    // _prevOutput = _output;
    _output = img;

    // Keep sync rendering for display, but still allow debug UIs to read back
    // RGBA bytes. `toByteData()` is async, so we trigger it out-of-band.
    // For the Static Vec4 Grid debug UI, a single readback is sufficient.
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

  void renderShader({required RenderData data}) {
    // Render target size.
    final renderSize = fixedOutputSize ?? (data.logicalSize * data.dpr * scale);

    // Uniform space (Shadertoy semantics): iResolution / iMouse coordinate system.
    final surfaceSize = data.logicalSize * data.dpr * scale;
    final uniformSize = useSurfaceSizeForIResolution ? surfaceSize : renderSize;
    Stopwatch stopwatch = Stopwatch()..start();
    _shader!
      ..setFloat(0, uniformSize.width)
      ..setFloat(1, uniformSize.height);

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
      ..setFloat(2, data.time)
      ..setFloat(3, data.iFrame)
      ..setFloat(4, mx)
      ..setFloat(5, my)
      ..setFloat(6, mz)
      ..setFloat(7, mw);

    // Optional Shadertoy-style per-channel wrap modes.
    // Encoded into a vec4 `iChannelWrap` (x/y/z/w == channel 0..3).
    // This is implemented shader-side as a UV transform, not as a real GPU sampler state.
    _setChannelWrapUniforms();
    _setChannelResolutionUniforms();
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

  void _setChannelWrapUniforms() {
    // Default to clamp.
    final modes = <double>[0.0, 0.0, 0.0, 0.0];
    for (int i = 0; i < _inputs.length && i < 4; i++) {
      modes[i] = _inputs[i].wrap.uniformValue;
    }

    // `iChannelWrap` is expected to be declared after `iMouse` in shader source,
    // so its float indices start at 8 (iResolution=2, iTime=1, iFrame=1, iMouse=4).
    // If a shader doesn't declare it, setting these floats may throw; swallow for compatibility.
    try {
      _shader!
        ..setFloat(8, modes[0])
        ..setFloat(9, modes[1])
        ..setFloat(10, modes[2])
        ..setFloat(11, modes[3]);
    } catch (_) {
      // Intentionally ignored.
    }
  }

  void _setChannelResolutionUniforms() {
    // Default to 0 to avoid accidental division by zero in shaders; users can guard.
    final sizes = <double>[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    for (int i = 0; i < _inputs.length && i < 4; i++) {
      final input = _inputs[i];
      final image = input.resolve() ?? _blankImage;
      if (image == null) continue;
      sizes[i * 2] = image.width.toDouble();
      sizes[i * 2 + 1] = image.height.toDouble();
    }

    // `iChannelResolution0..3` are expected to be declared after `iChannelWrap` in shader source,
    // so their float indices start at 12.
    // If a shader doesn't declare them, setting these floats may throw; swallow for compatibility.
    try {
      _shader!
        ..setFloat(12, sizes[0])
        ..setFloat(13, sizes[1])
        ..setFloat(14, sizes[2])
        ..setFloat(15, sizes[3])
        ..setFloat(16, sizes[4])
        ..setFloat(17, sizes[5])
        ..setFloat(18, sizes[6])
        ..setFloat(19, sizes[7]);
    } catch (_) {
      // Intentionally ignored.
    }
  }

  /// 只需要返回着色器的输入，用来构建依赖图
  /// Only need to return shader inputs, used to build the dependency graph
  Iterable<ShaderBuffer> get _dependencies sync* {
    for (final input in _inputs) {
      if (input is ShaderBufferInput) {
        yield input.buffer;
      }
    }
  }

  @override
  void dispose() {
    _output?.dispose();
    _prevOutput?.dispose();
    _output = null;
    _prevOutput = null;
    _blankImage?.dispose();
    _blankImage = null;
    _isDisposed = true;
    super.dispose();
  }

  @override
  String toString() {
    return 'ShaderBuffer(name: $name, shaderAssetPath: $shaderAssetPath)';
  }
}
