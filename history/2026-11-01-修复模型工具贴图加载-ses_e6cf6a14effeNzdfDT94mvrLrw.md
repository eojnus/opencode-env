# 修复模型工具贴图加载

- 会话 ID：`ses_e6cf6a14effeNzdfDT94mvrLrw`
- 时间：2026-11-01 01:37
- 目录：`C:\Users\Administrator`
- 模型：`deepseek/deepseek-flash`

---

## 🙋 我

你是《塔科夫之狼》项目的实施工程师。本轮任务是修复无头模型工具的贴图加载及结果可信度问题，并完善供其他 Agent 使用的现行文档。

一、项目位置与先读文件

项目绝对路径：

C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop

用户提供的测试模型：

C:\Users\Administrator\Downloads\apet.glb

请先读取：

1. AGENTS.md
2. tools/model-tool/README.md
3. docs/model-tools.md
4. docs/model-tool-architecture.md
5. tools/model-tool/cli.mjs
6. tools/model-tool/renderer/index.html
7. tools/model-tool/renderer/render.ts
8. tools/model-tool/renderer/inspect.ts
9. tools/model-tool/renderer/main.ts
10. 这些文件引用的模型加载、诊断和结果契约实现

执行一次 git status，了解当前工作树状态。

注意：当前工作树已有其他开发者的未提交改动，它们是项目现状的一部分。不要重置、覆盖、清理或擅自提交。不要创建新的项目内任务书或计划书。

二、背景与已知事实

架构师曾使用 apet.glb 对现有工具做有限试用：

- inspect 识别出模型骨骼和动作，但报告 60 次 blob 贴图加载失败。
- snapshot 生成的截图中角色呈灰色。
- snapshot 虽然记录了贴图加载失败，却返回 status: ok。
- 对 GLB 的静态检查发现其中有 60 张内嵌图片：47 张有 PNG 文件头，13 张有 JPEG 文件头。此检查没有验证图片是否完整可解码。
- 现有 Three.js GLTFLoader 可能为内嵌图片创建 blob URL；ImageBitmapLoader 会通过 fetch 读取。
- tools/model-tool/renderer/index.html 的 CSP 中，img-src 包含 blob:，connect-src 不包含 blob:。
- 上述 CSP 配置是高度可疑的根因，但尚未通过修复后实测确认，不得提前宣称已经证实。

原试用输出位于：

C:\Users\Administrator\Documents\ChatGPT\game2\model-tool-output\apet-review-20261101-inspect\report.json

C:\Users\Administrator\Documents\ChatGPT\game2\model-tool-output\apet-review-20261101-snapshot\report.json

以及同一截图目录中的：

snapshot-Calibration-0deg.png

这些是历史证据，不要覆盖。

三、本轮目标与优先级

P0：让合法 GLB 内嵌贴图能够正确加载，并确认真实原因。

P0：资源加载失败时，任何依赖该结果的检查或截图不得伪报 ok。

P1：让报告明确区分模型声明的资源、成功加载的资源、失败的资源以及无法确定的信息，避免误导 Agent。

P1：修复错误结果声称输出文件存在、但文件实际上没有写出的情况。

P1：整理本轮涉及的现行工具文档，使从未接触项目的 Agent 能理解命令、结果及限制。

本轮不开发跨模型动作、不修改游戏玩法、不重构游戏引擎、不实现新型模型编辑器。

四、具体修改要求

A. 修复贴图加载

主要检查和修改位置：

- tools/model-tool/renderer/index.html
- 模型加载器所在文件，以实际代码为准
- 必要时检查 tools/model-tool 的协议、渲染和诊断实现

步骤：

1. 沿 GLB 内嵌图片的加载路径确认实际失败原因。
2. 核实 CSP 是否阻止了 ImageBitmapLoader 对 blob URL 的读取。
3. 若证实或通过修复后运行验证支持该原因，在现有 connect-src 中最小范围增加 blob:，预期形式为：

   connect-src 'self' modeltool: data: blob:;

4. 不得为了修复而关闭 contextIsolation、启用 nodeIntegration、关闭 sandbox、允许任意远程网络或执行任意系统命令。
5. 不要将 connect-src 改成 *，不要增加不必要的 HTTP/HTTPS 白名单。
6. 如果实际根因不止 CSP，应继续修复必要的加载问题，在交付中说明每一项证据。
7. 保持现有 GLB、glTF、USDZ 支持边界；不要宣称没有实测过的格式已经验证通过。
8. 注意大模型内存占用，不能为了分析一个 100 MB 的 GLB，将整个文件无必要地多次转成 base64 在进程之间复制。

B. 修正加载不完整时的状态

主要检查和修改位置：

- tools/model-tool/renderer/render.ts
- tools/model-tool/renderer/inspect.ts
- tools/model-tool/renderer/main.ts
- tools/model-tool 的诊断和 TaskOutput 契约定义
- 其他直接复用模型加载结果并声称输出完整性的相关任务，按实际代码检查

要求：

1. 明确区分：

   - ok：任务完成，且没有已知会使该任务结果不完整的资源加载失败。
   - partial：主体结果可用，但存在贴图或其他必要资源加载失败等影响结果完整性的情况。
   - error：任务无法完成。

