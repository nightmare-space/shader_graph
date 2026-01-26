---
name: shaderMigrationAssistantFloat
description: Add float-safe RGBA8 feedback rules on top of the general Flutter/SkSL porting rules
---

**【ShaderToy → Flutter RuntimeEffect 迁移 Prompt（float + sg_feedback_rgba8 增量规范）】**

你要做的是“在 Flutter/SkSL 可编译”的前提下，把 Shadertoy 的 multipass（BufferA/BufferB/Main）移植为可运行的 shader graph，并且让**需要跨帧保存的 float 状态**在 RGBA8 `ui.Image` 中稳定工作。

## 0) 与通用 Prompt 的关系（先做什么）
1) **先按通用规则处理每个 pass**：遵循 [port_shader.prompt.md](.github/prompts/port_shader.prompt.md) 的结构/采样/变量初始化/SkSL 兼容性要求（include 顺序、`SG_TEX0..3`、移除自定义 main、底部 `main_shadertoy.frag` 等）。
2) **然后再按本文件补充“float 状态 + feedback”规则**：仅对“需要保存/读取上一帧状态”的 buffer 做 RGBA8 编码读写改造。

> 本 prompt 只讲“如何让 float feedback 在 RGBA8 下可靠”，避免重复通用迁移细节。

## 1) 何时必须启用 sg_feedback_rgba8
当满足任一条件时：
- 该 pass 需要读取**上一帧**的 Buffer 输出（feedback/self feedback/ping-pong）；或
- 该 pass 输出被下游当作“数据纹理/状态寄存器”使用（而不是纯颜色画面）。

则该 pass 在 `common_header.frag` 之后必须紧接：
```glsl
#include <../common/sg_feedback_rgba8.frag>
```

并且：
- **禁止**把 float 直接写进 `fragColor`（RGBA8 会量化/丢精度/引发不稳定）
- 必须使用本方案提供的 `SG_LOAD_*` 读取 + `sg_store*` 写入
- 避免用 alpha 存数据（可能被预乘/混色）

## 2) RGBA8 编码语义（必须理解并按此实现）
### 2.1 “虚拟 texel = vec4”的 lane 展开
- 虚拟坐标 `vpos = ivec2(x, y)`
- 对应的物理像素横向展开为 4 个 lane：`(x*4 + lane, y)`，`lane=0..3` 分别存 vec4 的 x/y/z/w
- 因此物理输出尺寸必须是：
  $$\text{physWidth} = \text{virtualWidth} * 4,\quad \text{physHeight} = \text{virtualHeight}$$

### 2.2 读写 API（强制）
读取（必须显式传 sampler + 虚拟尺寸 token）：
- `vec4 s = SG_LOAD_VEC4(iChannel0, vpos, VSIZE);`
- `float f = SG_LOAD_FLOAT(iChannel0, vpos, VSIZE);`
- `vec2/vec3` 用 `SG_LOAD_VEC2/SG_LOAD_VEC3`

写入（用 sg_feedback_rgba8 的 store，把“虚拟坐标”的数据写回当前像素）：
- `sg_storeVec4(re, va, fragColor, p);`
- 范围写入：`sg_storeVec4Range(reRect, va, fragColor, p);`

范围映射（当原数据不在 [-1,1]）：
- 写入前用 `sg_encodeRangeToSigned(x, minV, maxV)`
- 读取后用 `sg_decodeSignedToRange(x, minV, maxV)`

## 3) 线性采样导致 lane 串扰（必须按情况处理）
Flutter 的 `sampler2D` 在部分平台可能线性采样，导致相邻 lane 轻微混合，从而污染“vec4 寄存器”。

当某个寄存器**本质只存一个标量**（例如计时器、分数、状态标志）：
- 写入建议：把标量复制到 `xyzw`（`vec4(v, v, v, v)`），降低 lane 混合影响
- 读取建议：先 `vec4 raw = SG_LOAD_VEC4(...);` 再 `float v = dot(raw, vec4(0.25));` 取平均，进一步减抖

## 4) 反馈链路（读写冲突的标准解法）
优先采用以下结构来避免某些后端读写冲突：
1) BufferA：读上一帧（iChannel0）→ 更新状态 → 写出（RGBA8 编码）
2) BufferB：passthrough（复制 A 输出）
3) Main：只读 BufferB 渲染

如果出现“状态分叉/闪烁”：把 feedback 改成 ping-pong：
- A 读 B(prev)，写 A(curr)
- B 读 A(curr)，写 B(curr)
- Main 读 B

## 5) Dart 侧接线（你必须明确告知怎么做）
你输出的迁移结果必须包含一段 Dart 接线说明，至少写清：
- 每个数据 buffer 的 `fixedOutputSize` 设置为**物理尺寸**：`Size(VSIZE.x*4, VSIZE.y)`
- 哪个 buffer 调用 `.feedback()`（或采用 ping-pong 时 A/B 如何互 feed）
- Main 读取哪个 buffer

并明确选择 `iResolution/iMouse` 的语义：
- **Buffer-space（默认）**：`iResolution`/`iMouse` 等于当前 buffer 渲染目标（即 fixedOutputSize）。如果 shader 用虚拟格子坐标，需要在 shader 内把 x 方向 `/4` 还原。
- **Surface-space**：当 BufferA 需要屏幕语义做交互/物理时，Dart 侧对该 buffer 打开 `useSurfaceSizeForIResolution = true`。

## 6) 稳定性红线（避免把坏数据写进反馈）
一旦 `NaN/Inf` 写入 RGBA8 feedback，会在后续帧扩散导致闪烁/逻辑崩坏。
- 对 `1/x`、`normalize`、`inversesqrt(dot(v,v))` 等，必须加最小阈值保护，避免除以 0
- 所有临时变量/分支路径必须显式初始化

## 7) 交付清单（你输出必须包含）
- 修改后的 `BufferA.frag`：使用 `SG_LOAD_*` + `sg_store*` 完成状态读写
- `BufferB.frag`：passthrough（或 ping-pong 的 B）
- `Main.frag`：只读最终状态纹理渲染（必要时解码/平均 lane）
- Dart 侧 buffers 连接示例（含 `fixedOutputSize`、feedback/ping-pong、Main 读取）

> 遇到编译错误时：遵循通用 prompt 的“四类最小修复策略”（数组/位运算/texelFetch/未初始化），不要引入额外功能。
