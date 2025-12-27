# Shader Graph

`shader_graph` is a real-time multi-pass shader execution framework for Flutter
`FragmentProgram/RuntimeEffect`.

It can even run a full game implemented entirely in shaders.

<img src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Bricks%20Game.gif?raw=true"> 

It runs multiple `.frag` passes as a “render graph” (including Shadertoy-style
BufferA/BufferB/Main, feedback, ping-pong).

It supports keyboard input, mouse input, image inputs, and Shadertoy-style Wrap
(Clamp/Repeat/Mirror).

If you just want to quickly display a shader, you can use a simple Widget (for
example `ShaderSurface.auto`).

When you need a more complex pipeline (multi-pass / multiple inputs / feedback /
ping-pong), use `ShaderBuffer` to declare inputs and dependencies.

The framework handles the topological scheduling and per-frame execution, and
forwards each pass output as a `ui.Image` to downstream passes.

English | [中文 README](README-CH.md)

## Screenshots
### Games

<table>
  <tr>
    <td>
      <img width="200px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Bricks%20Game.png?raw=true">
      <br>
      Bricks Game
    </td>
    <td>
      <img width="200px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Pacman%20Game.png?raw=true">
      <br>
      Pacman Game
    </td>
    <td></td>
  </tr>
</table>

### Demos

<table>
  <tr>
    <td>
      <img width="200px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/IFrame.png?raw=true">
      <br>
      IFrame
    </td>
    <td>
      <img width="200px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Mac%20Wallpaper.png?raw=true">
      <br>
      Mac Wallpaper
    </td>
    <td>
      <img width="200px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Noise%20Lab.png?raw=true">
      <br>
      Noise Lab
    </td>
  </tr>
  <tr>
    <td>
      <img width="200px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Text.png?raw=true">
      <br>
      Text
    </td>
    <td>
      <img width="200px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Wrap.png?raw=true">
      <br>
      Wrap
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
  </tr>
</table>