2. snapshot 遇到贴图加载失败时，允许输出用于排查的截图，但必须返回 partial，报告明确说明图片可能无法反映真实材质。
3. inspect 不能将已知资源失败报告成完整成功。
4. 检查其他使用相同加载器的任务。若其结果受缺失资源影响，同样应如实降级或返回明确错误。
5. 对产生派生资产的任务，如缺失资源会造成输出资产损坏或丢失贴图，不能静默导出并返回 ok。根据已有接口，选择拒绝输出或明确 partial，并说明原因；优先采用不会让 Agent 把损坏资产当作完整结果的方案。
6. 不能把所有 warning 一律当成 partial。例如只读格式提示、时间被夹取等提示，应根据是否影响任务结果完整性区分。
7. 保持现有错误码和机器可读输出的兼容性；若必须调整契约，记录变化和调用方影响。
8. stdout 继续保持约定的机器可读格式，不要混入调试日志；日志按项目现有约定输出。

C. 改进资源报告的真实性与可读性

主要检查和修改位置：

- tools/model-tool/renderer/inspect.ts
- 模型加载和依赖诊断相关文件
- 如需新增共享类型，在工具自身现有契约范围内增量实现

要求：

1. 明确区分以下概念，不要把它们混成同一个数字：

   - 文件声明或引用的图片/纹理数量；
   - 运行时实际加载成功的资源；
   - 运行时加载失败的资源；
   - 无法确认的资源状态。

2. 若暂时无法可靠获取某个数据，使用 unknown/null 和说明，不允许猜测或把 unknown 当成功。
3. 当模型有图片资源但加载失败时，不应再给出容易让人理解为“模型原本没有贴图”的 NO_TEXTURES 提示。
4. 不要把一张图片、一个纹理对象和一个材质引用视为必然一一对应；计数口径要在字段或文档中说明。
5. 排查是否能在现有安全边界内读取 GLB JSON chunk，获取声明资源信息。若实现，须校验文件头、chunk 长度、偏移和文件边界，避免对大型二进制文件进行不必要的重复复制。
6. 如果 GLB JSON 安全读取会造成明显的架构扩展，本轮可以维持 unknown，但必须说明原因；不允许为了填一个数字编造结果。
7. 多次同类失败应便于 Agent 阅读。可以汇总重复诊断，但必须保留实际失败数量、错误类别和足够定位问题的样例；不要静默吞掉失败。
8. 临时 blob URL 不能被误认为稳定的原始资源路径。若能关联回模型中的图片索引或名称，可在现有条件下提供；关联不可靠时明确标 unknown。

D. 修复输出路径与实际文件不一致

主要检查和修改位置：

- tools/model-tool/cli.mjs
- 必要时检查结果 envelope 的构建和输出写入代码

当前需要重点检查：runCommand 在构建输出列表时可能先加入 report.json 路径，但只在 ok/partial 时写文件；错误情况下可能声称 report 存在，实际却没有生成。

要求：

1. 返回的 outputs 只能列出确实写出的文件。
2. 对 error 结果，选择以下一种一致且明确的行为：

   - 成功写入错误报告后，返回该报告路径；或
   - 不写错误报告，也不把不存在的报告路径加入 outputs。

3. 文件写入本身失败时，应如实报告失败，不能伪称输出成功。
4. 不覆盖用户已有文件，保留现有路径安全约束。
5. 不要借此重写整个 CLI。

E. 更新 Agent 使用文档

根据实际完成结果更新：

- tools/model-tool/README.md
- docs/model-tool-architecture.md
- docs/model-tools.md

要求：

1. 修正与实际实现不符的旧表述，包括仍称“工具未实现”的历史说明。
2. 写清 ok、partial、error 的含义及 Agent 应采取的动作。
3. 写清贴图加载失败时截图仍可能存在，但不能作为材质正确的证据。
4. 写清资源统计字段口径、unknown 的含义和当前限制。
5. 给出 inspect 和 snapshot 的实际调用示例，以现有 CLI 参数为准，不要编造参数。
6. 如本轮没有实测 USDZ、外部贴图、跨模型动作等，明确写未验证，不得写成通过。
7. 不在仓库内新增阶段任务书、临时交接文档或新版本计划书。

五、明确禁止的修改

- 不修改 Core、Engine、Game 业务逻辑和玩家存档。
- 不改变游戏玩法、角色控制、物理规则或现有资源。
- 不修改 Downloads 下原始 apet.glb。
- 不把 apet.glb 复制进仓库或提交到 Git。
- 不引入新的框架、模型处理大型依赖或网络服务。
- 不关闭 Electron 安全隔离。
- 不修复与本轮无关的动作重定向问题。
- 不启动正式游戏。
- 不结束用户现有的游戏、Electron 或其他进程。
- 不提交、合并、推送或发布。
- 不清理别人的未提交改动。

六、验证预算：严格遵守非必要不测试

本轮允许最多启动 3 次无头模型工具的 Electron 渲染进程，不启动正式游戏。

建议安排：

第 1 次：对 apet.glb 执行 inspect。
- 检查资源加载诊断与状态。
- 记录声明资源、加载结果和报告中的不确定项。

第 2 次：对 apet.glb 执行 snapshot。
- 查看生成的截图，确认角色贴图是否实际显示。
- 核对状态、诊断、输出路径与文件是否存在。
- 不要仅凭构建成功就宣称贴图已修复。

第 3 次：只有在需要验证缺失资源的错误处理时使用。
- 使用隔离的最小损坏资源或缺失贴图样例。
- 不修改原始 apet.glb。
- 确认结果不会伪报 ok，并核对实际文件与 outputs 一致。
- 如果无法在现有安全边界内构造可靠样例，保留未验证状态，不要为了凑测试次数启动进程。

