# C 动画处理与重定向报告

- 会话 ID：`ses_e6d61b8f5ffe58jzU4wsnfs67R`
- 时间：2026-10-31 23:40
- 目录：`C:\Users\Administrator`
- 模型：`deepseek/deepseek-flash`

---

## 🙋 我

You are a subagent spawned by another session.
实施 C 包。项目根：C:\Users\Administrator\Documents\ChatGPT\game2\wolf-desktop

## 你只能写这两个文件（其他一律不许改：禁止改 src/**、package.json、renderer/main.ts、renderer/api.ts、adapters/**）
1. tools/model-tool/renderer/animation.ts（新建，当前 127 字节占位注释，可整文件覆盖）
2. tools/model-tool/renderer/retarget.ts（新建，当前 115 字节占位注释，可整文件覆盖）

## 先读（只读）
- tools/model-tool/renderer/api.ts —— 硬契约：`Task`、`TaskTools`（load / frame / writePng / writeBinary / writeText / readSibling / diagnostics / info·warn·fail / gameAssetUrl）、`ToolRequest`、`TaskError`、`LoadedAsset`、`clipSummary`、`boxJson`、`round`。
- node_modules/three/examples/jsm/exporters/GLTFExporter.js —— 只用它的 parseAsync，不要引入新依赖。

## 任务 1：`animation-edit`（导出 `animationEditTask: Task`）
参数（request.args）：`clip`（必填，片段名）、`rename`（可选新名）、`start`、`end`（秒，可选，都给了才能裁剪，`end > start` 否则 TaskError 2）、`writeGlb`（可选，输出相对路径，必须以 `.glb` 结尾）、`confirmWrite`（布尔，默认 false）。

行为：
1. `const asset = await tools.load()`；`asset.format === 'usdz'` → 立即 `TaskError('USDZ_WRITE_UNSUPPORTED', '…现有证据只能读取 USDZ，没有无损写回证明…', 3)`。不得尝试写出，也不得声称支持。
2. 找不到 `clip` → `TaskError('CLIP_NOT_FOUND', …, 3)`，details 里列出可用片段名（最多 20 个）。
3. 裁剪：用 `THREE.AnimationUtils.subclip` 不行（它按帧号）；这里要按秒裁剪。正确做法：对每条 track 用 `THREE.AnimationUtils`/手写采样——最稳妥是 `clip.clone()` 后用 `THREE.AnimationUtils.subclip(clip, name, startFrame, endFrame, fps)` **仅在** 你显式取 fps=clip.duration 相关值时；更可靠的是手写：对每条 track 的 times/values 做区间切片并补插值端点，重算 duration。请自己实现一个小的 `trimClipBySeconds(clip, start, end)`，保留原 track 名称与插值类型，端点线性插值补齐，写单元级说明注释。
4. 重命名：`rename` 存在时给片段改名（`clip.name = rename`）。
5. 报告 data：`format`、`sourceClip`、`resultClip`、`durationBefore/After`、`tracksBefore/After`、`trim`、`rename`、`loopSafe`（首末采样差，按最大通道差给数值 + 布尔阈值 1e-3）、`writePlanned`（是否请求写出、目标路径、使用的导出器与 three 版本）。
6. 写出：只有 `writeGlb` + `confirmWrite === true` 同时成立才用 GLTFExporter（`binary: true`）导出**只含该片段**的 GLB，用 `tools.writeBinary(relPath, base64)` 落盘；否则只输出计划，并在 data 里 `written: false` + 原因。导出时只把 `asset.root`（或它的克隆）和 `[editedClip]` 交给导出器，不要带相机/灯光/参照物。导出失败 → `TaskError('EXPORT_FAILED', …, 5)` 并保留诊断。
7. 明确写入 data：`limits: ['不是无损编辑：导出为重新序列化的 GLB', 'USDZ 写回未实现']`。

