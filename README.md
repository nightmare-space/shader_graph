# Shader Graph

`shader_graph` is a real-time multi-pass shader execution framework for Flutter `FragmentProgram / RuntimeEffect`.

It is now even capable of running a **fully shader-driven game**.

![Bricks Game](https://github.com/nightmare-space/shader_graph/blob/main/screenshot/game/Bricks%20Game.gif?raw=true)

This framework connects multiple `.frag` shaders using a **render graph** model, fully supporting Shadertoy-style BufferA / BufferB / Main passes, as well as feedback / ping-pong patterns.

It supports keyboard input, mouse input, image input, widget input, and Shadertoy-style wrap modes (Clamp / Repeat / Mirror), filter modes, etc.

If you only want to quickly display a shader, you can directly use a simple widget (for example, `ShaderSurface.auto`).

When you need more complex pipelines (multi-pass / multiple inputs / feedback / ping-pong), you should explicitly declare inputs and dependencies using `ShaderBuffer`.

The source code of `shader_graph` itself includes extensive Chinese and English comments for easier reading and understanding.

Forgive me, I have not done a good job documenting this project. For those unfamiliar with shaders, these documents can be quite challenging. I have tried my best to make them as simple as possible, but a powerful library inevitably comes with a certain learning curve.

English | [中文](README.zh.md)

## Topics

- [Shader Graph](#shader-graph)
  - [Topics](#topics)
  - [Roadmap](#roadmap)
  - [Quick Start](#quick-start)
    - [Minimal runnable examples](#minimal-runnable-examples)
      - [1) Single shader (Widget)](#1-single-shader-widget)
      - [2) Two passes (A → Main)](#2-two-passes-a--main)
      - [3) feedback (A → A, plus a Main display)](#3-feedback-a--a-plus-a-main-display)
  - [Foreword](#foreword)
    - [`shader_graph` can already support very complex multi-pass scenarios](#shader_graph-can-already-support-very-complex-multi-pass-scenarios)
    - [Float support (RGBA8 feedback) solution](#float-support-rgba8-feedback-solution)
    - [`texelFetch` support](#texelfetch-support)
  - [Examples](#examples)
    - [Example Screenshots](#example-screenshots)
  - [Ping-Pong \& Multi-Pass \& RGBA8 Feedback](#ping-pong--multi-pass--rgba8-feedback)
  - [Wrap \& Filter](#wrap--filter)
    - [Keyboard \& Mouse \& Widget Input](#keyboard--mouse--widget-input)
  - [Others](#others)
  - [ShaderBuffer](#shaderbuffer)
  - [ShaderBuffer.feed](#shaderbufferfeed)
    - [Adding a Widget as input](#adding-a-widget-as-input)
    - [Adding another shader as input](#adding-another-shader-as-input)
    - [Adding keyboard as input](#adding-keyboard-as-input)
    - [Adding an image asset as input](#adding-an-image-asset-as-input)
    - [feedback / ping-pong](#feedback--ping-pong)
    - [Custom ShaderInput](#custom-shaderinput)
    - [Wrap (repeat / mirror / clamp)](#wrap-repeat--mirror--clamp)
    - [Custom Output Size](#custom-output-size)
  - [ShaderSurface.auto](#shadersurfaceauto)
  - [ShaderSurface.builder](#shadersurfacebuilder)
  - [Animation Control](#animation-control)
    - [Basic Usage](#basic-usage)
    - [Integration](#integration)
    - [Behavior](#behavior)
  - [Topological Sorting](#topological-sorting)
  - [toImageSync Memory Leak](#toimagesync-memory-leak)
  - [Copilot](#copilot)
  - [ShaderToy → Flutter porting guide](#shadertoy--flutter-porting-guide)


---

## Roadmap

- [x] Using one shader as a buffer input to another shader (Multi-Pass)
- [x] Using images as shader buffer inputs
- [x] Rendering a Widget into a texture and using it as a buffer input
- [x] Feedback input (Ping-Pong: previous frame → next frame)
- [x] Mouse input & Keyboard input
- [x] Automatic topological sorting
- [x] texelFetch (texel size calculated automatically via macros)
- [x] Shadertoy-style wrap modes (Clamp / Repeat / Mirror)
- [x] Shadertoy-style filters (Linear / Nearest / Mipmap)
  - [x] Nearest / Linear: basically supported, with minor differences
  - [ ] Mipmap: not supported yet; exploring mipmap-like approaches feasible in Flutter
- [x] Animation control (ShaderController for play/pause functionality)
- [x] Custom Uniforms
- [ ] Camera input & Audio input & Audio output (shader_graph itself will not integrate these features later, but will provide a feasible solution for them)

---

## Quick Start

First, one important point must be clarified:

**Shadertoy shaders must be ported before they can run in Flutter.**

**And currently, you must use the common_header.frag/main_shadertoy.frag in the example/shaders/common directory; otherwise, Wrap/Filter/texelFetch cannot be implemented. If you need to support rgba8 feedback, you also need to use sg_feedback_rgba8.frag.**

This project provides a helper prompt for porting: `port_shader.prompt.md`

The basic workflow is as follows:

1. Open the shader file you want to port (it is recommended to place it directly in your project)
2. Enter the corresponding prompt in Copilot or other AI tools

```text
Follow instructions in [port_shader.prompt.md](.github/prompts/port_shader.prompt.md).
```

### Minimal runnable examples

#### 1) Single shader (Widget)

```dart
SizedBox(
  height: 240,
  // shader_asset_main ends with .frag
  child: ShaderSurface.auto('$shader_asset_main'),
)
```

#### 2) Two passes (A → Main)

See [multi_pass.dart](example/lib/multi_pass.dart)

```dart
ShaderSurface.builder(() {
  final bufferA = '$shader_asset_buffera'.shaderBuffer;
  final main = '$shader_asset_main'.shaderBuffer.feed(bufferA);
  return [bufferA, main];
})
```

#### 3) feedback (A → A, plus a Main display)

See [bricks_game.dart](example/lib/game/bricks_game.dart)

```dart
ShaderSurface.builder(() {
  final bufferA = '$asset_shader_buffera'.feedback().feedKeyboard();
  final mainBuffer = '$asset_shader_main'.feed(bufferA);
  // Standard scheme: physical width = virtual * 4
  bufferA.fixedOutputSize = const Size(14 * 4.0, 14);
  return [bufferA, mainBuffer];
})
```

## Foreword

I found the shaders on Shadertoy extremely interesting. Some of them are essentially complete games, which led me to a question:

**Could these shaders be ported to run in Flutter?**

First of all, I want to thank the [shader_buffers](https://github.com/alnitak/shader_buffers) project, which initially enabled me to port some Shadertoy shaders to Flutter.

However, during practical use, I gradually realized that its design and functionality differed significantly from my needs. Some of these issues were addressed by contributing fixes via pull requests.

As my requirements continued to grow, I realized that the problem was not limited to shader_buffers. Instead, it reflected an entire category of issues that almost all existing Flutter shader frameworks had not addressed.

As a result, `shader_graph` was born.

### `shader_graph` can already support very complex multi-pass scenarios

Many of the stunning effects on ShaderToy are produced by mixing multiple shaders and various inputs. Most existing Flutter shader rendering solutions are essentially **single-pass**, making it very difficult to implement true multi-pass feedback scenarios.

It is even more unrealistic to achieve a full ShaderToy-style pipeline with **multi-pass + feedback + cyclic dependencies + filter + wrap**.

Take this shader as an example: [expansive reaction-diffusion](https://www.shadertoy.com/view/4dcGW2)

The detailed dependency graph is as follows:

```text
     ┌─────┐                  ┌───────┐
  ┌──|     |◀─────────────────| Noise | 
  |  |  A  |◀────────────┐    └───┬───┘ 
  └─▶│     │◀──────┐     |        |     
     └─┬─┬─┘       │     |        |     
  ┌────┘ │         │     |        |     
  |      ▼         │     |        |     
  |   ┌─────┐    ┌─┴─┐   |        |     
  |   │  B  │    | D |   |        |
  |   └──┬──┘    └───┘   |        |     
  |      ▼               |        |     
  |   ┌─────┐            |        |     
  |   │  C  │────────────┘        |     
  |   └──┬──┘                     │     
  |      └──────┐                 |
  |             ▼                 |
  |      ┌─────────────┐          |
  └─────▶│    Image    │◀─────────┘
         └─────────────┘
```

**A** depends on its own previous frame, **C** depends on A’s previous frame, and **A** in turn depends on C’s previous frame, forming a **cross-frame cyclic dependency**. This is now solvable.

> The visual result is slightly inconsistent. Once Flutter Impeller supports more sampler features, the reproduction quality should improve—especially for `texelFetch`, filter, and wrap behavior.

Use Three.js version: <https://nightmare-space.github.io/shader_graph/three.js.html>

Use Flutter(ShaderGraph) version: <https://nightmare-space.github.io/shader_graph?example=ReactionDiffusion>

Comparison of the two: <https://nightmare-space.github.io/shader_graph/combined.html>

![Three.js vs ShaderGraph](screenshot/multi-pass/ThreeJs%20VS%20Shader%20Graph.png)

---

### Float support (RGBA8 feedback) solution

Flutter feedback textures are typically **RGBA8**, which cannot reliably store arbitrary floating-point state.

This project provides a unified migration solution: `sg_feedback_rgba8`.  
Scalars are encoded into RGB (24-bit) and packed horizontally into 4 lanes, preserving the semantic of **“one texel = vec4”**.

---

### `texelFetch` support

Provided via `common_header.frag`:

- `SG_TEXELFETCH`
- `SG_TEXELFETCH0..3`

These macros replace native `texelFetch` calls and automatically obtain channel resolutions from `iChannelResolution0..3`. Note that the result may still be affected by Flutter’s internal filtering behavior.

---

## Examples

I’ve already created the [awesome_flutter_shaders](https://github.com/nightmare-space/awesome_flutter_shaders) project using this library.

It is currently the most comprehensive collection of examples, containing 100+ Flutter ports of Shadertoy shaders, and is highly recommended as a direct reference.

The project includes the current [example](example/lib/main.dart) shown in the screenshot above, as well as dedicated examples covering various features and use cases.

Even better, the shader_graph example and most of the shaders in awesome_flutter_shaders support Flutter Web.

You can visit the online demos to experience the power of shaders and see what kind of results you can achieve with this library:

- [shader_graph example web](https://nightmare-space.github.io/shader_graph)
- [awesome_flutter_shaders web](https://nightmare-space.github.io/awesome_flutter_shaders)

---

### Example Screenshots

## Ping-Pong & Multi-Pass & RGBA8 Feedback

<table>
  <tr>
    <td>
      <img width="400px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/game/Bricks%20Game.png?raw=true">
      <br>
      Bricks Game
    </td>
    <td>
      <img width="400px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/game/Pacman%20Game.png?raw=true">
      <br>
      Pacman Game
    </td>
  </tr>
</table>


## Wrap & Filter

The following examples demonstrate the decisive impact of wrap and filter modes on shader results.  
Without support for these features, the visual output differs significantly from Shadertoy.

<table>
  <tr>
    <td>
      <img width="400px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/wrap%20filter/Wrap%20Mode.png?raw=true">
      <br>
      Raw Image
    </td>
    <td>
      <img width="400px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/wrap%20filter/Wrap%20Transition%20Burning.png?raw=true">
      <br>
      Transition Burning
    </td>
    <td>
      <img width="400px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/wrap%20filter/Wrap%20Tissue.png?raw=true">
      <br>
      Tissue
    </td>
  </tr>
</table>

<table>
  <tr>
    <td>
      <img width="400px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/wrap%20filter/Wrap%20Black%20Hole.png?raw=true">
      <br>
      Black Hole
    </td>
    <td>
      <img width="400px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/wrap%20filter/Wrap%20Broken%20Time%20Gate.png?raw=true">
      <br>
      Broken Time Gate
    </td>
    <td>
      <img width="400px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/wrap%20filter/Wrap%20Goodbye%20Dream%20Clouds.png?raw=true">
      <br>
      Goodbye Dream Clouds
    </td>
  </tr>
</table>

### Keyboard & Mouse & Widget Input

> Note: These visuals are not Flutter UI elements. They are rendered entirely by shaders and respond to keyboard input in real time.

<table>
  <tr>
    <td>
      <img width="400px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/input/Keyboard%20Input.png?raw=true">
      <br>
      Keyboard Input
    </td>
    <td>
      <img width="400px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/input/Mouse%20Input.png?raw=true">
      <br>
      Mouse Input
    </td>
    <td>
      <img width="400px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/input/Widget%20Input.png?raw=true">
      <br>
      Widget Input
    </td>
  </tr>
</table>

## Others

<table>
  <tr>
    <td>
      <img width="300px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/other/Custom%20Uniforms.png?raw=true">
      <br>
      Custom Uniforms
    </td>
    <td>
      <img width="300px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/other/IFrame.png?raw=true">
      <br>
      IFrame
    </td>
    <td>
    </td>
  </tr>
  <tr>
    <td>
      <img width="300px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/other/Text%20Render.png?raw=true">
      <br>
      Text Render
    </td>
    <td>
      <img width="300px" src="https://raw.githubusercontent.com/nightmare-space/shader_graph/main/screenshot/other/Float%20Test.png">
      <br>
      Float Test
    </td>
  </tr>
</table>

---

## ShaderBuffer

`ShaderBuffer` can serve both as a final rendering shader and as an intermediate `Buffer` input to other shaders.

It is the core component for building Widget `ShaderSurface`.

Typically created via extension:

```dart
'$asset_path'.shaderBuffer;
```

It is equivalent to:

```dart
final buffer = ShaderBuffer('$asset_path');
```

`ShaderBuffer` can be used with the following APIs:

- `ShaderSurface.auto`: Automatically determines input types
- `ShaderSurface.builder`: Suitable for complex multi-pass scenarios, The builder ultimately calls buffers, but the builder provides a function callback that allows developers to optimize Widget code structure

```dart
// path ends with .frag
final buffer = '$shader_asset_path'.shaderBuffer;
ShaderSurface.auto(buffer);
final shader_asset_path = '$shader_asset_path';
ShaderSurface.auto(shader_asset_path);
ShaderSurface.builder(() {
  // ...
  return [bufferA, bufferB, mainBuffer];
});
ShaderSurface(buffers: [bufferA, bufferB, mainBuffer]);
```

## ShaderBuffer.feed

ShaderBuffer supports multiple input sources to simulate iChannel behavior in Shadertoy.

Currently supported input types include:

- Other ShaderBuffers
- Images (ui.Image / Asset)
- Widgets
- Keyboard input
- Mouse input
- Built-in uniforms such as time and resolution

`ShaderBuffer.feed` is used to bind **an input source** to the current `ShaderBuffer`. Based on the type passed in, it ultimately calls the corresponding method. If it's a string, it determines the method based on the string suffix:

- `feedWidgetInput(Widget)`
- `feedShader(ShaderBuffer)`
- `feedShaderFromAsset(String)`
- `feedImageFromAsset(String)`

Of course, you can also directly call the original APIs.

### Adding a Widget as input

```dart
final imageWidget = Text('Hello Flutter ShaderGraph!');
buffer.feed(imageWidget);
```

### Adding another shader as input

```dart
final otherBuffer = '$other_shader_asset_path'.shaderBuffer;
buffer.feed(otherBuffer);
// or
final otherBuffer = ShaderBuffer('$other_shader_asset_path');
buffer.feedShader(otherBuffer);
```

### Adding keyboard as input

```dart
buffer.feedKeyboard();
```

### Adding an image asset as input

> Typically used to input noise, textures, etc.

This part can be referenced from\
[awesome_flutter_shaders](https://github.com/mengyanshou/awesome_flutter_shaders/tree/main/assets)

```dart
// path ends with .png/.jpg/..., not .frag
buffer.feed('$image_asset_path');
```

You can call `feed` multiple times to bind multiple inputs to the current `ShaderBuffer`, thereby building more complex dependency relationships.

> Note that this order must match the iChannel order defined by Shadertoy.

```dart
final imageWidget = Image.asset('$image_asset_path');
final buffer = '$shader_asset_path'.shaderBuffer
  // path ends with .frag
  // will call feedShaderFromAsset
  .feed('$texture_asset_path1')
  // path ends with .png/.jpg
  // will call feedImageFromAsset
  .feed('$texture_asset_path2')
  // will call feedWidgetInput
  .feed(imageWidget)
  .feedback()
  .feedKeyboard();
```

### feedback / ping-pong

In Shadertoy, feedback is a very common pattern, for example:

- Particle simulations
- Fluid simulations
- Cellular automata
- Game logic entirely driven by shaders

```dart
final bufferA = '$asset_shader_buffera'.feedback();
```

After enabling feedback:

- The input of the current frame will include the output of the previous frame
- The framework automatically maintains double buffering (ping-pong)
- Users do not need to manually manage texture swapping

You can also continue to feed other inputs while using feedback:

```dart
final bufferA =
  '$asset_shader_buffera'
    .shaderBuffer
    .feedback()
    .feedKeyboard();
```

### Custom ShaderInput

Currently, customization space is limited, and there is no suitable callback timing for developers to update. However, by implementing a `ShaderInput`, custom input sources can still be achieved. For example, camera output streams, audio streams, etc., may be implemented in the future.

```dart
abstract class ShaderInput {
  Image? resolve();

  /// UV wrap semantics expected by the shader.
  ///
  /// Defaults to clamp for compatibility.
  WrapMode get wrap => WrapMode.clamp;

  /// Filter semantics expected by the shader.
  ///
  /// Defaults to linear for compatibility.
  FilterMode get filter => FilterMode.linear;
}
```

---

### Wrap (repeat / mirror / clamp)

Flutter Runtime Shader does not directly expose sampler wrap / filter states.

This project simulates wrap behavior via the `iChannelWrap` uniform and UV transformations inside the shader.

Set wrap for each input on the Dart side:

```dart
final buffer = '$shader_asset_path'.shaderBuffer;
buffer.feed('$texture_asset_path', wrap: WrapMode.repeat);
```

When sampling in the shader, you **must** use the macros provided by `common_header.frag`:

- `SG_TEX0`
- `SG_TEX1`
- `SG_TEX2`
- `SG_TEX3`

Do not directly use `texture(iChannelN, uv)`.

---

### Custom Output Size

By default, the output size of each `ShaderBuffer` is the same as the final Widget size.

However, in some scenarios, you may want to:

- Perform computation at a lower resolution (performance optimization)  
- Use a fixed logical resolution (e.g. pixel-art games)  
- Explicitly control the size of feedback buffers  

In such cases, you can explicitly specify the output size:

```dart
buffer.fixedOutputSize = const Size(64, 64);
```

In game examples, a common approach is:

- Use a logical resolution (such as 14×14)  
- Physical output width = logical width × 4 (RGBA8 feedback)  

---

## ShaderSurface.auto

`ShaderSurface.auto` returns a Widget that can be directly used to display a shader.

```dart
Center(
  child: ShaderSurface.auto('$shader_asset_path'),
)
```

You can place it anywhere in the Widget tree, and it usually needs a height constraint:

```dart
Column(
  children: [
    Text('This is a shader:'),
    Expanded(
      child: ShaderSurface.auto('$shader_asset_path'),
    ),
  ],
)
```

`ShaderSurface.auto` supports passing in:

- String (shader asset path)  
- ShaderBuffer  
- List\<ShaderBuffer>  

When a shader has inputs, passing a ShaderBuffer directly is more appropriate.

```dart
Builder(builder: (context) {
  final mainBuffer = '$shader_asset_path'.shaderBuffer;
  mainBuffer.feed('$noise_asset_path');
  return ShaderSurface.auto(mainBuffer);
}),
```

Or using the extension:

```dart
ShaderSurface.auto(
  '$shader_asset_path'.shaderBuffer.feed('$noise_asset_path'),
);
```

For example, when multiple ShaderBuffers all require inputs, it becomes:

```dart
Column(
  children: [
    Text('This is a shader:'),
    Builder(builder: (context) {
        final mainBuffer = ShaderBuffer('$shader_asset_path');
        mainBuffer.feedImageFromAsset('$noise_asset_path');
        return ShaderSurface.auto(mainBuffer);
    }),
    Builder(builder: (context) {
        final mainBuffer = ShaderBuffer('$shader_asset_path');
        mainBuffer.feedImageFromAsset('$noise_asset_path');
        return ShaderSurface.auto(mainBuffer);
    }),
  ],
)
```

With extensions, this can be simplified to:

```dart
Column(
  children: [
    Text('This is a shader:'),
    ShaderSurface.auto(
      '$shader_asset_path'.feed('$noise_asset_path'),
    ),
    ShaderSurface.auto(
      '$shader_asset_path'.feed('$noise_asset_path'),
    ),
  ],
)
```

## ShaderSurface.builder

The previous examples only involve a single shader.  
For more complex pipelines such as:

```text
┌─────┐    ┌─────┐    ┌────────┐
│  A  │───▶│  B  │───▶│  Main  │
│ ↺ A │    └─────┘    └────────┘
└─────┘
```

For such multi-pass scenarios, you can use `ShaderSurface.builder` to build the entire render graph.

```dart
ShaderSurface.builder(() {
  final bufferA = '$asset_shader_buffera'.feedback();
  final bufferB = '$asset_shader_bufferb'.feed(bufferA);
  final mainBuffer = '$asset_shader_main'.feed(bufferB);
  return [bufferA, bufferB, mainBuffer];
})
```

## Animation Control

ShaderController provides simple play/pause functionality for shader animations.

### Basic Usage

```dart
// Create a controller
final controller = ShaderController();

// Use with ShaderSurface
ShaderSurface.auto(
  'shaders/wrap/Transition Burning.frag',
  shaderController: controller,
);

// Control playback
controller.pause();   // Pause animation
controller.resume();  // Resume animation  
controller.toggle();  // Toggle play/pause state

// Check current state
bool isPaused = controller.isPaused;
```

### Integration

ShaderController can be passed to all ShaderSurface factory methods:

```dart
// With ShaderSurface.auto
ShaderSurface.auto(
  'shaders/example.frag',
  shaderController: controller,
);

// With ShaderSurface.builder  
ShaderSurface.builder(
  () {
    final bufferA = 'shaders/BufferA.frag'.shaderBuffer.feedback();
    final main = 'shaders/Main.frag'.shaderBuffer.feed(bufferA);
    return [bufferA, main];
  },
  shaderController: controller,
);

// With ShaderSurface.buffers
ShaderSurface.buffers(
  [bufferA, mainBuffer],
  shaderController: controller,
);
```

### Behavior

- When paused: Time stops advancing, but rendering continues using the last time value
- When resumed: Time continues from where it left off
- The controller is automatically managed by ShaderSurface's lifecycle

## Topological Sorting

For Shadertoy-style multi-pass setups, only when the dependencies within the same frame do not form a cycle (DAG) can the final buffer list be topologically sorted.

That is:

- Each pass can only read the output of passes it depends on (or external inputs)  
- Cyclic dependencies within the same frame are not allowed (e.g. A reads B while B reads A)  

Feedback / ping-pong reads the output of the previous frame, which is a cross-frame dependency and usually does not break the current frame’s topological ordering.

Note:  
Within a single Buffer, the order of input channels (iChannel0..N) must still strictly follow Shadertoy’s defined order, because shader-side sampling is bound by channel order.

---

See `pacman_game.dart` for a concrete example.

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
    return ShaderSurface.builder(
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

## toImageSync Memory Leak

[toImageSync retains display list which can lead to surprising memory retention](https://github.com/flutter/flutter/issues/138627)

A pitfall encountered previously: on Flutter 3.38.5 (macOS), `toImageSync` may still cause noticeable memory growth.
During local testing, after running the app for a period of time, it would continuously consume physical memory and start using swap, eventually reaching extremely large usage (over 200GB).

The current project’s mitigation strategy:

- Use the asynchronous `toImage()` instead (avoiding the high-risk path of `toImageSync`)  
- But it cannot be triggered every frame, otherwise it still causes huge overhead  
- Therefore, a Ticker / throttling strategy is used: only trigger the next update after a “new frame image is ready”  

## Copilot

To be honest, I am currently maintaining many projects, and several projects I care about are in a semi-paused state.

Therefore, during the implementation of this project, I relied on a considerable amount of AI (mainly GPT-5.2).

However, the overall design, structural decisions, debugging, and validation were still led by me.

I am not very familiar with shader-related topics; most of the code in this area was almost entirely generated by AI, and debugging and validation also consumed a significant amount of my effort.

The overall design on the Dart side was carried out almost entirely according to my ideas.

The goals have always been:

- Simple and intuitive to use  
- Sufficiently powerful functionality  
- Clear design structure  
- Readable project code  
- Extensive bilingual comments, suitable for learning and secondary development

---

## ShaderToy → Flutter porting guide

For detailed information on porting Shadertoy shaders to Flutter, including feedback mechanisms, wrap modes, and RGBA8 feedback specifications, see [DEVELOP.md](DEVELOP.md).

This guide covers:

- Wrap modes (repeat/mirror/clamp) and shader-side sampling
- RGBA8 feedback encoding for state machines
- `texelFetch` replacements
- Shader file structure and SkSL incompatibilities
- Dart-side multi-pass wiring
- Troubleshooting checklist