所有新测试输出放在项目文件夹外的工作区目录下，例如：

C:\Users\Administrator\Documents\ChatGPT\game2\model-tool-output\

使用新的唯一子目录，不覆盖历史输出。

如果遇到系统沙箱或权限阻止，不要通过关闭 Electron 安全配置绕过。记录具体错误，按当前执行环境的授权机制处理。

按 AGENTS.md 要求，交付前执行一次必要的类型检查和生产构建。结合本工具修改，至少执行：

npx tsc -p tools/model-tool/tsconfig.json --noEmit
npm run model-tool:build
npm run build

若某个命令不存在，以 package.json 的真实脚本为准，说明替代命令。只有失败后修复，才重跑相关检查。不做全量回归、性能压测或重复启动。

七、验收标准

1. 对 apet.glb 的 inspect 和 snapshot 能正常完成。
2. 截图中的角色贴图实际可见；报告没有未解释的贴图加载失败。
3. 报告的资源统计口径清楚，不把“加载失败”说成“模型没有贴图”。
4. 对确有必要资源缺失的情况，任务不会伪报 ok。
5. 返回的 outputs 与实际写出的文件一致。
6. 安全配置没有被不必要地放宽。
7. 类型检查和构建结果如实报告。
8. 既有工作树改动和原始测试模型均保留。
9. 文档足以让新的 Agent 根据报告判断结果是否可靠。
10. 不宣称本轮没有实际验证的功能通过。

八、交付说明

完成后请报告：

1. 实际根因、证据，以及 CSP 是否确认为原因。
2. 修改了哪些文件，每个文件为什么修改。
3. 资源失败时各命令的状态和输出行为。
4. apet inspect 的结果与报告绝对路径。
5. apet snapshot 的结果、截图绝对路径，以及你实际看到的贴图表现。
6. 若执行负例，说明构造方式、结果与证据；若未执行，说明未验证。
7. 每项检查和构建的实际结果。
8. Electron 工具实际启动次数；明确正式游戏启动次数。
9. 保留的问题、未验证范围和可能影响。
10. git status 摘要；确认没有提交、合并、推送或发布。

遇到需要修改本任务之外的核心架构、业务公共接口或引入新框架的情况，停止相关扩展，报告问题和最小建议，不要自行扩大范围。

## 🤖 AI

I'll start by reading the required files and checking the working tree state.

## 🤖 AI

Now I have the full picture. Let me check the build pipeline and then implement.

## 🤖 AI

Now the `runCommand` output/report logic:

## 🤖 AI

Now the CSP fix:

## 🤖 AI

Now `api.ts` — shared types plus texture accounting:

## 🤖 AI

Now let's typecheck to catch errors early:

## 🤖 AI

## 1. 根因、证据与 CSP 结论

**直接原因：工具页 CSP 的 `connect-src` 缺少 `blob:`。已确认，不是推测。**

证据链：

| 证据 | 内容 |
| --- | --- |
| 历史报告 | 60 条 `DEPENDENCY_LOAD_FAILED`，失败 URL 全是 `blob:modeltool://app/<uuid>`；`data.textures = 0`、截图全灰 |
| 加载器源码 | `three@0.186` 的 `GLTFLoader.loadImageSource()` 把 bufferView 图片包成 `Blob` → `URL.createObjectURL`；`GLTFParser` 在支持 `createImageBitmap` 时用 `ImageBitmapLoader`；`ImageBitmapLoader.load()` 用 `fetch(url)`，受 `connect-src` 约束 |
| CSP 对照 | 当时 `img-src` 已含 `blob:`、`connect-src` 不含 → 排除 blob 创建/注册问题，剩下 fetch 被策略拒绝 |
| 图片本身 | 静态检查：47 PNG 的 chunk 链完整走到 IEND、13 JPEG 以 EOI 结束，无截断（本地脚本，不启动 Electron） |
| 修复后实测 | 两次运行之间唯一的加载路径改动是 `connect-src` 加 `blob:`：失败数 60 → 0，带图纹理 0 → 60，截图由全灰变为完整材质 |

**证据的边界**：历史运行没有 CSP 监听器，所以没有留下 Chromium 的拒绝文本；本次新增 `CSP_BLOCKED` 诊断（记录 `violatedDirective`），以后能直接取证。`connect-src` 只在原有列表后追加 `blob:`，未改 `*`、未加 HTTP/HTTPS、未动 sandbox/contextIsolation/nodeIntegration/webSecurity。

## 2. 修改的文件与原因

