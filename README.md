# Shader Graph

`shader_graph` is a real-time, multi-pass shader execution framework for Flutter
`FragmentProgram/RuntimeEffect`.

It runs multiple `.frag` passes as a **render graph** (Shadertoy-style
BufferA/BufferB/Main, feedback, ping-pong).

If you just want to show a single shader quickly, you can use a simple widget
(for example `ShaderSurfaceWrapper.buffer`).

When you need more complex pipelines (multi-pass / multiple inputs / feedback /
ping-pong), use `ShaderBuffer` to declare inputs and dependencies.
The framework performs a topological schedule per frame and forwards each pass
output as a `ui.Image` to downstream passes.

English | [中文 README](README-CH.md)

## Screenshots

### Demos

<table>
  <tr>
    <td>
      <img width="200px" src="https://raw.githubusercontent.com/nightmare-space/shader_graph/main/screenshot/IFrame.png">
      <br>
      IFrame
    </td>
    <td>
      <img width="200px" src="https://raw.githubusercontent.com/nightmare-space/shader_graph/main/screenshot/Mac%20Wallpaper.png">
      <br>
      Mac Wallpaper
    </td>
    <td>
      <img width="200px" src="https://raw.githubusercontent.com/nightmare-space/shader_graph/main/screenshot/Noise%20Lab.png">
      <br>
      Noise Lab
    </td>
  </tr>
  <tr>
    <td>
      <img width="200px" src="https://raw.githubusercontent.com/nightmare-space/shader_graph/main/screenshot/Text.png">
      <br>
      Text
    </td>
    <td></td>
    <td></td>
  </tr>
</table>

### Games

<table>
  <tr>
    <td>
      <img width="200px" src="https://raw.githubusercontent.com/nightmare-space/shader_graph/main/screenshot/Bricks%20Game.png">
      <br>
      Bricks Game
    </td>
    <td>
      <img width="200px" src="https://raw.githubusercontent.com/nightmare-space/shader_graph/main/screenshot/Pacman%20Game.png">
      <br>
      Pacman Game
    </td>
    <td></td>
  </tr>
</table>

### Float

<table>
  <tr>
    <td>
      <img width="200px" src="https://raw.githubusercontent.com/nightmare-space/shader_graph/main/screenshot/Float%20Test.png">
      <br>
      Float Test
    </td>
    <td></td>
    <td></td>
  </tr>
</table>

## Features

- [x] Multi-pass (use a shader as a buffer for another shader)
- [x] Use images as shader inputs
- [x] Self feedback / ping-pong
- [x] Mouse input
- [x] Automatic topological sorting
- [x] Float precision workaround (requires additional porting code)
- [ ] Render a Widget into a texture and feed it as an input buffer

**Float support (RGBA8 feedback)**

Flutter feedback textures are typically RGBA8, which makes storing arbitrary
floating-point state unreliable.
This project provides a standard porting scheme (`sg_feedback_rgba8`) to encode
scalars into RGB (24-bit) and preserve Shadertoy-like “one texel = vec4” via
4-lane horizontal packing.

## Motivation

My understanding of shaders used to be pretty vague.
A friend recommended [The Book of Shaders](https://thebookofshaders.com/).
While I was reading it, I realized how fascinating Shadertoy shaders are — some
of them are basically complete games.
I wanted to run (ported) Shadertoy shaders inside Flutter.

Thanks to the author of
[shader_buffers](https://github.com/alnitak/shader_buffers), which helped me get
started with shader ports on Flutter.

While using it, I found gaps between what I needed and what existing Flutter
shader frameworks provide, so I started this project.

This project was built with help from AI (mostly GPT-5.2), but I tried to keep
myself in the driver seat. I wrote/iterated the prompts, and spent significant
time debugging and validating behavior.

The Dart-side design follows my preferences:
- Simple to use
- Powerful when needed
- Reasonable architecture
- Readable code
- Plenty of Chinese/English comments

## Usage

For a complete app, see [example](example/lib/main.dart).

### Minimal runnable examples

**1) Single shader (Widget)**
```dart
SizedBox(
  height: 240,
  child: ShaderSurfaceWrapper.buffer('shaders/frame/IFrame Test.frag'),
)
```

**2) Two passes (A → Main)**
```dart
ShaderSurfaceWrapper.builder(() {
  final a = 'shaders/multi_pass/MacOS Monterey wallpaper BufferA.frag'
      .shaderBuffer;
  final main = 'shaders/multi_pass/MacOS Monterey wallpaper.frag'
      .shaderBuffer
    ..feedShader(a);
  return [a, main];
})
```

**3) Feedback (A → A, plus a Main display)**
```dart
ShaderSurfaceWrapper.builder(() {
  final a = 'shaders/game_ported/Bricks Game BufferA.frag'.shaderBuffer;
  a.fixedOutputSize = const Size(14 * 4.0, 14);
  a.feedback().feedKeyboard();

  final main = 'shaders/game_ported/Bricks Game.frag'.shaderBuffer
    ..feedShader(a);
  return [a, main];
})
```

Shadertoy shaders usually need porting before they can run on Flutter.
This repo includes porting prompts/tools to help with that.

### ShaderBuffer

