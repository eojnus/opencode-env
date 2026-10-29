# 塔科夫之狼只读调查

- 会话 ID：`ses_e7785bfa6ffeOD7goXmYnUiMfG`
- 时间：2026-10-30 00:24
- 目录：`C:\Users\Administrator`
- 模型：`deepseek/deepseek-flash`

---

## 🙋 我

第一阶段提示词：项目只读调查

你是《塔科夫之狼》的外部实现 Agent。本阶段只负责调查真实工程并报告，为 GPT Work 后续架构设计提供依据。GPT Work 负责架构决策、Git 分支、审查和最终集成；用户负责实际体验验收。

输入与工程定位

指定工程路径：
C:\Users\Administrator\Documents\ChatGPT\game2
无法访问时立即报告，等待提供同一仓库的可访问位置，不得用其他项目替代。

先核对仓库根目录、当前分支、HEAD、工作区状态和本地分支关系。允许只读 Git 查询，禁止 fetch、checkout、switch、branch 创建、stash、add、commit、reset、clean、merge、rebase、push 等改变仓库状态的操作。

GPT Work 本次交接时观察到：
当前分支：main
HEAD：5d19c369c8839425a0368769c58e643bfb955ac7
main 比本地 origin/main 引用超前 2 个提交
feature/player-jump-spacebar 落后 main 2 个提交
工作区干净
这是交接快照，必须重新核对，不代表远端实时状态。发现基线变化或不明未提交工作时，报告差异并停止，交由 GPT Work 处理。

以下两份文件目前均已跟踪，必须保留，不覆盖、不清理：
docs/player-jump-plan.md
docs/rapier-physics-gptwork-task.md
先读材料

完整阅读：
AGENTS.md
docs/architecture.md
docs/contracts.md
docs/decisions.md
docs/player-jump-plan.md
docs/rapier-physics-gptwork-task.md
package.json
实际使用的锁文件、TypeScript 与 Vite 配置
重点理解架构第 18 节、契约第三十节，以及相关建筑、读档碰撞就绪、室内会话和暂停规则。区分现行契约、历史记录与未批准草案；发现冲突时列明，不自行裁决。

本阶段不下载或加载指定 Skill，不研究远端 API，不安装 Rapier，不运行脚手架，也不编写游戏功能。Rapier 已由用户选定，后续资料核验无需重新比较或申请引擎选型。

调查范围

按调用链追踪真实实现，至少覆盖以下内容。以下文件是调查入口，不能代替对实际依赖的检查。
1. 输入与暂停
   检查 src/app/game.ts、src/world/world.ts 及 UI 快捷键说明。说明 Space、Esc、E、Tab、F、输入框、鼠标锁定、页面隐藏、失焦和按键释放如何处理；区分有效暂停、业务面板锁人物、家具编辑与碰撞加载门控。标出按键重复、残留输入及编辑会话的相关保护。
2. 人物移动与动画
   检查 src/world/player.ts、src/world/character.ts。说明期望方向、速度、生存倍率、子步、碰撞修正、实际位移、转身、动画和位置恢复的关系。找出所有人物位置写入点，说明当前高度、脚底原点、身体尺寸和存档 pose 的口径。
3. 室外场景与碰撞
   检查 src/world/scene.ts、buildings/、blocks/、scenery/ 及相关配置和布局投影。分别追踪业务建筑、装饰街区、道路、地面、边界、庭院、街景设施的生成与碰撞来源。明确哪些来自规划包络，哪些来自显式盒体或视觉资源；哪些有高度信息，哪些只支持 X/Z 阻挡。
4. 室内与镜头
   检查 src/world/interiors/qingchuan.ts、src/content/interior.ts 和 World 室内切换逻辑。区分地板、固定墙体、门框、门头、天花板、门扇、家具、设施、相机遮挡与交互范围。不要把相机遮挡清单视为人物三维碰撞清单。
5. 住宅家具编辑
   检查 src/features/furniture/、src/app/furniture.ts、家具编辑器与 UI。追踪摆放、旋转、收纳、恢复布局、临时预览、提交和自动保存如何同步场景与碰撞。解释编辑退出和进入住宅的安全落点算法、固定壳体连通域、失败处理、会话代次和输入规则。
   特别标出：现行“不挡人”对象在三维碰撞升级中可能产生的语义冲突。只提出问题，不自行改变契约。
6. 生命周期与位置恢复
   追踪布局同步、异步模型加载、失败回退、过期回调、显示会话、室内进入/退出、新游戏、读档与销毁。明确资源所有权、取消机制、碰撞就绪信号，以及“最终碰撞就绪后只修正非法位置”的实现路径。
7. 时间与持久化
   检查主循环、真实时间 delta、经济时间推进、速度倍率、暂停及 WorldSaveData 的组装与恢复。说明人物未来增加运行时高度和竖直速度会涉及哪些接口；分别列出可保持内存状态的方案与确实可能需要持久化的理由，不预设存档升级。
8. 构建与工程边界
   确认依赖和锁文件版本、构建脚本、WASM 相关现有配置及资源来源记录方式。只记录接入 Rapier 需要在下一阶段核实的事项，不安装依赖或试改打包配置。
碰撞清点输出

按实际对象或共享同一规则的对象类别制作表格，包含：
对象类别与实例/生成入口
权威数据来源及文件/符号
当前人物碰撞
当前相机遮挡
高度、方向、缩放信息是否完整
门洞、可站立面、头顶阻挡的缺口
可能适用的三维形状及近似代价（仅供架构审查）
不参与碰撞的现行理由
布局变化、加载与销毁责任方
对无法确认的内容标为“未确认”，注明缺少什么证据。不得根据视觉模型存在就认定必须建立碰撞体，也不得从模型反推并更改业务建筑尺寸。

输出报告格式

直接在回复中交回报告，不向仓库写报告文件：
1. 仓库与 Git 基线。
2. 已阅读材料、实际调查范围及未读部分。
3. 关键文件职责与调用链，附文件路径、符号及可核对行号。
4. 人物位置、碰撞、镜头、交互、经济时间和存档的权威来源。
5. 场景碰撞清单与缺口。
6. 家具编辑、异步加载及资源生命周期的兼容风险。
7. 潜在接口、核心职责或存档影响，区分必需、可避免和待核实。
8. 需要 GPT Work 决策的问题，以及可能需要用户确认的事项。
9. 第二阶段需核验的 Rapier API、依赖版本与 WASM 打包问题。
10. 实际执行的命令和验证情况。
跳跃手感、可跳上哪些物体、空中打开业务面板、编辑态空中状态、镜头高度跟随、室内外覆盖范围等，若现行材料未确定，列为待决策项，不写成已确认需求。

限制与停止条件
- 不修改任何代码、文档、配置、依赖、锁文件或 Git 状态。
- 不启动游戏、浏览器自动化、长时间模拟、全流程回归或性能测试。
- 本阶段只读调查，不执行类型检查与生产构建；实施交付阶段再按项目纪律执行。
- 不制定最终架构，不自行扩大范围，不创建车辆、动态物品或其他未来系统占位。
- 路径不可访问、关键材料缺失、基线不符、不明已有工作或关键问题使调查无法可靠继续时，报告证据和阻塞点后停止。
- 正常完成报告后立即停止，等待 GPT Work 审阅并提供第二阶段提示词。不得自动进入 Skill 下载、依赖安装或实现阶段。

## 🤖 AI

我先核对仓库的访问情况和 Git 基线，再阅读材料。

## 🤖 AI

# 《塔科夫之狼》第一阶段只读调查报告

## 1. 仓库与 Git 基线

### 1.1 路径与工具状态

- 工程路径 `C:\Users\Administrator\Documents\ChatGPT\game2` 可访问，`.git`、`src`、`docs`、`package.json`、`package-lock.json` 均存在。
- 当前执行环境 **没有可用的 `git` 命令**（`Get-Command git` 无结果，常见安装目录也没有 `git.exe`）。因此没有执行任何 `git fetch/status/log` 命令。
- 为核对基线，我以只读方式解析了 `.git/HEAD`、`.git/refs`、`.git/packed-refs`、`.git/logs/HEAD`、`.git/index` 和 pack 对象。所有操作均为读取；未修改、未 checkout、未 fetch、未 add/commit/stash。

### 1.2 实际基线

| 项目 | 实际值 |
| --- | --- |
| 仓库根 | `C:\Users\Administrator\Documents\ChatGPT\game2` |
| 当前分支 | `main` |
| HEAD | `5d19c369c8839425a0368769c58e643bfb955ac7` |
| HEAD 提交 | `docs: consolidate history and plan Rapier upgrade` |
| HEAD 父提交 | `cd76526ab9e1f25001a6856aafea3261af2ae3d7`（`feat: add residence furniture editor`） |
| 再上一提交 | `e1e96af3ad94d4f93d1fdc111d9434443477c4bf` |
| 本地 `origin/main` 引用 | `e1e96af3ad94d4f93d1fdc111d9434443477c4bf` |
| `main` 相对 `origin/main` | 超前 2 个提交（`cd76526`、`5d19c36`），无分叉 |
| `feature/player-jump-spacebar` | `e1e96af...`，落后 `main` 2 个提交 |
| 额外分支 | `feature/furniture-editor = cd76526...` |
| 额外工作树 | `C:\Users\Administrator\Documents\ChatGPT\wolf-furniture-editor`，检出 `feature/furniture-editor` |

### 1.3 工作区状态

由于本机没有 Git，我解析了 `.git/index` 并对 247 个跟踪条目逐一计算工作区 blob 哈希。首次按原始字节比较时所有文件都显示“已修改”，原因是工作区为 CRLF、索引为 LF；按 Git 常见的 CRLF→LF 归一化后：

- 暂存区相对 HEAD：**无差异**
- 工作区相对索引：**无差异**
- 未跟踪文件：**无**（排除 `.git`、`node_modules`、`dist` 及 `.gitignore` 已列项）
- `docs/player-jump-plan.md`、`docs/rapier-physics-gptwork-task.md` 均在索引中，且与 HEAD 一致，**已跟踪、未修改**

额外工作树 `wolf-furniture-editor` 同样解析为：300 个索引条目、无暂存差异、无工作区差异、无未跟踪文件。其 `feature/furniture-editor` 尖端 `cd76526` 已经是 `main` 的父提交，因此没有“未合入的隐藏代码”，但该分支/工作树没有出现在本次交接快照中。

### 1.4 基线结论

- **主基线符合交接快照**：`main`、HEAD、超前 2、`feature/player-jump-spacebar` 落后 2、工作区干净、两份文档已跟踪。
- 交接任务书自身第 21、23 行写的“超前 1 / 落后 1 / 两份文档未跟踪”是旧快照，与当前仓库不符；以当前 Git 元数据为准。
- 额外存在一个干净的分支与工作树（`feature/furniture-editor`）。它不是不明未提交工作，也不改变 `main` 基线；但属于交接清单之外的仓库状态，建议 GPT Work 在分支安排时知悉，不要自行清理。

---

## 2. 已阅读材料、调查范围与未读部分

### 2.1 完整阅读

- `AGENTS.md`（全文）
- `docs/player-jump-plan.md`（全文）
- `docs/rapier-physics-gptwork-task.md`（全文）
- `package.json`
- `tsconfig.json`
- `vite.config.ts`
- `package-lock.json` 的根依赖与关键包条目

### 2.2 重点章节阅读

- `docs/architecture.md`
  - 12.5 场景比例与当前碰撞口径
  - 13.5 世界与读档碰撞修复
  - 16 建筑视觉接入正式地图、调度与生命周期
  - 17 晴川公寓室内会话
  - 18 个人住宅家具编辑
  - 城市街区写实化
- `docs/contracts.md`
  - 一、时间（含暂停）
  - 二十三、建设阶段与读档碰撞
  - 二十九、晴川公寓室内会话
  - 三十、个人住宅家具编辑
- `docs/decisions.md`
  - D8（位置由 world 持有）
  - D9（暂停语义）
  - D72（读档碰撞修复）
  - D91–D96（室内、相机、加载、家具编辑）
- `docs/history.md`、`docs/scene-scale.md` 的现行口径部分

### 2.3 代码调查范围

逐文件阅读或重点追踪：

- `src/app/game.ts`
- `src/app/furniture.ts`
- `src/app/state.ts`
- `src/app/timeAdvance.ts`（入口与时间顺序）
- `src/world/world.ts`
- `src/world/player.ts`
- `src/world/character.ts`
- `src/world/scene.ts`
- `src/world/buildings/factory.ts`、`layout-adapter.ts`
- `src/world/blocks/types.ts`、`plan.ts`、`generate.ts`、`scene.ts`
- `src/world/scenery/assets.ts`（接口与资源归属）
- `src/world/interiors/qingchuan.ts`
- `src/world/interiors/furniture-editor.ts`（输入、拖动、提交、取消）
- `src/features/city-layout/index.ts`
- `src/features/furniture/index.ts`
- `src/content/config.ts`、`interior.ts`、`city-scenery.ts`
- `src/infrastructure/storage.ts`、`save-types.ts`、`save-validation.ts`（世界位置部分）
- `src/ui/panels.ts`、`hud.ts`、`furniture-panel.ts`、`README.md` 的快捷键说明

### 2.4 未完整阅读/未验证部分

- `architecture.md`、`contracts.md`、`decisions.md` 中与本次无关的经济、资本、政府、房地产细节章节，只做了目录与结构核对，没有逐行通读。
- `world/buildings/details.ts`、`facade.ts`、`assets.ts` 的完整建模细节，只核对了尺寸/包络/资源接口。
- `save-migrations.ts` 的完整 v1→v20 迁移链，只核对了当前 v20 与世界位置字段。
- 全部 UI 面板内部实现、股票/政府等业务界面。
- 未运行游戏、未打开浏览器、未做性能或视觉验证。
- 未读取任何 Rapier 官方文档或 Skill（本阶段明确不做）。

### 2.5 材料冲突与过期点（只列明，不裁决）

1. **任务书旧基线**：`docs/rapier-physics-gptwork-task.md:21,23` 仍写“main 超前 1、feature 落后 1、两份文档未跟踪”；实际为超前 2、落后 2、已跟踪。
2. **Space 的现行契约与目标方向冲突**：
   - 现行 `docs/contracts.md:31`、`docs/decisions.md:118`、`docs/architecture.md:587` 仍把 Space 描述为暂停/继续。
   - `docs/player-jump-plan.md:7,98` 与任务书 `:29` 要求取消 Space 暂停、改为跳跃。
   - 这是“现行契约 vs 未实施目标”，不能由本阶段自行改契约。
3. **二维碰撞 vs Rapier 三维目标**：
   - 现行架构/契约明确室内外人物碰撞是 X/Z 平面 AABB（如 `docs/contracts.md:1458-1465`、`docs/architecture.md:767-774`）。
   - 任务书要求三维碰撞。该变化会替换现行权威口径，需要 GPT Work 决定文档和接口如何升级。