| 文件 | 修改 |
| --- | --- |
| `renderer/index.html` | `connect-src … data: blob:;`（根因修复） |
| `renderer/api.ts` | 新增 `AssetLoadRecord` / `DeclaredResourceSummary` / `TextureUsage`，`LoadedAsset.loads`、请求字段 `declaredResources`、`textureUsageOf()` |
| `renderer/load.ts` | 用 `LoadingManager.onProgress/onError` 记录真实请求与失败（`onStart` 只在空闲→加载中触发一次，不能计数）；URL 归类为 model/texture/buffer/other；失败按类别聚合成一条诊断 |
| `renderer/resources.ts`（新） | 资源账本：声明/成功/失败/未知、`notAttemptedImages`、`materialRisk`、计数口径说明 |
| `renderer/inspect.ts` | 声明数量来自 GLB 摘要或 `.gltf` JSON；输出 `data.resources`；状态由账本+依赖+几何合并；删除误导性 `NO_TEXTURES` 路径，改为 `TEXTURES_NOT_LOADED`/`TEXTURES_UNKNOWN` |
| `renderer/render.ts` | 贴图失败或声明与运行时对不上 → `partial`；报告写明“截图不能作为材质正确的证据”；输出 `resources`/`resourceIntegrity` |
| `renderer/main.ts` | 监听 `securitypolicyviolation` → `CSP_BLOCKED`（error），在判定 status 前并入诊断 |
| `renderer/animation.ts` | 加载失败时拒绝写出派生 GLB（`EXPORT_RESOURCE_INCOMPLETE`，exit 5）；只出计划时给警告与 `data.resourceLoad` |
| `lib/glb.mjs`（新） | 只读 GLB 头（12 B）+ JSON chunk 头（8 B）+ JSON + BIN 头；校验 magic/version/长度/chunk 类型/文件边界/bufferView 越界；只读约 1 MB，不读 BIN、不复制 100 MB 模型、不转 base64 |
| `lib/contract.mjs` | 允许并校验内部请求字段 `declaredResources` |
| `cli.mjs` | 传入 GLB 声明摘要；`outputs` 只在文件真实写出后列出；`error` 不写也不列报告；报告写入失败按 `error` + `REPORT_WRITE_FAILED`；`capabilities` 更新 GLB 实测状态 |
| `tools/model-tool/README.md`、`docs/model-tool-architecture.md`、`docs/model-tools.md`、`AGENTS.md` | 现行用法、状态语义、资源字段口径、实测/未验证分离；删除“工具未实现/占位”旧表述；构建命令统一为 `npm run model-tool:build` |

未改 Core/Engine/Game/存档，未新增项目内任务书。

## 3. 资源失败时的行为

- **inspect**：`status = incomplete/unknown ? partial(exit 6) : ok`。`data.resources.declared/runtime/failures/unknown` 分开；`null` 表示未知。
- **snapshot**：`materialRisk = known`（有失败/声明损坏）或 `possible`（外部图片、有槽位无图片）→ `partial`，PNG 仍写出并附“不可作为材质证据”的说明；`unknown`（USDZ 无清单）保持 `ok` 但报告写明未验证。
- **animation-edit**：有失败时计划模式只警告不落盘；`--write-glb --confirm-write` 直接拒绝（exit 5），避免导出丢贴图/几何的资产。
- **retarget**：只出映射报告，不产物，不因贴图降级。
- 只读提示（`USDZ_READ_ONLY`、`AXES_UNDECLARED`）与 `--time` 夹取不降级。

## 4─5. apet 实测结果

- inspect：`C:\Users\Administrator\Documents\ChatGPT\game2\model-tool-output\apet-fix-20261101-inspect-2\report.json`
  `status ok`，声明 60 图片（47 PNG/13 JPEG）、60 纹理、25 材质；请求 61（1 模型 + 60 贴图），失败 0；`textureObjects=60`、`texturesWithImage=60`、`materialTextureSlots=85`；105 骨骼、1 片段；1.47 s。
- snapshot：`...\apet-fix-20261101-snapshot\snapshot-Calibration-0deg.png`（124,340 B）+ 同目录 `report.json`，`status ok`、7.68 s。
  **实际看到的画面**：红格衬衫、破洞牛仔裤、红白球鞋、肤色与头发全部正常显示；与历史灰模截图对比明显。`outputs` 两条路径均存在，PNG 的 sha256 与报告一致。

历史证据保留且校验未变：`apet-review-*` 未覆盖；旧 PNG 哈希仍为 `8F4128…D2ED87`；`apet.glb` 哈希仍为 `9901833C…0974F`（未被修改/复制）。

## 6. 负例

**未执行**（3 次渲染预算已用尽，其中一次是计数修正前的中间运行）。没有构造缺失贴图样例跑端到端。替代验证：本地脚本（不启动 Electron）覆盖 5 类账本输入（60 失败 / 60 成功 / USDZ 未知 / 部分未请求 / 声明 bufferView 越界 / 无贴图），20 项断言全部通过；GLB 读取器 14 项边界断言（含 chunk 越界、magic 不符、长度不一致、文件缺失）全部通过。端到端 `partial` 行为仍属未验证。

## 7. 检查与构建

| 检查 | 结果 |
| --- | --- |
| `npx tsc -p tools/model-tool/tsconfig.json --noEmit` | exit 0 |
| `npm run model-tool:build` | 成功（约 0.4 s，产物 `.build/index.html` 已确认含 `blob:`） |
| `npm run build`（`tsc --noEmit && vite build`） | 成功（约 0.6 s，仅既有 chunk 体积提示） |
| `node tools/model-tool/cli.mjs capabilities` / `snapshot --help` | exit 0，机器可读 stdout 未混日志 |
| 本地逻辑脚本 ×2 | 20/20、14/14 通过 |

## 8. 进程次数

- 无头模型工具 Electron 渲染进程：**3 次**（inspect 中间运行 exit 6；inspect 最终 ok；snapshot ok）。
- 另有 1 次 CLI 调用在启动前因 `report.json` 已存在而 exit 4（未启动 Electron）。
- 正式游戏启动：**0 次**；未结束或干扰任何既有进程。

## 9. 保留的问题与未验证

