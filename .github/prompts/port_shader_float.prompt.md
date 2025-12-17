**【ShaderToy → Flutter RuntimeEffect 迁移 Prompt（sg_feedback_rgba8 标准）】**

目标：把一个 Shadertoy multipass shader（含 BufferA/BufferB/Main）移植到 Flutter `FragmentProgram/RuntimeEffect`，并支持 feedback（上一帧）在 RGBA8 `ui.Image` 中稳定工作，避免 float 精度丢失与读写冲突。  
约束：不使用位运算/bitcast（`>> & | ^`, `floatBitsToUint` 等），不依赖 `texelFetch`；避免使用 alpha 存数据（可能预乘）。

### 1) 通用约束（必须遵守）
- 所有 pass 顶部必须 `#include <common_header.frag>`；每个 pass 显式声明 `uniform sampler2D iChannelN;`
- 禁止：全局 `const int[] = int[](...)` 数组初始化（SkSL 易炸）；用 getter 函数 if-chain 替代
- 禁止：位运算与整数 `%`；用 `mod/floor/pow` 等 float 算术替代
- 采样替换：`texelFetch(tex, ivec2(x,y), 0)` → `texture(tex, (vec2(x,y)+0.5)/sizePx)`
- 所有临时变量尽量显式初始化（SkSL 对未初始化更敏感）
- 数据 buffer 禁用 `discard`（用写默认值/return 代替）

> 反馈（feedback）特别注意：一旦产生 `NaN/Inf`，会被写入 RGBA8 反馈并在后续帧“永久扩散/污染”，导致画面分叉、闪烁、逻辑崩坏。
> - 避免除以 0：对 `1/x`、`normalize(v)`、`inversesqrt(dot(v,v))` 等要做最小阈值保护
> - 避免分支里未初始化的变量路径
> - 避免 `texture` 线性采样导致的跨 lane 串扰（见第 2/4 节的写入策略）

### 2) RGBA8 feedback 数据编码（sg_feedback_rgba8）
- 数据 buffer 不能直接存 float；必须用 sg_feedback_rgba8 方案编码：
  - 标量 $v \in [-1,1]$ → RGB(24-bit) 打包，A 固定 1
  - “一个虚拟 texel = vec4” 的语义用横向 lane 展开：
    - virtual texel `(x,y)` 对应 physical 像素 `(x*4+lane, y)`，lane=0..3 分别存 vec4 的 x/y/z/w
  - 物理输出尺寸 = `(virtualWidth*4, virtualHeight)`（Dart 侧 `fixedOutputSize` 必须匹配）
- 使用 API：
  - 读：`sg_loadVec4(vpos, VSIZE)`
  - 写：`sg_storeVec4(re, va, fragColor, p)` / `sg_storeVec4Range(reRect, va, fragColor, p)`
  - 范围映射：`sg_encodeRangeToSigned/sg_decodeSignedToRange`（用于 points/time 等不在 [-1,1] 的值）

> 线性采样与 lane 串扰（重要）：Flutter 的 `sampler2D` 在部分平台/路径上可能是线性采样，
> 导致相邻 physical 像素（lane 0..3）发生轻微混合，从而污染“虚拟 texel 的 vec4”。
> - 对“只用到一个标量通道”的寄存器：建议写入时把标量复制到 `xyzw` 四个 lane（例如 `vec4(v,v,v,v)`）
> - 对应读取时：用 `dot(raw, vec4(0.25))` 取平均，进一步降低偶发 lane 混合造成的抖动

### 3) 反馈链路（避免读写冲突）
- 标准链路：
  - `BufferA`：读取上一帧 feedback（iChannel0），更新状态并输出
  - `BufferB`：passthrough（仅复制 BufferA 输出）用于避免某些平台读写冲突
  - `Main`：只读取 BufferB 输出渲染
- 如果出现“状态分叉/闪烁”，优先把反馈改成 ping-pong：`A <- B(prev)`，`B <- A(curr)`，Main 读 B

### 4) Dart 侧接线要求
- 对所有数据 buffer 设置 `fixedOutputSize` 为物理尺寸（例如 `Size(VSIZE.x*4, VSIZE.y)`）

#### 4.1 `iResolution/iMouse` 的两种语义（必须二选一，且 shader 逻辑要匹配）

**A) Buffer-space 语义（默认）**
- `iResolution`/`iMouse` 以当前 buffer 的渲染目标尺寸为准（即 `fixedOutputSize`）
- 适用：纯“状态网格/数据纹理”逻辑（例如 14x14 的 gameplay grid），只需要修正横向 pack（`/4`）
- shader 内如需按 Shadertoy 虚拟坐标计算：要自行把 `iMouse/iResolution` 从 physical（pack 后）还原为 virtual

**B) Surface-space 语义（屏幕语义）**
- 当原始 Shadertoy shader 在 BufferA 就直接用屏幕语义（例如 `M=(2*iMouse-iResolution)/iResolution.y` 参与物理/交互）时，
  BufferA 虽然渲染到 tiny `fixedOutputSize`，但仍需要拿到“屏幕尺寸/屏幕鼠标”。
- 做法：Dart 侧对该 buffer 打开 `useSurfaceSizeForIResolution = true`（或等价机制），让引擎用 surface 尺寸填充 `iResolution/iMouse`
- 注意：启用后，shader 内不要再用 `packX = iResolution.x / VSIZE.x` 这类“从 iResolution 反推 pack 比例”的代码；
  因为此时 `iResolution` 已不等于 buffer 的物理输出尺寸。

> 结论：
> - 像 Bricks 这类 gameplay grid：推荐 A（buffer-space）+ 手动 `/4` 修正
> - 像 Couch 2048 这类在 BufferA 直接用屏幕语义选取/施力：推荐 B（surface-space）

#### 4.2 时间步长
- Shadertoy 常用 `iTimeDelta`；Flutter/RuntimeEffect 未必提供同等精度/含义。
- 若 shader 依赖固定步长：可在 shader 内用常量 `dt = 1.0/60.0`（或由引擎提供 `iTimeDelta`）实现最小改动。

### 5) 迁移交付要求
- 保持原 shader 结构与变量名尽量不变（最小改动）
- 给出修改后的：
  - `BufferA.frag`（状态读写替换为 sg_load/sg_store）
  - `BufferB.frag`（passthrough）
  - `Main.frag`（读取解码后的状态渲染）
  - Dart 接线（buffers + fixedOutputSize + feedback/pingpong）
- 若遇到编译错误：按“数组/位运算/texelFetch/未初始化”四类逐项最小修复，不引入额外功能