4. **室内相机遮挡清单与文档措辞不完全一致**：
   - 文档称“墙体分段、家具、设施进移动碰撞；天花板与门洞封口只进相机遮挡”。
   - 代码中 `shellOccluders` 实际只包含北墙整片盒、天花板、隔断门头与隔断门扇；东/西/南墙、卫浴门头没有进入相机遮挡列表（`qingchuan.ts:342-357,619-626`）。
   - 这是代码观察，未做画面验证；不能据此断言相机一定穿墙。
5. **历史遗留**：`docs/history.md:9` 承认部分挂件/台灯可能悬空、部分地面装饰不挡人；这与现行“不挡人”契约一致，但会在三维碰撞升级中放大语义问题。
6. **AGENTS 中的旧存档版本**：`AGENTS.md` 的 v0.4 段落仍写 `formatVersion = 10`，属于历史记录；当前实际为 20（`config.ts:749`），不构成现行冲突。

---

## 3. 关键文件职责与调用链

### 3.1 文件职责

| 文件 | 职责 | 关键符号 |
| --- | --- | --- |
| `src/main.ts` | 启动、组装 Game、旧浏览器 `structuredClone` 回退 | `boot()` |
| `src/app/game.ts` | 应用协调：RAF、输入、暂停、面板、室内请求、家具会话、存档编排 | `Game.tick`、`handleKey`、`isPaused`、`applySnapshot` |
| `src/world/world.ts` | 世界编排：渲染、相机、输入、移动、布局同步、碰撞就绪、室内会话、家具编辑、存档位置 | `World.update`、`syncLayout`、`enterInterior`、`enterFurnitureEdit`、`getSaveData`、`restore` |
| `src/world/player.ts` | 人物水平移动、子步碰撞、转身、动画驱动 | `Player.update`、`Player.restore`、`PlayerPose` |
| `src/world/character.ts` | glTF 角色加载、1.78m 归一化、脚底贴地、动画混合 | `loadCharacterRig` |
| `src/world/scene.ts` | 城市地面、道路、建筑实例、建筑碰撞盒、标签、释放 | `buildCityScene`、`makeHandle`、`attachBuildingVisual` |
| `src/world/buildings/*` | 模块化楼体工厂、声明包络、视觉指纹、布局投影 | `envelopeOf`、`projectBuildingVisualRequest` |
| `src/world/blocks/*` | 只读布局派生的装饰街区、道路铺装、庭院、街景、碰撞 | `planCityBlocks`、`generateBlock`、`CityBlocks` |
| `src/world/interiors/qingchuan.ts` | 室内固定壳体、家具根节点、室内碰撞/遮挡、释放 | `loadQingchuanInterior`、`applyFurnitureLayout` |
| `src/world/interiors/furniture-editor.ts` | 俯视编辑相机、射线选择、拖动预览、提交/取消 | `FurnitureEditor` |
| `src/features/furniture/index.ts` | 纯家具规则、网格、碰撞盒派生、安全落点搜索 | `playerCollidersOf`、`findSafeStandingPose` |
| `src/app/furniture.ts` | 家具命令的原子提交与自动保存请求 | `FurnitureCommands` |
| `src/infrastructure/storage.ts` | 快照读写、备份、导入导出 | `writeSnapshot`、`parseSnapshot` |
| `src/infrastructure/save-types.ts` | `WorldSaveData` 等存档类型 | `WorldSaveData` |

### 3.2 主循环与时间链

1. `main.ts:36-94` 创建 `Game`，点击开始后 `Game.start()` 启动 RAF。
2. `Game.tick`（`game.ts:403-455`）：
   - 读取真实帧间隔 `rawDelta`；
   - 计算 `paused`；
   - 计算 `canMove`（未暂停、无面板、非家具编辑、鼠标锁定、碰撞就绪、非室内加载）；
   - `world.update(moveDeltaMs/1000, canMove, survival倍率)`；
   - 未暂停时 `accumulateSimulation(min(rawDelta, 1000ms))`；
   - 环境采样、`world.render`、HUD。
3. `accumulateSimulation`（`game.ts:458-464`）把真实时间按 `2.4 分钟/秒 × clock.speed` 累积，取整分钟后调用 `advanceGameTime`。
4. 经济倍率只作用于模拟时间，不作用于移动/动画（`config.ts:40-42`、`contracts.md:17-20`）。

### 3.3 输入与暂停链

- `Game.handleKey`（`game.ts:620-700`）处理 `E`、`Tab`、`F`、`Escape`、`Space`；输入框/可编辑元素直接忽略（`game.ts:613-621`）。
- `World` 自己监听 `keydown/keyup/blur`（`world.ts:354-360,1245-1284`）处理 WASD/方向键、Shift。
- 鼠标锁定：`requestPointerLock`/`exitPointerLock`（`world.ts:1354-1377`）；解锁回调在无面板且非编辑时自动打开暂停菜单（`game.ts:587-598`）。
- 有效暂停：`hiddenPaused ∨ clock.paused ∨ activePanel==='pause'`（`game.ts:540-544`）。
- 页面隐藏：设置 `hiddenPaused`、清输入、取消家具拖动、清模拟余量与帧基准（`game.ts:552-563`）。
- 失焦：World 只清输入与疾跑（`world.ts:1282-1284`），不暂停。
- 面板：只锁人物、释放鼠标，模拟继续（`game.ts:410-416,725-740`）。
- 家具编辑：`canMove` 为 false，模拟继续；编辑相机单独更新（`game.ts:410-416,427`、`world.ts:948-950`）。
- 碰撞加载门控：`world.update` 室外要求 `collisionReady`（`world.ts:1439-1441`）；app 的 `canMove` 也要求 `collisionReady` 与 `!interiorLoading`；F 交互与进入住宅分别有门控（`game.ts:652-660,835-838`、`world.ts:671-673`）。

### 3.4 读档/室内/家具链

- 读档：`Game.applySnapshot`（`game.ts:1344-1372`）→ `cancelFurnitureUi` → `invalidateResidenceRequest` → `world.cancelInterior` → `store.replace` → `beginDisplaySession` → `syncWorldLayout` → `world.restore(worldData)`。
- `World.restore`（`world.ts:1636-1666`）：先落原始 pose；碰撞未就绪则保存 `pendingRestorePose`；`markCollisionReady` 后调用 `applyPendingRestoreCorrection`，只对非法位置做一次最小推出。
- 室内：`Game.enterResidence`（`game.ts:817-872`）复核权限后调用 `World.enterInterior`（`world.ts:664-757`），动态 import 室内模块、原子提交、切换同一个 `player.group`；退出恢复室外快照（`world.ts:760-803`）。
- 家具：`Game.enterFurnitureEdit`（`game.ts:889-933`）生成 app 会话号；World 进入编辑态并创建 `FurnitureEditor`；每次拖动/旋转/收纳/摆放经 `FurnitureCommands` 原子提交并触发自动保存（`app/furniture.ts:31-72`）。

---

## 4. 人物位置、碰撞、镜头、交互、经济时间与存档的权威来源

### 4.1 人物位置写入点

所有人物位置写入都集中在 `Player` 与 `World`：

| 位置 | 文件/行 | 说明 |
| --- | --- | --- |
| 构造出生点 | `player.ts:89-117` | `CITY.spawn`，`group.position.y = 0` |
| 普通移动 | `player.ts:191-218` | 子步 X/Z 分离碰撞，最后 `group.position.set(posX, 0, posZ)` |
| `Player.restore` | `player.ts:135-142` | 设置 x/z/facing，`y = 0` |
| 进入室内 | `world.ts:729-733` | 使用 `safeSpawn` 的 x/z，facing 来自 `INTERIOR.spawn` |
| 退出室内 | `world.ts:783-787` | 恢复进入前室外快照 |
| 退出家具编辑安全落点 | `world.ts:915` | 2D 安全点 |
| 读档非法位置推出 | `world.ts:1096-1100` | 只改 x/z，不改 y |
| 装饰冲突推出 | `world.ts:1160` | 只改 x/z |
| 读档原始 pose | `world.ts:1643` | 只改 x/z/facing |
| 新游戏出生点 | `world.ts:1671` | 只改 x/z/facing |

**口径：**

- 当前人物没有运行时高度字段；`PlayerPose` 只有 `x/z/facing`（`player.ts:27-31`）。
- 模型归一化到 1.78m，脚底贴地（`character.ts:41-53`），`Player.group` 原点在脚底，`y=0`。
- 碰撞是水平圆（半径 0.42 室外、0.3 室内），没有胶囊高度、头顶或脚底体积；`hits()` 完全不读 `minY/maxY`（`player.ts:57-69`）。
- 室外移动边界来自动态 `bounds`，人物中心距边界 1.5m（`PLAYER_EDGE_MARGIN`）；室内边界余量用 `PLAYER.radius` 0.42，碰撞半径 0.3（`world.ts:768-769`、`contracts.md:1464-1465`）。
- 相机注视高度固定：室外 1.4m、室内 1.25m（`config.ts:293`、`interior.ts:110`）；不跟随人物 y。
- 存档 `WorldSaveData` 只包含 `player.x/z/facing`、可选相机 yaw/pitch/distance、`revision: 3`（`save-types.ts:28-34`、`world.ts:1619-1627`）。

### 4.2 碰撞权威来源

| 场景 | 人物碰撞权威 | 相机遮挡权威 |
| --- | --- | --- |
| 室外业务建筑 | `BuildingHandle.collider`，由 `LayoutBuilding.position/size` 和 `envelopeOf` 生成（`scene.ts:689-737`、`factory.ts:268-286`） | 同一个 `colliders` 数组，3D 射线检测 `minY/maxY`（`world.ts:1580-1585`） |
| 室外装饰街区 | `BlockPlan.colliders` → `BlockEntry.colliders` → `World.colliders`（`generate.ts:470-492`、`blocks/scene.ts:198-207`、`world.ts:1108-1119`） | 同一个 `colliders` 数组 |
| 室内 | `interiorColliders = shellColliders + playerCollidersOf(layout)`（`qingchuan.ts:945-968`） | `interiorOccluders = shellOccluders + 动态家具`（`qingchuan.ts:945-968`），不是人物碰撞清单的完整复制 |
| 家具 | `FurnitureDefinition.playerCollision` 局部盒，按 `quarterTurn` 旋转后转世界 AABB（`features/furniture/index.ts:468-497`） | 同一组动态盒；另有天花板/门头专用遮挡盒 |

### 4.3 交互权威

- `World.refreshNearbyBuilding`（`world.ts:1464-1495`）只遍历业务建筑 `handles`，用建筑碰撞盒到人物中心的水平矩形距离减半径，与 `interactionDistance` 比较；四边和转角都可交互。
- 不考虑人物高度、视线遮挡、跳跃状态；交互距离不来自模型。
- `Game.panelIdFor` 从当前逻辑布局的 `interactionId` 查询（`game.ts:713-715`）。

### 4.4 经济时间

- 唯一时间源 `clock.totalMinute`；主循环累积真实时间，按 `clock.speed` 推进；`advanceGameTime` 固定 1 分钟分段（`contracts.md:9-48`）。
- 人物移动使用真实 dt，单帧上限 100ms；经济模拟单帧上限 1000ms（`config.ts:43-49`、`game.ts:418-431`）。
- 生存倍率只乘人物水平目标速度（`game.ts:424`、`player.ts:172-175`），不改经济时间。

### 4.5 存档

- 当前 `SAVE.formatVersion = 20`（`config.ts:702-750`）。
- 保存：`Game.buildCurrentSnapshot` 深克隆 `GameState`，清零 `clock.paused`，附加 `world.getSaveData()`（`game.ts:1272-1282`）。
- 室内/加载中：`getSaveData()` 返回进入前的室外快照（`world.ts:1619-1621`）。
- 校验：`world.player.x/z/facing` 类型检查，camera 数值有限性检查（`save-validation.ts:2828-2840`）；x/z 未做有限性检查这一点也值得在新增 y/vy 时一并审视。

---

## 5. 场景碰撞清单与缺口

### 5.1 统一判据（先看这一段）

- **当前人物碰撞只认 X/Z**：`hits(x,z,collider,radius)` 忽略 `minY/maxY`（`player.ts:57-69`）。因此清单里的“有高度”只表示数据可用于未来三维化，**不代表现在已有三维效果**。
- **室外相机遮挡使用完整碰撞集合**：业务建筑 + 装饰街区，按 3D AABB 射线检测；因此相机能区分高度，人物不能。
- **室内相机遮挡不是人物碰撞的复制**：只用了 `shellOccluders`（北墙整片、天花板、隔断门头、隔断门扇）加动态家具；东西/南墙、卫浴门头不在该列表。
- “可站立面”当前不存在：没有垂直物理，人物永远在 y=0。

### 5.2 室外清单

