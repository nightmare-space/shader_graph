# ShaderToy → Flutter 移植指南 (反馈/环绕模式)

> 关键背景：Flutter RuntimeEffect/SkSL **不** 公开真实的采样器状态（wrap/filter 无法像 Shadertoy 中那样设置）。某些 GLSL 特性也受限（例如 `texelFetch`、位运算、全局数组初始化等）。本项目通过"头文件 + 宏 + Dart 端 uniforms/samplers 连接"的方式将常见 Shadertoy 代码移植为可运行形式。

---

## 0. 关键文件和术语

- 统一头文件（必须包含）：
  - `example/shaders/common/common_header.frag`
- Shadertoy 主入口包装器：
  - `example/shaders/common/main_shadertoy.frag`
- RGBA8 反馈编码工具（可选包含，取决于 common_header）：
  - `example/shaders/common/sg_feedback_rgba8.frag`
- Dart 端输入和环绕模式：
  - `lib/src/shader_input.dart`
  - `lib/src/shader_buffer.dart`

术语：

- **pass/buffer**：Shadertoy BufferA/BufferB/Main 中间渲染目标
- **feedback**：读取上一帧输出（状态机/游戏逻辑/分数/位置）
- **virtual texel**：逻辑状态网格（例如 14×14）
- **physical pixel**：实际输出像素。为了模拟"一个 texel = 一个 vec4"，`sg_feedback_rgba8` 将一个虚拟 texel 扩展为 4 个水平物理像素。

---

## 1. 正确的环绕模式用法 (repeat/mirror/clamp)

### 1.1 Dart 端：为每个输入通道设置环绕模式

本项目通过 `WrapMode`（编码为 `iChannelWrap` 中的浮点数）来建模环绕模式：

- `WrapMode.clamp`
- `WrapMode.repeat`
- `WrapMode.mirror`

示例（说明）：

```dart
final buf = 'shaders/xxx.frag'.shaderBuffer
  ..feed('assets/tex.png', wrap: WrapMode.repeat)
  ..feed('assets/tex2.png', wrap: WrapMode.mirror);
```

映射：

- `iChannelWrap.x` → iChannel0
- `iChannelWrap.y` → iChannel1
- `iChannelWrap.z` → iChannel2
- `iChannelWrap.w` → iChannel3

> 注意：这不是真实的 GPU 采样器状态。环绕模式是通过着色器端的 UV 变换实现的。

### 1.2 着色器端：采样必须通过环绕宏

`common_header.frag` 提供：

- `sg_wrapUv(uv, mode)`：clamp/repeat/mirror UV 变换
- `SG_TEX0/1/2/3(tex, uv)`：使用对应的 `iChannelWrap` 分量进行采样

因此在你的着色器中：

- **不要** 直接调用 `texture(iChannelN, uv)`（它会忽略环绕配置）
- 应该调用：

```glsl
vec4 c0 = SG_TEX0(iChannel0, uv);
vec4 c1 = SG_TEX1(iChannel1, uv);
```

如果你更喜欢显式形式：

```glsl
vec2 u = sg_wrapUv(uv, iChannelWrap.x);
vec4 c0 = texture(iChannel0, u);
```

### 1.3 关于 UV 语义

- 许多 Shadertoy 着色器在 `[0,1]` UV 空间中采样纹理。
- 某些着色器使用中心坐标（例如 `uv = (fragCoord - 0.5*iResolution)/iResolution.y`，大约 `[-1,1]`）。

环绕模式在数学上定义为对输入 UV 进行 clamp/repeat/mirror：

- 如果你的 UV 不在 `[0,1]` 范围内，repeat/mirror 仍然有效，但视觉结果可能与"标准纹理坐标"不同（这是预期的）。

---

## 2. `sg_feedback_rgba8`：RGBA8 反馈（前一帧）规范

### 2.1 为什么存在

Flutter 中间渲染目标通常是 `ui.Image`（RGBA8）。将高精度浮点状态直接写入 RGBA8 经常导致：

- 精度不足/量化抖动
- 某些 GPU 路径上的轻微邻近混合
- 一旦写入 `NaN/Inf`，它就会持续污染未来帧