## 任务 2：`retarget`（导出 `retargetTask: Task`）
参数：`source`（绝对路径，必填）、`target`（绝对路径，必填）、`map`（可选，字符串 `"srcBone=dstBone,srcBone2=dstBone2"` 或数组）、`angles`（默认 [0,90,180,270]）。
行为：
1. `tools.load(source)` 与 `tools.load(target)`（同一个 tools.load 支持传显式路径，仍受 allowedRoot 约束；两个文件必须都在 allowedRoot 内，否则 TaskError 4）。
2. 收集两侧骨骼名（按层级深度排序）、根骨骼名、绑定姿态（每个骨骼相对父级的 position/quaternion 局部值，最多记录 40 条）、整体包围盒与身高/比例比。
3. 自动候选映射：仅做**名称完全相同**的精确匹配，结果标记 `method: 'exact-name'`；再做一层归一化候选（去前缀 `mixamorig:`、`n` 数字、下划线大小写差异）但必须标 `method: 'normalized-name-guess'` 且 `requiresConfirmation: true`。**禁止**用几何位置或启发式强行匹配。
4. 未匹配项必须逐条列出（source 有、target 无；target 有、source 无，各限 50 条）。
5. 若提供了 `map`，校验每个源骨骼存在于 source、目标骨骼存在于 target，任一缺失 → 在 data 里 `invalidMappings` 列出并 `status` 语义上标 warning，不静默丢弃。
6. 根运动：检测 source 每个片段是否存在影响根骨骼的 position track，报告片段名与轨道名。
7. 比例：`targetHeight/sourceHeight`，以及 >1.2 或 <0.8 时给 warning（只说需要显式缩放，不自动缩放）。
8. **不导出任何重定向动画**。data 里写 `exportSupported: false` 与原因（绑定姿态/轴向/比例未证实）。不要建预览动图，不要复制游戏动作。
9. data 另含 `source`/`target` 摘要（format、clips 数、bones 数、bbox、heightMeters）与 `limitations`。