| 对象类别与实例/生成入口 | 权威数据来源（文件/符号） | 当前人物碰撞 | 当前相机遮挡 | 高度、方向、缩放是否完整 | 门洞、可站立面、头顶缺口 | 可能适用的三维形状及近似代价 | 不参与碰撞的现行理由 | 布局变化/加载/销毁责任方 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 室外地面 | `scene.ts#updateGround` 1126-1130；`CITY.groundSize` | 无；仅靠 `bounds` 水平夹取 | 无（平面不参与射线） | 顶面 y=0，平面；无旋转/缩放问题 | 无脚底落地面；地面边缘靠边界，不是实体 | 固定大盒/平面，成本很低 | 人物始终 y=0，地面不参与水平阻挡 | `CityScene` 创建/更新/释放 |
| 道路、人行道、路缘、标线、铺装 | `scene.ts#buildRoadNetwork` 882-1055；`config.ts:163-179` | 无 | 无 | 顶面 0.01–0.016m，矩形；方向随道路 | 无可站立薄面；路缘 0.04m 高差未参与 | 平面/薄盒；路缘可作为 0.04m 台阶 | 避免 1–4cm 高差干扰行走；视觉分层 | `CityScene.syncRoadNetwork` 重建/释放 |
| 城市边界 | `World.bounds`（`world.ts:404`）、`Player.update` 179-199 | 只夹取人物中心，不是碰撞体 | 无 | 来自逻辑地图 `bounds` | 无实体边界；物理若不夹取可能走出地面 | 静态边界墙或继续夹取，成本低 | 现有 2D 行走范围约定 | World / 逻辑布局 |
| 基础业务建筑 6 栋（home/bank/office/securities/government/convenience） | `config.ts:183-268`；`createBaseLayout` 240-272；`makeHandle` 689-704 | 完整 AABB，扩人物半径；不可进入 | 同一个 AABB，3D 射线 | 宽/深/高完整；高度即规划高度；朝向由入口轴决定，包络 AABB | 门洞不参与人物碰撞（建筑整体实心）；台阶/雨棚/阳台/屋顶设备不单独碰撞；屋顶不可站立 | 静态 cuboid，每栋 1 个，成本低；若要台阶/雨棚需拆分，成本中 | 入口只是交互点，不是可进入空间；业务建筑尺寸为权威，不能按模型反推 | `CityScene.syncBuildings` + `World` 句柄；视觉异步挂载/释放 |
| 扩张城区与招商业务建筑（科技/商业/住房条带、tech-lab） | `features/city-layout#addDistrict` 288-410；`content/districts.ts` 模板 | 同上，AABB | 同上 | 尺寸/高度来自模板；位置稳定；视觉包络同规划 | 同基础建筑；新区可能没有门洞视觉，仍整体实心 | 静态 cuboid，成本低 | 与基础建筑同一规则 | `World.syncLayout` 增量；`beginVisualLoading` |
| 装饰街区楼体 | `blocks/plan.ts#planOne` 387-410；`blocks/generate.ts#toDecor` 324-338；`blocks/scene.ts` | 每个装饰楼体一个 AABB，按 `footprint` | 同一个 `colliders` | `size.width/depth/height` 完整；世界占地用轴对齐 `footprint` | 无门洞；无内部空间；屋顶不可站立 | cuboid；每块 4–8 栋，成本低 | 只作为街景体量，不承载业务 | `CityBlocks.sync` 按 block key 重建/释放 |
| 庭院围墙/绿篱 | `generate.ts:676-680`；`BlockPlan.walls` | AABB，高度 0.45（墙）或 1.2（绿篱） | 同一个 `colliders` | 矩形 + 高度；无旋转（轴对齐） | 可跨越/跳上？未定义；顶部可站立但当前无 Y | cuboid，成本低 | 规划上是实体边界 | `CityBlocks` |
| 行道树 | `content/city-scenery.ts:99-110`；`generate.ts:407-433` | 树干 AABB 0.56×0.56，`maxY=5.6`；树冠不碰撞 | 同一树干盒 | 高度按整树 5.6m；树干直径实测 0.54；树冠 2.44×2.0 仅视觉避让 | 树冠下可穿行（有意）；树干顶部 5.6m 不应是实心顶面；没有枝叶碰撞 | 树干圆柱/细 cuboid，成本低；树冠不建议碰撞 | 树冠稀疏，做盒会封死庭院/巷口（`city-scenery.ts:88-93`） | `CityBlocks.loadProps` / 共享资产库 |
| 长椅、路灯 | `city-scenery.ts:112-131`；`generate.ts:368-403` | 长椅 1.85×0.65×0.45；路灯 0.34×0.34×4.2，AABB | 同一个 `colliders` | 尺寸/高度/旋转完整（程序化长椅、外部路灯） | 长椅可站立；路灯细杆；当前人物可穿过其上方/下方（无 Y） | 长椅 cuboid；路灯细圆柱；成本低 | 街景设施需要阻挡但不需要复杂形状 | `CityBlocks` + `SceneryAssetLibrary` |
| 模块楼体附属装饰（台阶、雨棚、阳台、女儿墙、屋顶设备、招牌） | `buildings/details.ts`、`facade.ts`；正式挂载只用 `visual.envelope` 写 `handle.collider` 714-737 | 不单独碰撞；被建筑整体 AABB 覆盖或忽略 | 只受建筑 AABB 影响 | 视觉有高度/偏移；正式挂载不校验实际 AABB 是否落在声明包络内 | 雨棚/阳台下方的头顶净空没有表达；台阶不是可站立面；屋顶设备不挡人 | 若需要，拆分 cuboid/凸包，成本中–高；不建议自动对全部装饰生成 | 现行契约：碰撞只取规划尺寸 + 朝向的声明包络，不用模型包围盒（`architecture.md:399-405`） | `BuildingVisualFactory` + `CityScene.attach/detach` |
| 建筑标签、天空、太阳、雨、雾 | `scene.ts#makeBuildingLabel`、`world/environment/*` | 无 | 无 | 不适用 | 无 | 不建 | 纯表现，无空间阻挡意义 | World / EnvironmentRig |

### 5.3 室内清单

| 对象类别与实例/生成入口 | 权威数据来源（文件/符号） | 当前人物碰撞 | 当前相机遮挡 | 高度、方向、缩放是否完整 | 门洞、可站立面、头顶缺口 | 可能适用的三维形状及近似代价 | 不参与碰撞的现行理由 | 布局变化/加载/销毁责任方 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 室内地板与房间边界 | `qingchuan.ts#addRoomShell` 242-255；`INTERIOR.room` 78-85；`bounds` 984 | 无地板碰撞；仅 `interiorBounds` 水平夹取 | 无 | 地板 y=0；房间 3.3×6.2×2.55；边界缩 0.08 墙厚 | 无脚底落地面；边界余量 0.42 使实际中心范围更窄 | 固定薄盒/平面，成本很低 | 人物 y=0，边界已夹取 | `qingchuan` 场景创建/释放 |
| 室内外墙、入口门洞、南窗 | `qingchuan.ts:267-299`；`INTERIOR.openings.entrance/window` 164-168 | 北墙分两段，留 1.26–2.06m 门洞；南墙整面阻挡；东西墙整面阻挡；门头/窗头不在人物碰撞 | 仅北墙整片盒 + 天花板；东/西/南墙不在 `shellOccluders` | 墙高 2.55、门洞高 2.1、窗 0.5–2.1；尺寸完整 | 入口门头（2.1–2.55）没有人物碰撞，跳跃会穿头；南窗不可通过；屋顶/天花板不可站立 | 墙体 cuboid；门洞用分段墙 + 门头 cuboid；成本低 | 门洞必须可通行；天花板/门头只进相机遮挡，避免 2D 封死房间 | `qingchuan` 构建/释放 |
| 卫浴墙体、卫浴门洞、门扇 | `qingchuan.ts:382-414,475-484`；`openings.bathroomDoor` | 墙体分段 + 门洞留空；卫浴门扇视觉未单独加碰撞 | 卫浴门头、门扇均未进入 `shellOccluders`（仅部分固定盒进入编辑隐藏列表） | 门洞 z 1.35–2.3、高 2.05；尺寸完整 | 门头 2.05–2.55 无人物碰撞；门扇视觉可穿；门洞净宽需按三维复核 | 墙体 cuboid；门头 cuboid；门扇薄盒；成本低 | 与隔断同一策略：保证门洞通行 | `qingchuan` |
| 服务区隔断、门头、滑门 | `qingchuan.ts#addPartition` 546-662；`openings.partition` 169-181 | 门柱、厨房短墙、全开滑门停靠位都碰撞；门洞 1.54–2.66 留空 | 门头（2.05–2.55）与滑门停靠位进入 `occluders` | 净宽 1.12、门高 2.05、门扇 1.05×2.0；尺寸完整 | 门头只挡相机，不挡人物；跳跃会穿门头；滑门停靠位已是实体 | 门头 cuboid + 门柱/短墙 cuboid + 门扇薄盒；成本低 | 门洞必须可通行；门头只用于相机避障 | `qingchuan` |
| 天花板 | `qingchuan.ts:257-262`；遮挡盒 350-357 | 无 | 有：全房间 2.49–2.61m 薄盒 | 高 2.55；完整 | 跳跃头部会穿过天花板；没有室内“屋顶”人物碰撞 | 固定薄盒/平面，成本很低 | 2D 碰撞若加入会封死整个房间；只用于相机 | `qingchuan` |
| 挡人家具：床、沙发、书桌、椅子、鞋柜、马桶、洗手台、冰箱、下柜、床头小几、盆栽花盆、淋浴玻璃条 | `content/interior.ts:197-398` 的 `playerCollision`；`features/furniture/index.ts#playerCollidersOf` 468-497 | 每个显式局部盒，按 q 旋转为世界 AABB；当前忽略 Y | 同一组动态盒进入 `occluders` | 宽度/深度/局部偏移/`minY/maxY` 都有；q 0–3；完整度较高 | 床/桌/柜顶部可作为站立面但当前无 Y；沙发/椅子等高度不同；没有“从上方落下”的概念；`playerCollision` 刻意小于可见 AABB | 每件 1–2 个 cuboid；床/柜可组合；成本低–中 | 只挡人，不按可见模型包围盒；避免被子、台面外挑等变成隐形墙 | `qingchuan.applyFurnitureLayout` + `World.applyFurnitureLayout` 每次提交重建 |
| 不挡人家具/设施：玄关地垫、地毯、镜子、吊柜、抽油烟机、台灯、吸顶灯 | `content/interior.ts` 对应 `playerCollision: []`；`features/furniture/index.ts:475` 跳过 | 无 | 也不进入动态遮挡 | 有 `visualHeight`/`dragHeight`；吊柜 2.26、烟机 1.61、吸顶灯 2.54、台灯 0.71、镜子 1.89 | 地垫/地毯是薄面；吊柜/烟机/吸顶灯是头顶或高处障碍；跳跃时可能撞头；台灯放在小几上但没有支撑碰撞 | 若改为三维：地毯/地垫保持薄面或忽略；吊柜/烟机/吸顶灯加“仅头顶”盒；台灯/镜子按实际支撑判断 | 现行契约明确“不挡人”（`contracts.md:1538-1539`），避免地面装饰和高处物件变隐形墙 | `qingchuan` + 家具定义 |
| 卫浴/厨房固定视觉（淋浴底盘、马桶座圈外挑、台面外挑、门扇、把手等） | `qingchuan.ts:422-484` 等；与家具定义部分重叠 | 只按家具定义的碰撞盒；底盘/外挑/把手等不挡人 | 只按家具动态盒；固定视觉不额外遮挡 | 视觉尺寸有；与碰撞盒刻意不一致 | 淋浴底盘可走入、玻璃条挡人；座圈/台面外挑不挡人；门扇视觉与碰撞不完全一致 | 以 `playerCollision` 为准；不建议从视觉 AABB 反推 | 可见 AABB 与人物碰撞分离（`architecture.md:823-825`） | `qingchuan` |
| 相机专用遮挡盒 | `qingchuan.ts:342-357,619-626`；`contracts.md:1456-1463` | 不应作为人物碰撞 | 北墙整片、天花板、隔断门头、隔断门扇 | 有完整 minY/maxY | 若直接复制成人物碰撞会封死门洞/房间 | 只读遮挡数据，不建物理体 | 用途不同，不能混用 | `qingchuan` |

### 5.4 主要缺口汇总

1. **室外没有地面/竖直碰撞**：人物永远 y=0；地面、道路、铺装只有视觉，边界靠水平夹取。Rapier 必须补 ground/静态地面，或保留夹取并明确不落地。
2. **室内没有地板碰撞**：`interiorBounds` 只是水平边界；跳跃落地需要地板。
3. **天花板与门头只做相机遮挡**：室内天花板、入口门头、卫浴门头、隔断门头都不是人物碰撞。三维升级若直接把 `occluders` 复制成 collider，会把门洞封死；若完全不补，跳跃会穿天花板/门头。
4. **业务建筑是整块实心 AABB**：门洞、雨棚、阳台、台阶、屋顶设备都没有独立碰撞；不能从模块楼体视觉反推业务尺寸。
5. **装饰楼体、围墙、树木、长椅、路灯有高度数据，但人物只按 X/Z 使用**：树冠有意不碰撞；树的 `maxY=5.6` 是整树高度而非树干顶面，三维化时不能直接当可站立顶面。
6. **家具可见 AABB 与人物碰撞盒刻意分离**：床不含被子、柜不含台面外挑、淋浴只玻璃条、盆栽只花盆、地毯/吊柜/烟机/台灯/吸顶灯不挡人。三维升级若按视觉 AABB 自动生成，会改变现行语义。
7. **相机遮挡清单不完整/用途不同**：室外相机与人物共用同一碰撞集合；室内只用了部分壳体 + 家具。不能把任一清单直接当三维人物碰撞清单。
8. **模块楼体实际几何是否完全落在声明包络内，正式挂载时不校验**：`compareBounds` 只在开发原型使用；`attachBuildingVisual` 直接写 `visual.envelope`。对楼体装饰的三维化需要重新测量/验证。
9. **可站立面未定义**：屋顶、长椅、桌子、床、围墙顶、树冠都没有“站上去”的现行规则；跳跃高度和是否允许跳上家具是待决策项。
10. **交互不看高度**：`refreshNearbyBuilding` 只按 X/Z 矩形距离；空中、屋顶、家具上仍可能触发 F。

---

## 6. 家具编辑、异步加载与资源生命周期的兼容风险

### 6.1 家具编辑的现行机制

- **进入条件**：室内、无面板、非加载、碰撞就绪；E 进入（`game.ts:889-903`）。注意：在室外按 E 也会调用 `enterFurnitureEdit`，随后提示“只能在个人住宅内编辑家具”（`game.ts:623-630,891-894`），不是静默无操作。
- **会话代次**：app 的 `furnitureSession`，每个命令携带会话号；World 侧 `furnitureEditing` 与 `FurnitureEditor` 双重校验；读档/新游戏/离开住宅/dispose 递增会话并丢弃拖动（`game.ts:904-910,935-958`、`app/furniture.ts:47-54`）。
- **相机**：进入时保存 `camera.up`、位置、四元数、fov/near/far、yaw/pitch/距离、followTarget；俯视编辑；退出恢复（`world.ts:854-903,969-996`）。
- **输入**：E 进入/退出；Esc 先退出编辑；Tab/F 先尝试退出，失败则不继续原动作（`game.ts:623-679,634-643`）；指针按下/移动/抬起、lostpointercapture、window blur、visibilitychange、contextmenu 都有处理（`furniture-editor.ts:189-228`）。
- **提交**：拖动临时预览，pointerup 重算最终格后一次提交；每次提交 `store.run` 原子写入并请求自动保存（`app/furniture.ts:54-62`）；World 立即 `applyFurnitureLayout` 重建室内碰撞/遮挡（`world.ts:960-967`、`qingchuan.ts:948-969`）。
- **安全落点**：退出时若人物被家具覆盖，搜索阶段忽略所有可移动家具，只以固定壳体建立原站位连通域；先试四轴最小推出，再做 5cm 网格四方向 Dijkstra，检查起点首段/相邻格线段不穿固定墙体；最终落点仍检查全部家具（`world.ts:907-918,1031-1041`、`features/furniture/index.ts:282-434`）。
- **进入住宅**：用最新布局检查 `runtime.spawn`；被家具覆盖时在固定壳体连通域找安全点；找不到则中止进入并释放室内资源（`world.ts:699-718`）。

### 6.2 三维升级下的语义冲突（只提出问题）

1. **“不挡人”对象**：地毯/地垫、镜子、吊柜、烟机、台灯、吸顶灯目前明确不挡人。三维化后：
   - 地毯/地垫若被当作实体薄盒，会产生 2–6mm 的台阶/碰撞抖动；
   - 吊柜、烟机、吸顶灯位于头部或更高处，跳跃时可能真的撞头；
   - 台灯没有支撑碰撞，可能悬空；镜子贴墙但无碰撞。
   - 这些不是“漏了碰撞”，而是现行契约的有意选择，不能静默改成实体。
