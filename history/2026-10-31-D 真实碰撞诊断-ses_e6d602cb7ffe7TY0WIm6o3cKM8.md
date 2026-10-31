# D 真实碰撞诊断

- 会话 ID：`ses_e6d602cb7ffe7TY0WIm6o3cKM8`
- 时间：2026-10-31 23:41
- 目录：`C:\Users\Administrator`
- 模型：`deepseek/deepseek-flash`

---

## 🙋 我

You are a subagent spawned by another session.
实施 D 包。项目根：C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop

## 你只能写一个文件
tools/model-tool/adapters/game-collision.ts（新建，当前 127 字节占位注释，可整文件覆盖）
禁止改 src/**、package.json、renderer/**、adapters/game-character.ts、文档、git。

## 先读（只读）
- tools/model-tool/renderer/api.ts —— 硬契约：`Task`、`TaskTools`、`ToolRequest`、`TaskError`、`RenderFrame`、`applyDefaultLights`、`frameCamera`、`boxJson`、`round`。
- src/world/physics/collision.ts（`withGround`）、src/world/physics/runtime.ts:109-119（胶囊定义）、src/world/physics/types.ts（`PhysicsBox`）。
- src/features/city-layout/index.ts 的 `createBaseLayout()`、src/world/blocks/plan.ts 的 `planCityBlocks()`、src/content/config.ts 的 `PHYSICS`、src/world/player.ts 的 `PLAYER_EDGE_MARGIN`。

## 已完成的侦察结论（不要重新推导，直接用；如需核对可读源码）
真实碰撞几何的唯一输入是：
1. `layout.buildings[].collision`（业务建筑 AABB，已在布局里）；
2. `planCityBlocks(layout).blocks[].colliders`（每个 `{rect:{x0,x1,z0,z1}, minY, maxY}`）；
3. 顺序：建筑在前、街区在后，然后 `withGround([...], layout.bounds)`；
4. 胶囊：`PHYSICS.character.height`、`PHYSICS.character.radius`、`PHYSICS.character.offset`，collider 平移 y = height/2，halfHeight = height/2 − radius；
5. 规划是纯确定性函数（hashSeed/mulberry32），同一布局 ⇒ 同一盒集合。

## 目标：`collision` 任务（导出 `collisionTask: Task`）
1. `const layout = createBaseLayout()`；盒 = `[...layout.buildings.map(b => ({...b.collision})), ...planCityBlocks(layout).blocks.flatMap(p => p.colliders.map(...))]`，再 `withGround(boxes, layout.bounds)`。
2. 用 `tools.frame(width, height)`（默认 1280×800）渲染：
   - 地面网格（1 m 或 10 m 格，注明间隔）；
   - 每个静态盒的 `Box3Helper` 或线框（颜色区分建筑/街区/地面，材质 `depthTest:false` 或半透明让内部可见）；
   - 真实胶囊：`CapsuleGeometry(radius, height - 2*radius)` 线框，放在出生点（用布局/`PLAYER` 的出生位置；取不到就放原点并在 details 说明），标注轴向上；
   - 相机：`frameCamera` 以盒集合 + 胶囊的联合包围盒取景，azimuth 35°、elevation 25°；参数写进报告。
3. 写 PNG：`collision-overview.png`；若 args 给了 `focus`（格式 `"x,z"` 米），再做一张 `collision-focus.png` 以该点为中心、半径 25 m 取景。
4. data 至少含：
   - `scene`: `{ source: 'createBaseLayout()', layoutBuildings: n, blockColliders: n, ground: true, note }`
   - `boxes`: `{ total, byKind: {building, block, ground}, degenerateDropped: n, bounds }`
   - `capsule`: `{ radius, height, centerY, note: '与 PhysicsRuntime.createCharacterCollider 同参数' }`
   - `layout`: `{ bounds, buildings: n, blocks: n }`
   - `camera`、`viewport`、`png`（文件路径）
   - `parity`: 必须逐条写明与运行时快照的差异：① 会话内街区抑制（`CityBlocks.suppressed`）未包含；② 运行中 `addStaticBox` 会丢弃退化盒，这里如实统计 `degenerateDropped`；③ 室内 `setInterior` 结构/家具未包含；④ `edgeMargin` 是位置夹紧不是碰撞体。
   - `limits`: 字符串数组，含「不是运行中 Rapier 世界的逐项快照」「不改物理参数与存档」「不能替代游戏内手感验收」。
5. 绝不把模型包围盒当碰撞；绝不实例化第二套物理世界做判定（不 import PhysicsRuntime、不 import rapier）。只画真实输入几何。
6. 若 `planCityBlocks` 抛错或返回空，`TaskError('COLLISION_DATA_UNAVAILABLE', …, 3)`，不要退回假数据。
7. 颜色/材质自定但要写进报告 `legend`（kind → 颜色）。

## 通用要求
- 不新增依赖；不跑 Electron/截图/Vite build；不改文档。
- 数值用 `round()`；未知写 null。
- 完成后可跑一次 `npx tsc -p tools/model-tool/tsconfig.json --noEmit`，只修本文件报错；其他文件报错忽略并说明。

## 交付回复
导出签名、data 字段表、实际 import 路径（确认没有 three 之外的重量级依赖）、tsc 结果、未验证假设。不要贴大段代码。

## 🤖 AI

<summary>
已新建并实现 D 包碰撞可视化任务 `tools/model-tool/adapters/game-collision.ts`。只读取布局与街区规划的纯数据，用 `withGround` 复现运行时静态盒集合；未 import Rapier / `PhysicsRuntime`，未使用模型包围盒。渲染总览（+可选 focus）PNG，并在 data 中写入盒统计、胶囊参数、相机、图例、parity 与 limits。

导出签名：
```ts
export const collisionTask: Task
// Task = (tools: TaskTools, request: ToolRequest) => Promise<TaskOutput>
```
</summary>

<changes>
- `tools/model-tool/adapters/game-collision.ts`: 整文件实现（唯一改动文件）
  - 盒来源：`createBaseLayout().buildings[].collision` + `planCityBlocks(layout).blocks[].colliders`，再 `withGround(..., layout.bounds)`；顺序与运行时一致。
  - 退化盒按 `addStaticBox` 的 `half <= 1e-5` 规则统计并跳过绘制。
  - 胶囊：`CapsuleGeometry(radius, height - 2*radius)`，位于 `CITY.spawn`，中心 `y = height/2`；白色 Y+ 箭头标注轴向。
  - 相机：总览用 `frameCamera(联合包围盒, 35°, 25°, padding 1.18)`；focus 为 `"x,z"`，半径 25 m、padding 1.05、同角度。
  - 输出 `collision-overview.png`；有 focus 时输出 `collision-focus.png`。
  - `planCityBlocks` 抛错或 `blocks.length === 0` 时抛 `TaskError('COLLISION_DATA_UNAVAILABLE', ..., 3)`。
</changes>

**实际 import 路径（无 three 之外的重量级依赖）**
- `three`
- `../renderer/api`：`boxJson`、`frameCamera`、`round`、`TaskError`、`vectorJson`、`type Task`
- `../../../src/content/config`：`CITY`、`PHYSICS`
- `../../../src/features/city-layout`：`createBaseLayout`
- `../../../src/world/blocks/plan`：`planCityBlocks`、`type BlockCollider`
- `../../../src/world/physics/collision`：`withGround`
- `../../../src/world/physics/types`：`type PhysicsBox`
- `../../../src/world/player`：`PLAYER_EDGE_MARGIN`（会连带引入该模块的 three 加载器，无 rapier/物理运行时）

**data 字段**
| 字段 | 内容 |
|---|---|
| `scene` | `source/layoutBuildings/blockColliders/ground/note/grid`（网格 1 m、尺寸、divisions、说明） |
| `boxes` | `total/byKind{building,block,ground}/degenerateDropped/bounds` |
| `capsule` | `radius/height/centerY/halfHeight/offset/spawn{x,z,footY,source}/axis/note`（note 为“与 PhysicsRuntime.createCharacterCollider 同参数”） |
| `layout` | `bounds/buildings/blocks/skippedBlocks/layoutVersion/revision` |
| `camera` | 总览：方位角、仰角、padding、fov、aspect、distance、position、target、near/far |
| `cameraFocus` | focus 相机同结构 + 中心与 25 m 半径；无 focus 为 `null` |
| `viewport` | `width/height/pixelRatio` |
| `png` | 总览 PNG 绝对路径（字符串） |
| `pngFocus` | focus PNG 绝对路径或 `null` |
| `focus` | `{x,z,radiusMeters,padding,png}` 或 `null` |
| `legend` | `building/block/ground/capsule/axis/grid → #hex` |
| `parity` | ① `CityBlocks.suppressed` 未包含；② 退化盒按运行时规则统计；③ `setInterior` 室内结构/家具未包含；④ `PLAYER_EDGE_MARGIN` 是位置夹紧非碰撞体 |
| `limits` | 不是 Rapier 世界逐项快照；不改物理参数与存档；不能替代游戏内手感验收；仅室外静态盒 |

**tsc**
- 执行：`npx tsc -p tools/model-tool/tsconfig.json --noEmit`
- 结果：本文件无报错；唯一报错为其他包文件 `renderer/main.ts(7,3) TS6133: 'disposeSubtree' is declared but its value is never read.`，按约定忽略。

**未验证假设**
- 未实际运行渲染/截图/Vite，图像效果与 `writePng` 首次写入行为未验证。
- 假设 `tools.frame()` 会按请求宽高设置 `camera.aspect`；否则 `frameCamera` 取景比例会偏移。
- 假设当前 `planCityBlocks(createBaseLayout())` 实际返回非空（按侦察结论）；未在此环境执行 TS 运行时验证。
- focus 的“半径 25 m 取景”按 25 m 世界半径 + 1.05 padding 计算相机距离；这是对需求口径的实现解释。
- 额外支持 `args.width/height`（64–8192 整数），不在原任务硬性要求内；非法值报 `INVALID_VIEWPORT`（退出码 2）。

## 🙋 我

实际跑了一次 `collision`（真实 GPU，51 个盒），总览图能出，但**胶囊几乎看不见**：全城 110 m 取景下 1.78 m 的胶囊只有几个像素，网格 1 m×110 段又太密。请只改 `tools/model-tool/adapters/game-collision.ts`，修三件事：

1. **默认两张图**（不依赖 --focus）：
   - `collision-overview.png`：现状全城取景，但网格改为 10 m 间隔（注明 intervalMeters=10）；
   - `collision-spawn.png`：以胶囊出生点为中心、半径 12 m 取景（padding 1.05），网格 1 m，胶囊与附近盒必须清晰可辨。若给了 `--focus`，仍额外输出 `collision-focus.png`（半径 25 m、网格 1 m）。
2. **胶囊更醒目**：保持真实尺寸不变（半径 0.42、高 1.78，禁止放大冒充），改用明显区分的颜色（如 `#ff4d4f`）+ 半透明外壳 + 顶部/底部水平圆环标记脚底与头顶；`capsule.centerY` 与 `spawn` 数据不变。
3. 数据里补充 `pngSpawn`（绝对路径）与 `cameraSpawn`（同 camera 结构）；`grid` 改成按视图分别记录（`overview` / `near`），不要只留一个。

顺带修一个真实问题：本次数据里 `layout.blocks = 4` 但 `skippedBlocks = 12`。请在 data 里把 `skippedBlocks` 的含义写清楚（是 planCityBlocks 明确跳过的块，还是未生成），如果它其实表示「被规划跳过而未产出碰撞的街区数量」，就在字段旁加 `skippedBlocksNote` 说明来源函数与原因；不确定就写 `null` + 说明，不要猜。

约束不变：不改 `src/**`、`renderer/**`、文档、git；不跑 Electron/Vite；只跑一次 `npx tsc -p tools/model-tool/tsconfig.json --noEmit` 修本文件报错。完成后回复：新增/修改的 data 字段、grid 口径、胶囊视觉做法、tsc 结果（简短，不要贴代码）。

## 🤖 AI

已只修改 `tools/model-tool/adapters/game-collision.ts`。

**新增/修改 data 字段**
- 新增 `pngSpawn`：`collision-spawn.png` 绝对路径（默认必出）。
- 新增 `cameraSpawn`：与 `camera` 同结构，另含 `center`、`radiusMeters: 12`、`padding: 1.05`。
- `camera` 仍为总览；`cameraFocus` / `pngFocus` / `focus` 仅在给 `--focus` 时非 null。
- `scene.grid` 改为按视图：`{ overview, near, focus }`，每项含 `intervalMeters / sizeMeters / divisions / center / note`；无 `--focus` 时 `focus` 为 `null`。
- `capsule` 增加 `visual` 说明；`centerY`、`spawn` 未变。
- `layout` 增加 `skippedBlocksNote`：明确 `skippedBlocks` 来自 `planCityBlocks(layout).skipped`，是“被该函数明确判定跳过、未产出碰撞的条目数”，含手写试点模板、`planSites` 未通过站点、`generateBlock` 校验失败的生成街区；与 `blocks`（实际产出街区数）不是同一口径。

**grid 口径**
- overview：110 m 范围、11 段，`intervalMeters = 10`。
- near（出生点）：24 m、24 段，`intervalMeters = 1`。
- focus（可选）：50 m、50 段，`intervalMeters = 1`。
- 三张网格同时存在但按视图切换可见性；均标注“仅视觉参照，不代表碰撞体”。

**胶囊视觉做法**
- 几何仍是真实尺寸：半径 0.42、高 1.78、`centerY = 0.89`，未缩放。
- 颜色改为 `#ff4d4f`：半透明外壳（opacity 0.28，双面）+ 线框（opacity 0.9）。
- 脚底与头顶各加一个水平圆环（`TorusGeometry`，颜色 `#ffd666`），分别位于 y≈0.02 与 y=1.78；legend 新增 `capsuleRing`。
- 保留 Y+ 白色箭头标注轴向。

**tsc**
- 执行一次 `npx tsc -p tools/model-tool/tsconfig.json --noEmit`：无输出，通过。