## 通用要求
- 所有任务通过 `tools.*` 拿资源和写文件，不直接碰 fs/DOM；不新增依赖；不跑 Electron、不截图、不跑 Vite build、不改文档、不碰 git。
- 数值四舍五入用 `round()`；未知写 null 并给 warning，绝不写 0 冒充。
- 完成后可跑一次 `npx tsc -p tools/model-tool/tsconfig.json --noEmit`，只修你自己两个文件的报错；其他文件（main.ts、adapters/**）的报错忽略并说明。

## 交付回复
两个导出签名、参数表、data 字段表、trimClipBySeconds 的实现要点、tsc 中属于你文件的报错（应为空）、未验证假设。不要贴大段代码。

## 🤖 AI

I'll start by reading the contract files to understand the interfaces.

## 🤖 AI

Now I have the contract. Writing `animation.ts`:

## 🤖 AI

Now `retarget.ts`:

## 🤖 AI

Now run the type check:

## 🤖 AI

<summary>
已实现 C 包的两个任务模块：`animation-edit`（按秒裁剪 + 重命名 + 确认后导出仅含该片段的 GLB）与 `retarget`（只出重定向计划报告，不导出动画）。只改了指定的两个文件。
</summary>

<changes>
- `tools/model-tool/renderer/animation.ts`：新建，导出 `animationEditTask: Task`。含 USDZ 拒绝闸门（`USDZ_WRITE_UNSUPPORTED`/3）、`CLIP_NOT_FOUND`（/3，details 列最多 20 个片段名）、`trimClipBySeconds`（按秒、逐轨、端点用轨道自身插值器补帧）、`loopDelta`（首末采样最大通道差，阈值 1e-3，未知为 null）、`writePlanned`（导出器/THREE.REVISION/binary/strip 策略）、`SkeletonUtils.clone` 导出树并移除灯光/相机/Grid·Axes·Arrow·BoxHelper、导出前用 `PropertyBinding` 预检轨道绑定（避免导出器静默跳过轨道）、`GLTFExporter.parseAsync({binary:true, animations:[editedClip]})` + base64 落盘、`limits` 固定两条。
- `tools/model-tool/renderer/retarget.ts`：新建，导出 `retargetTask: Task`。含 allowedRoot 预检（/4，并对 `..`/符号链接写法回退到 CLI 已解析的 `request.input`）、双侧骨架摘要（按深度排序的骨骼名、根骨骼、最多 40 条绑定姿态、bbox、身高）、精确名映射 + 归一化猜测（标 `normalized-name-guess` 且 `requiresConfirmation: true`，撞车进 `ambiguousGuesses` 不猜）、用户 `map` 校验（`invalidMappings` 逐条列出、status 转 warning）、未匹配双向列 50 条、根骨骼 position 轨道检测、身高比与 0.8–1.2 警告、`exportSupported: false` + 原因与 `limitations`。
</changes>

**导出签名**
- `export const animationEditTask: Task`（`(tools: TaskTools, request: ToolRequest) => Promise<TaskOutput>`）
- `export const retargetTask: Task`

**animation-edit 参数**

| 参数 | 类型 | 必填 | 行为 |
|---|---|---|---|
| `clip` | string | 是 | 片段名，缺失→`CLIP_NOT_FOUND`(3) |
| `rename` | string | 否 | `clip.name = rename` |
| `start`/`end` | number(秒) | 否 | 必须同时给；`end > start` 否则 `BAD_ARGS`(2)；越界→`TRIM_OUT_OF_RANGE`(2) |
| `writeGlb` | string | 否 | 必须 `.glb` 结尾、输出目录内相对路径（无 `..`），否则 2/4 |
| `confirmWrite` | boolean | 否（默认 false） | 非布尔→`BAD_ARGS`(2)；与 `writeGlb` 同时成立才写盘 |

**animation-edit data 字段**：`format`、`sourceClip`、`resultClip`、`durationBefore/After`、`tracksBefore/After`、`sourceClipSummary`、`resultClipSummary`、`trim{requested,applied,mode,start,end,duration,timeOriginShiftedToZero,endpointStrategy,keptKeys,synthesizedEndpoints,droppedTracks,droppedTrackCount}`、`rename{requested,applied,from,to}`、`loopSafe{maxChannelDelta,threshold,loopSafe,tracksCompared,note}`、`writePlanned{requested,confirmed,willWrite,targetPath,exporter,threeRevision,threeVersionNote,binary,animations,stripLightsAndCameras,reason}`、`written`、`writeResult{absolutePath,bytes,clip,trackCount}|null`、`limits`。

**retarget 参数**：`source`（绝对路径，必填）、`target`（绝对路径，必填）、`map`（`"a=b,c=d"` 或数组，元素可为 `"a=b"` 或 `{source,target}`）、`angles` 未使用（按设计不生成预览，因此不消费；未在 data 中伪报）。

**retarget data 字段**：`status`、`statusReasons`、`source`/`target`（`input,format,clips,bones,rootBones,boneNames,boneNamesTruncated,bbox,heightMeters,bboxBasis,clipList,clipListTruncated,skeletonRootsFromMeshes`）、`scale{sourceHeightMeters,targetHeightMeters,ratio,acceptableRange,warning,note}`、`mapping{provided,method,requiresConfirmation,confirmed,entries,counts,exactName,normalizedGuess,ambiguousGuesses,invalidMappings,invalidMappingCount,unmatchedSource(+Count),unmatchedTarget(+Count),rule}`、`bindPose{note,maxEntries,source,target,sourceTruncated,targetTruncated}`、`rootMotion{sourceRootBones,detected,clipsWithRootMotion,tracks,trackCount,note}`、`exportSupported`、`exportBlockedReason`、`limitations`。

**trimClipBySeconds 要点**
- 逐轨处理：保留 `[start,end]` 内原关键帧，时间平移 `-start`（输出从 0 播放），时长重算 `end-start`。
- 端点缺失时用该轨道自己的插值工厂（Discrete/Linear/Smooth/Bezier，四元数轨道走 slerp）在 `start`/`end` 求值补一个关键帧，而不是一律线性硬切。
- 补出的值块长度取 `getValueSize()`，三次/贝塞尔轨道仍是「切向量+值+切向量」结构，保持合法关键帧；已知近似：端点切线由插值器按通道求得，非重新拟合。
- `track.clone()` 后整体替换 `times/values`（不写源数组），保留轨道名与插值模式；`values.length % times.length !== 0` 或空轨道记入 `droppedTracks`。

<verification>
- Performed: `npx tsc -p tools/model-tool/tsconfig.json --noEmit`
- Result: 失败，唯一报错不属于我的文件：`renderer/main.ts(7,3): error TS6133: 'disposeSubtree' is declared but its value is never read`（main.ts 由其他包负责，未修改）。我的两个文件 0 报错。
- Performed: 未运行 Electron / Vite build / 截图 / 真实模型加载（按任务约束跳过），故 GLB 导出的实际字节结果**未验证**。
</verification>

**未验证假设**
1. 轨道名以节点/骨骼名绑定（GLTFLoader 常规行为）；若是 UUID 绑定，导出前预检会以 `EXPORT_FAILED`(5) 明确拒绝，而不是产出空动画——这条分支未实跑。
2. `SkeletonUtils.clone` 是导出克隆的正确方式（普通 `clone()` 会让 SkinnedMesh 指向原骨骼）；依据 API 与源码判断，未运行验证。
3. 三次/贝塞尔轨道的端点补帧是结构合法但切线近似的值；未做数值对照。
4. `Box3.setFromObject` 对 SkinnedMesh 取的是绑定姿态静态几何，报告里已标 `bboxBasis: 'static-geometry-in-bind-pose'`。
5. `allowedRoot` 语义按 CLI 实现推断（retarget 的 source/target 必须同目录）；`args.source` 未 realPath 化，故做了 `request.input` 回退。
6. `writeBinary`/`writeText` 对已存在文件会拒绝写入，我的代码按原样向外抛（若是 `TaskError` 直接透传），未实测其错误类型。
7. `angles` 参数按“不生成任何重定向/预览”的约束而不使用，若上游期望它出现在 data 中需要再定。