2. **可见 AABB 与碰撞盒分离**：床、柜、淋浴、盆栽、马桶、台面都有意缩小碰撞。若三维碰撞从可见网格或 `visualHeight` 反推，会改变可通行宽度和“可站立”语义。
3. **2D 安全落点**：`findSafeStandingPose` 只判断 X/Z；如果角色可以站在床上/桌上，或家具在角色脚下被移动，当前算法会把“站在家具上”判为非法并推回地面。需要明确三维下“安全落点”是地面落点还是允许站在家具顶面。
4. **编辑态空中状态**：目前进入编辑不要求人物在地面；若跳跃后再按 E，可能在空中进入编辑，编辑相机/人物隐藏/退出落点都只处理 X/Z。需规定编辑是否强制落地、是否允许空中进入。
5. **Space 与编辑态**：当前 `Game.handleKey` 在编辑态没有拦截 Space；编辑态不是 `panels.isOpen`，所以按 Space 会切换手动暂停。若 Space 改为跳跃，必须明确编辑态不触发跳跃，且是否仍允许 Space 暂停。
6. **F/Tab/Esc 的重复键**：E 有 `event.repeat` 保护，Tab/F/Esc 没有。长按 F 可能在打开面板后立即被重复事件关闭；长按 Tab 可能反复开关。当前不是跳跃专属问题，但改动输入时应一并审查。
7. **切换时的落点责任**：家具提交会立即改变碰撞；如果人物正站在被移动/收纳的家具位置，当前不处理，只有退出编辑时才搜索安全点。三维化后“家具从脚下移走/在头顶放下”需要明确的即时策略。

### 6.3 异步加载与资源生命周期

| 流程 | 现行保护 | 三维化风险 |
| --- | --- | --- |
| 建筑视觉 | `visualGeneration + layoutRevision + handle 实例 + 视觉指纹` 四重检查（`world.ts:528-543`）；过期成功结果 `dispose`；失败保留占位碰撞并结算（`world.ts:557-567`） | 物理体必须与视觉同一代次；不能让过期回调创建/删除碰撞体 |
| 碰撞就绪 | 每轮 `beginVisualLoading` 设 `pendingVisualLoads`，全部成功/明确失败后 `markCollisionReady`；过期代次不扣当前计数（`world.ts:456-468,551-555`） | Rapier 初始化/静态体构建也必须纳入“就绪”信号，否则人物会在空物理世界里移动 |
| 读档位置修正 | 原始 pose 先落；就绪后只对非法位置做一次最小推出（`world.ts:1636-1665,1222-1227`） | “非法”目前只检查业务建筑 + 装饰冲突；三维后需要定义脚底悬空/嵌入/头顶卡住是否算非法 |
| 室内模块 | 动态 import、四件 glTF `Promise.allSettled` 全部结束后统一提交；失败逐个释放迟到成功模型并释放场景；`interiorGeneration` 检查（`qingchuan.ts:862-937`、`world.ts:664-757`） | 室内物理世界/碰撞体必须在同一提交点创建；失败时释放，不能留下半套物理体 |
| 家具布局 | 每次提交重建 `currentColliders/currentOccluders`；World 重新指向新数组（`qingchuan.ts:948-969`、`world.ts:831-838`） | 需要增量增删物理体或整组替换；存储旧数组引用会留下幽灵碰撞 |
| 角色模型 | 加载完成检查 `disposed`，失败保留占位（`world.ts:1230-1241`） | 不影响物理胶囊；但跳跃动画/落地动画需要另建 |
| 场景销毁 | World 先失效代次/取消请求 → 摘人物 → 释放室内 → 装饰街区 → 城市场景 → 街景库 → 建筑工厂 → renderer（`world.ts:1689-1726`） | Rapier world 的释放顺序必须明确，避免场景对象已释放但物理 world 仍持有引用；反之亦然 |
| 自动保存 | 家具每次命令入 Promise 链；快照在 `performSave` 时构建；室内返回室外快照（`game.ts:1284-1302`、`world.ts:1619-1621`） | 若保存 y/vy，需保证快照与物理状态同一时刻；若只在内存保留，读档需明确“回到地面” |

---

## 7. 潜在接口、核心职责或存档影响

### 7.1 必需（若实现三维跳跃/碰撞）

| 项 | 说明 |
| --- | --- |
| 人物运行时竖直状态 | `Player` 需要高度、竖直速度、落地状态；`PlayerPose` 至少增加 `y`，`PlayerUpdateResult` 可能需要 `grounded`/`verticalSpeed`。 |
| 单一权威位移 | 不能让旧 2D `hits()` 与 Rapier 同时写人物位置；当前所有位置写入点必须收敛到一个控制器。 |
| 地面碰撞 | 室外 y=0 地面、室内地板；当前完全没有人物竖直落地面。 |
| 静态碰撞体生命周期 | 建筑、装饰街区、室内壳体、家具的增删/替换必须与现有 `syncLayout`、`applyFurnitureLayout`、`enterInterior/exitInterior`、`dispose` 对齐。 |
| 碰撞就绪扩展 | `isCollisionReady`/`whenCollisionReady` 应覆盖“Rapier 初始化 + 当前场景静态体构建完成”，否则现有加载门控会失效。 |
| 输入与暂停 | Space 从暂停改为跳跃；需要 `grounded`、按键重复、面板/编辑/加载/鼠标锁定门控；暂停与业务面板要能区分“冻结物理”和“只锁输入”。 |
| 相机策略 | 当前固定 1.4/1.25m 目标高度；跳跃是否跟随、跟随比例、落地回弹需要决定。 |
| 室内外切换 | 进入/退出要切换物理世界或重建静态体；退出恢复室外 pose 时必须清零竖直速度。 |
| 交互规则 | 空中/家具上/屋顶是否允许 F、Tab、E；当前交互不看高度。 |

### 7.2 可避免（不必为本次引入）

| 项 | 理由 |
| --- | --- |
| 持久化 y/vy | 若接受“读档回地面/回室外快照”的策略，可保持 `WorldSaveData` 不变，避免存档版本变化。 |
| 新增存档切片/版本 | 当前家具已经是 v20；跳跃若只存内存，不需要新版本。 |
| 车辆/动态物品/ECS/事件总线 | 任务书明确本轮不做，也不预埋。 |
| 把全部视觉模型转成碰撞 | 现行契约明确按规划/显式盒，不从模型反推；树冠、地毯、吊柜等不应自动生成。 |
| 改动经济时间 | 物理应使用真实 dt，与 `advanceGameTime` 分离；不需要动经济时间接口。 |
| 把相机遮挡清单复制成人物碰撞 | 用途不同，尤其室内天花板/门头。 |

### 7.3 待核实

- 家具/装饰的现有 `minY/maxY` 是否足以直接映射为 Rapier cuboid；哪些需要组合形状。
- 模块楼体实际视觉是否严格落在 `envelope` 内；屋顶设备、台阶、雨棚的外扩量。
- 室内东西/南墙为什么没有进入相机遮挡列表；是刻意省略还是遗漏。
- 人物胶囊的半径/高度/脚底偏移与 1.78m 模型、0.42/0.3 碰撞半径如何统一。
- 低帧率下固定步长、最大子步数、积压丢弃策略。
- WASM 初始化失败时的降级行为（禁止移动？保留旧 2D 回退？需要决策）。

### 7.4 存档影响

- 当前 `WorldSaveData` 只有 x/z/facing + 可选相机；`revision` 为 3。
- 若只保留运行时 y/vy，不写存档：**不需要改 `SAVE.formatVersion`**；读档/进入室内/退出时统一回到地面或快照位置即可。这是可避免存档升级的方案，但需要用户接受“空中保存后读档不在空中”。
- 若要保存 y/vy 或“室内地点”，则涉及 `WorldSaveData` 结构、校验、迁移和 `SAVE.formatVersion`，按 AGENTS 必须先确认；本阶段不预设。
- 家具布局已在 `GameState.furniture`，不在 `WorldSaveData`；三维家具碰撞不需要新存档字段。

---

## 8. 需要 GPT Work 决策的问题与可能需要用户确认的事项

### 8.1 需要 GPT Work 决策

1. **分支基线**：从当前 `main`（含 `cd76526` 家具编辑与 `5d19c36` 文档）新建实现分支，还是复用 `feature/player-jump-spacebar`？旧分支目前等于 `origin/main`，不含家具编辑；不能直接在其上实现而不先对齐。
2. **覆盖范围**：第一阶段只做室外 + 地面/建筑/街区，还是同时做室内壳体/家具？任务书要求清点全部，但实施范围仍需拆分。
3. **碰撞权威映射**：业务建筑是否继续整块 AABB，还是为门洞/雨棚/台阶拆分？装饰楼体、围墙、树木、长椅、路灯是否全部进入 Rapier 静态体？
4. **“可站立”规则**：屋顶、长椅、桌子、床、围墙顶、树冠是否允许站立；跳跃高度是否足以到达；这决定是否需要顶面和台阶。
5. **室内天花板/门头**：是否补人物头顶碰撞；如果补，门洞如何保持通行；是否限制室内跳跃。
6. **暂停/面板/编辑语义**：业务面板打开时空中角色继续下落还是冻结；家具编辑时是否强制落地；Space 在编辑态是否仍可暂停。
7. **存档策略**：只保内存竖直状态，还是保存 y/vy；是否接受读档回地面；是否需要版本升级。
8. **相机策略**：跳跃时镜头是否跟随 y、跟随比例、是否影响室内相机高度钳制。
9. **交互策略**：空中、家具上、屋顶是否允许 F/Tab/E；交互距离是否加入高度/视线。
10. **失败降级**：Rapier 初始化或 WASM 加载失败时，是锁人物并提示，还是保留旧 2D 移动作为临时回退（后者会增加双系统风险，需明确禁止）。
11. **文档更新责任**：现行 architecture/contracts/decisions 仍写 2D 与 Space 暂停；实现后由谁、在哪个提交同步修改，需先约定。

### 8.2 可能需要用户确认

- 跳跃手感：高度、上升/下落时长、是否可变跳、是否要跳跃动画；当前完全未定。
- 可跳上的物体：家具、长椅、矮墙、台阶、屋顶；是否允许跳上桌子/床。
- 室内是否允许跳跃；天花板很低（2.55m），门头 2.05m。
- 空中打开业务面板时人物继续落地还是冻结。
- 跳跃时镜头是否跟随人物高度。
- 空中保存/读档是否必须保留空中状态。
- 是否接受“读档/进入室内回到地面”的简化。
- 是否要求街景小物件（路灯、树冠、地毯、吊柜）也参与三维碰撞；现行契约是“不因模型存在就建碰撞”。

---

## 9. 第二阶段需核验的 Rapier API、依赖版本与 WASM 打包问题

### 9.1 当前依赖事实

- `package.json` 直接依赖只有 `three ^0.186.0`；devDependencies 为 `@types/three ^0.186.0`、`typescript ^5.9.3`、`vite ^8.3.5`。
- `package-lock.json` `lockfileVersion: 3`；实际安装：
  - `three 0.186.1`
  - `vite 8.3.5`
  - `typescript 5.9.3`
  - `@types/three 0.186.0`
- `@dimforge/rapier3d-compat 0.12.0` 出现在 `node_modules` 和 lockfile 中，但它是 `@types/three` 的依赖（`dev: true`），**不是项目直接依赖，也不是已批准的运行时接入**。第二阶段必须把它当作“类型包的传递依赖”对待，不能据此声称 Rapier 已安装/已选版本。
- 项目没有 `@dimforge/rapier3d` 直接依赖，没有 Rapier 初始化代码，没有 WASM 资源配置。

### 9.2 需要核验的 API/行为

1. **包选择**：`@dimforge/rapier3d-compat` 与 `@dimforge/rapier3d` 的区别；compat 是否内嵌 WASM（base64）从而无需单独资源；最新稳定版本、Apache-2.0 许可、TypeScript 类型。
2. **初始化**：`await RAPIER.init()` 的时机；初始化是否可重复；失败/超时处理；是否阻塞首帧。
3. **人物控制器**：
   - `KinematicCharacterController` 的创建参数：`offset`、`maxSlopeClimbAngle`、`minSlopeSlideAngle`、`autostep`、`snapToGround`、`applyImpulsesToDynamicBodies`。
   - `computeColliderMovement` / `computedMovement` / `computedGrounded` / `numComputedCollisions` 的语义。
   - 角色 collider 用 capsule 还是 cylinder；半径 0.42/0.3、身高 1.78、脚底原点如何对齐。
   - 水平期望位移如何与竖直速度组合；子步/固定步长下如何避免穿透。
4. **静态体**：
   - `ColliderDesc.cuboid/cylinder`、`RigidBodyDesc.fixed()`、复合体/多 collider；
   - 世界坐标 AABB 与 `Collider` 的 minY/maxY 直接映射；
   - 树冠/细杆/薄片是否用凸包或圆柱；
   - 大量静态体的创建/删除成本。
5. **世界步进**：
   - `world.timestep`、固定步长、累积器、最大子步数；
   - 真实 dt 与暂停/后台/面板的交互；
   - 是否需要插值渲染；
   - `world.step()` 与手动 `computeColliderMovement` 的关系。
6. **生命周期**：`world.free()`、`ColliderSet/RigidBodySet` 释放；布局变化/室内切换时整世界重建还是增删；与 `World.dispose` 顺序。
7. **查询**：是否需要 raycast/shape cast 处理相机、交互、落地检测；Rapier 查询与现有 Three.js 相机射线的职责边界。

### 9.3 WASM/Vite 打包问题

- `vite.config.ts`：`base: './'`、`build.target: 'es2019'`、`assetsDir: 'bundle'`、`optimizeDeps.rolldownOptions.transform.target: 'es2019'`。
- 需要验证：
  - Rapier 的 JS glue 是否含 ES2020+ 语法，是否会被降级到 es2019；
  - WASM 是内嵌 base64 还是独立 `.wasm`；若独立，`base: './'` 下生产路径、`assetsDir`、MIME、`instantiateStreaming` 回退；
  - Vite 8/Rolldown 对 WASM 的预打包与构建行为；
  - 旧 Chromium/Edge 92 的 WebAssembly/JS 语法兼容性（项目明确关心旧浏览器）；
  - 开发服务器与 `file://`/静态部署的差异；
  - WASM 体积（当前传递包约 1.4MB wasm + 2MB JS）对首屏和低端设备的影响；
  - 是否需要 `optimizeDeps.exclude` 或专用插件；不能用“能 import”代替“能构建、能运行”。
- 本阶段不安装、不改配置、不跑构建；以上均为第二阶段核验项。

---

## 10. 实际执行的命令与验证情况

### 10.1 已执行（全部只读）

- 检查路径存在、列出仓库根目录与 `.git`。
- 读取 `.git/HEAD`、`.git/config`、`.git/packed-refs`、`.git/refs/**`、`.git/logs/HEAD`、worktree 元数据。
- 使用 Node 26.13.0 在临时目录运行自写只读脚本，解析：
  - `.git/index`（v2，247 条）；
  - HEAD commit/tree 对象（含 pack 与 delta 解析）；
  - 工作区文件 blob 哈希；
  - `.gitignore`、未跟踪文件；
  - 提交父链。