I have already used this library to create
[awesome_flutter_shaders](https://github.com/mengyanshou/awesome_flutter_shaders),
which contains 100+ ported shader examples.

## Features

- [x] Support using a Shader as a Buffer, then feeding it into another Shader (Multi-Pass)
- [x] Support feeding images as Buffer inputs into shaders
- [x] Support feedback inputs (Ping-Pong: feed previous frame into next frame)
- [x] Mouse input
- [x] Keyboard input
- [x] Wrap (Clamp/Repeat/Mirror)
- [x] Automatic topological sorting
- [x] texelFetch support with automatic texel size computation (requires macros and shader code changes)

**Float support (RGBA8 feedback)**

Flutter feedback textures are typically RGBA8, which cannot reliably store
arbitrary float state.
This project provides a unified porting scheme `sg_feedback_rgba8`: encode
scalars into RGB (24-bit), and preserve Shadertoy-like “one texel = vec4”
semantics via 4-lane horizontal packing.

**texelFetch support**

Replace native `texelFetch` calls with the `SG_TEXELFETCH` / `SG_TEXELFETCH0..3`
macros from `common_header.frag` (using `iChannelResolution0..3` as channel
pixel sizes).

## Roadmap

- [ ] Render a Widget into a texture, then feed it as an input Buffer to a shader
- [ ] Support Shadertoy-style Filter (Linear/Nearest/Mipmap). This directly affects whether some ports match.

## Preface

My understanding of shaders used to be vague.
A friend recommended [The Book of Shaders](https://thebookofshaders.com/).
I read part of it, but I still didn't fully understand the underlying ideas.
However, I found Shadertoy shaders incredibly fun — some of them are even full
games. That's crazy, so I wanted to port them to Flutter.

First, thanks to the author of
[shader_buffers](https://github.com/alnitak/shader_buffers), which helped me
start porting shaders to Flutter.

While using that library, I found gaps between what I needed and what the
original design provided, so I contributed fixes via PRs.

But I still had too many requirements left to implement — not only for
shader_buffers, but for almost every shader framework in Flutter — so
shader_graph was born.

## Usage

First, you must understand that Shadertoy shader code needs to be ported before
it can run on Flutter. This repo includes a porting prompt:
[port_shader.prompt](.github/prompts/port_shader.prompt.md)

Usage: open the shader asset path you want to port (it should live in the
project), then in Copilot or similar AI tools, input the following prompt:

```text
Follow instructions in [port_shader.prompt.md](.github/prompts/port_shader.prompt.md).
```

This repo includes fairly complete example code. See
[example](example/lib/main.dart)

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

It can be the final render shader, or an intermediate Buffer that feeds into
another shader. Typically we use the extension to create it:

```dart
'$asset_path'.shaderBuffer;
```

Which is equivalent to:

```dart
final buffer = ShaderBuffer('$asset_path');
```

Use it with `ShaderSurface.auto` / `ShaderSurface.builder`, or use
`ShaderSurface.buffers` to pass a `List<ShaderBuffer>`.

### Add inputs

Inputs are added uniformly via the extension `buffer.feed` method. It infers
the input type from the string suffix. You can also use the raw APIs like
`feedShader` / `feedShaderFromAsset` / ...

**Feed another shader as an input**
```dart
// use ShaderBuffer directly
buffer.feed(anotherBuffer);
// use string path which ends with .frag
buffer.feed("$asset_path");
```

**Keyboard input**
```dart
buffer.feedKeyboard();
```

**Feed an asset image**
> Commonly used for noise/texture inputs

You can see examples in
[awesome_flutter_shaders](https://github.com/mengyanshou/awesome_flutter_shaders/tree/main/assets)

```dart
buffer.feed('$image_asset_path');
```

**Ping-Pong**

That is, feeding itself into itself. Don't worry about infinite loops;
shader_graph handles it.

This keeps the original Shadertoy semantics, and it's a very common pattern on
Shadertoy.

```dart
buffer.feedback();
```

**Set Wrap (repeat/mirror/clamp)**

Flutter runtime shaders don't expose sampler wrap/filter states directly.
This project models Wrap via a shader-side UV transform through the uniform
`iChannelWrap` (x/y/z/w correspond to iChannel0..3).

Set wrap per input on the Dart side:

```dart
final buffer = '$shader_asset_path'.shaderBuffer;
buffer.feed('$texture_asset_path', wrap: WrapMode.repeat);
```

On the shader side, sample using `SG_TEX0/1/2/3(...)` provided by
`common_header.frag` (do not call `texture(iChannelN, uv)` directly).

## ShaderSurface.auto

`ShaderSurface.auto` returns a `Widget`:

```dart
Center(
  child: ShaderSurface.auto('$shader_asset_path'),
)
```

You can place it anywhere. Note that you usually need to provide a height:

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

`ShaderSurface.auto` supports String (shader asset path) / `ShaderBuffer` /
`List<ShaderBuffer>`.

When the shader has inputs, passing a `ShaderBuffer` is more appropriate.

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

### Using Extensions

When multiple `ShaderBuffer`s need inputs, it becomes like this:

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

With Extensions it can be optimized to:

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

The examples above only have a single shader. But for complex pipelines, for
example:

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

## Topological sorting

For Shadertoy multi-pass pipelines, the final Buffer list can be topologically
sorted only when the per-frame dependency graph has no cycles (i.e. it is a DAG).

In other words: within the same frame, passes may read outputs from passes they
depend on (or external inputs), but must not form a cycle (for example A reads B
while B reads A).

Feedback / ping-pong reads the *previous frame* output, which is a cross-frame
dependency and typically does not break the current-frame topological order.

Note: for inputs within a single Buffer, you must still feed them in Shadertoy
iChannel order (iChannel0..N), because channels are bound sequentially.

See [pacman_game.dart](example/lib/game/pacman_game.dart)

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

## toImageSync memory leak

[toImageSync retains display list which can lead to surprising memory retention](https://github.com/flutter/flutter/issues/138627)

I hit a pitfall here: on Flutter 3.38.5 (macOS), `toImageSync` can still show
obvious memory growth.
In my local tests, after running for a while, the app would keep consuming
physical memory and start using Swap. The peak usage became extremely large
(over 200GB).

Current mitigation in this repo:

- Use async `toImage()` (avoid the risky `toImageSync` path)
- But we cannot trigger a conversion every frame, otherwise the overhead is huge
- Use a Ticker / throttling strategy: only schedule the next update after a
  “new frame image is ready”

## Copilot

To be honest, I maintain too many projects, and many projects I care about are
in a semi-maintained state.

So for this project, I used a lot of AI to help build it — mostly GPT-5.2.
Also because I do a fair amount of open source, I get some free quota every
month. I love open source.

But I try to keep myself in the driver seat rather than letting it drive me.
I’m not very familiar with shader-related topics, and most of the shader-side
code was written by it.

I was responsible for organizing things and writing prompts. Even though the
AI did a lot, debugging and validation still took significant time.

The Dart-side design is almost entirely based on my own ideas.

I try to ensure:

- Simple and convenient usage
- Powerful capabilities
- Reasonable design
- Readable code
- Lots of Chinese/English comments