- `snapshot` 在真实缺失贴图上的端到端 `partial`：仅本地逻辑覆盖。
- `animation-edit` 的 `EXPORT_RESOURCE_INCOMPLETE` 拒绝路径：仅代码审查。
- `.gltf` 的 `snapshot` 未单独实跑，快照报告里 `.gltf` 声明数量为 `unknown`；`.gltf` 外部贴图的**成功**加载未实测（只测过缺失）。
- USDZ 资源数量仍为 `unknown`（不枚举，未编造）。
- `CSP_BLOCKED` 修复后未再触发，缺一次“被拦截”的实跑记录。
- 兼容性变化：同类失败诊断由 60 条聚合为 1 条（`details.count/attempted/samples` 保留）；`error` 的 `outputs` 不再包含不存在的 `report.json`；`inspect.data.textures` 语义不变（= `runtime.textureObjects`）。`schemaVersion` 仍为 1，退出码不变。

## 10. Git

`git status` 显示大量**其他人**的未提交改动（`src/**`、`package.json`、`docs/model-tool-work-packages.md`、多个 adapters 等）与既有 untracked 文件，全部原样保留。我新增 `lib/glb.mjs`、`renderer/resources.ts` 两个文件。HEAD 仍为 `d6a5ad6`：**没有提交、合并、推送或发布**。中间那次计数错误的 inspect 输出目录（`apet-fix-20261101-inspect`）已删除，避免留下会误导的“60 张图片未尝试加载”报告；最终证据在 `…-inspect-2` 与 `…-snapshot`。

## 🙋 我

一、项目位置和工作方式

主项目：

C:\CODING\wolf-of-tarkov

请先确认当前所在的仓库、分支和工作树状态，不要假定你当前的目录就是项目根目录。

优先在用户为你指定的独立开发 worktree 中工作；如果没有单独指定，可从上述主项目读取现状，并根据自己的执行环境选择合法的工作目录。不要为了创建工作区覆盖或清理现有修改。

先读取：

1. AGENTS.md
2. tools/model-tool/README.md
3. docs/model-tool-architecture.md
4. docs/model-tools.md
5. tools/model-tool/cli.mjs
6. tools/model-tool/adapters/game-character.ts
7. tools/model-tool/adapters/runtime-collision.ts
8. tools/model-tool/renderer/load.ts
9. tools/model-tool/renderer/resources.ts
10. tools/model-tool/renderer/main.ts
11. tools/model-tool/runner/main.cjs
12. src/world/character.ts
13. src/world/player.ts
14. src/world/physics/runtime.ts
15. src/world/physics/types.ts

先运行：

node tools/model-tool/cli.mjs capabilities

检查 Git 状态，记录已有未提交改动。不要重置、清理、覆盖其他人的工作。

二、本轮明确目标

完成以下项目：

1. 修复游戏角色多朝向截图的动作更新顺序。
2. 增加有限、可复现的连续转向诊断。
3. 验证完整外部贴图的 glTF 读取和截图。
4. 验证损坏图片的加载失败诊断。
5. 验证 CSP 阻止资源时的诊断，不实际访问外网。
6. 验证错误 GLB 内容的错误报告。
7. 验证 RoundCuboid 的真实快照读取和绘制。
8. 验证物理快照的重复读取、副本隔离和不推进物理。
9. 验证软件渲染分支；若环境不支持，准确报告。
10. 对不支持的特殊动作插值做最小局部拒绝验证，不导出动作文件。
11. 更新现行工具文档与能力声明，使其与实际验证结果一致。

三、本轮明确不做

- 不实现、不测试跨模型动作套用。
- 不实现、不测试 retarget 动作导出。
- 不导出任何动作 GLB，也不测试 animation-edit 的导出拒绝路径。
- 不开发新的战斗、枪械、动画玩法。
- 不修改游戏物理规则、游戏存档或玩家行为。
- 不重构 Core、Engine 或 Game。
- 不在正式场景里增加测试碰撞体。
- 不使用用户正在运行的游戏进程或玩家存档。
- 不下载模型、贴图或其他网络资源。
- 不关闭 Electron sandbox、contextIsolation 或 webSecurity。
- 不提交、合并、推送或发布。
- 不在游戏项目里放任务书、阶段计划书或临时交接文档。

四、最高优先级：修复多朝向截图的验证方式

涉及文件：

- tools/model-tool/adapters/game-character.ts
- 必要时 tools/model-tool/renderer/transform.ts
- tools/model-tool/README.md
- docs/model-tool-architecture.md

现状和问题：

当前 `snapshot-game-character` 大致按以下顺序运行：

1. rig.reset()
2. 在默认朝向下，多次 rig.update(...)
3. 循环修改 rig.root.rotation.y
4. 测量和截图

这只是把已经计算好的姿态整体旋转，不能证明每个朝向下的程序化四肢动作都按正确的角色局部轴计算。

而游戏中的实际顺序是：

1. Player 先更新人物 group 的朝向。
2. CharacterRig 在当前朝向下执行 update。
3. CharacterRig 根据当前角色空间计算程序化姿态。

请调整工具，使每个静态朝向都独立按真实顺序模拟。

具体要求：

1. 保留现有 `--yaw`、`--angles`、`--action`、`--time` 的参数与输出兼容性。
2. 对每一个 yaw：
   - 重置角色动作状态。
   - 设置角色根的目标朝向。
   - 同步必要的世界矩阵。
   - 在该朝向下，以固定 dt = 1/60 秒执行原有 motion 计划。
   - 再读取包围盒、骨骼方向并截图。
