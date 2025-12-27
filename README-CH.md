# Shader Graph

`shader_graph` 是一个面向 Flutter `FragmentProgram/RuntimeEffect` 的实时多 Pass Shader 执行框架

它现在甚至可以运行一个完整的着色器实现的游戏！！！

<img src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Bricks%20Game.gif?raw=true"> 

用“渲染图”的方式把多个 `.frag` 串起来跑（包含 Shadertoy 风格的 BufferA/BufferB/Main、feedback/ping-pong）

支持键盘输入、鼠标输入、图片输入，支持 Shadertoy 风格的 Wrap(Clamp/Repeat/Mirror)

如果你只是想快速把一个着色器显示出来，可以直接用简单的 Widget 加载（例如 `ShaderSurface.auto`）

当你需要更复杂的链路（多 Pass / 多输入 / feedback / ping-pong）时，
再使用 `ShaderBuffer` 声明输入与依赖关系

框架负责拓扑调度与逐帧执行，并把每个 pass 的输出作为 `ui.Image` 传给下游

[English README](README.md) | 中文

## 截图

### 游戏

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

### 示例

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

我现在已经使用这个库，创建了 [awesome_flutter_shaders](https://github.com/mengyanshou/awesome_flutter_shaders) 项目，里面有超过 100+ 个着色器移植示例，欢迎查看 

## 功能

- [x] 支持将一个 Shader 作为 Buffer 然后输入到另一个 Shader (Multi-Pass)
- [x] 支持将图片作为 Buffer 输入到 Shader
- [x] 支持反馈输入 (Ping-Pong，即自己的上一帧输入到自己的下一帧)
- [x] 支持鼠标事件
- [x] 支持键盘事件输入
- [x] 支持 Wrap（Clamp/Repeat/Mirror）
- [x] 自动拓扑排序
- [x] 支持 texelFetch，自动计算 texel 大小 (需要使用宏以及更改着色器代码) 

**Float 支持（RGBA8 feedback）**

Flutter 的 feedback 纹理通常是 RGBA8，无法稳定存储任意 float 状态。
本项目提供统一的移植方案 `sg_feedback_rgba8`：把标量编码进 RGB（24-bit），并通过横向 4-lane 打包保留 “一个 texel = vec4” 的语义。

**texelFetch 支持**
通过 `common_header.frag` 提供的 `SG_TEXELFETCH` / `SG_TEXELFETCH0..3` 宏替代原生的 `texelFetch` 调用，并使用 `iChannelResolution0..3` 自动获得通道分辨率。

## 路线图
- [ ] 支持将 Widget 渲染成纹理，然后作为 Buffer 输入到 Shader
- [ ] 支持 Shadertoy 风格的 Filter(Linear/Nearest/Mipmap)，这个会直接决定部分着色器效果是否一致

## 前言

我以前对着色器的理解总是很模糊，朋友推荐我看 [The Book of Shaders](https://thebookofshaders.com/)，看了一部分，我总是不理解其中的原理，但我觉得 Shadertoy 上的着色器太有趣，有的甚至都是一个完整的游戏，这太疯狂啦，所以我想把它移植到 Flutter 上运行

首先感谢 [shader_buffers](https://github.com/alnitak/shader_buffers) 的作者，在最初可以让我将一些着色器代码移植到 Flutter

也正是因为在使用这个库的时候，发现了有些不足的地方，且与我希望的设计和原设计，有比较大的差别，其中的缺陷我均以提交 PR 的方式帮助修复

但我仍然有太多需要实现的需求，不仅是 shader_buffers，而是几乎所有的 Flutter 中存在的着色器框架都没有解决的问题，所以 shader_graph 诞生了

## 快速开始

首先，你必须清楚，Shadertoy 的着色器代码，是需要移植到 Flutter，才能运行的，项目里面有辅助移植的 Prompt [port_shader.prompt](.github/prompts/port_shader.prompt.md)

使用如下，先打开需要移植的着色器路径，它应该放在项目中，在 Copilot 等 AI 工具中，输入如下 Prompt：
```text
Follow instructions in [port_shader.prompt.md](.github/prompts/port_shader.prompt.md).
```

项目有比较完整的示例代码，见 [example](example/lib/main.dart)

### 最小可运行示例

**1) 单 shader（Widget）**
```dart
SizedBox(
  height: 240,
  // shader_asset_main ends with .frag
  child: ShaderSurface.auto('$shader_asset_main'),
)
```

**2) 两个 pass（A → Main）**
见 [multi_pass.dart](example/lib/multi_pass.dart)
```dart
ShaderSurface.builder(() {
  final bufferA = '$shader_asset_buffera'.shaderBuffer;
  final main = '$shader_asset_main'.shaderBuffer.feed(bufferA);
  return [bufferA, main];
})
```

**3) feedback（A → A，再接一个 Main 显示）**
见 [bricks_game.dart](example/lib/game/bricks_game.dart)
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

