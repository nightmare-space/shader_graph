# ShaderToy → Flutter Porting Guide (Feedback/Wrap)

> Key background: Flutter RuntimeEffect/SkSL does **not** expose real sampler
> states (wrap/filter can't be set like Shadertoy). Some GLSL features are also
> limited (for example `texelFetch`, bit operations, global array
> initialization, etc.). This project ports common Shadertoy code into a runnable
> form via "header files + macros + Dart-side uniforms/samplers wiring".

---

## 0. Key files and terms

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
- **physical pixel**: the actual output pixels. To simulate "one texel = vec4",
  `sg_feedback_rgba8` expands one virtual texel into 4 horizontal physical pixels.

---

## 1. Correct wrap usage (repeat/mirror/clamp)

### 1.1 Dart side: set wrap per input channel

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

### 1.2 Shader side: sampling must go through wrap macros

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

### 1.3 About UV semantics

- Many Shadertoy shaders sample textures in `[0,1]` UV space.
- Some shaders use centered coordinates (for example
  `uv = (fragCoord - 0.5*iResolution)/iResolution.y`, roughly `[-1,1]`).

Wrap is mathematically defined as clamp/repeat/mirror over the input UV:

- If your UV is not in `[0,1]`, repeat/mirror still works, but the visual result
  may differ from "standard texture coordinates" (this is expected).

---

## 2. `sg_feedback_rgba8`: RGBA8 feedback (previous frame) spec

### 2.1 Why it exists

Flutter intermediate render targets are typically `ui.Image` (RGBA8). Writing
high-precision float state directly into RGBA8 often causes:

- insufficient precision / quantization jitter
- slight neighbor mixing on some GPU paths
- once `NaN/Inf` is written, it keeps contaminating future frames

Goals of `sg_feedback_rgba8`:

- stable state storage in RGBA8
- reduce linear-sampling crosstalk for state machines

### 2.2 Include order

Include in this order:

```glsl
#include <../common/common_header.frag>
#include <../common/sg_feedback_rgba8.frag>
```

Note: `sg_feedback_rgba8.frag` depends on macros like `SG_TEXELFETCH` provided by `common_header.frag`.

### 2.3 Virtual texels and physical output size

`sg_feedback_rgba8` expands lanes horizontally to simulate storing a vec4 per texel:

- virtual `(x, y)` maps to physical `(x*4 + lane, y)`, lane=0..3 maps to vec4 x/y/z/w

So:

- virtual size = `VSIZE = vec2(VW, VH)`
- physical output size = `(VW*4, VH)`

Dart side must match:

- set `fixedOutputSize = Size(VW*4, VH)` for the data buffer

Otherwise reads/writes will be offset.

### 2.4 Read/write API (macros + store functions)

#### Read: `SG_LOAD_*` macros (explicit channel token)

Example:

```glsl
const vec2 VSIZE = vec2(14.0, 14.0);

vec4 s = SG_LOAD_VEC4(iChannel0, ivec2(0, 0), VSIZE);
float a = SG_LOAD_FLOAT(iChannel0, ivec2(1, 0), VSIZE);
vec3 v = SG_LOAD_VEC3(iChannel0, ivec2(2, 0), VSIZE);
```

Key point:

- Always use `SG_LOAD_*` and pass the channel token explicitly (`iChannelN`).

#### Write: `sg_storeVec4` / `sg_storeVec4Range`

At the end of `mainImage(out vec4 fragColor, in vec2 fragCoord)`, write by register address:

```glsl
ivec2 p = ivec2(fragCoord - 0.5);

fragColor = vec4(0.0);
sg_storeVec4(txSomeReg, valueSigned, fragColor, p);
```

Where:

- `p` is the physical pixel coord (typically `ivec2(fragCoord - 0.5)`)
- `valueSigned` must be encoded into **[-1,1]** (see next section)

### 2.5 Range encoding: map any range to [-1,1]

`sg_feedback_rgba8` storage assumes:

- scalar channels are stored in [-1, 1]

So map real ranges (for example score 0..50000) into [-1,1], and decode after reading.

Common helpers (in `sg_feedback_rgba8.frag`):

- `sg_encodeRangeToSigned(v, min, max)`
- `sg_decodeSignedToRange(s, min, max)`
- `sg_encode01ToSigned(v01)` / `sg_decodeSignedTo01(s)`

### 2.6 Crosstalk mitigation (important)

On some GPU paths, `sampler2D` sampling can be slightly linear, mixing lanes
(`x*4+0..3`) and corrupting state.

Recommendations:

- for "single scalar" registers: write `vec4(v,v,v,v)`
- for reads of those registers: average (for example `dot(raw, vec4(0.25))`)

### 2.7 NaN/Inf protection (feedback can contaminate forever)

Once `NaN/Inf` is written, it spreads on future frames.

Common triggers:

- division by 0
- `normalize(v)` / `inversesqrt(dot(v,v))` when `v` is near 0
- `log(0)`

Mitigations:

- clamp denominators (for example `max(abs(x), 1e-6)`)
- check vector length before normalizing

---

## 3. `texelFetch` replacement (Plan A: per-channel resolution uniforms)

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

## 4. Port Shadertoy with Copilot prompts (recommended)

This repo includes two porting prompts:

- `.github/prompts/port_shader.prompt.md`: general porting (may not use feedback)
- `.github/prompts/port_shader_float.prompt.md`: multi-pass + `sg_feedback_rgba8` spec (recommended for games/state machines)

### 4.1 Before you start

1) Ensure shader assets are declared under `flutter: shaders:` in the consuming app (usually `example/`) `pubspec.yaml`.

