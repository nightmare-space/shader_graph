## 0.0.1

First public release.

- Render-graph style multi-pass execution for Flutter `FragmentProgram/RuntimeEffect`.
- `ShaderBuffer` API for wiring shader inputs (other shaders, images, keyboard, mouse).
- Feedback / ping-pong support for Shadertoy-style buffers.
- Automatic topological scheduling of buffer lists.
- RGBA8 feedback float workaround via `sg_feedback_rgba8` (RGB24 encoding + 4-lane packing).
- Example app and a set of ported Shadertoy-style shaders included in `example/`.