它可以是最终渲染的着色器，也可以作为中间的一个 Buffer 喂给另一个着色器，通常我们使用 extension 来创建它

```dart
'$asset_path'.shaderBuffer;
```

它等价于
```dart
final buffer = ShaderBuffer('$asset_path');
```

配合 `ShaderSurface.auto` `ShaderSurface.builder` 使用，或使用 `ShaderSurface.buffers` 传入`List<ShaderBuffer>`

### 添加输入

都统一使用 Extension buffer.feed 的方式添加，函数会通过字符串的后缀来判断输入类型，当然，也可以使用原始的 `feedShader`/`feedShaderFromAsset`/...

**添加另一个着色器作为输入**

```dart
// use ShaderBuffer directly
buffer.feed(anotherBuffer);
// use string path which ends with .frag
buffer.feed("$asset_path");
```

**添加键盘事件作为输入**

```dart
buffer.feedKeyboard();
```

**添加资源图片作为输入**

> 通常用来输入噪声, 纹理等

这部分可以见 [awesome_flutter_shaders](https://github.com/mengyanshou/awesome_flutter_shaders/tree/main/assets)

```dart
buffer.feed('$image_asset_path');
```

**Ping-Pong**
也就是自己给自己，不用担心死循环，shader_graph 做了适配

保留原始的 Shadertoy 语义, 这也是 Shadertoy 上非常常见的的 Ping-Pong 反馈

```dart
buffer.feedback();
```


**设置 Wrap（repeat/mirror/clamp）**

Flutter runtime shader 不直接暴露 sampler 的 wrap/filter 状态。
本项目通过 uniform `iChannelWrap`（x/y/z/w 对应 iChannel0..3）在 shader 内做 UV 变换来实现 wrap。

在 Dart 侧为每个输入设置 wrap：

```dart
final buffer = '$shader_asset_path'.shaderBuffer;
buffer.feed('$texture_asset_path', wrap: WrapMode.repeat);
```

在 shader 侧采样时使用 `common_header.frag` 提供的 `SG_TEX0/1/2/3(...)`（不要直接使用 `texture(iChannelN, uv)`）。



## ShaderSurface.auto
`ShaderSurface.auto` 返回一个 `Widget`
```dart
Center(
  child: ShaderSurface.auto('$shader_asset_path'),
)
```
你可以把它放在任何地方，注意，通常需要告诉它高度

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

`ShaderSurface.auto` 支持传入 String（shader 资源路径）/ `ShaderBuffer` / `List<ShaderBuffer>`

当 Shader 有输入时，传入 `ShaderBuffer` 更合适。

```dart
Builder(builder: (context) {
  final mainBuffer = '$shader_asset_path'.shaderBuffer;
  mainBuffer.feed('$noise_asset_path');
  return ShaderSurface.auto(mainBuffer);
}),
```
或者使用 extension
```dart
ShaderSurface.auto(
  '$shader_asset_path'.shaderBuffer.feed('$noise_asset_path'),
);
```

### 使用 Extension
当多个 ShaderBuffer 都需要有输入的时候，就会变成这样
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

使用 Extension 经过优化可以变成这样
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

上面的例子都是只有一个着色器存在，但是如果是复杂的链路，例如
```text
┌─────┐    ┌─────┐    ┌─────┐
│  A  │───▶│  B  │───▶│  C  │
│ ↺ A │    └─────┘    └─────┘
└─────┘
```
或者
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


`ShaderSurface` 提供了 `builder` 来应对这种情况，你可以像这个使用，这样可以不会使用多个 `Builder(Flutter)`
> Builder 不会消失，只是它转移了
```dart
ShaderSurface.builder(() {
  final bufferA = '$asset_shader_buffera'.feedback().feedKeyboard();
  final mainBuffer = '$asset_shader_main'.feed(bufferA);
  // Standard scheme: physical width = virtual * 4
  bufferA.fixedOutputSize = const Size(14 * 4.0, 14);
  return [bufferA, mainBuffer];
})
```

## 拓扑排序
对于 Shadertoy 的多 pass，只有当“同一帧”的依赖关系不形成环（DAG）时，最终的 Buffer 列表才可以拓扑排序。

也就是说：每个 pass 只能读取它依赖的其它 pass 的输出（或外部输入），不能在同一帧出现循环依赖（例如 A 读 B 同时 B 读 A）。

feedback / ping-pong 读取的是“上一帧”的输出，属于跨帧依赖，通常不会破坏当前帧的拓扑排序。

注意：单个 Buffer 内部的输入通道顺序（iChannel0..N）仍必须按 Shadertoy 的定义顺序 feed，因为 shader 侧采样通道是按顺序绑定的。

见 [pacman_game.dart](example/lib/game/pacman_game.dart)

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

## ShaderToy → Flutter（shader_graph）迁移与 Feedback/Wrap 指南

> 重要背景：Flutter RuntimeEffect/SkSL **不暴露真实 sampler 状态**（wrap/filter 不能像 Shadertoy 那样直接设置），且对某些 GLSL 特性有限制（例如 `texelFetch`、位运算、全局数组初始化等）。本项目用“头文件 + 宏 + Dart 侧喂 uniforms/samplers”的方式把常见 Shadertoy 代码迁移到可运行的形态。

---

### 0. 关键文件与术语

- 统一头文件（强制 include）：
  - `example/shaders/common/common_header.frag`
- Shadertoy 主入口包装：
  - `example/shaders/common/main_shadertoy.frag`
- RGBA8 feedback 编码工具（可选 include，依赖 common_header）：
  - `example/shaders/common/sg_feedback_rgba8.frag`
- Dart 侧输入与 wrap：
  - `lib/src/shader_input.dart`
  - `lib/src/shader_buffer.dart`

术语：

- **pass/buffer**：Shadertoy 的 BufferA/BufferB/Main 等一张张中间渲染目标
- **feedback**：读上一帧的输出（常用于“状态机/游戏逻辑/积分/位置”等）
- **virtual texel**：逻辑上的状态网格（例如 14×14）
- **physical pixel**：实际输出的像素。`sg_feedback_rgba8` 为了模拟 vec4 texel，把 1 个 virtual texel 展开成横向 4 个 physical 像素。

---

### 1. Wrap（repeat/mirror/clamp）的正确用法

#### 1.1 Dart 侧：给每个输入通道设置 wrap

本项目用 `WrapMode` 表示 wrap（会被编码为 float 写入 `iChannelWrap`）：

- `WrapMode.clamp`
- `WrapMode.repeat`
- `WrapMode.mirror`

典型用法（示意）：

```dart
final buf = 'shaders/xxx.frag'.shaderBuffer
  ..feed('assets/tex.png', wrap: WrapMode.repeat)
  ..feed('assets/tex2.png', wrap: WrapMode.mirror);
```

对应关系：

- `iChannelWrap.x` → iChannel0
- `iChannelWrap.y` → iChannel1
- `iChannelWrap.z` → iChannel2
- `iChannelWrap.w` → iChannel3

> 注意：这不是 GPU 真实 sampler state，而是 shader 内做 `uv` 变换实现 wrap。

#### 1.2 Shader 侧：采样时必须走 wrap 宏

在 `common_header.frag` 里已经提供：

- `sg_wrapUv(uv, mode)`：把 uv 做 clamp/repeat/mirror
- `SG_TEX0/1/2/3(tex, uv)`：按 iChannelWrap 对应分量采样

因此你的 shader 里：

- **不要**直接 `texture(iChannelN, uv)`（会忽略 wrap 配置）
- **要**改成：

```glsl
vec4 c0 = SG_TEX0(iChannel0, uv);
vec4 c1 = SG_TEX1(iChannel1, uv);
```

如果你希望更显式，也可以写：

```glsl
vec2 u = sg_wrapUv(uv, iChannelWrap.x);
vec4 c0 = texture(iChannel0, u);
```

#### 1.3 关于 uv 坐标语义

- Shadertoy 很多纹理采样默认使用 `[0,1]` 纹理坐标。
- 也有一些 shader 用中心坐标（例如 `uv = (fragCoord - 0.5*iResolution)/iResolution.y`，范围大致 `[-1,1]`）。

wrap 的数学定义是对输入 uv 做 clamp/repeat/mirror：

- 如果你的 uv 不在 `[0,1]`，repeat/mirror 也能工作，但视觉效果可能与“标准贴图坐标”不同（这是预期差异，不是 bug）。

---

### 2. `sg_feedback_rgba8`：RGBA8 feedback（上一帧）规范

#### 2.1 为什么需要它

Flutter 的中间渲染目标通常是 `ui.Image`（RGBA8）。直接把高精度 float 状态写进 RGBA8，会遇到：

- 精度不足、量化抖动
- 某些平台路径可能存在线性采样，导致相邻像素轻微混合
- feedback 一旦写入 `NaN/Inf`，下一帧读回会持续污染（“永久扩散”）

`sg_feedback_rgba8` 的目标：

- 在 RGBA8 中 **稳定** 存/取状态
- 尽量降低线性采样串扰对状态机的影响

#### 2.2 include 顺序

请按下面顺序 include（正常导包）：

```glsl
#include <../common/common_header.frag>
#include <../common/sg_feedback_rgba8.frag>
```

说明：`sg_feedback_rgba8.frag` 依赖 `common_header.frag` 提供的 `SG_TEXELFETCH` 等宏。

#### 2.3 虚拟 texel 与 physical 输出尺寸

`sg_feedback_rgba8` 使用“横向 lane 展开”来模拟一个 virtual texel 存 vec4：

- virtual `(x, y)` 对应 physical `(x*4 + lane, y)`，lane=0..3 对应 vec4 的 x/y/z/w

因此：

- virtual 尺寸 = `VSIZE = vec2(VW, VH)`
- physical 输出尺寸 = `(VW*4, VH)`

Dart 侧必须匹配：

- 对数据 buffer 设置 `fixedOutputSize = Size(VW*4, VH)`

否则读写坐标会错位。

#### 2.4 读写 API（强制使用宏 + store 函数）

##### 读：用 `SG_LOAD_*` 宏（必须显式传通道 token）

推荐写法：

```glsl
const vec2 VSIZE = vec2(14.0, 14.0);

vec4 s = SG_LOAD_VEC4(iChannel0, ivec2(0, 0), VSIZE);
float a = SG_LOAD_FLOAT(iChannel0, ivec2(1, 0), VSIZE);
vec3 v = SG_LOAD_VEC3(iChannel0, ivec2(2, 0), VSIZE);
```

要点：

- 读取统一使用 `SG_LOAD_*` 宏，并且必须显式传入通道 token（`iChannelN`）。

##### 写：用 `sg_storeVec4` / `sg_storeVec4Range`

在 `mainImage(out vec4 fragColor, in vec2 fragCoord)` 末尾，把你想写入的数据按寄存器地址写回：

```glsl
ivec2 p = ivec2(fragCoord - 0.5);

fragColor = vec4(0.0);
sg_storeVec4(txSomeReg, valueSigned, fragColor, p);
```

其中：

- `p` 是 physical 像素坐标（通常 `ivec2(fragCoord - 0.5)`）
- `valueSigned` 是 **已编码到 [-1,1]** 的值（见下一节）

#### 2.5 范围编码：把任意范围映射到 [-1,1]

`sg_feedback_rgba8` 的存储假设是：

- 单通道标量存储在 [-1, 1]

所以你需要把现实范围（例如积分 0..50000）映射到 [-1,1]，并在读取后解码回来。

常用函数（在 `sg_feedback_rgba8.frag` 内）：

- `sg_encodeRangeToSigned(v, min, max)`
- `sg_decodeSignedToRange(s, min, max)`
- `sg_encode01ToSigned(v01)` / `sg_decodeSignedTo01(s)`

#### 2.6 抗串扰建议（很关键）

某些平台上 `sampler2D` 可能发生轻微线性采样，导致 lane（x*4+0..3）之间混合，进而把状态污染。

建议：

- 对“只有一个标量”的寄存器：写入时复制到 4 个 lane（`vec4(v,v,v,v)`）
- 读取时对这类寄存器：做一次平均（`dot(raw, vec4(0.25))`）进一步降低抖动

这在已迁移的例子里可以看到（例如 Bricks/Pacman 的某些寄存器）。

#### 2.7 NaN/Inf 防护（feedback 会“永久污染”）

一旦写入 `NaN/Inf`，之后每帧读回都会扩散。

常见触发点：

- 除以 0
- `normalize(v)` / `inversesqrt(dot(v,v))` 里 v 非常接近 0
- `log(0)`

做法：

- 对关键除数加下限（如 `max(abs(x), 1e-6)`）
- 对 normalize 做长度判断

---

### 3. `texelFetch` 的替代（Plan A：通道分辨率 uniforms）

`common_header.frag` 提供：

- `uniform vec2 iChannelResolution0..3;`
- `SG_TEXELFETCH(tex, ipos, sizePx)`：texel-center UV + snap 的通用替代
- `SG_TEXELFETCH0/1/2/3(ipos)`：对 `iChannel0..3` 的便捷宏（推荐）

迁移时建议优先：

```glsl
vec4 v = SG_TEXELFETCH0(ivec2(x, y));
```

而不是手写 `textureSize` 常量。

---

### 4. 用 Copilot Prompts 迁移 Shadertoy（推荐流程）

本项目提供两个迁移 prompt：

- `.github/prompts/port_shader.prompt.md`：通用迁移（不一定用 feedback）
- `.github/prompts/port_shader_float.prompt.md`：多 pass + `sg_feedback_rgba8` 规范（推荐用于游戏/状态机）

#### 4.1 迁移前准备

1) 确认 shader 资源在 consuming app（通常是 `example/`）的 `pubspec.yaml` 中声明到了 `flutter: shaders:`。