- 对 `wolf-furniture-editor` 工作树重复同样检查（300 条索引）。
- 读取 `package.json`、`package-lock.json`、`node_modules` 中 `three`、`vite`、`typescript`、`@types/three`、`@dimforge/rapier3d-compat` 的版本。
- 阅读上述源码与文档。

### 10.2 结果

- `main` 基线、超前/落后关系、工作区干净、两份文档已跟踪：**均已核对**。
- 额外分支/工作树：**已发现并报告**，干净，无隐藏未提交工作。
- 未执行 `git fetch`，因此 `origin/main` 只是本地引用，不代表远端实时状态。
- 未运行 `npm install`、`vite`、`tsc`、生产构建、浏览器、游戏或性能测试。
- 未安装/加载 Skill，未访问 Rapier 官方文档，未修改任何文件。
- 临时脚本仅位于 `C:\Users\Administrator\AppData\Local\Temp\opencode\gitcheck.mjs`，不在仓库内。

### 10.3 验证边界

- 本文所有“当前行为”结论来自代码与文档静态审查；没有实际运行验证。
- 建筑视觉实际包围盒、相机穿墙、家具悬空、树冠遮挡等，均未做画面验收；相关行已标为“未确认/需运行验证”。
- 未对经济、存档迁移链做完整回归；本阶段不要求。

---

**报告结束。**  
本阶段未进入 Skill 下载、Rapier 安装、依赖修改或游戏功能实现；等待 GPT Work 审阅并提供第二阶段提示词。

## 🙋 我

你是《塔科夫之狼》的外部实现 Agent，负责 Rapier 接入、人物三维移动碰撞、现有场景碰撞整理及相关资料记录。

你已经充分了解本项目，不再单独提交“了解项目”阶段报告。请在实施前核对受影响代码与现行契约，随后连续完成资料准备、具体实现和交付，不因普通实现细节等待中间审查。

GPT Work 负责架构决策、Git 分支管理、最终审查和集成；你不得提交、合并、推送或发布。用户负责实际游戏体验验收。
一、工程与执行前提
指定工程：
C:\Users\Administrator\Documents\ChatGPT\game2
无法访问时停止报告，不得使用其他项目替代。

遵守：
AGENTS.md
docs/architecture.md
docs/contracts.md
docs/decisions.md
docs/player-jump-plan.md
docs/rapier-physics-gptwork-task.md
重点复核架构第 18 节、契约第三十节，以及室内会话、暂停、建筑规划、异步代次和读档碰撞就绪规则。现行架构与契约优先于历史记录；本提示词覆盖旧草案中尚未授权 Rapier 的表述。

允许只读查询 Git 状态，禁止任何 Git 写操作，也不得通过其他工具改写 Git 元数据或自行创建工作树。

必须在 GPT Work 已安排的独立开发分支上实现。 如果仍在 main、分支基线无法确认，或存在无法辨认的已有改动，停止并报告，由 GPT Work 处理，不得自行切换或创建分支。

保留用户已有文件，尤其：
docs/player-jump-plan.md
docs/rapier-physics-gptwork-task.md
不得覆盖、清理或自行处理它们。执行时以真实 Git 状态为准，不沿用任务书中的历史分支关系。
二、连续完成 Skill 与官方资料准备
指定 Skill：

threejs-gameplay-systems / SKILL.md

从该仓库获取完整的：
skills/threejs-gameplay-systems/
将其放在游戏仓库之外的独立资料目录，记录绝对路径、来源与提交标识。不要为了下载资料操作游戏仓库的 Git；可采用固定提交的仓库归档下载方式。

完整读取 SKILL.md，沿引用读取本任务相关资料，特别是：
references/physics-engine-selection.md
审阅相关脚本后才能判断是否使用，不能直接执行。报告实际读取内容，不得将“下载”表述成“已加载”；说明采用的加载方式。若运行环境不支持注册 Skill，明确区分“已读取并应用指导”与“已由环境加载”。

研读 Rapier 官方资料：
- JavaScript 入门
- 角色控制器
- 碰撞体
- 车辆控制器
车辆资料只用于理解能力边界，本轮不实现车辆。

Rapier 已经选定，不重新申请选型确认。使用原生 Three.js、TypeScript、Vite，不引入 React、React Three Fiber、ECS、事件总线或其他框架。不运行 Skill 脚手架，不使用 --force，不套用其目录模板、测试体系或新游戏流程。

核实候选依赖的真实版本、类型、许可证、WASM 初始化和 Vite 生产构建支持后，选择适合当前工程的官方包。普通版本与初始化适配选择由你依据资料完成；新增打包插件或其他框架超出本次默认授权，先报告。

Skill 建议与项目规则冲突时，遵守项目规则，并在最终报告中记录取舍。指定 Skill 无法获取、关键引用缺失或官方 API 无法核实时，停止报告，不编造结果。

完成资料核验后直接继续实施，无需提交中间报告等待批准。
三、文件职责与架构边界
按以下职责组织，避免将全部逻辑堆进 world.ts：
位置	职责
src/world/physics/	Rapier 初始化、物理世界、角色控制、碰撞体创建与释放
src/world/physics/ 内独立适配文件	将现有场景权威数据转换为运行时三维碰撞描述
src/world/player.ts	输入期望、人物朝向和动画；消费唯一权威物理位移
src/world/world.ts	活动场景、物理运行时与人物、镜头、就绪门控的协调
src/world/scene.ts、buildings/、blocks/、interiors/	各自对象的碰撞数据来源与生命周期衔接
src/content/config.ts	新增物理步长、跳跃和控制参数
src/content/interior.ts	住宅固定结构与家具的显式几何定义，沿用既有职责
src/app/game.ts	有效暂停、人物操作门控、输入入口及场景恢复编排
src/ui/	快捷键提示及必要的加载/失败提示
依赖清单、锁文件	必需的 Rapier 依赖
相关文档	实际采用的架构、契约、决策和碰撞近似


具体文件名和局部私有函数可按工程风格确定，不预建未来系统。

物理层不得读取经济状态、推进游戏时间或访问存档数据库；World/UI 不直接读写业务状态。跨业务协调仍在 app。

不改变 src/core/ 职责，不擅自变更波及两个以上业务模块的公共接口签名，不更改 SAVE.formatVersion，不使用 any、双重断言或可写转换绕过只读边界。
四、人物控制与输入
使用 Rapier 运动学角色控制器作为本轮人物碰撞实现路径；重力、竖直速度和跳跃状态由项目角色控制代码明确维护。

必须满足：
- Space 从暂停改为跳跃，忽略自动重复，按住不连续起跳。
- 只在可靠的可起跳地面状态触发；空中重复按键不能追加跳跃；落地后重新按键可跳。
- 不默认增加二段跳、土狼时间、跳跃缓存、蹲伏或攀爬。
- 地面吸附不得抵消向上的跳跃；碰头应终止向上运动；墙面接触不能误判为地面。
- 保留现有方向、疾跑、生存速度倍率、实际位移驱动转身及动画规则。
- 人物身体尺寸、脚底原点与模型比例协调；不要用可见模型包围盒每帧重算角色尺寸。
- 不为跳跃强行增加外部动画资产；没有现成跳跃动画时采用克制的现有表现并如实报告。
- 人物位移与碰撞只有一套权威结果，移除旧二维移动阻挡对同一人物位置的竞争。
旧二维几何若仍用于家具编辑选取、连通域或安全候选搜索，可以保留，但必须明确职责；最终人物落点仍须符合三维碰撞，不能让旧算法随后覆盖物理结果。

输入框、面板、失焦、页面隐藏、指针锁变化和编辑会话切换时正确处理输入，禁止残留跳跃请求在恢复操作后突然触发。
五、时间、暂停和空中状态
物理使用真实时间固定步长，与经济游戏分钟和速度倍率分离。设置累计时间上限和每帧最大子步数，丢弃超限积压，避免恢复页面时补算长时间物理。

采用以下本轮规则：
- 手动暂停、Esc 暂停菜单、页面隐藏：冻结物理，恢复时不追赶暂停期间时间。
- 业务面板：经济继续；禁止新的人物移动和跳跃输入，已有竖直运动继续受重力与碰撞影响直至落地。
- 家具编辑：冻结人物物理与输入，保持现有编辑相机及会话规则；恢复前校验落点并清理竖直速度与待处理跳跃。
- 进入/退出室内、读档和新游戏：在目标碰撞就绪后恢复合法落点，清空旧场景竖直速度、累计步长和输入请求。
- 物理或场景未就绪：锁人物移动与相关交互，不能借此暂停经济。
保留现有 Esc、E、Tab、F 的编辑退出优先级与失败阻断行为。暂停期间仍可整理家具的既有能力不得因冻结人物物理而失效。

跳跃期间镜头目标应考虑人物高度，并保留既有遮挡处理；不新增镜头模式或大幅改动水平跟随手感。手感数值集中配置，作为待用户验收的初始值。
六、场景三维碰撞整理
覆盖正式室外场景和现有住宅室内。先建立实际清单，再按对象实现，不根据渲染 Mesh 无差别生成碰撞体。

每类对象记录：权威数据、变换、形状、可站立性、头顶阻挡、近似、不参与碰撞的理由，以及创建/更新/释放责任方。

实施原则：
- 室外地面、道路及可行走区域提供连续可靠支撑；城区边界遵循现有动态布局边界。
- 业务楼体以声明包络和规划尺寸为权威，不从视觉模型反推业务尺寸。
- 装饰楼和街景按实际生成数据处理，保留设计中的通道与庭院。
- 室内地板、固定墙体、门框、门头、天花板分别处理；门洞不能被整块外包盒封死。
- 家具优先使用显式局部几何、组合盒等简单形状；不能用可见 AABB 替代既有精细碰撞定义。
- 位置、旋转、缩放和局部到世界变换必须一致。
- 合理高度、具有实体支撑的表面允许自然落脚，不增加自动攀爬或自动登阶玩法。
- 相机遮挡、人物碰撞、交互范围保持独立，不互相无差别复制。
- 静态三角网格仅在简单形状明显不适用且能说明代价时使用；不得给所有模型自动创建 trimesh。
现行家具“不挡人”契约继续有效。不要顺手把地毯、镜子、吊柜、烟机等全部改成新的三维障碍。若完整头顶碰撞目标与某件家具现行规则发生实质冲突，指出具体对象、影响和最小建议，停止该冲突部分等待处理，不擅自改契约。
七、布局、异步与家具编辑同步
必须保留并衔接现有：
- 布局增量同步、显示会话切换。
- 异步请求代次、取消与失败回退。
- 最终碰撞就绪门控。
- 读档后仅修正非法位置。
- 室内取消和资源释放。
- 家具编辑会话、临时预览、原子提交与自动保存。
家具临时拖动预览不得变成正式物理布局；已提交的移动、旋转、收纳和重新摆放必须同步正式碰撞，不能累积旧碰撞体或重复注册。

退出编辑时，原位置合法则保留；需要调整时遵守固定壳体连通域和最终全部家具检查。找不到合法点则保持编辑态并提示，禁止穿墙、移动家具或忽略最终碰撞。

进入住宅使用最新已提交布局检查出生位置；失败时取消进入并释放资源。

物理碰撞更新须避免人物观察到半更新状态。过期异步回调不能往新场景注册碰撞体。销毁时释放角色控制器、刚体、碰撞体和物理世界；共享渲染资源仍按原所有权释放。

WASM 初始化失败应明确提示并阻止人物在无碰撞状态移动，不能静默启用第二套移动实现。
八、存档与范围限制
本轮新增高度、竖直速度、接地状态及物理句柄均作为运行时状态，不写入 GameState 或存档，不新增迁移占位。

保留室内存档为进入前室外快照、读档回楼外的现行规则。

空中保存采用地面恢复语义：在当前所在场景已有碰撞数据中，为存档快照派生可靠的支撑落点，不在保存时移动正在游玩的角色，也不保存 Rapier 对象。读档仍等最终碰撞就绪后校验并仅修正非法位置。

若现有存档字段无法无歧义表达所需落点，或高处恢复会破坏既有契约，停止报告具体问题；不得自行升级格式或静默丢弃必要的位置语义。

不实现车辆、动态物品玩法、车辆业务、行业框架或未来物理对象注册系统。

实际新增美术资源才更新 public/assets/SOURCES.md，列明来源、作者、许可证和署名要求；不得引入许可不清的资源。
九、最小验证与交付
遵守“非必要不测试、必要时最小范围测试”。

先审查：
- 人物位置是否只有一套权威。
- Space 是否与暂停彻底解绑且不会重复起跳。
- 地面、碰头、墙面、门洞和落地判定。
- 固定步长是否独立于经济倍率。
- 面板、暂停、编辑态和场景切换的空中状态。
- 家具提交、异步过期、读档就绪与销毁。
- 存档、经济推进和既有暂停契约是否保持。
存在具体疑点时才做一次性局部验证，限制在受影响路径；用完删除临时验证脚本，不扩建 scripts/smoke.ts。不做全流程自动游玩、长时间模拟、性能压测或多浏览器矩阵。

由于涉及 WASM 接入，应做一次最小初始化验证；只有明确需要时才启动页面检查资源加载和角色控制基本路径，并记录实际范围，不扩展为全面体验测试。

交付前执行一次：
npm run typecheck
npm run build
先核对项目实际包管理器；如不是 npm，使用对应命令。构建脚本内部重复类型检查属于既有流程，无需为此改脚本。仅在失败并修复后重跑相关检查。

同步更新实际受影响的架构、契约和决策文档，清楚区分已实现规则与用户待验收的手感。

最终报告包括：
1. 实际分支、基线与修改文件。
2. Skill 来源、提交标识、保存路径、加载方式和实际阅读内容。
3. Rapier 包、版本、官方资料与初始化方式。
4. 最终文件职责、人物位移与碰撞数据流。
5. 场景碰撞清单、已知近似及未覆盖对象。
6. 暂停、面板、家具编辑、存档和场景切换规则。
7. 已完成的代码审查。
8. 类型检查和生产构建的真实结果。
9. 实际执行的局部验证、未验证项及留给用户的运行验收。
10. 已知风险和需要 GPT Work 决策的问题。
完成后停止，交由 GPT Work 统一审查和 Git 集成。不得自行提交、合并、推送或发布。

遇到核心职责变化、波及两个以上业务模块的公共接口签名变化、额外框架或引擎、存档版本变化，或无法保证兼容的问题，说明问题、影响范围和最小修改建议后停止。普通实现细节、已授权 Rapier 接入及范围内修复不需要中间确认。

## 🤖 AI

## 停止报告：当前仍在 `main`，不满足实施前提

已按要求先核对 Git 基线，但在开始 Skill 下载、依赖接入或代码修改之前触发了停止条件：