`sg_feedback_rgba8` 的目标：

- 在 RGBA8 中进行稳定的状态存储
- 减少线性采样串扰以保护状态机

### 2.2 包含顺序

按此顺序包含：

```glsl
#include <../common/common_header.frag>
#include <../common/sg_feedback_rgba8.frag>
```

注意：`sg_feedback_rgba8.frag` 依赖于 `common_header.frag` 提供的宏，如 `SG_TEXELFETCH`。

### 2.3 虚拟 texel 和物理输出大小

`sg_feedback_rgba8` 将通道水平扩展以模拟每个 texel 存储一个 vec4：

- 虚拟 `(x, y)` 映射到物理 `(x*4 + lane, y)`，lane=0..3 映射到 vec4 的 x/y/z/w

因此：

- 虚拟大小 = `VSIZE = vec2(VW, VH)`
- 物理输出大小 = `(VW*4, VH)`

Dart 端必须匹配：

- 为数据缓冲设置 `fixedOutputSize = Size(VW*4, VH)`

否则读/写会偏移。

### 2.4 读/写 API（宏 + 存储函数）

#### 读：`SG_LOAD_*` 宏（显式通道标记）

示例：

```glsl
const vec2 VSIZE = vec2(14.0, 14.0);

vec4 s = SG_LOAD_VEC4(iChannel0, ivec2(0, 0), VSIZE);
float a = SG_LOAD_FLOAT(iChannel0, ivec2(1, 0), VSIZE);
vec3 v = SG_LOAD_VEC3(iChannel0, ivec2(2, 0), VSIZE);
```

关键点：

- 始终使用 `SG_LOAD_*` 并显式传递通道标记（`iChannelN`）。

#### 写：`sg_storeVec4` / `sg_storeVec4Range`

在 `mainImage(out vec4 fragColor, in vec2 fragCoord)` 末尾，按寄存器地址写入：

```glsl
ivec2 p = ivec2(fragCoord - 0.5);

fragColor = vec4(0.0);
sg_storeVec4(txSomeReg, valueSigned, fragColor, p);
```

其中：

- `p` 是物理像素坐标（通常 `ivec2(fragCoord - 0.5)`）
- `valueSigned` 必须编码为 **[-1,1]**（见下一节）

### 2.5 范围编码：将任何范围映射到 [-1,1]

`sg_feedback_rgba8` 存储假设：

- 标量通道存储在 [-1, 1]

所以将真实范围（例如分数 0..50000）映射到 [-1,1]，并在读取后解码。

`sg_feedback_rgba8.frag` 中的常见辅助函数：

- `sg_encodeRangeToSigned(v, min, max)`
- `sg_decodeSignedToRange(s, min, max)`
- `sg_encode01ToSigned(v01)` / `sg_decodeSignedTo01(s)`

### 2.6 串扰缓解（重要）

在某些 GPU 路径上，`sampler2D` 采样可能略微是线性的，混合通道（`x*4+0..3`）并破坏状态。

建议：

- 对于"单标量"寄存器：写 `vec4(v,v,v,v)`
- 对于这些寄存器的读取：平均（例如 `dot(raw, vec4(0.25))`）

### 2.7 NaN/Inf 保护（反馈可以永远污染）

一旦写入 `NaN/Inf`，它就会在未来的帧中传播。

常见触发器：

- 除以 0
- 当 `v` 接近 0 时的 `normalize(v)` / `inversesqrt(dot(v,v))`
- `log(0)`

缓解措施：

- 钳制分母（例如 `max(abs(x), 1e-6)`）
- 在归一化前检查向量长度

---

## 3. `texelFetch` 替换（方案 A：每通道分辨率 uniforms）

`common_header.frag` 提供：

- `uniform vec2 iChannelResolution0..3;`
- `SG_TEXELFETCH(tex, ipos, sizePx)`：texel 中心 UV + snap 替换
- `SG_TEXELFETCH0/1/2/3(ipos)`：`iChannel0..3` 的便捷宏（推荐）

更倾向于：

```glsl
vec4 v = SG_TEXELFETCH0(ivec2(x, y));
```

而不是硬编码 `textureSize` 常数。

---

