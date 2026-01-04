# Shader Graph

`shader_graph` is a real-time multi-pass shader execution framework for Flutter `FragmentProgram / RuntimeEffect`.

It is now even capable of running a **fully shader-driven game**.

<img src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Bricks%20Game.gif?raw=true">

This framework connects multiple `.frag` shaders using a **render graph** model, fully supporting Shadertoy-style BufferA / BufferB / Main passes, as well as feedback / ping-pong patterns.

It supports keyboard input, mouse input, image input, and Shadertoy-style wrap modes (Clamp / Repeat / Mirror).

If you only want to quickly display a shader, you can directly use a simple widget (for example, `ShaderSurface.auto`).

When you need more complex pipelines (multi-pass / multiple inputs / feedback / ping-pong), you should explicitly declare inputs and dependencies using `ShaderBuffer`.

The framework handles topological scheduling and per-frame execution, and passes the output of each pass downstream as a `ui.Image`.

[English README](README.md) | 中文

---

## Examples

I have created the  
[awesome_flutter_shaders](https://github.com/mengyanshou/awesome_flutter_shaders) project using this library.

This is currently the most complete collection of examples, containing **100+ Shadertoy shaders ported to Flutter**, and is highly recommended as a reference.

The `example` directory in this project also contains demonstrations for individual features.  
The source code of `shader_graph` itself includes extensive Chinese and English comments for easier reading and understanding.

---

## Roadmap

- [x] Support using one shader as a buffer input to another shader (Multi-Pass)
- [x] Support using images as shader buffer inputs
- [x] Support feedback input (Ping-Pong: previous frame → next frame)
- [x] Support mouse input
- [x] Support keyboard input
- [x] Support wrap modes (Clamp / Repeat / Mirror)
- [x] Automatic topological sorting
- [x] Support texelFetch (texel size calculated automatically via macros)
- [x] Support Shadertoy-style filters (Linear / Nearest / Mipmap)
  - [x] Nearest / Linear: basically supported, with minor differences
  - [ ] Mipmap: not supported yet; exploring mipmap-like approaches feasible in Flutter
- [ ] Support rendering a Widget into a texture and using it as a buffer input
- [ ] Animation control

---

## Float Support (RGBA8 Feedback)

Flutter feedback textures are usually RGBA8 and cannot reliably store arbitrary float values.

This project provides a unified porting solution: `sg_feedback_rgba8`.  
Scalar values are encoded into RGB (24-bit), and packed horizontally using 4 lanes, preserving the semantic model of “one texel = one vec4”.

---

## texelFetch Support

Provided by `common_header.frag`:

- `SG_TEXELFETCH`
- `SG_TEXELFETCH0..3`

These macros replace native `texelFetch` calls and automatically obtain channel resolutions via `iChannelResolution0..3`.

---

## Ping-Pong & Multi-Pass & RGBA8 Feedback

<table>
  <tr>
    <td>
      <img width="300px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Bricks%20Game.png?raw=true">
      <br>
      Bricks Game
    </td>
    <td>
      <img width="300px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Pacman%20Game.png?raw=true">
      <br>
      Pacman Game
    </td>
    <td></td>
  </tr>
</table>


## Wrap & Filter

The following examples demonstrate the decisive impact of wrap and filter modes on shader results.  
Without support for these features, the visual output differs significantly from Shadertoy.


**Raw Image**

<img width="600px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Wrap%20Raw Image.png?raw=true">

**Transition Burning**

<img width="600px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Wrap%20Transition%20Burning.png?raw=true">

**Tissue**

<img width="600px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Wrap%20Tissue.png?raw=true">

**Black Hole**

<img width="600px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Wrap%20Black%20Hole.png?raw=true">

**Broken Time Gate**

<img width="600px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Wrap%20Broken%20Time%20Gate.png?raw=true">

**Goodbye Dream Clouds**

<img width="600px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Wrap%20Goodbye%20Dream%20Clouds.png?raw=true">

### Keyboard Input

> Note: These visuals are not Flutter UI elements. They are rendered entirely by shaders and respond to keyboard input in real time.


<img width="600px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Keyboard.png?raw=true">

## Others

<table>
  <tr>
    <td>
      <img width="300px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/IFrame.png?raw=true">
      <br>
      IFrame
    </td>
    <td>
      <img width="300px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Noise%20Lab.png?raw=true">
      <br>
      Noise Lab
    </td>
  </tr>
  <tr>
    <td>
      <img width="300px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Text.png?raw=true">
      <br>
      Text
    </td>
    <td>
      <img width="300px" src="https://raw.githubusercontent.com/nightmare-space/shader_graph/main/screenshot/Float%20Test.png">
      <br>
      Float Test
    </td>
  </tr>
</table>

---

## Foreword

My understanding of shaders used to be quite vague. A friend recommended that I read  
[The Book of Shaders](https://thebookofshaders.com/). I read part of it, but never truly grasped the underlying principles.

However, I found the shaders on Shadertoy extremely interesting. Some of them are essentially complete games, which led me to a question:

**Could these shaders be ported to run in Flutter?**

First of all, I would like to thank the author of  
[shader_buffers](https://github.com/alnitak/shader_buffers). This project was what initially allowed me to run some Shadertoy shaders in Flutter.

However, during practical use, I gradually realized that its design and functionality differed significantly from my needs. Some of these issues were addressed by contributing fixes via pull requests.

As my requirements continued to grow, I realized that the problem was not limited to shader_buffers. Instead, it reflected an entire category of issues that almost all existing Flutter shader frameworks had not addressed.

As a result, `shader_graph` was born.

---

## Quick Start

First, one important point must be clarified:

**Shadertoy shaders must be ported before they can run in Flutter.**

This project provides a helper prompt for porting:  
`port_shader.prompt.md`

The basic workflow is as follows:

1. Open the shader file you want to port (it is recommended to place it directly in your project)
2. Enter the corresponding prompt in Copilot or other AI tools

```text
Follow instructions in [port_shader.prompt.md](.github/prompts/port_shader.prompt.md).
```

Example code can be found at: [example](example/lib/main.dart)

### Minimal runnable examples

**1) Single shader (Widget)**
```dart
SizedBox(
  height: 240,
  // shader_asset_main ends with .frag
  child: ShaderSurface.auto('$shader_asset_main'),
)
```

**2) Two passes (A → Main)**
See [multi_pass.dart](example/lib/multi_pass.dart)
```dart
ShaderSurface.builder(() {
  final bufferA = '$shader_asset_buffera'.shaderBuffer;
  final main = '$shader_asset_main'.shaderBuffer.feed(bufferA);
  return [bufferA, main];
})
```

**3) feedback (A → A, plus a Main display)**
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

