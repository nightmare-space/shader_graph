# Shader Graph

`shader_graph` 是一个面向 Flutter `FragmentProgram / RuntimeEffect` 的实时多 Pass Shader 执行框架。

它现在甚至可以运行一个**完全由着色器实现的游戏**。

<img src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Bricks%20Game.gif?raw=true">

该框架通过「渲染图（Render Graph）」的方式，将多个 `.frag` 串联执行，完整支持 Shadertoy 风格的 BufferA / BufferB / Main、feedback / ping-pong 等模型。

支持键盘输入、鼠标输入、图片输入，并支持 Shadertoy 风格的 Wrap（Clamp / Repeat / Mirror）。

如果你只是想快速把一个着色器显示出来，可以直接使用简单的 Widget（例如 `ShaderSurface.auto`）。

当你需要更复杂的链路（多 Pass / 多输入 / feedback / ping-pong）时，再使用 `ShaderBuffer` 显式声明输入与依赖关系。

框架会负责拓扑调度与逐帧执行，并把每个 pass 的输出作为 `ui.Image` 传递给下游。

[English README](README.md) | 中文

---

## 示例

我已经使用该库创建了  
[awesome_flutter_shaders](https://github.com/mengyanshou/awesome_flutter_shaders) 项目。

这是目前最完整的示例集合，包含 **100+ 个 Shadertoy 着色器的 Flutter 移植示例**，非常推荐直接参考。

在当前项目的 `example` 中，也包含了针对各个功能点的示例；`shader_graph` 的源码中则包含了大量中英文注释，方便阅读与理解。

---

## 路线图

- [x] 支持将一个 Shader 作为 Buffer 输入到另一个 Shader（Multi-Pass）
- [x] 支持将图片作为 Buffer 输入到 Shader
- [x] 支持反馈输入（Ping-Pong：上一帧 → 下一帧）
- [x] 支持鼠标事件
- [x] 支持键盘事件
- [x] 支持 Wrap（Clamp / Repeat / Mirror）
- [x] 自动拓扑排序
- [x] 支持 texelFetch（通过宏自动计算 texel 大小）
- [x] 支持 Shadertoy 风格的 Filter（Linear / Nearest / Mipmap）
  - [x] Nearest / Linear：已基本支持，存在轻微差异
  - [ ] Mipmap：暂不支持，探索 Flutter 中可落地的 mipmap-like 方案
- [ ] 支持将 Widget 渲染为纹理，再作为 Buffer 输入
- [ ] 动画控制

---

## Float 支持（RGBA8 feedback）

Flutter 的 feedback 纹理通常为 RGBA8，无法稳定存储任意 float 状态。

本项目提供统一的移植方案 `sg_feedback_rgba8`：  
将标量编码进 RGB（24-bit），并通过横向 4-lane 打包，保留“一个 texel = vec4”的语义。

---

## texelFetch 支持

通过 `common_header.frag` 提供的：

- `SG_TEXELFETCH`
- `SG_TEXELFETCH0..3`

宏替代原生 `texelFetch` 调用，并使用 `iChannelResolution0..3` 自动获得通道分辨率。

---

### Ping-Pong & Multi-Pass & RGBA8 Feedback

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

---

### Wrap & Filter

以下示例展示了 Wrap / Filter 对着色器效果的决定性影响。如果不支持这些特性，画面效果会与 Shadertoy 存在明显差异。

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

> 注意：这些画面并非 Flutter UI，而是完全由着色器渲染，并且可以实时响应键盘输入

<img width="600px" src="https://github.com/nightmare-space/shader_graph/blob/main/screenshot/Keyboard.png?raw=true">

### 其他

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

## 前言

我以前对着色器的理解一直比较模糊。朋友推荐我阅读  
[The Book of Shaders](https://thebookofshaders.com/)，我看了一部分，但始终没能真正理解其中的原理。

但我觉得 Shadertoy 上的着色器实在太有趣了，有些作品甚至本身就是一个完整的游戏，这让我产生了一个想法：  
**能不能把这些着色器移植到 Flutter 上运行？**

首先要感谢 [shader_buffers](https://github.com/alnitak/shader_buffers) 的作者。正是这个项目，让我最初能够把一些 Shadertoy 的着色器代码移植到 Flutter 中运行。

但在实际使用过程中，我逐渐发现它在设计和功能上与我的需求存在较大差异。其中一部分问题，我已经通过提交 PR 的方式参与修复。

随着需求的不断增加，我意识到问题并不只存在于 shader_buffers，而是几乎所有 Flutter 现有的着色器框架都没有覆盖的一整类问题。

因此，`shader_graph` 诞生了。

---

## 快速开始

首先需要明确一点：  
**Shadertoy 的着色器代码必须经过移植，才能在 Flutter 中运行。**

项目中提供了辅助移植的 Prompt：  
`port_shader.prompt.md`

基本流程如下：

1. 打开需要移植的着色器文件（建议直接放在项目中）
2. 在 Copilot 等 AI 工具中输入对应 Prompt

```text
Follow instructions in [port_shader.prompt.md](.github/prompts/port_shader.prompt.md).
```

示例代码见：[example](example/lib/main.dart)

---

### 最小可运行示例

### 1) 单 Shader（Widget）

```dart
SizedBox(
  height: 240,
  // shader_asset_main ends with .frag
  child: ShaderSurface.auto('$shader_asset_main'),
)
```

### 2) 两个 Pass（A → Main）

见 [multi_pass.dart](example/lib/multi_pass.dart)

```dart
ShaderSurface.builder(() {
  final bufferA = '$shader_asset_buffera'.shaderBuffer;
  final main = '$shader_asset_main'.shaderBuffer.feed(bufferA);
  return [bufferA, main];
})
```

### 3) feedback（A → A → Main）

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

`ShaderBuffer` 既可以作为最终渲染的着色器，也可以作为中间 `Buffer` 输入到其他着色器。

它是整个渲染图（Render Graph）中最核心的节点抽象。

通常通过 extension 创建：

```dart
'$asset_path'.shaderBuffer;
```

它等价于

```dart
final buffer = ShaderBuffer('$asset_path');
```

`ShaderBuffer` 可以配合 `ShaderSurface.auto`、`ShaderSurface.builder` 使用，
或者通过 `ShaderSurface.buffers` 直接传入 `List<ShaderBuffer>`。

### 输入源（Inputs）

ShaderBuffer 支持多种输入源，用于模拟 Shadertoy 中的 iChannel 行为。

目前支持的输入类型包括：

- 其他 ShaderBuffer 的输出  
- 图片（ui.Image / Asset）  
- 键盘输入  
- 鼠标输入  
- 时间 / 分辨率等内置 Uniform  

这些输入会在每一帧被统一绑定到对应的着色器参数中。


### feed

`feed` 用于将**一个输入源**绑定到当前的 `ShaderBuffer`。

这个输入源可以是：

- 另一个 `ShaderBuffer` 的输出  
- 一个以 `.frag` 结尾的 shader 资源路径（会被隐式创建为 `ShaderBuffer`）

这是构建多 Pass 渲染链路的核心方式。

```dart
// 直接使用另一个 ShaderBuffer 作为输入
buffer.feed(bufferA);

// 使用以 .frag 结尾的 shader 资源路径作为输入
buffer.feed("$asset_path");
```

上述代码表示：

- `bufferA`（或 `$asset_path` 对应的 ShaderBuffer）会先执行  
- 它的输出结果会作为纹理输入（iChannel）传递给当前的 `buffer`

也就是说，`feed` 始终作用于**调用它的 ShaderBuffer**，并不会改变被 feed 的那个 buffer 本身。

你可以连续调用 `feed`，为当前 `ShaderBuffer` 绑定多个输入，从而构建更复杂的依赖关系。

**添加键盘作为输入**

```dart
buffer.feedKeyboard();
```

**添加资源图片作为输入**

> 通常用来输入噪声、纹理等

这部分可以参考  
[awesome_flutter_shaders](https://github.com/mengyanshou/awesome_flutter_shaders/tree/main/assets)

```dart
buffer.feed('$image_asset_path');
```

## feedback / ping-pong

在 Shadertoy 中，feedback 是一个非常常见的模式，例如：

- 粒子模拟  
- 流体模拟  
- 细胞自动机  
- 完全由 Shader 驱动的游戏逻辑  

`shader_graph` 通过 `feedback()` 对这一模式进行了明确支持。

```dart
final bufferA = '$asset_shader_buffera'.shaderBuffer.feedback();
```

启用 feedback 后：

- 当前帧的输入中，会包含上一帧的输出  
- 框架内部会自动维护双缓冲（ping-pong）  
- 使用者无需手动管理纹理交换  

你也可以在 feedback 的同时，继续喂入其他输入：

```dart
final bufferA =
  '$asset_shader_buffera'
    .shaderBuffer
    .feedback()
    .feedKeyboard();
```

---


## Wrap（repeat / mirror / clamp）

Flutter Runtime Shader 不直接暴露 sampler 的 wrap / filter 状态。

本项目通过 `iChannelWrap` uniform，并在 shader 内部进行 UV 变换来模拟 Wrap 行为。

在 Dart 侧为每个输入设置 wrap：

```dart
final buffer = '$shader_asset_path'.shaderBuffer;
buffer.feed('$texture_asset_path', wrap: WrapMode.repeat);
```

在 shader 侧采样时，**必须**使用 `common_header.frag` 提供的宏：

- `SG_TEX0`
- `SG_TEX1`
- `SG_TEX2`
- `SG_TEX3`

不要直接使用 `texture(iChannelN, uv)`。

---

## 输出尺寸（Output Size）

默认情况下，每个 ShaderBuffer 的输出尺寸等同于最终 Widget 的尺寸。

但在一些场景中，你可能希望：

- 使用更低分辨率进行计算（性能优化）  
- 使用固定逻辑分辨率（例如像素风游戏）  
- 明确控制 feedback Buffer 的尺寸  

此时可以显式指定输出尺寸：

```dart
buffer.fixedOutputSize = const Size(64, 64);
```

在游戏示例中，常见的做法是：

- 使用逻辑分辨率（如 14×14）
- 物理输出尺寸 = 逻辑宽度 × 4（RGBA8 feedback）

---


## ShaderSurface.auto

`ShaderSurface.auto` 返回一个 Widget，可直接用于展示 Shader。

```dart
Center(
  child: ShaderSurface.auto('$shader_asset_path'),
)
```

你可以把它放在任意 Widget 树中，通常需要给它一个高度约束：

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

`ShaderSurface.auto` 支持传入：

- String（shader 资源路径）  
- ShaderBuffer  
- List<ShaderBuffer>  

当 Shader 存在输入时，直接传入 ShaderBuffer 更合适。

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

例如当多个 ShaderBuffer 都需要有输入的时候，就会变成这样

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

当存在复杂的多 Pass 依赖关系时，应使用 `ShaderSurface.builder`。

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


示例：

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

对于 Shadertoy 风格的多 pass，只有当同一帧内的依赖关系不形成环（DAG）时，最终的 Buffer 列表才可以被拓扑排序。

也就是说：

- 每个 pass 只能读取它依赖的其它 pass 的输出（或外部输入）  
- 不能在同一帧出现循环依赖（例如 A 读 B，同时 B 读 A）  

feedback / ping-pong 读取的是上一帧的输出，属于跨帧依赖，通常不会破坏当前帧的拓扑排序。

注意：  
单个 Buffer 内部的输入通道顺序（iChannel0..N）仍必须严格按照 Shadertoy 的定义顺序 feed，因为 shader 侧采样是按通道顺序绑定的。

---

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

## toImageSync 内存泄露

[toImageSync retains display list which can lead to surprising memory retention](https://github.com/flutter/flutter/issues/138627)

这里之前踩过一个坑：在 Flutter 3.38.5（macOS）上，`toImageSync` 仍可能出现明显的内存占用增长。
我在本机测试时，应用运行一段时间会持续吃掉物理内存并开始占用 Swap，最终占用会变得非常夸张。（超过200GB）

当前工程的规避方式：
- 改用异步的 `toImage()`（避免 `toImageSync` 的高风险路径）
- 但不能每一帧都触发一次转图，否则仍会造成巨大开销
- 因此用 Ticker/节流策略：只在“新的一帧 image 准备好”之后再触发下一次更新

## Copilot

老实说，我手上正在维护的项目很多，其中不少我在乎的项目都处于半停更状态。

因此这个项目的实现过程中，我借助了比较多的 AI（主要是 GPT-5.2）。

但整体设计、结构决策、调试与验证，仍然是由我主导完成的。

着色器相关的很多内容我并不熟悉，这部分的代码实现几乎都是 AI 完成的，调试与验证同样消耗了我大量精力。

Dart 侧的整体设计，几乎完全按照我的想法来推进。

目标始终是：

- 使用简单、直观  
- 功能足够强  
- 设计结构清晰  
- 工程代码可读  
- 大量中英文注释，适合学习与二次开发 

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