### 实际状态

| 项目 | 实际值 |
| --- | --- |
| 工程路径 | `C:\Users\Administrator\Documents\ChatGPT\game2`（可访问） |
| 当前分支 | **`main`** |
| HEAD | `5d19c369c8839425a0368769c58e643bfb955ac7` |
| 工作区 | 干净：无暂存差异、无工作区差异、无未跟踪文件（247 个索引条目） |
| 本地分支 | `main`、`feature/player-jump-spacebar`、`feature/furniture-editor` |
| 是否已安排独立开发分支 | **没有**；未发现 `feature/rapier-*` 或其他本次实施分支 |
| `docs/player-jump-plan.md` | 已跟踪，未修改 |
| `docs/rapier-physics-gptwork-task.md` | 已跟踪，未修改 |

本机仍没有可用的 `git` 命令，因此通过只读解析 `.git/HEAD`、`.git/refs/heads`、`.git/logs/HEAD` 和 `.git/index` 得到上述结论；未执行任何 Git 写操作。

### 为什么停止

本次提示词明确要求：

> 必须在 GPT Work 已安排的独立开发分支上实现。如果仍在 `main`、分支基线无法确认，或存在无法辨认的已有改动，停止并报告，由 GPT Work 处理，不得自行切换或创建分支。

当前 HEAD 指向 `refs/heads/main`，且没有 GPT Work 新建的实施分支。我不能自行 `checkout`、`switch`、创建分支或创建工作树，因此不能继续实施。

### 需要 GPT Work 处理

请由 GPT Work 完成以下任一操作，然后重新下发实施指令：

1. 从当前 `main`（`5d19c36`）创建并切换到独立实施分支；或
2. 指定一个已存在的实施分支并完成切换；或
3. 提供一个已检出的独立工作树路径，并确认其基线。

分支确定后，我会从“Skill 与官方资料核验”开始连续执行，不再要求中间审查。

### 本阶段实际执行情况

- 已核对仓库路径、分支、HEAD、工作区与本地分支。
- 未下载或加载 Skill。
- 未访问 Rapier 官方资料。
- 未安装任何依赖，未修改 `package.json` / 锁文件。
- 未修改任何源码、文档、配置或 Git 元数据。
- 未运行 `npm run typecheck` 或 `npm run build`。
- 未启动游戏或浏览器。

## 🙋 我

GPT Work 已在 C:\Users\Administrator\Documents\ChatGPT\game2 创建并切换到实施分支 codex/rapier-physics，基线为 5d19c369c8839425a0368769c58e643bfb955ac7，工作区干净。

请只读复核分支和基线；一致后，沿用上一份完整实施提示词，从“Skill 与官方资料准备”继续，连续完成实现及必要的最小验证，最后交回结果供 GPT Work 审查。

不要求分支名必须为 feature/rapier-*；本次正式指定分支是 codex/rapier-physics。你仍不得执行 Git 写操作。若执行环境仍无 Git 命令，可只读核对元数据，不自行修复 Git 环境。

## 🤖 AI

# 《塔科夫之狼》Rapier 接入与三维人物碰撞交付报告

## 1. 实际分支、基线与修改文件

### 分支

- 实施分支：`codex/rapier-physics`
- 基线：`5d19c369c8839425a0368769c58e643bfb955ac7`
- HEAD 指向 `refs/heads/codex/rapier-physics`，与指定基线一致。
- 未执行任何 Git 写操作：无 commit、merge、push、checkout、stash、reset、clean。
- 当前修改全部为工作区未提交/未跟踪状态，交 GPT Work 审查与集成。

### 修改文件

| 文件 | 内容 |
| --- | --- |
| `package.json` / `package-lock.json` | 新增直接依赖 `@dimforge/rapier3d-compat ^0.21.0` |
| `src/world/physics/runtime.ts` | 新增 Rapier 世界、角色控制器、固定步长、跳跃、静态体生命周期 |
| `src/world/physics/collision.ts` | 新增地面/地板盒与场景 AABB 适配 |
| `src/world/physics/types.ts` | 新增物理纯类型 |
| `src/world/physics/index.ts` | 物理层出口 |
| `src/world/player.ts` | 移除二维移动碰撞，改为消费唯一物理位移；增加脚底 y 与贴地影 |
| `src/world/world.ts` | 物理初始化、场景静态体重建、跳跃输入、暂停/门控、镜头 y、室内/读档协调 |
| `src/app/game.ts` | Space 不再暂停；物理暂停标志；家具编辑落地门控；WASM 失败提示 |
| `src/world/interiors/qingchuan.ts` | 室内物理专用结构盒：门头、天花板、地板衔接 |
| `src/content/config.ts` | 新增 `PHYSICS` 参数 |
| `src/content/interior.ts` | 出生点增加 `y: 0` |
| `src/ui/hud.ts`、`src/ui/panels.ts`、`README.md` | 快捷键说明改为 Space 跳跃 |
| `docs/architecture.md` | 新增第 19 节，更新室内/碰撞口径 |
| `docs/contracts.md` | 更新暂停与室内碰撞；新增第三十一节 |
| `docs/decisions.md` | 新增 D97，更新 Space/室内就绪说明 |

`docs/player-jump-plan.md` 与 `docs/rapier-physics-gptwork-task.md` 未修改、未清理。

---

## 2. Skill 来源、提交标识、保存路径与加载方式

### 来源

- 仓库：`majidmanzarpour/threejs-game-skills`
- 固定提交：`8286774b22a2566bf894dbc825825c16921866af`
- 下载方式：GitHub codeload 固定提交 ZIP 归档
- 保存路径：

```text
C:\Users\Administrator\Documents\ChatGPT\skill-refs\threejs-game-skills-8286774
```

Skill 目录：

```text
...\skills\threejs-gameplay-systems
```

### 加载方式

运行环境没有把该 Skill 注册为“已加载 Skill”。我是从文件系统手动读取并应用其指导，**不是环境自动加载**。

### 实际阅读内容

- `SKILL.md`
- `references/physics-engine-selection.md`
- `references/game-feel.md`
- 审阅 `scripts/create_threejs_game.py`（只读，未执行）
- 查看了同目录的 scaffold、测试模板和资源结构，但未复制、未运行。

### 应用与取舍

采用：

- 物理归属独立系统，不放进渲染/业务代码；
- 固定步长 + 有上限的累积器；
- 角色控制器使用胶囊、运动学移动、单一系统同步结果；
- 不从详细视觉网格生成碰撞。

未采用：

- Skill 的 Vite 脚手架、`--force` 覆盖、目录模板；
- `lil-gui`、Playwright/bot/视觉回归测试体系；
- Skill 面向新游戏的 agent 工作流和设计 brief 模板。

原因：项目已有完整架构、测试纪律与现行契约，AGENTS 明确优先于 Skill 默认流程。

---

## 3. Rapier 包、版本、官方资料与初始化方式

### 包

| 项目 | 值 |
| --- | --- |
| 包 | `@dimforge/rapier3d-compat` |
| 版本 | `0.21.0` |
| 许可证 | Apache-2.0 |
| 引入方式 | 直接 dependency（`^0.21.0`） |
| 初始化 | `await RAPIER.init()` |
| WASM | compat 包内嵌 base64 WASM，不需要单独 `.wasm` 资源 |

`@types/three@0.186.0` 仍带一个 dev-only 的 `@dimforge/rapier3d-compat@0.12.0` 传递依赖；项目直接 import 解析到顶层 `0.21.0`，构建也使用 0.21.0。

### 官方资料

已阅读 Rapier JavaScript 0.21 文档：

- Getting started
- Colliders
- Controllers（角色控制器、车辆控制器、PID）
- 其中车辆部分只用于理解能力边界，本轮未实现车辆。

采用的 API 行为：

- `World.createCharacterController(offset)`
- `computeColliderMovement(collider, desiredTranslation)`
- `computedMovement()` / `computedGrounded()`
- `enableAutostep` 未启用；`enableSnapToGround` 未启用；
- 运动学刚体使用 `setNextKinematicTranslation`；
- 静态体使用 fixed rigid body + cuboid collider。

---

## 4. 最终文件职责、人物位移与碰撞数据流

### 职责

| 层 | 职责 |
| --- | --- |
| `world/physics/runtime.ts` | 唯一 Rapier 世界、唯一人物刚体/胶囊/控制器、固定步长、重力/跳跃、静态体创建与释放 |
| `world/physics/collision.ts` | 地面/地板盒；场景 AABB 到物理盒的纯适配 |
| `world/player.ts` | 脚底原点、朝向、动画；只消费物理实际位移 |
| `world/world.ts` | 活动场景、物理/视觉就绪、室内会话、读档、镜头、输入门控 |
| `world/interiors/qingchuan.ts` | 室内固定壳体、门头、天花板、家具布局与物理结构数据 |
| `app/game.ts` | 有效暂停、面板/编辑门控、Space 输入移除、WASM 失败提示 |
| `content/config.ts` | 固定步长、重力、跳跃、胶囊尺寸、子步上限 |

### 数据流

```text
Game.tick
  → World.update(dt, canMove, survival倍率, physicsPaused)
  → 读取摄像机朝向与 WASD
  → 期望水平速度
  → PhysicsRuntime.advance()
      → 固定 1/60s 子步
      → 重力/跳跃/角色控制器修正
      → 唯一实际位移
  → Player.updateFromPhysics(实际位移)
  → 朝向/动画/贴地影
  → 镜头跟随人物 y
  → 渲染
```

旧二维 `Collider` 仍用于：

- 家具编辑的安全落点与固定壳体连通域；
- 读档后的旧位置最小推出；
- 相机遮挡（室外共用碰撞集合，室内独立 occluders）。

它们不再参与逐帧人物移动。

---

## 5. 场景碰撞清单、已知近似与未覆盖对象

### 室外

| 对象 | 实际物理实现 | 近似/说明 |
| --- | --- | --- |
| 地面 | 固定地面盒，顶面 y=0；城区 bounds 夹取 | 连续支撑，不按道路/铺装分块 |
| 道路、人行道、路缘、标线 | 不单独建碰撞 | 视觉薄层；避免 1–4cm 高差干扰 |
| 基础业务建筑 6 栋 | 规划尺寸 AABB → 固定 cuboid | 整栋实心，门洞不可进入；不从视觉模型反推 |
| 扩张城区/招商建筑 | 同上，来自当前逻辑布局 | 增量布局同步后整体替换静态体 |
| 装饰街区楼体 | `BlockPlan.colliders` → cuboid | 使用现成 footprint/height，不按 mesh 生成 |
| 庭院围墙/绿篱 | 现成墙 rect + height | 0.45/1.2m 实体，可站立/可跳上 |
| 行道树 | 树干 AABB | 树冠不碰撞，保留庭院/巷口通行 |
| 长椅/路灯 | 现成 prop collider | 长椅可站；路灯细杆盒 |
| 建筑台阶、雨棚、阳台、屋顶设备 | 未单独建碰撞 | 仍由建筑声明包络整体覆盖或被忽略；未从视觉反推 |
| 城市边界 | 物理移动后按动态 bounds 夹取 | 没有实体边界墙，不会走出地面 |
| 标签、天空、太阳、雨、雾 | 无物理 | 纯表现 |

### 室内

| 对象 | 实际物理实现 | 近似/说明 |
| --- | --- | --- |
| 地板 | 固定地面盒 | 顶面 y=0 |
| 外墙、入口门洞、窗 | 墙体分段 cuboid；南窗整面阻挡 | 入户门洞保持通行 |
| 卫浴墙、门洞 | 墙体分段 + 门头盒 | 门头 2.05–2.55m 进物理；门洞留空 |
| 服务区隔断、门柱、短墙、滑门停靠位 | 现成 shell colliders | 门洞 1.12m 保持通行 |
| 隔断门头 | 物理专用门头盒 | 与相机遮挡分开 |
| 天花板 | 物理专用薄盒（约 2.55m） | 跳跃会碰头 |
| 挡人家具（床、沙发、桌、椅、柜、马桶、洗手台、冰箱、床头几、盆栽花盆、淋浴玻璃） | `playerCollision` 显式局部盒 → cuboid | 不用可见 AABB；旋转后为世界 AABB |
| 不挡人家具（地垫、地毯、镜子、吊柜、烟机、台灯、吸顶灯） | 无物理 | 继续遵守现行“不挡人”契约 |
| 相机遮挡盒 | 仍为独立 `interiorOccluders` | 不当作人物碰撞 |

### 已知近似

- 所有静态体都是轴对齐 cuboid；没有 trimesh、凸包或自动网格碰撞。
- 业务建筑整体实心，不能进入门厅/雨棚下方；这是沿用“入口只做交互”的现行行为。
- 树冠不碰撞；树干盒高度使用整树参数，顶部不可达。
- 长椅、矮墙等低矮实体允许自然落脚，但没有自动攀爬/自动台阶。
- 室内家具碰撞沿用精确局部盒，但仍是 AABB 近似，不是家具视觉网格。
- 室内相机遮挡列表仍是既有范围：北墙整片、天花板、隔断门头/门扇与家具；东西/南墙、卫浴门头未进入该列表。这是既有行为，本轮未改。

---

## 6. 暂停、面板、家具编辑、存档和场景切换规则

### 输入

- Space 已从暂停解绑，改为跳跃。
- 跳跃只在鼠标锁定、人物可操作、接地且 `movementAllowed` 时触发。
- `event.repeat` 被忽略；空中按键会被消费但不缓存，落地后重新按下才可再跳。
- `clearInput()` 同时清除移动、疾跑和跳跃请求；失焦、鼠标解锁、面板开关、页面隐藏、场景切换都会清理。
- 业务面板打开时禁止水平输入和跳跃；已有竖直运动继续受重力影响。

### 暂停

| 状态 | 行为 |
| --- | --- |
| 手动暂停 | 物理冻结，恢复不补算 |
| Esc 暂停菜单 | 物理冻结，恢复不补算 |
| 页面隐藏 | 物理冻结，清输入与累计器 |
| 业务面板 | 经济继续；禁止新移动/跳跃；重力继续 |
| 家具编辑 | 人物物理与输入冻结；编辑相机继续按既有规则工作 |
| 碰撞/物理未就绪 | 人物移动与 F 交互锁定，经济不暂停 |
| WASM 初始化失败 | 人物保持锁定并弹出错误提示，不回退旧移动 |

### 场景切换与存档

- 进入室内：先检查物理与视觉就绪，再加载室内、建立室内静态体、传送到安全出生点。
- 退出室内：恢复进入前室外快照，清空竖直速度、累计步长和输入，重建室外静态体。
- 读档/新游戏：取消室内会话，恢复室外布局，人物落 y=0，等最终碰撞就绪后只修正非法位置。
- 空中保存：仍只保存 x/z/facing；读档按地面恢复，`WorldSaveData` 不变，`SAVE.formatVersion` 仍为 20。
- 家具编辑：临时预览不生成物理体；正式提交后整体替换室内静态体；退出时仍使用固定壳体连通域和安全落点，找不到则保持编辑态。
- 家具编辑入口新增“必须落地”检查，避免空中进入编辑后落点语义不一致。

