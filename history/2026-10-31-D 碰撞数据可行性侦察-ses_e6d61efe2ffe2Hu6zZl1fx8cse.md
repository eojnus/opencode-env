# D 碰撞数据可行性侦察

- 会话 ID：`ses_e6d61efe2ffe2Hu6zZl1fx8cse`
- 时间：2026-10-31 23:39
- 目录：`C:\Users\Administrator`
- 模型：`deepseek/deepseek-flash`

---

## 🙋 我

You are a subagent spawned by another session.
只读侦察，不要修改任何文件。项目根：C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop

问题：我要在 tools/model-tool/adapters/game-collision.ts 里展示**真实**的游戏碰撞数据（胶囊 + 静态碰撞盒），前提是**不修改 src/** 的任何公共边界**（不改 PhysicsRuntime 类、不改 world.ts 导出）。请回答：

1. `src/world/world.ts` 里 `rebuildColliders()` 的完整实现（贴出函数体），它依赖哪些输入（城市/街区规划、建筑布局、content/config 常量）？这些输入能否在**没有 DOM、没有 THREE.Scene、没有 renderer** 的浏览器页面里通过纯函数重新计算出来？逐项给出函数名、文件、是否 export。
2. `src/world/physics/runtime.ts` 的 `setOutdoor(boxes, bounds, edgeMargin)` 接受的 `PhysicsBox[]` 是否是唯一权威碰撞几何？除它以外，游戏是否还有别处注册静态碰撞（室内 `setInterior`、角色胶囊）？给出位置。
3. 若要在不修改 `PhysicsRuntime` 的前提下拿到「当前场景实际喂给 Rapier 的 box 列表」，有哪些可行路径？例如：调用同一个碰撞盒生成函数、从 `world.blocks`/`world.buildings` 的规划函数重新生成。请给出最小可行调用链（含 import 路径与参数）。
4. `src/world/physics/collision.ts`（50 行）是什么？`playerCollidersOf` 之类函数在哪、做什么？
5. `PhysicsRuntime.create()` 是否依赖 DOM 或 window？（看它 import 的 rapier3d-compat 初始化方式 ensureRapier()）
6. 现有建筑/街区规划的确定性：是否有固定随机种子？同一输入是否必然生成同一碰撞盒集合？

输出要求：按 1–6 编号回答，关键结论给文件路径+行号，代码只贴必要片段（每段 ≤25 行）。最后给一句结论：D 包能否在不改 src/** 的情况下展示真实碰撞盒；如果不能，明确写出缺哪个只读访问器。

## 🤖 AI

I'll start by mapping the relevant files in parallel.

## 🤖 AI

<results>
<files>
- C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop\src\world\world.ts:1237 - `rebuildColliders()`（核心）；410 送物理；252 `colliders` 私有
- C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop\src\world\scene.ts:689 - `makeHandle()` 用布局尺寸生成 AABB；714 `attachBuildingVisual()` 用 `visual.envelope` 原位覆盖
- C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop\src\world\buildings\factory.ts:268 - `envelopeOf()`（声明包络，等价规划占地）
- C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop\src\world\blocks\plan.ts:498 - `planCityBlocks()` 纯函数
- C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop\src\world\blocks\scene.ts:74 - `CityBlocks.colliders`（plan 直拷贝，198）
- C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop\src\world\physics\runtime.ts:156 - `setOutdoor()`；170 `setInterior()`；109 胶囊
- C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop\src\world\physics\collision.ts:16 - 地面/地板纯适配
- C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop\src\features\furniture\index.ts:468 - `playerCollidersOf()`
- C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop\src\features\city-layout\index.ts:204 - `createBaseLayout()`；288 `addDistrict()`
- C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop\src\world\buildings\random.ts:19 - `hashSeed` / `mulberry32`
</files>

<answer>

## 1. `rebuildColliders()` 的完整实现与输入

`src/world/world.ts:1236-1248`（被构造器 :344、`syncLayout` :477、`planBlocks` :1268 调用）：

```ts
/** 合并碰撞集合：业务建筑在前、装饰街区在后，顺序稳定。 */
private rebuildColliders(): void {
  this.buildingColliders = this.handles.map((handle) => handle.collider);
  const scenery: Collider[] = this.blocks.colliders.map((item) => ({
    minX: item.minX, maxX: item.maxX, minZ: item.minZ, maxZ: item.maxZ,
    minY: item.minY, maxY: item.maxY,
  }));
  this.colliders = [...this.buildingColliders, ...scenery];
}
```

两项输入：

1. **业务建筑盒** `this.handles` ← `buildCityScene(layout, …).buildings`（`scene.ts:689-705`）。值来自布局的 `position + size`：
```ts
const { width, height, depth } = building.size;
const collider = { minX: pos.x - width/2, maxX: pos.x + width/2,
                   minZ: pos.z - depth/2, maxZ: pos.z + depth/2, minY: 0, maxY: height };