3. 不能先模拟一次，然后仅旋转已生成姿态作为所有朝向的结果。
4. 如果为了计算统一取景框需要两轮遍历，可以在两轮中各自重置并按相同参数重演，保证同一 yaw 的诊断与截图来自相同的动作状态。
5. 注意 `rig.reset()` 和设置 yaw 的实际顺序：检查真实实现，确保 reset 不会让 yaw 回到错误状态。
6. 保持原有真实 `loadCharacterRig()`、`rig.update()` 和现有 motion 计划，不复制一套假的游戏动作。
7. 保留统一相机、比例参照、报告与现有输出文件名。
8. 更新报告中的 assumptions/说明，准确写明：
   - 每个角度独立重演；
   - 先设置朝向，再调用角色 update；
   - `angles` 是静态朝向检查，不是连续转向。
9. 不改 `src/world/player.ts` 或 `src/world/character.ts` 中的游戏行为；若发现游戏本身有问题，先记录，不擅自扩展范围。

最低验证：

使用一次 `snapshot-game-character` 调用，对同一动作、同一动作时间，输出 0、90、180、270 度四张截图和报告。

检查：

- 四张图片真实存在；
- 报告记录每个角度；
- 四个方向均在各自 yaw 下经历真实 rig.update；
- 身体和四肢没有明显沿固定世界轴错误摆动；
- 数值检查与视觉检查结论分别报告；
- 不得把静态四方向截图称作连续转向已通过。

五、增加连续转向诊断

涉及文件：

- tools/model-tool/cli.mjs
- tools/model-tool/adapters/game-character.ts
- 如内部请求校验确实需要，修改 tools/model-tool/lib/contract.mjs
- tools/model-tool/README.md
- docs/model-tool-architecture.md

目标：

在一个隔离工具进程中，让真实 CharacterRig 按固定时间步连续转向，并在多个时间点截图和记录骨骼方向。

不要改游戏控制器，也不要新增正式游戏界面。

建议在现有 `snapshot-game-character` 上增加以下可选参数：

--turn-from <number>       起始 yaw，单位度
--turn-to <number>         结束 yaw，单位度
--turn-duration <number>   转向持续时间，单位秒
--turn-samples <string>    逗号分隔的采样时间，单位秒

连续转向模式具体契约：

1. 四个参数应成组提供；参数不完整、不是有限数字、采样时间超范围时返回参数错误。
2. 连续转向模式与 `--yaw`、`--angles` 互斥；冲突时返回清晰参数错误，不自行猜测用户意图。
3. 沿用户指定的数值方向线性插值 yaw，不擅自将 0→360 改成最短路径 0→0。
4. `--turn-duration` 必须大于 0 且不超过 10 秒；采样点最多 17 个。
5. 按 1/60 秒的固定时间步推进；把采样点映射到实际帧时，报告请求时间与实际采样时间。相同实际帧去重并明确报告，不覆盖输出文件。
6. `--time` 在连续模式下定义为转向前的动作预热时间；在帮助和报告中明确这一含义。预热阶段保持起始 yaw。
7. 每一帧先设置当前 yaw，再同步必要的变换，再调用 rig.update。
8. 每个采样点记录：
   - 请求时间；
   - 实际时间和步数；
   - yaw；
   - 骨骼方向数据；
   - PNG 路径；
   - 固定 dt、action 和预热时间。
9. 文件名按采样序号生成，例如：
   `character-walk-turn-000.png`
   `character-walk-turn-001.png`
   不能仅以角度命名，避免重复或覆盖。
10. 固定相机与取景条件，方便比较。报告必须说明这属于受控 CharacterRig 模拟，不是实际游戏输入、性能或动作手感验收。
11. 保留原有静态模式，旧调用不受影响。
12. 依旧使用安全的工具输出目录，不写入源模型或玩家存档。

最低验证：

一次工具进程，使用 walk、预热 0.5 秒、从 0° 转至 180°、持续 1 秒，采样 0、0.25、0.5、0.75、1 秒。

检查每张截图和报告中的时间、角度顺序。

重要：连续转向过程中动作本身也随时间变化，不能直接比较不同时刻的骨骼方向后断言“局部方向应完全一致”。如要做数值对照，应与相同动作时间、相同目标 yaw 的静态重演比较，并说明比较口径和容差。无法可靠自动判断的内容写为人工观察或未验证，不制造虚假的通过结论。

六、验证完整外部贴图的 glTF

涉及实现，按实际问题最小修改：

- tools/model-tool/renderer/load.ts
- tools/model-tool/renderer/resources.ts
- tools/model-tool/renderer/inspect.ts
- tools/model-tool/renderer/render.ts
- tools/model-tool/runner/main.cjs
- 必要的路径处理文件
- README 与架构文档

创建独立、最小的测试资产，不使用或修改用户模型：

- 一个 `.gltf`；
- 一个简单可见网格；
- 一个保存在 glTF 同一目录下的有效 PNG 或 JPEG；
- 材质引用该外部图片；
- 可以使用简单的内联几何 buffer；
- 图片应有足够明显的颜色，便于截图确认。

执行一次 `snapshot`，并核对：

1. 外部贴图确实显示，不只是 PNG 文件存在。
2. 没有贴图加载失败。
3. 报告中资源数量、状态和 unknown 原因与实际一致。
4. `outputs` 列出的文件真实存在。
5. 不得因声明清单未解析就编造 complete；以工具真实契约为准。
6. 只验证了该样例时，文档写“外部贴图样例通过”，不能宣称所有 glTF 扩展均通过。

测试材料放在用户授权工作区内的独立目录；不要放进游戏资源目录。

七、验证损坏图片和 CSP 诊断