---

## 7. 已完成的代码审查

已审查：

- 人物位置只有一套权威：`Player` 不再做碰撞，旧 `Player.update` 已移除；物理运行时输出唯一位移。
- Space 与暂停彻底解绑；`Game` 中无 Space 处理；UI 文案已改。
- 跳跃重复键、空中按键、落地重置、暂停清请求均已处理。
- 胶囊脚底原点、1.78m 总高、室外 0.42 / 室内 0.3 半径与现有比例一致。
- 固定步长、最大帧长、最大子步数与经济倍率完全分离。
- 地面、墙体、碰头、门洞、天花板和家具盒均用简单形状。
- 室内门头/天花板使用独立物理结构盒，没有直接把相机遮挡清单复制成人物碰撞。
- 布局同步、家具提交、室内进入/退出、读档、销毁都调用静态体整体替换；过期视觉回调不会注册物理体。
- 物理初始化失败时 `isCollisionReady()` 为 false，人物移动和 F 交互保持锁定。
- 保存格式、经济时间、业务状态边界未改。
- 文档已同步实际实现。

未发现类型层面的 `any`、双重断言或绕过只读边界的新增用法。

---

## 8. 类型检查和生产构建的真实结果

执行：

```text
npm run typecheck
npm run build
```

结果：

- `tsc --noEmit`：**通过**
- `vite build`：**通过**
- 构建输出：
  - `dist/bundle/index-*.js`：约 **5,791.88 kB**（gzip **2,084.04 kB**）
  - `dist/bundle/qingchuan-*.js`：约 13.88 kB
  - `dist/bundle/index-*.css`：约 42.96 kB
- Vite 给出 chunk 超过 500kB 的警告，主要来自内嵌 WASM 的 Rapier compat 包。

依赖安装命令：

```text
npm install @dimforge/rapier3d-compat@^0.21.0 --save
```

---

## 9. 实际执行的局部验证、未验证项与运行验收

### 已执行的局部验证

使用 `rolldown` 临时将 `PhysicsRuntime` 与 Rapier 打成 Node ESM，执行真实 WASM 初始化与步进；临时脚本已删除。

实际结果：

```text
rest 0.0001            # 600 帧静止后脚底 y
jump max 0.850         # 室外跳跃脚底最高点
land 0.000             # 落地后脚底
120hz jump max 0.880   # 120Hz 下跳跃请求未丢失
freeze midair 0.724 -> 0.724  # 空中暂停冻结
wall stop x 0.560      # 1m 墙前、半径 0.42 的停止位置
indoor jump feet 0.750 head 2.530  # 室内天花板下碰头
```

说明：

- 角色控制器、WASM 初始化、跳跃、重力、碰头、墙面阻挡、暂停冻结均实际跑通。
- 室内测试使用近似壳体盒，未加载真实室内 glTF 场景。
- 未启动浏览器，未做画面、相机、家具编辑、真实室内/街区布局的运行时验收。

### 未验证项

- 实际游戏画面中的脚底贴地、阴影、镜头跟随与遮挡。
- 真实住宅门洞、门头、天花板和家具编辑落点。
- 真实城市布局下的建筑/装饰街区/庭院碰撞。
- 低端设备 WASM 首次加载时间与内存。
- 长时间运行、性能压测、多浏览器矩阵。
- 用户对跳跃高度、落地时间、镜头跟随和可站立家具的手感验收。

### 留给用户验收

- Space 跳跃与落地手感；
- 室内外门洞、家具、台阶和矮墙；
- 业务面板打开时空中继续落地；
- 暂停/Esc/页面隐藏恢复；
- 读档、新游戏、进出住宅后的位置与碰撞；
- 家具编辑退出落点；
- 实际画面中的镜头高度跟随与遮挡。

---

## 10. 已知风险与需要 GPT Work 决策的问题

### 风险

1. **主包体积**：Rapier compat 使主 JS 约 5.79MB、gzip 约 2.08MB。构建通过但首屏成本明显；是否需要动态 import/code split 需 GPT Work 决定。
2. **全 AABB 近似**：业务建筑整栋实心，雨棚/台阶/阳台/屋顶设备没有独立物理；树冠、路灯等只按规划盒处理。若需要更精细碰撞，需要新增形状拆分。
3. **室内相机遮挡仍不完整**：东西/南墙、卫浴门头未进入 `interiorOccluders`，这是既有问题；物理门头已补，但相机表现需运行验收。
4. **初始落点抬升**：场景切换/读档时脚底抬高 3cm 后自然落下，约 5 帧稳定；极大可能是短暂视觉下沉/回弹，需要用户观察。
5. **家具编辑新增落地门控**：空中按 E 不再进入编辑，改为提示“落地后再整理家具”；这是为三维落点一致性新增的行为。
6. **室内跳跃高度受天花板限制**：实测脚底最高约 0.75m；0.8m 桌面在室内不可直接跳上。是否符合预期需用户确认。
7. **读档落点仍是地面语义**：空中保存后读档从 y=0 开始，再走既有非法位置修正；如果存档点正好在家具/矮墙上方，可能出现推出而非保留原支撑面。
8. **物理失败无重试**：WASM 初始化失败后人物保持锁定，需要刷新页面；没有自动重试或降级。
9. **旧二维安全落点**：家具编辑仍使用二维搜索；物理最终落点由 y=0 + 相同家具盒保证，但未做三维落点复验。
10. **未做浏览器运行验证**：构建通过不等于实际体验通过。

### 需要 GPT Work 决策

- 是否接受当前 5.8MB 主包，或改为动态加载 Rapier 做代码分割。
- 业务建筑是否保持整栋 AABB，还是为门厅/雨棚/台阶拆分物理形状。
- 长椅、矮墙、桌面等可站立范围是否符合设计；是否调整跳跃初速/重力。
- 室内是否允许跳跃；当前天花板会限制跳跃高度，桌面在室内不可直接跳上。
- 空中打开业务面板时“继续落地”的规则是否最终确认。
- 空中进入住宅是否也应被禁止；当前允许进入，退出按地面恢复。
- 是否保存竖直状态；当前按地面恢复，不改存档格式。
- 室内相机遮挡清单是否补齐东西/南墙与卫浴门头。
- 是否需要为楼体附属装饰生成独立碰撞，还是维持声明包络。
- 初始落点 3cm 抬升是否需要改为无抬升的其他落点策略。

---

**交付状态：** 实现、文档、类型检查、生产构建和一次性 WASM/角色控制局部验证均已完成；未提交、未合并、未推送。等待 GPT Work 审查与 Git 集成。

## 🙋 我

把这份交付报告打包成一个md文件放在桌面上

## 🤖 AI

已生成并放到桌面：

`C:\Users\Administrator\Desktop\塔科夫之狼-Rapier交付报告.md`

文件内容为完整交付报告，UTF-8 编码，约 17 KB。

## 🙋 我

采用以下方案：

1. Rapier 保持唯一权威位置和现有固定步长，维护相邻两个已完成物理步的位置。
2. 以剩余累计时间除以固定步长得到插值比例，生成只供表现使用的位置。
3. 人物显示和镜头跟随目标使用同一插值位置；镜头后续沿用既有跟随和遮挡规则。
4. 插值结果不写回物理；碰撞查询、落点判定、交互及保存均使用明确的权威状态。
5. 不从 `player.group.position` 反推权威位置，不用预测位置绕过碰撞。
6. 不用额外指数平滑替代固定步长插值，以免新增随速度变化的拖尾；不提高物理频率替代插值。
7. 零 delta、无物理步、多子步、超限积压丢弃都须一致处理，插值比例不得越界。
8. 暂停保持显示冻结，不能因累计余量清零而回退一个物理步；恢复不追赶暂停时间、不跳变。
9. 初始化、传送、读档、新游戏、场景切换和合法位置修正后同时重置前后插值状态，禁止从旧场景飞向新位置。
10. 保留室内隐藏人物、家具编辑相机、镜头高度限制与遮挡行为。

残影边界：以上已确认问题能够解释顿挫与重影感。若修复后仍存在真正的跨帧画面残留，定点核查重复人物实例、重复渲染或帧缓冲累积并提供证据；不要猜测性更改阴影、抗锯齿或材质，不新增运动模糊、后处理或补帧系统。

## 四、文件职责与修改边界

| 文件/目录 | 允许修改的职责 |
| --- | --- |
| `src/world/physics/types.ts` | 物理步运动样本、权威/表现输出等必要纯类型 |
| `src/world/physics/runtime.ts` | 初始化同步、步进样本、插值历史、三维空间/支撑查询、静态体同步及重置 |
| `src/world/player.ts` | 区分权威与表现位置，动画与转身消费正确运动样本 |
| `src/world/world.ts` | 场景、读档、保存快照、家具编辑安全落点、物理与镜头协调 |
| `src/app/game.ts` | 必需的暂停、会话和输入门控衔接，不扩大业务改动 |
| `src/world/character.ts` | 仅必要接口衔接，优先保持既有动画算法和参数 |
| `src/content/config.ts` | 确有必要的新物理/表现可调参数 |
| 相关现行文档 | 同步实际实现的架构、契约及决策 |

必要的场景碰撞适配可在现有职责内最小调整；不要大改楼体、重建室内模型或重新设计家具模块。

禁止新增依赖、框架、状态管理、事件总线或未来车辆占位。禁止更改 `src/core/` 职责、经济时间入口、业务规则、资源兼容标识或 `SAVE.formatVersion`。不得用 `any`、双重断言或只读转可写绕过约束。

物理与表现分离必须落实到所有相关调用点，不能为修动画破坏 R1—R4 的位置和快照语义。保留业务面板经济继续、暂停冻结、场景未就绪锁人物及交互的契约；定点复核未就绪时竖直物理不会提前改变待恢复位置。

## 五、本轮不扩大处理的已知事项

这些应在报告中如实保留，不得混称为已修复，也不要求为本轮补丁擅自扩大范围：

- Rapier compat 带来的约 5.79 MB 主包：本轮不强制代码分割，不新增打包插件。
- 业务建筑整栋 AABB、附属雨棚/台阶等近似：不借机重做全部碰撞资产。
- 室内相机既有遮挡范围不完整：只处理本轮引入的同步回归，不顺带全面重设计。
- 跳跃高度、室内天花板限制、初始抬升、动画美感和设备性能：继续留给用户体验验收，不宣称数值验证等于手感通过。
- 不新增跳跃动画、车辆、动态物品玩法或持久化竖直状态。

## 六、必要的最小验证

遵守 `AGENTS.md`：先代码审查，再针对具体风险做最小局部验证，不构建长期测试套件，不扩建 `scripts/smoke.ts`，临时脚本用完删除。

### 1. 生命周期与安全位置

- 延迟物理初始化期间恢复一个合法、非出生点位置，初始化完成后位置保持；同时检查新游戏/后续恢复不会被旧请求覆盖。
- 抑制一个冲突街区后，正式碰撞集合与物理集合都不再保留它，不必遍历全城。
- 地面、实体顶部/上方保存快照的派生结果合法，保存本身不移动正在游玩的角色。
- 在可站立家具上编辑且不改布局，退出不搬走人物；移除支撑或覆盖身体空间时，保持合法落点或明确阻止退出。
- 二维搜索候选最终经过三维检查，不能跨固定墙。

### 2. 动画与表现

用真实实现，在简单地面上短时验证 60Hz、120Hz、144Hz、240Hz，以及一组交替帧时间，覆盖无物理步和单帧多个子步。

这是有限取样，不建立刷新率矩阵；统一算法应自然支持 75/90/165Hz 等其他刷新率及正常帧时间变化。

记录持续移动、松键、撞墙、暂停/恢复和传送时：

- 无物理步是否错误转待机。
- 动画速度是否出现零速/倍速交替，而不仅是平均速度正确。
- 实际撞墙停止后动画是否正确停止。
- 显示位置是否连续、是否仅影响表现。
- 镜头是否使用同一表现位置。
- 暂停、读档和传送是否回退、拖尾或留下旧状态。

如有必要，只做一次短时页面观察核查人物、镜头与残影，不扩展为全流程游玩、性能压测、长时间模拟或多浏览器测试。

### 3. 类型与构建

全部修复完成后执行一次：

```text
npm run typecheck
npm run build
```

仅失败修复后重跑相关检查，不在每个小改动后反复全量构建。

## 七、最终交付格式

请一次性交回：

1. 实际分支、基线和修改文件。
2. R1—R6 逐项状态：根因、修改、对应证据；未解决项必须明确写出。
3. 权威物理位置、插值显示位置、动画速度、镜头、交互和存档快照各自的数据来源。
4. 无物理步、多子步、暂停、初始化及传送的具体语义。
5. 三维支撑/空间校验与二维安全候选搜索之间的职责划分。
6. 实际执行的局部验证、采样结果和未验证部分。
7. 类型检查与生产构建的真实结果。
8. 是否实际观察过画面，残影已验证到什么程度。
9. 已知近似、剩余风险和留给用户的运行验收。

完成后停止，等待 GPT Work 审查与集成。不得自行提交、合并、推送或发布。构建通过不等于运行体验通过，局部验证不等于所有刷新率和设备都已验收。

## 🤖 AI

# 《塔科夫之狼》固定步长插值与表现位置修复交付

## 1. 实际分支、基线与修改文件

### 分支

- 实施分支：`codex/rapier-physics`
- 基线：`5d19c369c8839425a0368769c58e643bfb955ac7`
- 未执行任何 Git 写操作：无 commit、merge、push、checkout、stash、reset、clean。
- 所有修改仍为工作区未提交/未跟踪状态，交 GPT Work 审查与集成。

### 本轮修改文件

| 文件 | 内容 |
| --- | --- |
| `src/world/physics/types.ts` | 物理步结果拆分为 `authoritative` / `display` / `displayDeltaX/Z` |
| `src/world/physics/runtime.ts` | 相邻两物理步历史、表现插值、暂停冻结、支撑高度查询、三维空间校验、传送重置 |
| `src/world/player.ts` | 权威位置与表现位置分离；动画/转身消费表现帧间位移 |
| `src/world/world.ts` | 镜头使用表现位置；读档支撑落点；三维落点校验；延迟初始化取最新位置；街区抑制同步物理 |
| `src/world/physics/collision.ts` | 地面/地板顶面与角色控制器间隙 |
| `src/content/config.ts` | `PHYSICS` 参数：固定步长、跳跃、恢复支撑高度等 |
| `docs/architecture.md` | 第 19 节补充插值、权威/表现分离、支撑查询 |
| `docs/contracts.md` | 第三十一节补充插值、暂停、支撑恢复、三维校验 |
| `docs/decisions.md` | D97 补充插值与支撑恢复决策 |
| `package.json` / `package-lock.json` | Rapier 依赖仍为 `@dimforge/rapier3d-compat ^0.21.0` |