2) 识别 Shadertoy 的每个 pass：

- BufferA/BufferB/BufferC/BufferD
- Image（主输出）

3) 识别每个 pass 的输入通道（iChannel0..）：

- 来自哪个 buffer（上一 pass 输出）
- 来自图片 asset
- 来自键盘纹理（本项目已有 KeyboardInput）

#### 4.2 Shader 文件结构（必须遵守）

每个 pass 文件：

1) 文件开头放迁移日志（可选但推荐）
2) **第一行 include 必须是**：

```glsl
#include <../common/common_header.frag>
```

3) 紧接着声明你需要的 `uniform sampler2D iChannelN;`

4) 如果该 pass 用 `sg_feedback_rgba8`，则紧接着 include：

```glsl
#include <../common/sg_feedback_rgba8.frag>
```

5) 文件底部必须 include：

```glsl
#include <../common/main_shadertoy.frag>
```

#### 4.3 SkSL 常见不兼容点（迁移时按最小改动修复）

- **不要**把 `sampler2D` 当函数参数传递（改为宏）
- **不要**全局 `const int[] = int[](...)` 初始化（用 if-chain getter）
- **不要**位运算（`>> & | ^`）和 int `%`（用 `floor/mod/pow` 等替代）
- **不要**依赖 `texelFetch`（用 `SG_TEXELFETCH*` 替代）
- **所有局部变量显式初始化**（SkSL 对未初始化更敏感）