`ShaderBuffer` can be a final render pass, or an intermediate buffer that feeds
another shader.

```dart
final buffer = ShaderBuffer('$asset_path');
```

**Feed another shader as an input**
```dart
buffer.feedShader(anotherBuffer);
buffer.feedShaderFromAsset("$asset_path");
```

**Keyboard input**
```dart
buffer.feedKeyboard();
```

**Feed an asset image**
> Commonly used for noise textures. This path still has issues and will be
> improved.

```dart
buffer.feedImageFromAsset('$noise_asset_path');
```

**Ping-pong / feedback**
This is common on Shadertoy.

```dart
buffer.feedback();
```

### ShaderSurfaceWrapper.buffer

If you only need to render a single `.frag`, this is usually the simplest.

```dart
ShaderSurfaceWrapper.buffer('$shader_asset_path');
```

You can place it anywhere; usually you need to constrain its height.

```dart
Column(
  children: [
    Text('This is a shader:'),
    ShaderSurfaceWrapper.buffer('$shader_asset_path'),
  ],
)
```

`ShaderSurfaceWrapper.buffer` accepts either a String path or a `ShaderBuffer`.
Passing a `ShaderBuffer` is useful when the shader has inputs.

```dart
Builder(builder: (context) {
  final mainBuffer = ShaderBuffer('$shader_asset_path');
  mainBuffer.feedImageFromAsset('$noise_asset_path');
  return ShaderSurfaceWrapper.buffer(mainBuffer);
})
```

### Using Extensions

When multiple `ShaderBuffer`s need inputs, this can get verbose:

```dart
Column(
  children: [
    Text('This is a shader:'),
    Builder(builder: (context) {
      final mainBuffer = ShaderBuffer('$shader_asset_path');
      mainBuffer.feedImageFromAsset('$noise_asset_path');
      return ShaderSurfaceWrapper.buffer(mainBuffer);
    }),
    Builder(builder: (context) {
      final mainBuffer = ShaderBuffer('$shader_asset_path');
      mainBuffer.feedImageFromAsset('$noise_asset_path');
      return ShaderSurfaceWrapper.buffer(mainBuffer);
    }),
  ],
)
```

With extensions it can be shorter:

```dart
ShaderSurfaceWrapper.buffer(
  '$shader_asset_path'.shaderBuffer
      .feedImageFromAsset('$noise_asset_path'),
)
```

### ShaderSurfaceWrapper.builder

The examples above are either a single shader or a simple chain (A→B→C).
For more complex graphs (A→A, A→B, B→C, A/B/C→D), use `builder`:

```dart
return ShaderSurfaceWrapper.builder(
  () {
    final bufferA = 'shaders/game_ported/Bricks Game BufferA.frag'
        .feedback()
        .feedKeyboard();
    final mainBuffer = 'shaders/game_ported/Bricks Game.frag'
        .feedShaderBuffer(bufferA);
    // Standard scheme: physical width = virtual * 4
    bufferA.fixedOutputSize = const Size(14 * 4.0, 14);

    return [bufferA, mainBuffer];
  },
);
```

## Topological sorting

For many Shadertoy multi-pass shaders, the final list of buffers can be
topologically sorted.

Inputs *within a single buffer* must still follow the Shadertoy `iChannelN`
order.

That means you can provide `[A, B, C, D]` or `[D, C, B, A]` (etc) and the final
result should be the same.

```dart
class PacmanGame extends StatefulWidget {
  const PacmanGame({super.key});

  @override
  State<PacmanGame> createState() => _PacmanGameState();
}

class _PacmanGameState extends State<PacmanGame> {
  late final List<int> _order;

  @override
  void initState() {
    super.initState();
    _order = [0, 1, 2]..shuffle(Random(DateTime.now().microsecondsSinceEpoch));
  }

  @override
  Widget build(BuildContext context) {
    return ShaderSurfaceWrapper.builder(
      () {
        final bufferA = 'shaders/game_ported/Pacman Game BufferA.frag'.shaderBuffer;
        final bufferB = 'shaders/game_ported/Pacman Game BufferB.frag'.shaderBuffer;
        final mainBuffer = 'shaders/game_ported/Pacman Game.frag'.shaderBuffer;
        bufferA.fixedOutputSize = const Size(32 * 4.0, 32);
        bufferA.feedback().feedKeyboard();
        bufferB.feedShader(bufferA);
        mainBuffer.feedShader(bufferA).feedShader(bufferB);

        final buffers = [bufferA, bufferB, mainBuffer];
        return _order.map((i) => buffers[i]).toList(growable: false);
      },
    );
  }
}
```

## toImageSync memory retention

[toImageSync retains display list which can lead to surprising memory retention](https://github.com/flutter/flutter/issues/138627)

This project hit a real-world pitfall: on Flutter 3.38.5 (macOS), `toImageSync`
can still lead to noticeable memory growth.
In my tests, the app would keep consuming physical RAM, then swap, and the total
usage could become huge.

Current mitigation in this repo:
- Use async `toImage()` instead (avoid the risky `toImageSync` path)
- Avoid triggering conversion every frame (too expensive)
- Use a Ticker/throttling strategy: only schedule the next update when a new
  image/frame is ready