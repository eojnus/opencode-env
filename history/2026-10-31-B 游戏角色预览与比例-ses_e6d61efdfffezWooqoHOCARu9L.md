# B 游戏角色预览与比例

- 会话 ID：`ses_e6d61efdfffezWooqoHOCARu9L`
- 时间：2026-10-31 23:39
- 目录：`C:\Users\Administrator`
- 模型：`deepseek/deepseek-flash`

---

## 🙋 我

You are a subagent spawned by another session.
实施 B 包。项目根：C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop

## 你只能写这两个文件（其他文件一律不许改，尤其禁止改 src/**、package.json、renderer/main.ts、renderer/api.ts）
1. tools/model-tool/adapters/game-character.ts（新建，当前是 132 字节占位注释，可整文件覆盖）
2. tools/model-tool/renderer/transform.ts（新建，当前是 117 字节占位注释，可整文件覆盖）

## 先读（只读）
- tools/model-tool/renderer/api.ts —— 共享类型：`Task`、`TaskTools`、`ToolRequest`、`TaskError`、`Frame`、`applyDefaultLights`、`frameCamera`、`boxJson`、`round`、`vectorJson`。这是硬契约，不许改它。
- src/world/character.ts —— 真实游戏角色实现。重点：`CharacterRig` 接口（root / update(dt, motion) / reset / dispose）、`CharacterMotion` 字段语义、`loadCharacterRig()`（硬编码读 `PLAYER.model.url`，即 `assets/models/character/Alina_Ip_Animated.usdz`，相对页面 URL）、`clipReference`/`trimClip`/`stripRootMotion` 的行为。
- src/content/config.ts 的 `PLAYER` 段（身高、骨骼名、clips 映射）。

## 目标
`snapshot-game-character` 任务：用**真实** `loadCharacterRig()` 与 `rig.update(dt, motion)` 驱动语义动作并截图，提供比例参照与多朝向诊断。