#### 4.4 Dart 侧接线（多 pass + feedback 的最小范式）

典型链路（避免读写冲突）：

- BufferA：读上一帧 feedback，更新状态
- BufferB：passthrough（只复制 BufferA 输出）
- Main：只读 BufferB 渲染

要点：

- 数据 buffer 必须设置 `fixedOutputSize` 为 physical 尺寸（例如 `Size(VSIZE.x*4, VSIZE.y)`）
- feedback 使用 `.feedback()` 或 `.feed(buffer, usePreviousFrame: true)`
- 如果需要屏幕语义的 `iResolution/iMouse`（而 buffer 渲染到 tiny fixedOutputSize），对该 buffer 打开 `useSurfaceSizeForIResolution = true`

> 注意：一旦开启 `useSurfaceSizeForIResolution`，shader 内不要再用 `iResolution` 反推 pack 比例（因为 `iResolution` 不再等于 render target）。

---

### 5. 最小可用示例（片段）

#### 5.1 Wrap 采样

```glsl
#include <../common/common_header.frag>

uniform sampler2D iChannel0;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = SG_TEX0(iChannel0, uv);
}

#include <../common/main_shadertoy.frag>
```

#### 5.2 键盘纹理（推荐用 `SG_TEXELFETCH*`）

```glsl
// 假设 iChannel1 是 keyboard texture
float keyDown(int keyCode) {
    return SG_TEXELFETCH1(ivec2(keyCode, 0)).x;
}
```