`src/app/game.ts`、`src/world/interiors/qingchuan.ts`、UI 文件在本轮未新增职责，但保留上一轮修改。

---

## 2. R1—R6 逐项状态

> 说明：本轮提示词引用 R1—R6 但未重复列出原文；以下按本轮 1—10 条方案归并为六项，并给出根因、修改和证据。若 GPT Work 的 R1—R6 定义不同，请以编号对应关系复核。

### R1 · 物理权威位置与相邻两个物理步

**状态：完成。**

- **根因**：此前每帧只返回最后一个物理步的位置，表现层和动画直接消费该步进结果；无物理步的帧没有位移，多子步帧又把多步位移压在一帧。
- **修改**：
  - `PhysicsRuntime` 维护 `previousPose`、`currentPose`，每个已完成物理步更新；
  - `authoritative` 始终来自刚体当前步位置；
  - 不把上一帧表现位置当权威，也不从 `player.group.position` 反推。
- **证据**：
  - `runtime.ts` 的 `advance()` 在每次 `stepOnce` 前后读取刚体位置；
  - 局部验证中 `display` 与 `auth` 保持固定差值（120Hz 下约 0.09m，即一个物理步）。

### R2 · 表现位置插值

**状态：完成。**

- **根因**：固定步长和渲染帧率不同步时，缺少 `alpha` 插值，画面在步进点上跳变。
- **修改**：
  - 每帧使用 `剩余累计时间 / 固定步长`，夹在 `0–1`；
  - `display = lerp(previousPose, currentPose, alpha)`；
  - 插值结果只保存在 `displayPoseValue`，不写回刚体。
- **证据**：
  - 60Hz / 120Hz / 144Hz / 240Hz 采样下，持续移动的每帧表现位移分别为
    `0.0900 / 0.0450 / 0.0375 / 0.0225`，与 `5.4m/s × dt` 一致；
  - 交替帧时间采样 `5.4m/s` 速度保持 5.400，无零速/倍速交替。

### R3 · 人物显示与镜头使用同一表现位置

**状态：完成（代码审查；未做浏览器画面观察）。**

- `World.placeCamera()` 与 `placeInteriorCamera()` 都读取 `player.displayPose()`。
- `updateEnvironment()` 也使用表现位置做环境/阴影跟随。
- 镜头原有的跟随速率、遮挡射线、距离/高度限制保持不变。
- 交互缓存仍使用 `player.pose()` 的权威位置，不因镜头表现位置提前触发。

### R4 · 动画速度与转身消费正确运动样本

**状态：完成。**

- **根因**：此前动画看物理步增量，0 步帧 `moved=false` 会转待机，多步帧速度突增。
- **修改**：
  - `Player.updateFromPhysics` 接收 `displayDeltaX/Z`；
  - 动画、朝向、脚步速度都按表现帧间位移计算；
  - 权威位置只写入玩家 `pose()`，不参与动画速度。
- **证据**：
  - 60/120/144/240Hz 持续移动：动画速度全程 **5.400**；
  - 240Hz 下 132 个“无物理步”帧仍保持移动状态，未错误转待机；
  - 撞墙测试：角色在 `x≈0.560` 停止，停止后动画不再前进；
  - 交替帧时间：动画速度仍为 5.400。

### R5 · 暂停冻结、不回退、不追赶

**状态：完成。**

- `advance()` 在 `frozen` 时直接返回当前 `displayPoseValue`，**不重算 alpha、不清累计余量**。
- 因此暂停不会因为累计器归零而回退一个物理步。
- 恢复后沿用原累计余量继续插值，不补算暂停时间。
- **证据**：
  - 空中暂停：显示 `0.724 → 0.724`，完全冻结；
  - 恢复后位移 `0.045`，无回退；
  - 60—240Hz 采样中 `backward = 0`。

### R6 · 初始化、传送、读档、场景切换与合法修正重置插值

**状态：完成。**

- `teleport()` 同时重置：
  - 刚体位置；
  - 竖直速度；
  - 累计余量；
  - `previousPose/currentPose/displayPoseValue/lastDisplayPose`；
- `clearMotion()` 也重置前后插值历史；
- 进入/退出室内、读档、新游戏、家具安全落点、非法位置修正均走 `teleport` 或 `clearMotion`。
- 延迟物理初始化期间发生读档/新游戏时，初始化完成后用**最新** `player.pose()` 再次 `teleport`，不会被初始化开始时的旧请求拉回。
- **证据**：
  - 传送测试：`teleport(10,-3)` 后零 delta 仍为 `(10,-3)`；
  - 超限积压测试：单帧最多 6 子步，显示位移 `0.540`，不回放历史。

### 未解决/未完全验证项

- **没有在浏览器中实际观察人物、镜头与残影**。
- 初始落点仍有约 2–2.4cm 的控制器间隙表现（脚底略高于可见地面），需要用户运行验收；本轮未用视觉偏移掩盖。
- 三维支撑查询是 AABB 顶面查询，不是射线精确取面；低矮实体顶面支持，超过 `recoveryMaxSupportHeight = 2m` 的屋顶回落地面。
- 旧二维安全搜索仍只提供候选，最终由三维胶囊相交校验决定是否接受。

---

## 3. 各类数据来源

| 数据 | 权威来源 | 使用方 |
| --- | --- | --- |
| 权威物理位置 | `PhysicsRuntime.currentPose` / Rapier 刚体 `translation()` | 碰撞、落点、交互、存档快照 |
| 表现位置 | `PhysicsRuntime.displayPoseValue`，由 `previous/current + alpha` 生成 | 人物 Group、镜头目标、环境跟随 |
| 动画速度/转身 | `displayDeltaX/Z ÷ 真实帧 dt` | `Player.updateFromPhysics` |
| 镜头目标 | `Player.displayPose()` | `placeCamera` / `placeInteriorCamera` |
| 交互目标 | `Player.pose()` 权威位置 | `refreshNearbyBuilding` |
| 存档快照 | `Player.pose()` 的 x/z/facing | `World.getSaveData` |
| 支撑高度 | `PhysicsRuntime.supportHeightAt()` 读取当前静态盒快照 | 读档落点派生 |
| 三维空间校验 | `PhysicsRuntime.isPoseFree()` 胶囊/静态体相交 | 住宅出生点、家具编辑退出 |
| 二维安全候选 | `findSafeStandingPose` + 固定壳体连通域 | 仅提供候选，不写人物位置 |

`player.group.position` 只作为表现结果写入，没有任何逻辑反向读取它作为权威位置。

---

## 4. 无物理步、多子步、暂停、初始化及传送的具体语义

### 无物理步

- `accumulator` 继续增加，`previous/current` 不变；
- `alpha` 增大，`display` 在相邻两个已完成步之间平滑移动；
- 动画继续按表现帧间位移播放，不会错误转待机；
- 不产生新的权威物理步。

### 多子步

- 依次执行多个固定步；
- 每个步更新 `previous/current`；
- 只保留最后一对相邻步；
- `alpha` 取剩余累计时间比例，夹在 `0–1`；
- 动画速度按整帧表现位移计算，已验证 3 步/6 步帧仍为 5.400m/s。

### 超限积压

- 真帧最多采信 `0.1s`；
- 每帧最多 `6` 子步；
- 超出部分直接丢弃，不补算、不回放；
- 显示仍在最后一对步之间插值。

### 暂停

- 手动暂停、Esc 菜单、页面隐藏、家具编辑：返回冻结的表现位置；
- 不清累计余量、不重算 alpha、不移动权威刚体；
- 恢复后继续原插值进度，不补暂停时间、不回退一个物理步。

### 初始化与传送

- 初始化：构造运行时后以最新玩家位置建立首对 `previous/current`；异步初始化结束前如发生读档/新游戏，再以最新位置 `teleport`；
- `teleport`：同时重置位置、竖直速度、累计器、前后插值状态和上次表现位置；
- 读档/新游戏/进出住宅/安全落点/非法位置修正：均走 `teleport` 或 `clearMotion`，禁止从旧场景插值飞向新位置。

---

## 5. 三维支撑/空间校验与二维安全候选的职责划分

### 二维搜索

`findSafeStandingPose` 仍负责：

- 固定壳体连通域；
- 忽略可移动家具后的搜索；
- 四方向离散搜索；
- 起点/相邻格线段不穿固定墙。

它只输出 **候选 x/z**，不再直接决定最终落点。

### 三维校验

`PhysicsRuntime.isPoseFree(x, y, z)`：

- 使用当前胶囊形状；
- 查询当前静态体（含地板、墙体、家具）；
- 排除自身 collider；
- 需要静态体创建后先推进查询管线，`setOutdoor/setInterior` 已补 `world.step()`。

住宅出生点、家具编辑退出最终落点都要通过该检查；失败则中止进入或保持编辑态。

### 支撑高度

`supportHeightAt(x, z)`：

- 只读当前静态盒快照；
- 选择覆盖该 x/z、顶面不超过 `recoveryMaxSupportHeight = 2m` 的最高顶面；
- 地面返回 0，低矮实体顶面返回其高度；
- 用于读档地面恢复，**保存时不会移动正在游玩的角色**。

---

## 6. 实际执行的局部验证、采样结果和未验证部分

### 插值/动画采样

使用临时 Node 脚本真实加载 Rapier 与 `Player`，临时脚本已删除。

| 帧率 | 每帧表现位移 | 动画速度 | 无物理步但仍移动 | 零速/回退 |
| --- | --- | --- | --- | --- |
| 60Hz | 0.0900 | 5.400 | 0 | 0 |
| 120Hz | 0.0450 | 5.400 | 89 | 0 |
| 144Hz | 0.0375 | 5.400 | 103 | 0 |
| 240Hz | 0.0225 | 5.400 | 132 | 0 |
| 交替帧时间 | 0.0225–0.0900 | 5.400 | 70 | 0 |

多子步：

- 3 子步：显示位移 0.270，动画速度 5.400；
- 6 子步：显示位移 0.540，动画速度 5.400。

暂停/传送：

- 空中冻结：`0.724 → 0.724`；
- 恢复：单帧 0.045，无回退；
- 传送 `(10,-3)` 后零 delta 仍为 `(10,-3)`；
- 超限积压最多 6 步。

跳跃/墙体（同一实现）：

- 室外跳跃脚底最高约 `0.874m`，落地约 `0.024m`；
- 室内天花板下脚底最高约 `0.750m`，头顶约 `2.530m`；
- 1m 墙前停止 `x≈0.560`，接近墙面时无零位移帧。

支撑/空间校验：

- 地面支撑高度 `0.000`，低矮实体顶面 `0.450`；
- 地面点 `isPoseFree = true`；
- 低矮盒内部点 `isPoseFree = false`；
- 站在顶面 `isPoseFree = true`。

### 未验证

- 未启动浏览器，未做真实画面、镜头、阴影、残影检查。
- 未实际跑完整读档/新游戏/室内家具编辑流程。
- 未做性能压测、低端设备 WASM 加载测试、多浏览器矩阵。
- 60/120/144/240Hz 为合成步进采样，不是实际显示器刷新率验证。
- 未验证初始 2cm 控制器间隙在画面中的观感。

---

## 7. 类型检查与生产构建真实结果

执行：

```text
npm run typecheck
npm run build
```

结果：

- `tsc --noEmit`：**通过**
- `vite build`：**通过**
- 输出：
  - 主 JS：约 **5,794.19 kB**（gzip **2,084.56 kB**）
  - 室内分包：约 13.88 kB
  - CSS：约 42.96 kB
- Vite 仍有 chunk > 500kB 警告，来源是 Rapier compat 内嵌 WASM；本轮未做代码分割，符合“不扩大范围”。

---

## 8. 是否实际观察过画面，残影验证程度

**没有实际观察过浏览器画面。**

已做的代码级残影边界核查：

- 全程只有一个 `Player` 实例；
- 进入/退出室内只是移动同一个 `player.group`，没有创建第二个角色；
- 每帧只有一次 `renderer.render(...)`；
- 没有 motion blur、后处理、补帧或帧缓冲累积代码；
- 没有修改阴影、抗锯齿、材质或色调映射。

因此：

- **本轮的顿挫/动画零速问题**已用固定步长插值解决；
- **真正的跨帧画面残留**尚未通过实际画面验证，不能宣称已修复或已排除；
- 若修复后仍出现残影，下一步应定点检查重复人物实例、重复 render、Canvas 尺寸/像素比、浏览器合成或帧缓冲，而不是猜测性修改阴影/AA/材质。

---

## 9. 已知近似、剩余风险和留给用户的运行验收

### 已知近似

- 人物胶囊 1.78m，室外半径 0.42m、室内 0.30m；静态体仍以 AABB cuboid 为主。
- 地面物理顶面略低于可见地面，角色控制器保留数值间隙；落地脚底约在 y≈0.02m，视觉上可能有轻微悬浮。
- 读档支撑高度上限 2m：长椅、矮墙、桌面等低矮实体可恢复；更高屋顶回落地面。
- 支撑查询是静态盒顶面查询，不是精确三角面射线。
- 室内相机遮挡仍沿用既有范围；未重做东西/南墙、卫浴门头遮挡。
- 家具“不挡人”契约保持：地垫、地毯、镜子、吊柜、烟机、台灯、吸顶灯不生成新物理障碍。

### 剩余风险

1. **初始/落地 2cm 间隙**：控制器接地后停在略高于可见地面的位置，需用户观察是否明显。
2. **插值延迟**：表现位置天然落后一个物理步；60Hz 下有约 16ms 的视觉延迟，属于固定步长插值代价。
3. **室内天花板较低**：实测脚底最高约 0.75m；室内桌面基本不可直接跳上，是否符合设计需确认。
4. **支撑恢复可能选择低矮实体顶面**：读档到长椅/矮墙顶是合法支撑，但可能不是玩家预期的“地面”。
5. **三维校验依赖查询管线已更新**：`setOutdoor/setInterior` 已主动 `world.step()`；后续若新增碰撞写入路径，必须遵守同一顺序。
6. **物理未就绪/失败**：WASM 初始化失败仍锁人物并提示，没有自动重试或旧移动回退。
7. **没有实际浏览器验证**：构建通过和合成采样不等于画面/手感通过。

### 留给用户运行验收

- Space 跳跃、落地、连续按键不重复起跳；
- 业务面板打开时空中继续下落；
- 暂停/页面隐藏/恢复不跳变、不回退；
- 读档/新游戏/进出住宅后的位置与镜头；
- 家具编辑退出：站在低矮可站立家具上不搬走，家具覆盖时正确阻止或找落点；
- 人物脚底是否明显悬浮；
- 镜头跟随高度、遮挡和室内隐藏人物；
- 真实画面是否还有残影；若有，再按残影边界提供证据定点核查。

---

**交付状态：** 插值、表现/权威分离、暂停冻结、重置、支撑恢复、三维校验均已实现；`npm run typecheck` 与 `npm run build` 通过；未提交、未合并、未推送。等待 GPT Work 审查与 Git 集成。