### 硬性规则
- 绝不修改 src/**；通过 `import { loadCharacterRig, type CharacterMotion } from '../../../src/world/character'` 复用（路径从 adapters/ 出发：adapters → model-tool → tools → 根）。
- 角色加载走页面相对 URL `assets/models/…`，渲染页 origin 是 `modeltool://app/`，Electron 侧已把 `/assets/…` 映射到项目 `public/assets`。**不要**自己拼 modeltool URL，也不要改 PLAYER 配置。
- 禁止把 USDZ 自带展示动作说成游戏 walk/run/jump：walk/run/jump 是程序化骨骼姿态，报告里必须写明「语义动作由真实 CharacterRig 程序化路径生成，不是资产片段」。
- 不得创建第二套角色逻辑、不得伪造 rig。拿不到 rig（例如加载异常）就让任务以 `TaskError('CHARACTER_LOAD_FAILED', …, 5)` 失败，并在 details 里带原始错误。
- 帧率固定 dt = 1/60 秒，模拟步数 = round(time × 60)，先 `rig.reset()`，保证同一 time 结果可复现；`rig.root.rotation.y = yawDeg × π/180` 之后再截图。

### 语义动作 → CharacterMotion 映射（按此实现，写进报告 data.motion）
- idle: `{speed:0, moving:false, sprinting:false, grounded:true, verticalVelocity:0, leftGround:false, touchedGround:false}`
- walk: speed = PLAYER.speed（5.4），moving true，sprinting false，grounded true
- run: speed = PLAYER.speed × PLAYER.sprintMultiplier，moving true，sprinting true，grounded true
- jumpStart: grounded true 且第 1 步 `leftGround:true`，verticalVelocity 取正的小值（用一个明确常量并在报告里写明）
- airborne: grounded false，verticalVelocity 正
- land: grounded true 且第 1 步 `touchedGround:true`
不要从 config 猜新参数；凡自定常量都要进报告 `assumptions`。

### 参数（request.args，由 CLI 传入，全部可选但有默认）
`action`（默认 'idle'）、`time`（秒，默认 0.5）、`yaw`（度，默认 0）、`angles`（逗号串或数组，如 [0,90,180,270]，给了就每个角度各截一张，忽略 `yaw`）、`width`（默认 720）、`height`（默认 900）、`scaleReference`（布尔，默认 true）。
非法 action → `TaskError('BAD_ACTION', …, 2)`。

### 输出
- 每个角度一张 PNG：`character-<action>-<yaw>deg.png`，用 `tools.writePng()` 写。
- 比例参照（scaleReference 为 true 时）：不要新增资源文件。用 Three.js 在场景内画同尺寸参照物：1 m 高的刻度柱（每 0.25 m 一节）+ 地面网格（1 m 格），高度参照基于角色包围盒；参照物必须命名（`model-tool-ruler-*`）且报告里说明「仅为视觉参照，不改变游戏比例或物理」。
- report data 至少含：`action`、`timeSeconds`、`simulatedSteps`、`dtSeconds`、`motion`、`assumptions`、`note`（程序化说明）、`character`（包围盒 boxJson、身高、脚底 y）、`angles`（每项：yaw、文件、包围盒、骨骼朝向诊断）、`rigBones`（若可读：数量）、`limits`。
- 多朝向诊断调用 transform.ts。

## transform.ts 要求
导出纯函数（无副作用、不加载资源）：
- `boneWorldDirections(root, boneNames)` → 每个骨骼的世界前向（用骨骼世界四元数取 +Z 或 +Y 时要在结果里标明轴）与父级链深度。
- `compareYawOrientations(samples)` → 计算同一骨骼在 0/90/180/270° 下**角色局部空间**方向的一致性（局部方向应基本不变；世界方向应随 yaw 旋转），返回每个骨骼的最大偏差角（度）与 `consistent: boolean`。
- `detectScaleAnomalies(root)` → 检测非均匀缩放（各轴缩放差异 >1e-3）与镜像（行列式 < 0），返回条目；只报告，不修正。
所有角度用度、保留 2 位小数。无法判断时返回 null 并在调用侧生成 warning 诊断，不能静默填 0。

## 不要做
- 不要跑 Vite build、不要启动 Electron、不要截图、不要改文档、不要动 git。
- 完成后可以跑一次 `npx tsc -p tools/model-tool/tsconfig.json --noEmit`，但只修你自己两个文件里的报错；其他文件（尤其 renderer/main.ts、animation.ts、retarget.ts）的报错不是你的事，忽略并在报告里说明。

## 交付回复
列出：两个文件的导出签名、参数表、报告 data 字段表、你自定的常量、tsc 里属于你文件的报错（应为空）、以及任何你无法验证的假设。不要贴大段代码。

## 🤖 AI

我先读取共享接口约定和角色实现。

## 🤖 AI

<summary>
B 包完成：`snapshot-game-character` 用真实 `loadCharacterRig()` + `rig.update(dt, motion)` 驱动语义动作并逐角度截图，包含包围盒比例参照与多朝向/缩放诊断。未改动 `src/**`、`package.json`、`renderer/main.ts`、`renderer/api.ts`。
</summary>

<changes>
- `tools/model-tool/adapters/game-character.ts`（整文件覆盖）
  - `export const task: Task`
  - `export const characterTask: Task`（同一实现的别名：当前 `renderer/main.ts` 的命令表按 `characterTask` 导入；未改 main.ts）
  - 真实复用 `loadCharacterRig()` / `CharacterMotion`；固定 `dt=1/60`，`steps=round(time×60)`，先 `reset()`，再逐帧 `update`，最后按 yaw 设 `rig.root.rotation.y`。
  - 加载失败 → `TaskError('CHARACTER_LOAD_FAILED', …, 5)`，`details.error` 带原始 name/message/stack，`details.modelUrl` 带 `PLAYER.model.url`。
  - 场景内生成参照物（不新增资源文件）：`model-tool-ruler-column`、`model-tool-ruler-segment-<i>`（每 0.25 m 一节）、`model-tool-ruler-tick-<i>`（整米刻度更长）、`model-tool-ruler-grid`（1 m 格）。
- `tools/model-tool/renderer/transform.ts`（新建，纯函数、不更新矩阵、不加载资源）
  - `boneWorldDirections(root, boneNames, options?: { axis?: 'z'|'y' }): BoneDirectionReport`
  - `compareYawOrientations(samples, options?: { toleranceDeg?: number }): YawOrientationComparison`
  - `detectScaleAnomalies(root, options?: { epsilon?: number }): ScaleAnomalyReport`
  - 辅助：`angleBetweenDegrees(a: THREE.Vector3, b: THREE.Vector3): number | null`
  - 角度统一 2 位小数；缺失/非有限一律 `null` + `issues`，调用侧转 warning。
</changes>

**导出签名 / 参数表**

| 参数 | 类型 | 默认 | 规则 |
|---|---|---|---|
| `action` | string | `'idle'` | 仅 `idle/walk/run/jumpStart/airborne/land`，否则 `BAD_ACTION` exit 2 |
| `time` | number | `0.5` | 0–120 秒；`steps=round(time×60)` |
| `yaw` | number | `0` | 度；与 `angles` 同时给时被忽略 |
| `angles` | 逗号串或数组 | 未给 | 每个角度一张图；四舍五入 2 位、按值去重 |
| `width` | int | `720` | 64–4096 |
| `height` | int | `900` | 64–4096 |
| `scaleReference` | boolean | `true` | 场景内刻度柱 + 1 m 地面网格 |

输出文件：`character-<action>-<yaw>deg.png`（`tools.writePng()`）。

**report data 字段表**

| 字段 | 内容 |
|---|---|
| `action` / `timeSeconds` / `simulatedSteps` / `dtSeconds` | 实际使用值与步数 |
| `motion` | `firstStep`、`steadyState`、`moving`、`sprinting`、`note`（含首步事件差异说明） |
| `assumptions` | 全部自定常量与约定（含 jumpStart 后续步 grounded=false 的理由） |
| `note` | 程序化说明：walk/run/jumpStart/airborne/land 由真实 CharacterRig 程序化路径生成，不是资产片段；idle 播放裁剪源片段；不拿 USDZ 展示动作冒充游戏动作 |
| `character` | `box`（boxJson，全部角度并集）、`heightMeters`、`footY`、`widthMeters`/`depthMeters`、`boxScope`、`modelUrl`、`configuredHeightMeters` |
| `angles[]` | `yaw`、`file`、`outputPath`、`box`、`boneDirections`（每骨骼世界/局部方向、axis、parentDepth、缺失原因） |
| `orientation` | `toleranceDeg`、`yaws`、每骨骼 `maxLocalDeviationDeg`/`maxWorldDeviationDeg`/`consistent`、`perYaw` |
| `rigBones` | `count`、`mappedCount`、`names`（前 40）、`namesTruncated` |
| `scaleAnomalies` | `inspected`、`entries`、`nonUniformCount`、`mirroredCount`、`hasAnomalies`、`issues`（只报告不修正） |
| `scaleReference` | 是否构建、柱高、节距、网格格距/尺寸、对象命名、视觉参照声明 |
| `camera` | 方位/仰角/padding/距离/目标/fov/宽高/aspect |
| `request` / `limits` / `warningsEmitted` | 请求回显、上限、诊断截断与相位时长提示 |

**自定常量**：`DT_SECONDS=1/60`、`TAKEOFF_VERTICAL_VELOCITY=1.6 m/s`、`AIRBORNE_VERTICAL_VELOCITY=1.2 m/s`、相机 `azimuth 0°/elevation 8°/padding 1.22`、`RULER_STEP_METERS=0.25`、`RULER_SEGMENT_WIDTH=0.06`、`RULER_OFFSET=0.6`、`GRID_MIN_SIZE=4 m`、骨骼前向轴 `+Z`、朝向容差 `1°`、`MAX_TIME=120s`、宽高 64–4096、warning 上限 20。全部写入 `assumptions`。

<verification>
- Performed: `npx tsc -p tools/model-tool/tsconfig.json --noEmit`
- Result: 我负责的两个文件 **0 报错**；最后一次全量输出只剩 `renderer/main.ts(7,3): TS6133 'disposeSubtree' declared but never read`（A 包文件，非我职责）。期间出现的 `retarget.ts`、`game-collision.ts`、`animation.ts` 报错已由其他并行包消除，我未改动这些文件。
- 未执行（按要求）：Vite build、Electron 启动、实际截图。故运行时行为未实测。

**无法验证的假设**
1. `jumpStart` 规格只写「第 1 步 grounded=true + leftGround=true」；若后续步继续 grounded=true，`CharacterRig` 会在 `startSeconds(0.12s)` 后回落 ground。我实现为首步后 `grounded=false`（vv 仍为正）以保留 takeoff→air 相位，已写入 `motion.note`/`assumptions`。
2. `land` 位姿只维持 `PLAYER.model.jump.landSeconds(0.22s)`，默认 `time=0.5` 时截图已回到 idle；已在 `limits.poseTimingHint` 明示，未改动规格中的默认 time。
3. 参照柱高度取 `ceil(角色包围盒高/0.25)×0.25`（≈1.75 m），理解为「与角色同尺寸的 0.25 m 刻度柱」；不是固定 1 m。
4. `yaw=0°` 视为正面（相机 azimuth 0、看向 +Z 侧角色），180° 为背面；相机不随 yaw 旋转。
5. 单角度时 `orientation.consistent` 为 `null`，并按「无法判断→warning」生成 `CHARACTER_ORIENTATION` 警告。
6. 依赖页面 origin `modeltool://app/` 把 `assets/models/...` 映射到 `public/assets`（未自行拼 URL、未改 PLAYER 配置），该映射未在本次类型检查范围内实测。
</verification>