## 4. 使用 Copilot 提示移植 Shadertoy（推荐）

本仓库包含两个移植提示：

- `.github/prompts/port_shader.prompt.md`：通用移植（可能不使用反馈）
- `.github/prompts/port_shader_float.prompt.md`：多-pass + `sg_feedback_rgba8` 规范（推荐用于游戏/状态机）

### 4.1 开始之前

1) 确保在消费应用（通常是 `example/`）的 `pubspec.yaml` 中的 `flutter: shaders:` 下声明着色器资源。

2) 识别 Shadertoy passes：

- BufferA/BufferB/BufferC/BufferD
- Image（主输出）

3) 识别每个 pass 的输入通道（iChannel0..）：

- 哪个缓冲区输出（来自哪个 pass）
- 哪个图像资源
- 键盘纹理输入（本项目提供）

### 4.2 着色器文件结构（必须遵循）

对于每个 pass 文件：

1) 添加移植日志头（可选但推荐）
2) **第一个 include 必须是**：

```glsl
#include <../common/common_header.frag>
```

3) 声明需要的 `uniform sampler2D iChannelN;`

4) 如果 pass 使用 `sg_feedback_rgba8`，则包含：

```glsl
#include <../common/sg_feedback_rgba8.frag>
```

5) 在文件末尾包含：

```glsl
#include <../common/main_shadertoy.frag>
```

### 4.3 常见 SkSL 不兼容性（最小修复）

- **不要** 将 `sampler2D` 作为函数参数传递（使用宏）
- 避免全局 `const int[] = int[](...)` 初始化（使用 if-chain 获取器）
- 避免位运算（`>> & | ^`）和整数 `%`（使用 `floor/mod/pow` 替代）
- 避免本地 `texelFetch`（使用 `SG_TEXELFETCH*`）
- 显式初始化局部变量（SkSL 更敏感）

### 4.4 Dart 端连接（最小多-pass + 反馈方案）

典型管道（避免读/写冲突）：

- BufferA：读取前一帧反馈，更新状态
- BufferB：传递（复制 BufferA 输出）
- Main：通过仅读取 BufferB 进行渲染

关键点：

- 数据缓冲必须将 `fixedOutputSize` 设置为物理大小（例如 `Size(VSIZE.x*4, VSIZE.y)`）
- 通过 `.feedback()` 或 `.feed(buffer, usePreviousFrame: true)` 进行反馈
- 如果你需要在渲染到微小的 fixedOutputSize 时使用表面大小的 `iResolution/iMouse`，则在该缓冲区上启用 `useSurfaceSizeForIResolution = true`

> 注意：一旦启用 `useSurfaceSizeForIResolution`，不要从 `iResolution` 派生封装比率（它不再等于渲染目标大小）。

---

## 5. 最小代码片段

### 5.1 环绕采样

```glsl
#include <../common/common_header.frag>

uniform sampler2D iChannel0;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = SG_TEX0(iChannel0, uv);
}

#include <../common/main_shadertoy.frag>
```

### 5.2 键盘纹理（更倾向于 `SG_TEXELFETCH*`）

```glsl
// 假设 iChannel1 是键盘纹理
float keyDown(int keyCode) {
    return SG_TEXELFETCH1(ivec2(keyCode, 0)).x;
}
```

---

## 6. 故障排除清单

- 视觉"分割/抖动/闪烁"：
  - 通道串扰？（尝试写入 `vec4(v,v,v,v)` 并平均读取）
  - 写入了 NaN/Inf？（检查除以 0 / 归一化 / log）

- 仅显示角落/拉伸：
  - 是否再次将 `iResolution` 乘以 dpr/scale？（这里 `iResolution` 已经以像素为单位）
  - 在实际渲染到 `fixedOutputSize` 时启用了 `useSurfaceSizeForIResolution`？（坐标不匹配）

- 环绕模式不工作：
  - 是否通过 `SG_TEX0/1/2/3` 或 `sg_wrapUv` 采样？（不要直接使用 `texture(iChannelN, uv)`）

---

## 7. 参考：提示文件

- `.github/prompts/port_shader.prompt.md`
- `.github/prompts/port_shader_float.prompt.md`