```
楼体挂载后用 `visual.envelope` 原地覆盖（`scene.ts:714-737`），而 `envelopeOf`（`factory.ts:268-286`）+ `projectBuildingVisualRequest`（`world/buildings/layout-adapter.ts:81-102`，转角只有 0/±π/2/π 且交换局部宽深）算出的数值**恒等于**上面这个 AABB，也等于布局自带的 `building.collision`（`features/city-layout/index.ts:70-77`、`262-269`、`383`）。

2. **装饰街区盒** `this.blocks.colliders` ← `planCityBlocks(layout)` 的 `BlockPlan.colliders`（`blocks/scene.ts:198-207` 原样映射 `{rect,minY,maxY}` → `{minX,maxX,minZ,maxZ,minY,maxY}`）。

依赖的常量/规划函数（逐项）：

| 项 | 文件:行 | export? | 是否纯（无 DOM/THREE） |
|---|---|---|---|
| `createBaseLayout()` | `features/city-layout/index.ts:204` | ✅ | ✅ 文件头声明“不 import Three.js / DOM”（:2） |
| `addDistrict(layout, input)` | 同上 :288 | ✅ | ✅（就地写传入的 layout，需传草稿/克隆） |
| `CITY`(buildings/roads/bounds) | `content/config.ts` | ✅ | ✅ 纯数据 |
| `DISTRICT_TEMPLATES` / `DISTRICT_LAYOUT` | `content/districts.ts` | ✅ | ✅ |
| `BLOCK_TEMPLATES` / `BLOCK_RULES_VERSION` / `blockFamilyById` / `defaultFamilyForDistrict` | `content/city-blocks.ts` | ✅ | ✅ |
| `RESERVE_LAND_PARCELS` | `content/real-estate.ts` | ✅ | ✅ |
| `SCENERY_RULES` / `SCENERY_MODELS` | `content/city-scenery.ts` | ✅ | ✅ |
| `planCityBlocks(layout, opts?)` | `world/blocks/plan.ts:498` | ✅ | ✅ 头注释“纯函数，不 import Three.js”（:2） |
| `generateBlock()` / `generatePerimeterBlock()` | `world/blocks/generate.ts` | ✅ | ✅（只 import content + `buildings/random`） |
| `planSites()` | `world/blocks/sites.ts` | ✅ | ✅（只有 Math.min/max/round） |

**能否在无 DOM / 无 Scene / 无 renderer 的页面纯函数重算**：能。整条依赖链 `features/city-layout → content/* → world/blocks/{plan,sites,generate} → world/buildings/random` 不含 three、DOM、renderer（THREE 只在 `world/scene.ts` 之后的装配层出现）。

唯一硬前提：**必须提供“当前真实布局”**。真实 `CityLayoutView` 是 `GameState.cityLayout`（`app/state.ts:182`，初值 :251，随城区扩张由 `app/city-development.ts:170` 调 `addDistrict` 修改，存档校验见 `infrastructure/save-validation.ts:1643`），是纯 JSON，可直接传入；`createBaseLayout()` 只等于新开局城市，读档后有扩建城区就会偏。

## 2. `setOutdoor(boxes, bounds, edgeMargin)` 是否是唯一权威几何

- `runtime.ts:155-167`：`clearStatics()` → `bounds/edgeMargin` → `for (const box of withGround(boxes, bounds)) this.addStaticBox(box)`（地面盒由 `withGround` 追加，`collision.ts:32-42`）→ `world.step()`。
- 真正喂给 Rapier 的是 `addStaticBox`（`runtime.ts:129-147`），它会**丢弃退化盒**（任一 half ≤ 1e-5，:131）。`staticBoxes`（:59）只是同源镜像，供 `supportHeightAt` 用，非权威。
- 除 `setOutdoor` 外**还有**：
  - 室内静态：`setInterior()`（`runtime.ts:169-184`）= `floorBox(room)` + `interior.structureColliders` + `playerCollidersOf(furniture)`；调用点 `world.ts:414-424`，`structureColliders` 来源 `world/interiors/qingchuan.ts:889-920`。
  - 角色胶囊：`createCharacterCollider()`（`runtime.ts:109-119`，`ColliderDesc.capsule(height/2 - radius, radius)`，平移 y = height/2，脚底为刚体原点）；室外半径 `PHYSICS.character.radius = 0.42`（`content/config.ts:425` / `PLAYER.radius` :312），室内换成 `INTERIOR.player.collisionRadius = 0.3`（`content/interior.ts:88`，经 `setCharacterRadius` `runtime.ts:122-127`）。
  - 全仓只有 `runtime.ts` 调 `createCollider/createRigidBody`（grep：仅 :83/:118/:132/:144），没有第二套物理注册点。
- `edgeMargin` 只是位置**夹紧**参数（`isPoseFree` :259、`stepOnce` :390-395），**不是**碰撞体；室外传 `PLAYER_EDGE_MARGIN = 1.5`（`world/player.ts:64`）。

## 3. 不改 `PhysicsRuntime` 拿到“实际喂给 Rapier 的盒列表”

现状：**没有只读访问器**。`World.colliders` 是 `private`（`world.ts:252`），`PhysicsRuntime.staticBoxes` 是 `private`（`runtime.ts:59`），对外只有 `debugCounts()` 返回**数量**（:231-237）。

可行路径（按推荐度）：

- **A. 纯重算（不新建物理世界，推荐）**：用同一规划函数 + 同一地面适配函数重建，与 `setOutdoor` 输入逐位一致。
```ts
import { createBaseLayout, type CityLayoutView } from '../../src/features/city-layout';
import { planCityBlocks } from '../../src/world/blocks/plan';
import { withGround } from '../../src/world/physics/collision';
import { PHYSICS } from '../../src/content/config';
import type { PhysicsBox } from '../../src/world/physics/types';
import { PLAYER_EDGE_MARGIN } from '../../src/world/player';   // 1.5；注意该模块 import three

export function realOutdoorBoxes(layout: CityLayoutView): PhysicsBox[] {
  const buildings: PhysicsBox[] = layout.buildings.map((b) => ({ ...b.collision }));
  const blocks: PhysicsBox[] = planCityBlocks(layout).blocks.flatMap((p) =>
    p.colliders.map((c) => ({ minX: c.rect.x0, maxX: c.rect.x1,
                              minZ: c.rect.z0, maxZ: c.rect.z1,
                              minY: c.minY, maxY: c.maxY })));
  return withGround([...buildings, ...blocks], layout.bounds);   // 顺序与 world.ts:1247 一致
}
const layout = createBaseLayout();            // 或从存档 JSON 取 state.cityLayout
// 胶囊：halfHeight = PHYSICS.character.height/2 - PHYSICS.character.radius  (0.47)
//       collider 平移 y = PHYSICS.character.height/2                        (0.89)
```
- **B. 自建一个 `PhysicsRuntime` 实例**（同一份 src 代码，`import { PhysicsRuntime } from '../../src/world/physics'`，`await PhysicsRuntime.create({x,y,z}, PHYSICS.character.radius)` 再 `setOutdoor(boxes, layout.bounds, PLAYER_EDGE_MARGIN)`），可拿到真正 Rapier 的碰撞查询行为；但这是**第二套世界**，不是游戏里那一个，且它同样不暴露盒列表（只能 `debugCounts()`/`castShape`）。
- **C. 不可行**：从 `World` 实例读取（私有字段，TS 下只有 `// @ts-ignore` 或 `any` 绕过，属改公共边界的行为，不建议）。

A 方案与运行时的全部差异（必须如实标注）：
1. **街区抑制是会话内状态**（`blocks/scene.ts:144-153`，由 `world.resolveSceneryConflict()` 触发，不写存档），被抑制的块在运行时不存在碰撞，重算会把它算进去。
2. `addStaticBox` 丢弃退化盒（`runtime.ts:131`）。
3. 室内 `setInterior`（结构 + 家具）与 `playerCollidersOf` 无法从布局重算，需要家具状态与室内壳体。
4. `bounds` 夹紧（1.5 m）不是几何，画出来只是活动边界。

## 4. `src/world/physics/collision.ts`（50 行）是什么

`src/world/physics/collision.ts` 是**纯几何适配层**，把“世界坐标 AABB”转成 Rapier 静态盒所需的 `PhysicsBox`，不读 Three.js 对象、不从可见网格反推尺寸（文件头 :1-6）。导出 4 个纯函数：
- `groundBox(bounds)` :16-30 — 地面薄盒，顶面 `GROUND_TOP = -PHYSICS.character.offset`（:14）。
- `withGround(boxes, bounds)` :32-42 — `[groundBox, ...boxes]`，`setOutdoor` 唯一入口。
- `floorBox(width, depth)` :44-46 — 室内地板。
- `ceilingBox(width, depth, height)` :48-50 — 天花板。

**`playerCollidersOf` 不在这里**，在 `src/features/furniture/index.ts:468-497`：遍历 `state.items` 中 `status === 'placed'` 的家具，按 `definition.playerCollision` 的局部盒 + `quarterTurn` 旋转 + 网格 `cellCenter` 转成世界 AABB（已收纳不返回）；同模块 `findSafeStandingPose` 在 :282。室内壳体/门头/天花板 `structureColliders`、相机遮挡 `occluders` 在 `src/world/interiors/qingchuan.ts:876-920`。

## 5. `PhysicsRuntime.create()` 是否依赖 DOM / window

不依赖。`runtime.ts:104-107`：
```ts
static async create(pose, radius) { await ensureRapier(); return new PhysicsRuntime(pose, radius); }
```
`ensureRapier()`（:26-29）只做 `RAPIER.init()` 的一次性缓存。`@dimforge/rapier3d-compat@^0.21.0`（`package.json:21`）的 `dist/rapier.mjs` 里 `init()` 的实现是 `yield EI({ module_or_path: oC.toByteArray("AGFzbQ…") })`——WASM 以 base64 内联、在 JS 内解码，实测该文件里 `document.` / `window.` / `performance.now` / `atob` 均 0 次命中（仅 wasm-bindgen 的 `typeof self/window` 受保护静态访问器），不 `fetch` 外部 wasm、不碰 canvas。`runtime.ts` 自身只 import `RAPIER`、`content/config` 的 `PHYSICS`、`./collision`、`./types`，**不 import three/DOM**。结论：普通浏览器页面（乃至 Node）都能 `await PhysicsRuntime.create(...)`，只需 `WebAssembly` 支持。

## 6. 建筑/街区规划的确定性

完全确定性，无 `Math.random`、无时间、无遍历顺序依赖：

- 随机数来源唯一：`world/buildings/random.ts` 的 `hashSeed`（FNV-1a 混种，:19-27）与 `mulberry32`（:29-39），文件头明确“不使用 Math.random、时间、遍历顺序”。
- 种子输入：
  - 手写试点 `plan.ts:354`：`hashSeed([template.id, template.version, BLOCK_RULES_VERSION])`。
  - 全城生成 `generate.ts:630`：`hashSeed([family.id, family.version, BLOCK_RULES_VERSION, request.blockId])`；围合模板另加 `'perimeter'`（:775）。
  - 树种 `plan.ts:117-120` 同样走 `mulberry32(seed)`。
- `src/world/blocks` 全目录 grep 无 `Math.random`；`planSites` 只用 `Math.min/max/round`（`sites.ts:173-258`）。
- 因而：**同一 `CityLayoutView` + 同一 content 版本常量 ⇒ 同一碰撞盒集合（数值逐位相同）**。注意 `BLOCK_RULES_VERSION` / `family.version` 是种子的一部分，改它们会整体换布局；站点顺序依赖布局数组顺序，用同一份存档布局即稳定。

---

**结论**：可以——D 包能在不改 `src/**` 的情况下展示“真实”碰撞盒与胶囊，路径是纯重算 `createBaseLayout()`（或存档里的 `state.cityLayout`）→ `layout.buildings[].collision` + `planCityBlocks(layout).blocks[].colliders` → `withGround(..., layout.bounds)`，胶囊参数直接取 `PHYSICS.character.{radius,height,offset}`。**唯一做不到的是“运行中那一个 Rapier 世界的精确快照”**：会话内街区抑制（`CityBlocks.suppressed`）、室内 `setInterior` 结构+家具、以及退化盒剔除后的真实列表都拿不到；若这些必须与运行时逐项一致，缺的只读访问器是 `PhysicsRuntime.getStaticBoxes(): readonly PhysicsBox[]`（或 `World.getCollisionSnapshot()`），这属于给 `runtime.ts`/`world.ts` 增公共方法，需要走架构审查，不在“不改 src/**”范围内。

</answer>
</results>