## ShaderBuffer

`ShaderBuffer` can be used either as the final rendering shader, or as an intermediate `Buffer` that is fed into other shaders.

It is the most core node abstraction in the entire render graph.

It is usually created via an extension:

```dart
'$asset_path'.shaderBuffer;
```

Which is equivalent to:

```dart
final buffer = ShaderBuffer('$asset_path');
```

`ShaderBuffer` can be used together with `ShaderSurface.auto` and `ShaderSurface.builder`,
or passed directly as a `List<ShaderBuffer>` via `ShaderSurface.buffers`.

### Inputs

`ShaderBuffer` supports multiple input sources, used to simulate the iChannel behavior in Shadertoy.

Currently supported input types include:

- Output of other ShaderBuffers  
- Images (ui.Image / Asset)  
- Keyboard input  
- Mouse input  
- Built-in uniforms such as time and resolution  

These inputs are bound uniformly to the corresponding shader parameters on every frame.

### feed


`feed` is used to bind an **input source** to the current `ShaderBuffer`.

The input source can be:

- The output of another `ShaderBuffer`  
- A shader asset path ending with `.frag` (which will be implicitly created as a `ShaderBuffer`)

This is the core mechanism for building multi-pass rendering pipelines.

```dart
// Use another ShaderBuffer directly as input
buffer.feed(bufferA);

// Use a shader asset path ending with .frag as input
buffer.feed("$asset_path");
```

The code above means:

- `bufferA` (or the ShaderBuffer created from `$asset_path`) will be executed first  
- Its output will be passed to the current `buffer` as a texture input (iChannel)

In other words, `feed` always affects the ShaderBuffer it is called on, and does not modify the fed buffer itself.

You can also add other inputs while calling `feed`.

**Add keyboard as input**

```dart
buffer.feedKeyboard();
```

**Add asset image as input**

> Usually used to input noise, textures, etc.