2) Identify Shadertoy passes:

- BufferA/BufferB/BufferC/BufferD
- Image (main output)

3) Identify each pass input channel (iChannel0..):

- which buffer output (from which pass)
- which image asset
- keyboard texture input (provided by this project)

### 4.2 Shader file structure (must follow)

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

### 4.3 Common SkSL incompatibilities (minimal fixes)

- do **not** pass `sampler2D` as a function parameter (use macros)
- avoid global `const int[] = int[](...)` initialization (use if-chain getters)
- avoid bit ops (`>> & | ^`) and int `%` (use `floor/mod/pow` alternatives)
- avoid native `texelFetch` (use `SG_TEXELFETCH*`)
- explicitly initialize locals (SkSL is more sensitive)

### 4.4 Dart-side wiring (minimal multi-pass + feedback scheme)

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

## 5. Minimal snippets

### 5.1 Wrap sampling

```glsl
#include <../common/common_header.frag>

uniform sampler2D iChannel0;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = SG_TEX0(iChannel0, uv);
}

#include <../common/main_shadertoy.frag>
```

### 5.2 Keyboard texture (prefer `SG_TEXELFETCH*`)

```glsl
// Assume iChannel1 is the keyboard texture
float keyDown(int keyCode) {
    return SG_TEXELFETCH1(ivec2(keyCode, 0)).x;
}
```

---

## 6. Troubleshooting checklist

- visual "split/jitter/flicker":
  - lane crosstalk? (try writing `vec4(v,v,v,v)` and averaging reads)
  - wrote NaN/Inf? (check division by 0 / normalize / log)

- only a corner shows / stretched:
  - did you multiply `iResolution` by dpr/scale again? (here `iResolution` is already in pixels)
  - enabled `useSurfaceSizeForIResolution` while actually rendering to `fixedOutputSize`? (coordinate mismatch)

- wrap not working:
  - are you sampling via `SG_TEX0/1/2/3` or `sg_wrapUv`? (don't use `texture(iChannelN, uv)` directly)

---

## 7. References: prompt files

- `.github/prompts/port_shader.prompt.md`
- `.github/prompts/port_shader_float.prompt.md`
