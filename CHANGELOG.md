## 0.0.5(2026.01.04)

- Support set input filter mode(Nearest / Linear).
- Optimized example
- Improved documentation

## 0.0.4(2025.1227)

- Support set input wrap mode for image inputs.
- Improved existing examples and added new ones.
- Improved overall code structure, architecture, and file organization.

## 0.0.3(2025.1218)

- Try fix pub's readme screenshot display issue again.

## 0.0.2(2025.1218)

- Fix dart pub readme screenshot display issue.
- Add virtual keyboard widget for example
- Fix Android's game problems in example

## 0.0.1(2025.1218)

First public release.

- Render-graph style multi-pass execution for Flutter `FragmentProgram/RuntimeEffect`.
- `ShaderBuffer` API for wiring shader inputs (other shaders, images, keyboard, mouse).
- Feedback / ping-pong support for Shadertoy-style buffers.
- Automatic topological scheduling of buffer lists.
- RGBA8 feedback float workaround via `sg_feedback_rgba8` (RGB24 encoding + 4-lane packing).
- Example app and a set of ported Shadertoy-style shaders included in `example/`.