---

### 6. 排查清单（遇到画面异常时）

- 画面“分叉/抖动/闪烁”：
  - 是否发生 lane 串扰？（尝试对标量寄存器写 `vec4(v,v,v,v)` + 读取取平均）
  - 是否写入了 NaN/Inf？（检查除以 0、normalize、log）

- 画面“只显示一角/被拉伸”：
  - 是否在 shader 里把 `iResolution` 又乘了 dpr/scale？（本项目里 iResolution 已是像素空间）
  - 是否打开了 `useSurfaceSizeForIResolution` 但 pass 实际渲染到 `fixedOutputSize`？（坐标系会不一致）

- 贴图 wrap 不生效：
  - 是否用 `SG_TEX0/1/2/3` 或 `sg_wrapUv` 采样？（不要直接 `texture(iChannelN, uv)`）

---

### 7. 参考：Prompt 文件

- `.github/prompts/port_shader.prompt.md`
- `.github/prompts/port_shader_float.prompt.md`

## toImageSync 内存泄露

[toImageSync retains display list which can lead to surprising memory retention](https://github.com/flutter/flutter/issues/138627)

这里之前踩过一个坑：在 Flutter 3.38.5（macOS）上，`toImageSync` 仍可能出现明显的内存占用增长。
我在本机测试时，应用运行一段时间会持续吃掉物理内存并开始占用 Swap，最终占用会变得非常夸张。（超过200GB）

当前工程的规避方式：
- 改用异步的 `toImage()`（避免 `toImageSync` 的高风险路径）
- 但不能每一帧都触发一次转图，否则仍会造成巨大开销
- 因此用 Ticker/节流策略：只在“新的一帧 image 准备好”之后再触发下一次更新

## Copilot

老实说，我手上正在维护的项目太多，其中很多我在乎的项目，都是半停更的状态

所以这个项目的实现，我借助了比较多的 AI 来完成这个项目，主要是 GPT5.2，也正是因为我做了比较大量的开源，每个月有一些免费的额度，我爱开源！

但是我尽量保证是我驱动它，而不是它驱动我，我对着色器相关很多都不太熟，这部分的代码实现几乎都是它完成的

我负责整理，编写 Prompt，虽然是它负责比较多，但其中的调试验证也花费了不少的精力

Dart 侧的设计几乎是完全按照我的想法

尽量保证
- 使用上的简洁、方便
- 保证功能的强大
- 设计上的合理
- 保证工程代码可读
- 大量的中英文注释，适合中国宝宝