This part can be referenced from  
[awesome_flutter_shaders](https://github.com/mengyanshou/awesome_flutter_shaders/tree/main/assets)

```dart
buffer.feed('$image_asset_path');
```

## feedback / ping-pong

In Shadertoy, feedback is a very common pattern, for example:

- Particle simulations  
- Fluid simulations  
- Cellular automata  
- Game logic entirely driven by shaders  

`shader_graph` provides explicit support for this pattern via `feedback()`.

```dart
final bufferA = '$asset_shader_buffera'.shaderBuffer.feedback();
```

After feedback is enabled:

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

---

## Wrap (repeat / mirror / clamp)

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

## Output Size

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
- List<ShaderBuffer>  

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
┌─────┐    ┌─────┐    ┌─────┐
│  A  │───▶│  B  │───▶│  C  │
│ ↺ A │    └─────┘    └─────┘
└─────┘
```

Or:

```text
┌──────────── Shader A ────────────┐
│                                  │
│   ┌─────┐                        │
│   │  A  │◀───────────────┐       │
│   └──┬──┘                │       │
│      │                   │       │
│      ▼                   │       │
│   ┌─────┐                │       │
│   │  B  │────────────────┘       │
│   └──┬──┘                        │
│      ▼                           │
│   ┌─────┐                        │
│   │  C  │                        │
│   └──┬──┘                        │
└──────┼───────────────────────────┘
       ▼
   ┌─────────┐
   │    D    │
   │  A B C  │
   └─────────┘
```

`ShaderSurface` provides `builder` to handle these cases. Used like this, you
won't need multiple `Builder(Flutter)`.
> Builder doesn't disappear; it just moves.

```dart
ShaderSurface.builder(() {
  final bufferA = '$asset_shader_buffera'.feedback().feedKeyboard();
  final mainBuffer = '$asset_shader_main'.feed(bufferA);
  // Standard scheme: physical width = virtual * 4
  bufferA.fixedOutputSize = const Size(14 * 4.0, 14);
  return [bufferA, mainBuffer];
})
```

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

## ShaderToy → Flutter porting guide (Feedback/Wrap)

> Key background: Flutter RuntimeEffect/SkSL does **not** expose real sampler
> states (wrap/filter can't be set like Shadertoy). Some GLSL features are also
> limited (for example `texelFetch`, bit operations, global array
> initialization, etc.). This project ports common Shadertoy code into a runnable
> form via “header files + macros + Dart-side uniforms/samplers wiring”.

---

### 0. Key files and terms

- Unified header (must include):
  - `example/shaders/common/common_header.frag`
- Shadertoy main entry wrapper:
  - `example/shaders/common/main_shadertoy.frag`
- RGBA8 feedback encoding utilities (optional include, depends on common_header):
  - `example/shaders/common/sg_feedback_rgba8.frag`
- Dart-side inputs and wrap:
  - `lib/src/shader_input.dart`
  - `lib/src/shader_buffer.dart`

Terms:

- **pass/buffer**: Shadertoy BufferA/BufferB/Main intermediate render targets
- **feedback**: reading previous frame output (state machines / game logic / score / positions)
- **virtual texel**: logical state grid (for example 14×14)
- **physical pixel**: the actual output pixels. To simulate “one texel = vec4”,
  `sg_feedback_rgba8` expands one virtual texel into 4 horizontal physical pixels.

---

### 1. Correct wrap usage (repeat/mirror/clamp)

#### 1.1 Dart side: set wrap per input channel

This project models wrap via `WrapMode` (encoded as floats into `iChannelWrap`):

- `WrapMode.clamp`
- `WrapMode.repeat`
- `WrapMode.mirror`

Example (illustration):

```dart
final buf = 'shaders/xxx.frag'.shaderBuffer
  ..feed('assets/tex.png', wrap: WrapMode.repeat)
  ..feed('assets/tex2.png', wrap: WrapMode.mirror);
```

Mapping:

- `iChannelWrap.x` → iChannel0
- `iChannelWrap.y` → iChannel1
- `iChannelWrap.z` → iChannel2
- `iChannelWrap.w` → iChannel3

> Note: this is not a real GPU sampler state. Wrap is implemented via a shader-side UV transform.

#### 1.2 Shader side: sampling must go through wrap macros

`common_header.frag` provides:

- `sg_wrapUv(uv, mode)`: clamp/repeat/mirror UV transform
- `SG_TEX0/1/2/3(tex, uv)`: samples using the corresponding `iChannelWrap` component

Therefore in your shader:

- Do **not** call `texture(iChannelN, uv)` directly (it ignores wrap configuration)
- Do call:

```glsl
vec4 c0 = SG_TEX0(iChannel0, uv);
vec4 c1 = SG_TEX1(iChannel1, uv);
```

If you prefer an explicit form:

```glsl
vec2 u = sg_wrapUv(uv, iChannelWrap.x);
vec4 c0 = texture(iChannel0, u);
```

#### 1.3 About UV semantics

- Many Shadertoy shaders sample textures in `[0,1]` UV space.
- Some shaders use centered coordinates (for example
  `uv = (fragCoord - 0.5*iResolution)/iResolution.y`, roughly `[-1,1]`).

Wrap is mathematically defined as clamp/repeat/mirror over the input UV:

- If your UV is not in `[0,1]`, repeat/mirror still works, but the visual result
  may differ from “standard texture coordinates” (this is expected).

---

### 2. `sg_feedback_rgba8`: RGBA8 feedback (previous frame) spec

#### 2.1 Why it exists

Flutter intermediate render targets are typically `ui.Image` (RGBA8). Writing
high-precision float state directly into RGBA8 often causes:

- insufficient precision / quantization jitter
- slight neighbor mixing on some GPU paths
- once `NaN/Inf` is written, it keeps contaminating future frames

Goals of `sg_feedback_rgba8`:

- stable state storage in RGBA8
- reduce linear-sampling crosstalk for state machines

#### 2.2 Include order

Include in this order:

```glsl
#include <../common/common_header.frag>
#include <../common/sg_feedback_rgba8.frag>
```

Note: `sg_feedback_rgba8.frag` depends on macros like `SG_TEXELFETCH` provided by `common_header.frag`.

#### 2.3 Virtual texels and physical output size

`sg_feedback_rgba8` expands lanes horizontally to simulate storing a vec4 per texel:

- virtual `(x, y)` maps to physical `(x*4 + lane, y)`, lane=0..3 maps to vec4 x/y/z/w

So:

- virtual size = `VSIZE = vec2(VW, VH)`
- physical output size = `(VW*4, VH)`

Dart side must match:

- set `fixedOutputSize = Size(VW*4, VH)` for the data buffer

Otherwise reads/writes will be offset.

#### 2.4 Read/write API (macros + store functions)

##### Read: `SG_LOAD_*` macros (explicit channel token)

Example:

```glsl
const vec2 VSIZE = vec2(14.0, 14.0);

vec4 s = SG_LOAD_VEC4(iChannel0, ivec2(0, 0), VSIZE);
float a = SG_LOAD_FLOAT(iChannel0, ivec2(1, 0), VSIZE);
vec3 v = SG_LOAD_VEC3(iChannel0, ivec2(2, 0), VSIZE);
```

Key point:

- Always use `SG_LOAD_*` and pass the channel token explicitly (`iChannelN`).

##### Write: `sg_storeVec4` / `sg_storeVec4Range`

At the end of `mainImage(out vec4 fragColor, in vec2 fragCoord)`, write by register address:

```glsl
ivec2 p = ivec2(fragCoord - 0.5);

fragColor = vec4(0.0);
sg_storeVec4(txSomeReg, valueSigned, fragColor, p);
```

Where:

- `p` is the physical pixel coord (typically `ivec2(fragCoord - 0.5)`)
- `valueSigned` must be encoded into **[-1,1]** (see next section)

#### 2.5 Range encoding: map any range to [-1,1]

`sg_feedback_rgba8` storage assumes:

- scalar channels are stored in [-1, 1]

So map real ranges (for example score 0..50000) into [-1,1], and decode after reading.

Common helpers (in `sg_feedback_rgba8.frag`):

- `sg_encodeRangeToSigned(v, min, max)`
- `sg_decodeSignedToRange(s, min, max)`
- `sg_encode01ToSigned(v01)` / `sg_decodeSignedTo01(s)`

#### 2.6 Crosstalk mitigation (important)

On some GPU paths, `sampler2D` sampling can be slightly linear, mixing lanes
(`x*4+0..3`) and corrupting state.

Recommendations:

- for “single scalar” registers: write `vec4(v,v,v,v)`
- for reads of those registers: average (for example `dot(raw, vec4(0.25))`)

#### 2.7 NaN/Inf protection (feedback can contaminate forever)

Once `NaN/Inf` is written, it spreads on future frames.

Common triggers:

- division by 0
- `normalize(v)` / `inversesqrt(dot(v,v))` when `v` is near 0
- `log(0)`

Mitigations:

- clamp denominators (for example `max(abs(x), 1e-6)`)
- check vector length before normalizing

---

### 3. `texelFetch` replacement (Plan A: per-channel resolution uniforms)

`common_header.frag` provides:

- `uniform vec2 iChannelResolution0..3;`
- `SG_TEXELFETCH(tex, ipos, sizePx)`: texel-center UV + snap replacement
- `SG_TEXELFETCH0/1/2/3(ipos)`: convenience macros for `iChannel0..3` (recommended)

Prefer:

```glsl
vec4 v = SG_TEXELFETCH0(ivec2(x, y));
```

instead of hardcoding `textureSize` constants.

---

### 4. Port Shadertoy with Copilot prompts (recommended)

This repo includes two porting prompts:

- `.github/prompts/port_shader.prompt.md`: general porting (may not use feedback)
- `.github/prompts/port_shader_float.prompt.md`: multi-pass + `sg_feedback_rgba8` spec (recommended for games/state machines)

#### 4.1 Before you start

1) Ensure shader assets are declared under `flutter: shaders:` in the consuming app (usually `example/`) `pubspec.yaml`.

2) Identify Shadertoy passes:

- BufferA/BufferB/BufferC/BufferD
- Image (main output)

3) Identify each pass input channel (iChannel0..):

- which buffer output (from which pass)
- which image asset
- keyboard texture input (provided by this project)

#### 4.2 Shader file structure (must follow)

For each pass file:

1) add a porting log header (optional but recommended)
2) **the first include must be**:

```glsl
#include <../common/common_header.frag>
```

3) declare needed `uniform sampler2D iChannelN;`

4) if the pass uses `sg_feedback_rgba8`, then include:

```glsl
#include <../common/sg_feedback_rgba8.frag>
```

5) at the end of file include:

```glsl
#include <../common/main_shadertoy.frag>
```

#### 4.3 Common SkSL incompatibilities (minimal fixes)

- do **not** pass `sampler2D` as a function parameter (use macros)
- avoid global `const int[] = int[](...)` initialization (use if-chain getters)
- avoid bit ops (`>> & | ^`) and int `%` (use `floor/mod/pow` alternatives)
- avoid native `texelFetch` (use `SG_TEXELFETCH*`)
- explicitly initialize locals (SkSL is more sensitive)

#### 4.4 Dart-side wiring (minimal multi-pass + feedback scheme)

Typical pipeline (avoid read/write conflicts):

- BufferA: read previous frame feedback, update state
- BufferB: passthrough (copy BufferA output)
- Main: render by reading BufferB only

Key points:

- data buffers must set `fixedOutputSize` to the physical size (for example `Size(VSIZE.x*4, VSIZE.y)`)
- feedback via `.feedback()` or `.feed(buffer, usePreviousFrame: true)`
- if you need surface-sized `iResolution/iMouse` while rendering to a tiny fixedOutputSize, enable `useSurfaceSizeForIResolution = true` on that buffer

> Note: once `useSurfaceSizeForIResolution` is enabled, don't derive packing ratios from `iResolution` (it no longer equals the render target size).

---

### 5. Minimal snippets

#### 5.1 Wrap sampling

```glsl
#include <../common/common_header.frag>

uniform sampler2D iChannel0;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = SG_TEX0(iChannel0, uv);
}

#include <../common/main_shadertoy.frag>
```

#### 5.2 Keyboard texture (prefer `SG_TEXELFETCH*`)

```glsl
// Assume iChannel1 is the keyboard texture
float keyDown(int keyCode) {
    return SG_TEXELFETCH1(ivec2(keyCode, 0)).x;
}
```

---

### 6. Troubleshooting checklist

- visual “split/jitter/flicker”:
  - lane crosstalk? (try writing `vec4(v,v,v,v)` and averaging reads)
  - wrote NaN/Inf? (check division by 0 / normalize / log)

- only a corner shows / stretched:
  - did you multiply `iResolution` by dpr/scale again? (here `iResolution` is already in pixels)
  - enabled `useSurfaceSizeForIResolution` while actually rendering to `fixedOutputSize`? (coordinate mismatch)

- wrap not working:
  - are you sampling via `SG_TEX0/1/2/3` or `sg_wrapUv`? (don't use `texture(iChannelN, uv)` directly)

---

### 7. References: prompt files

- `.github/prompts/port_shader.prompt.md`
- `.github/prompts/port_shader_float.prompt.md`