A. 损坏图片

在独立测试资产中保留有效的 glTF 和几何，把图片替换为“文件存在但内容无法解码”的本地图片。

运行一次 `snapshot`，核对：

- 输出为 partial 或明确的 error，不得是完整成功；
- 诊断指出图片加载失败；
- 不能把它说成“模型没有贴图”；
- 如果有截图，报告必须说明不能用它证明材质正确；
- 不得仅根据失败就断言具体解码器错误，除非实际获得明确证据。

B. CSP 阻止

目标是验证工具现有的 `CSP_BLOCKED` 诊断，不是降低安全性。

使用独立的受控样例，引用一个会被现有 CSP 在发起网络连接前拦截的 HTTPS 图片地址，例如保留域名 `https://example.invalid/blocked.png`。

要求：

1. 不运行本地或远程服务，不实际联网。
2. 不改变正式工具 CSP。
3. 运行一次相关工具命令，检查浏览器是否产生 securitypolicyviolation。
4. 如实记录顶层 status、退出码、`CSP_BLOCKED`、directive 和输出文件。
5. 如果 `CSP_BLOCKED` 没有进入最终结果，检查：
   - `tools/model-tool/renderer/main.ts` 中 violation 事件记录时机；
   - 任务异常走 `errorPayload()` 时是否丢掉 CSP 诊断；
   - 异步事件是否在提交结果之后才到达。
6. 只做必要修复。错误结果也应保留已观察到的 CSP 诊断；不要把一般的下载/解码失败无证据地标成 CSP。
7. 如环境或 Electron 行为无法稳定触发，写“未验证”及证据，不允许修改安全配置强行制造通过结果。

八、验证错误 GLB 文件

构造一个扩展名为 `.glb`、内容不是有效 GLB 的独立小文件。

执行一次 `inspect`，核对：

- 非 0 退出；
- `status: error`；
- 错误代码与说明可读；
- `outputs` 不包含不存在的 report；
- 没有伪称模型内容有效。

如果当前错误文案已经清楚，不需要为了测试而修改代码。

九、验证 RoundCuboid 和物理快照只读性

涉及文件：

- src/world/physics/runtime.ts：只审查或通过测试调用，不改变游戏物理规则。
- src/world/physics/types.ts：仅在发现确切快照契约缺陷时最小修改。
- tools/model-tool/adapters/runtime-collision.ts：必要时抽取或导出可复用的绘制辅助函数。
- 工具的临时验证代码或确有长期价值的小型验证辅助代码。
- README 和架构文档。

测试必须在独立物理世界中进行，不能修改正式游戏地图、角色或家具配置。

A. RoundCuboid

1. 创建仅供验证的隔离 Rapier 世界或隔离 PhysicsRuntime。
2. 在其中创建一个真实的 Rapier RoundCuboid，使用明显可见的不同半尺寸和圆角半径。
3. 不复制一套独立的“假快照转换逻辑”冒充正式代码；尽可能调用现有 `captureDebugSnapshot()` 路径读取真实 collider。
4. 若需要在验证代码中访问私有物理世界，只允许在隔离测试辅助代码中进行，不得为测试向正式游戏公开可写的 Rapier World。
5. 将读取结果交给 `runtime-collision.ts` 的实际绘制逻辑。若函数目前是私有的，可做最小范围的工具内部抽取或导出，不要建立第二套形状绘制实现。
6. 核对：
   - shape 为 `round-cuboid`；
   - halfExtents 与 border radius 对应真实 Rapier 数据；
   - 生成方式为 `rounded-box`；
   - 盒子的外尺寸与 Rapier 形状定义一致。
7. 用工具渲染一张独立验证图，视觉确认圆角可见。
8. 如果 Rapier 的半尺寸语义与当前代码假设不同，以安装版本的实际 API 和实测为依据修复，记录依据，不要为了迎合预期硬编码截图。
9. 如果无法安全复用现有快照路径或渲染路径，停止该部分并说明障碍，不要报告通过。

B. 只读、副本和不推进物理

使用同一个隔离实例，在没有调用正常物理推进的条件下：

1. 记录 collider 数量、角色位置、接地状态及可访问的相关状态。
2. 连续调用两次快照，比较关键字段。
3. 修改第一次返回值中的嵌套位置或尺寸对象。
4. 再次捕获快照，确认修改第一次副本没有影响后续结果或运行时实际对象。
5. 对隔离实例的物理 `step` 调用做有边界的测试观察，确认 capture 期间没有调用 step；不要影响其他实例。
6. 完成后仅释放本测试创建的 Rapier 对象。

报告必须说明具体验证了哪些字段和调用；不要把这一次局部测试扩大为对所有物理状态的绝对保证。

十、验证软件渲染分支

涉及文件：

- tools/model-tool/runner/main.cjs
- tools/model-tool/lib/runner.mjs
- 文档

在单次工具调用的子进程环境中设置：

MODEL_TOOL_SOFTWARE_GL=1

使用第六节的有效小模型截图，检查报告里的实际 renderer/backend。

要求：

- 不能仅因为设置了环境变量就声称 SwiftShader 生效。
- 若实际 backend 显示软件渲染，记录具体字符串和截图结果。
- 若本机 Electron/驱动不支持，报告实际输出、错误和环境限制，不能关闭安全沙箱或修改系统设置强行通过。
- 不把环境变量永久写入用户系统。

十一、特殊动作插值的最小拒绝验证

本节不导出动作文件，不实现新的插值支持。

