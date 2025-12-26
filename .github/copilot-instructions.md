# Copilot instructions for shader_graph

## Project snapshot (what this repo is)
- Flutter/Dart package that runs **multi-pass runtime shaders** (`ui.FragmentProgram` / `RuntimeEffect`) as a **render graph** (Shadertoy-style BufferA/BufferB/Main + feedback/ping-pong).
- A runnable demo app lives in `example/` and consumes the package via a path dependency.

## Where to start (key files)
- Public library entry: `lib/shader_graph.dart` (exports extensions + controllers, and `part`s in most implementation files).
- Render graph + scheduling: `lib/src/shader_graph.dart` (`ShaderGraph`, topological order, per-frame execution).
- Per-pass node + inputs: `lib/src/shader_buffer.dart`, `lib/src/shader_input.dart` (`ShaderBuffer`, `ShaderInput`, feedback semantics).
- Rendering widget + render pipeline: `lib/src/view/shader_surface.dart`, `lib/src/view/shader_surface_render_object.dart` (`ShaderSurface`, `ShaderSurfaceLayer`).
- Convenience DSL: `lib/src/extension/extension.dart` (`'path'.shaderBuffer`, `.feed(...)`).
- Keyboard texture semantics: `lib/src/controller/keyboard_controller.dart`.

## Dev workflows (this repo)
- Run the demo app: `cd example && flutter pub get && flutter run`.
- Run tests (note: example test is boilerplate and may not match the current UI): `cd example && flutter test`.

## Project-specific conventions & “gotchas”
### 1) This codebase intentionally uses `part` files
Many implementation files are `part of 'package:shader_graph/shader_graph.dart';`.
- Keep new core runtime classes inside the same library if they need access to private fields like `ShaderBuffer._output`.
- If you add a *public* API, ensure it is reachable via `lib/shader_graph.dart` exports.

### 2) Feedback / ping-pong semantics are frame-start, not per-pass
Feedback inputs use `ShaderBufferInput(usePreviousFrame: true)` and must sample **the previous frame**, independent of render order.
- Do NOT advance `_prevOutput` at the end of each pass.
- The correct behavior is advancing feedback for **all buffers once at frame start** via `ShaderBuffer._beginFrame()` called from `ShaderGraph._renderFrame*()`.

### 3) Shader inputs are ordered (iChannel0..N)
Samplers are set sequentially in `ShaderBuffer.renderShader()` based on `_inputs` order.
- `ShaderBuffer.feedShader(...)` / `feedImageFromAsset(...)` / `feedKeyboard()` append inputs.
- `.feedback()` appends “self as previous frame” input.

### 4) Asset declaration is required for runtime shaders
Runtime shaders are loaded via `ui.FragmentProgram.fromAsset(shaderAssetPath)`.
- Add `.frag` files under `flutter: shaders:` in the consuming app’s `pubspec.yaml` (see `example/pubspec.yaml`).

### 5) Fixed-size buffers vs display size
State buffers often render to a tiny fixed pixel grid.
- Use `ShaderBuffer.fixedOutputSize` for Shadertoy-style data buffers.
- If you need Shadertoy coordinate semantics while rendering to a tiny target, set `ShaderBuffer.useSurfaceSizeForIResolution = true`.

## Common usage patterns (use in examples/docs)
```dart
// Single pass
ShaderSurface.auto('shaders/frame/IFrame Test.frag');

// Multi-pass + feedback
final a = 'shaders/game_ported/Bricks Game BufferA.frag'.shaderBuffer
  ..fixedOutputSize = const Size(14 * 4.0, 14)
  ..feedback()
  ..feedKeyboard();

final main = 'shaders/game_ported/Bricks Game.frag'.shaderBuffer..feed(a);
ShaderSurface.buffers([a, main]);
```