现有工具声称：CUBICSPLINE、Smooth/Bezier 或未知自定义插值不能静默当作 LINEAR/STEP 编辑。

要求：

1. 先检查 `tools/model-tool/renderer/animation.ts` 中的实际判断逻辑，以及 Three.js 当前版本能真实表达的轨道类型。
2. 对能由 Three.js 构造的 Smooth 或自定义 interpolant，使用最小本地验证，确认进入明确拒绝路径，不发生线性化。
3. 不使用 `--write-glb` 或 `--confirm-write`，不生成派生动作资产。
4. 不要为 glTF 标准本身不支持的插值形式编造“真实 glTF 测试成功”。
5. 如果某种形式无法通过现有加载路径表达，记录这一限制即可，不新增复杂框架。

十二、输出与文档维护

至少检查并按实际结果更新：

- tools/model-tool/README.md
- docs/model-tool-architecture.md
- 如讨论结论确实变化，更新 docs/model-tools.md
- 如能力状态、说明或参数变化，更新 tools/model-tool/cli.mjs 的 capabilities / help

文档要求：

1. 将已实际验证的条目从“未验证”改为真实验证记录。
2. 没有完成或被环境阻止的条目保留“未验证”，附原因。
3. 持续保留以下限制：
   - 跨模型动作套用和导出未实现，本轮未做；
   - USDZ 写回不支持；
   - 截图不能证明动作自然、游戏性能或真实玩家会话；
   - 只有局部样例通过，不等于所有模型和扩展通过。
4. 区分静态四方向和连续转向，描述修正后的动作更新顺序。
5. 修正 capabilities 或文档中与当前项目路径有关的过时硬编码描述；实际输出范围按代码和当前 worktree 说明。
6. 不覆盖此前由其他人生成的报告和截图。
7. 不把本任务书或临时交付记录写进仓库。

十三、允许修改的文件范围

优先只修改：

- tools/model-tool/adapters/game-character.ts
- tools/model-tool/adapters/runtime-collision.ts
- tools/model-tool/renderer/transform.ts
- tools/model-tool/renderer/load.ts
- tools/model-tool/renderer/resources.ts
- tools/model-tool/renderer/main.ts
- tools/model-tool/cli.mjs
- tools/model-tool/lib/contract.mjs
- 为验证真正需要的、范围有限的工具测试辅助代码
- tools/model-tool/README.md
- docs/model-tool-architecture.md
- docs/model-tools.md

只有在有明确缺陷且无法在上述范围修复时，才考虑修改其他文件，并在交付中解释原因。

不得修改游戏中的角色动作、物理行为、玩家状态、模型源文件或存档格式。

十四、验证预算

遵守“非必要不测试”。

- 正式游戏启动：0 次。
- 无头 Electron 工具进程：最多 8 次，按实际必要使用；失败启动也计入。
- 同一次进程可以产生多张与同一任务有关的截图。
- 不做全流程回归、性能压测、多浏览器矩阵或无目的重复测试。
- 不为凑满次数而运行。

建议预算：

1. 静态四朝向角色检查：1 次。
2. 连续转向检查：1 次。
3. 完整外部贴图 glTF：1 次。
4. 损坏图片负例：1 次。
5. CSP 阻止负例：1 次。
6. 错误 GLB：1 次。
7. 隔离 RoundCuboid / 快照验证：最多 1 次。
8. 软件渲染检查：1 次。

如果某项能用不启动 Electron 的本地最小验证完成，就不消耗工具进程；剩余预算可用于确有必要的失败修复复验。超过 8 次前停止该项，说明尚未验证的部分，不擅自追加。

注意：一次命令即使没创建 WebGL 截图，只要启动 Electron 工具进程，也必须计入次数。

如果 Windows 执行沙箱的 ACL 阻止 Electron 自身启动，按你当前环境的授权机制处理；不要修改用户系统 ACL，不要关闭 Electron 安全隔离。无法获得许可时如实报告。

交付前按 AGENTS.md 执行必要的类型检查和生产构建：

npx tsc -p tools/model-tool/tsconfig.json --noEmit
npm run model-tool:build
npm run build

若修复导致检查失败，只重跑受影响的检查。

十五、交付要求

请给出一份可核验的交付报告：

1. 修改文件清单，以及每个文件修改原因。
2. 静态四方向原问题是否修复，修复前后的执行顺序。
3. 连续转向命令、参数、报告路径、每个采样点的截图路径和观察结果。
4. 完整外部贴图样例的实际状态、贴图表现和报告路径。
5. 损坏图片、CSP 阻止、坏 GLB 的实际状态、退出码、诊断及输出文件。
6. RoundCuboid 的真实尺寸、半径、快照字段、渲染方式及截图。
7. 快照副本/不推进物理的具体检查方法和结果。
8. 软件渲染的实际 backend 字符串；如果不能验证，说明原因。
9. 特殊插值拒绝验证使用的真实轨道类型和结果；不宣称未实现形式已实测。
10. 构建和类型检查结果。
11. 每次无头 Electron 工具进程的用途、结果和总次数；正式游戏启动次数。
12. 仍未解决的问题和未验证项，特别保留动作导出和跨模型套用不在范围内的说明。
13. git status 摘要；确认没有提交、合并、推送或发布。

不得把“代码已实现”写成“已实测通过”；不得把局部样例通过写成所有模型均兼容。

## 🤖 AI

现在我会在 `game-character.ts` 中实现逐 yaw 独立重演，并加入连续转向模式。

