# 新手教程opencode

- 会话 ID：`ses_e7d41ad41ffeYoWP4SHFBb3d2X`
- 时间：2026-10-28 21:41
- 目录：`C:\Users\Eojnus`
- 模型：`opencode/deepseek-v4.1-flash-free`

---

## 🙋 我

作为一个新手我怎样使用opencode的agent呢

## 🤖 AI

学习 agent 最省事的方式，是把它当成“给同一套工具的几套权限和提示词”。下面按“是什么 → 内置的怎么用 → 自己造一个”的顺序讲。

## 1. 两种 agent

| 类型 | 谁在与之对话 | 特点 |
|---|---|---|
| **primary（主 agent）** | 你 | 占据聊天窗口，可以自己用工具，也能派活给子 agent |
| **subagent（子 agent）** | 主 agent | 独立子会话、**全新上下文**，干完把结论汇报给主 agent |

关键点：子 agent 不是你去“启动”的，通常是主 agent 自己判断需要派活。你只要在提示词里点名即可。

## 2. 内置的四个

| Agent | 模式 | 干什么 |
|---|---|---|
| `build` | primary | 默认写代码的，能改文件、跑命令 |
| `plan` | primary | 只读探索 + 出方案，不动项目文件（你现在就在这个里） |
| `general` | subagent | 多步骤研究、杂活，工具权限大，但不能再派子 agent |
| `explore` | subagent | 快速搜代码、找文件、读代码，不改文件 |

## 3. 日常操作（TUI 里）

你 `cli.json` 没改键位，所以都是默认值：

- **切换主 agent**：`Shift+Tab` 循环（build ↔ plan）
- **列出所有 agent**：`Ctrl+X` 然后 `A`（`leader` 是 `Ctrl+X`，`agent.list` 是 `<leader>a`）
- **看子 agent 干活**：有子会话时按 `↓` 打开 subagent picker，`←` / `→` 在上一个、下一个子会话间切，`↑` 回父会话
- **打断**：`Esc`（打断当前会话）

## 4. 新手最实用的三个套路

**① 大改动前先 plan**

```
Shift+Tab 切到 Plan，然后：
帮我看看这个项目怎么加登录功能，先给方案别改代码
```

看完方案，再 `Shift+Tab` 切回 Build 说“按方案做”。

**② 让子 agent 去翻代码（省上下文）**

```
用 explore 子 agent 找一下所有处理支付回调的地方，告诉我文件路径和关键函数
```

好处是它翻几十个文件的过程不会塞进你的主对话。

**③ 明确禁止改文件**

```
用 explore 只读地分析，不要修改任何文件
```

## 5. 自己造一个 agent（最小模板）

在 `C:\Users\Eojnus\.config\opencode\agents\` 下建 Markdown 文件（这个目录你还没有，新建即可），全局生效：

```md
---
description: 只读审查改动，按严重程度列出问题
mode: subagent
---

审查当前改动。按严重程度排序，每条都给出文件路径和行号。
不要修改任何文件。
```

权限想收紧就加 frontmatter：

```yaml
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: shell
    resource: "*"
    effect: deny
```

保存后**自动生效，不用重启**。文件放 `.opencode/agents/` 就是只管当前项目；子目录会进 ID，比如 `team/reviewer.md` → `team/reviewer`。

## 6. 几个容易踩的坑

- **`description` 一定要写**，模型靠它决定派哪个子 agent；不写基本不会被选中
- **子 agent 是空上下文**，派活时把背景说清楚，否则它得从零摸索
- **`mode` 别写错**：写成 `subagent` 就没法直接切过去当主 agent
- **`model` 用 `provider/model` 格式**（可带 `#variant`），写错名字不会报错，只会静默回退
- **自定义 agent 不会自动拿到你的 `AGENTS.md`？会拿到** —— 项目指令、skills 是额外注入的，只有 `system` 正文会替换基础提示词

## 7. 建议路线

先别急着写自定义 agent。用一周 `plan` + `build`，观察主 agent 什么时候会自己叫 `explore`；等你发现“有件事我每次都要重复同样的交代”，那才是该抽成 agent 的时候。

---

需要的话，等你切到 Build 模式（`Shift+Tab`），我可以直接帮你把 `reviewer` 或某个更贴合你工作流的 agent 文件写好。现在 Plan 模式我不动文件。

## 🙋 我

我怎样根据我的日常需要来让ai自动给我搞新的agent，比如我用opencode进行了大量的对话与开发后，怎样让他自动弄出个适合我的agent呢

## 🤖 AI

先说结论：OpenCode **没有**“读我的历史对话、自动生成 agent”的现成功能。但可以搭建一个小型的“复盘、起草、审核、写入文件”流程，让它每次运行后给出候选 agent，由你决定是否采用。关键是把会话记录变成可用的数据。

## 一、数据现成，我查过你的实例

```
opencode api get "/api/session?limit=50"
```
返回标题、agent、模型、目录、token。你现在有 6 个会话，分布在 `C:\Users\Eojnus`、`C:\Coding`、`Documents\默认项目`。

```
opencode api get /api/experimental/session/stats
```
返回你的真实使用画像：16 个 prompt、116 步、118 次工具调用（110 成功 / 6 失败）、活跃 2 天。

```
opencode api get /api/experimental/session/<id>/export
```
返回完整对话。**但不要直接交给 AI**：你那个“新手教程”会话一个就 150KB，塞满工具输出。

只取用户原话就够了：`data.messages[]` 里筛 `type == "user"`，再只保留 `content[].type == "text"`。这样几十个会话能压成几百行，而这正好反映“你平时是怎么跟 AI 说话的”，是设计 agent 的最强信号。

## 二、流程设计（四层，逐层自动化）

| 层 | 触发方式 | 做什么 |
|---|---|---|
| 1 | 会话里让 AI 直接读 export | 能跑，但粗糙、容易污染上下文 |
| 2 | 自定义命令 `/distill`（推荐） | 固定流程：取会话、压语料、聚类、写草稿 |
| 3 | `/distill` + `subagent: true` | 后台执行，不占用你当前会话 |
| 4 | 插件 hook | 会话结束自动触发。成本高、会悄悄改你的配置，不建议新手一上来就做 |

新手建议直接从第 3 层开始。第 4 层的真正问题是：自动运行等于“每次聊天后都可能往你全局配置里写东西”，你会失去对自己环境的掌控权。建议采用每周一次手动运行 `/distill` 的节奏。

## 三、需要建的四个东西

**1. `~/.config/opencode/commands/distill.md`**

```md
---
description: 复盘最近会话，起草适合我的 agent
agent: general
subagent: true
---

分析我最近 $ARGUMENTS 个会话（默认 30）。

1. `opencode api get "/api/session?limit=30"` 列出会话
2. 对每个会话导出，只保留用户消息里的 text，丢掉 tool 和 reasoning
3. 找出重复出现的模式（见判定标准）
4. 只在 ~/.config/opencode/agents-draft/ 下写草稿，每个候选一个 md
5. 返回一张表：名字 / 触发场景 / 省了什么 / 证据会话 ID

不要修改 ~/.config/opencode/agents/ 下的任何文件。
```

**2. `~/.config/opencode/agents/profiler.md`**（专门负责这项分析的子 agent）

```md
---
description: 分析我的历史会话，找出该沉淀成 agent 的重复模式
mode: subagent
permissions:
  - action: edit
    resource: "~/.config/opencode/agents/**"
    effect: deny
  - action: edit
    resource: "~/.config/opencode/agents-draft/**"
    effect: allow
  - action: shell
    resource: "*"
    effect: deny
  - action: shell
    resource: "opencode api get *"
    effect: allow
---
你只做分析和起草。禁止改动 agents/ 和任何项目文件。
```

注意权限是**最后匹配的规则生效**，所以宽泛的 `deny` 必须写在例外之前，这个顺序不能颠倒。

**3. `~/.config/opencode/scripts/session-prompts.ps1`**

用一段 PowerShell 遍历会话，导出文件，再抽掉工具输出，只写入用户原话。这样每次分析只读一个几十 KB 的语料文件，成本可预测。

**4. `~/.config/opencode/agents-draft/`**

草稿区。**故意不放在 `agents/`**，因为放进去就会被自动加载，半成品会立刻污染你的 agent 列表。

## 四、判定标准（决定产出质量的关键）

让 AI 按这个筛，否则它会给你造出一堆没用的 agent：

| 观察到的模式 | 该变成什么 |
|---|---|
| 同一段约束/开场白重复 ≥3 次 | `AGENTS.md` 一行，**不是** agent |
| 同一个多步流程重复（先搜→再改→跑测试） | **command**（`/xxx`） |
| 需要不同权限边界（只读审查、禁止改文件） | **agent** ✅ |
| 需要不同模型（便宜模型干粗活） | **agent** ✅ |
| 只是输出格式偏好（中文、表格、先给结论） | `AGENTS.md` |
| 只干过一次的事 | 什么都不建 |

**核心判据：一个 agent 只有在“需要不同的权限或不同的模型”时才值得存在。** 只是“省一段提示词”的，应该是 command 或 AGENTS.md。绝大多数人第一步就错在这里，最后攒了十几个从不使用的 agent。

## 五、审核环节不能省

- AI 只写 `agents-draft/`，你 review 后手动移到 `agents/`
- 每个草案必须回答三个问题：什么时候该用它、它和 `build` 的区别、它省掉了什么
- 草案里写清 `description`（模型靠它决定派不派），否则建了也永远不会被调用
- 试用两周，用不上直接删

## 六、一个现实提醒

你现在只有 6 个会话、16 个 prompt、跨 3 个目录。**这个数据量跑出来的画像会很空**，大概只能得出“你喜欢中文回答”这种结论，而这个结论更该写进 `AGENTS.md`。

比较务实的路线：

1. 现在先建好 `/distill` 和 `profiler`，跑一次，看看流程通不通（哪怕结论很薄）
2. 攒 2～3 周真实使用，每周跑一次
3. 当某个候选连续两周都出现，再把它转正

---

现在我在 Plan 模式，不能写文件。**你 `Shift+Tab` 切到 Build，我就把这四个东西建好，并用你的真实会话跑一遍**，给你看看第一版候选长什么样（大概率会先建议你往 `AGENTS.md` 补两条，而不是造 agent）。要不要顺便让它按项目目录分开分析？你现在三个目录的工作内容明显不同，项目级 agent 可能比全局的更有用。

## 🙋 我

看来我觉得短期agnet.md更适合我呢

## 🤖 AI

这个判断是对的。以你现在的使用阶段，`AGENTS.md` 的投入产出比最高：它不需要额外搭建环境、不涉及权限配置，改一行就生效。而且你 80% 想放进 agent 的内容，本质上都只是偏好和约束，本来就该放在这里。

我先说三个关键事实，它们会影响你怎么写：

- 全局文件是 `~/.config/opencode/AGENTS.md`，**每次请求都会注入**，所以它的体积就是持续成本
- 项目根目录的 `AGENTS.md` 只在对应目录被读取时才加载，越靠近代码越划算
- V2 **只认 `AGENTS.md`**，不再回退读 `CLAUDE.md`；并且多个文件是「合并」关系，不会覆盖，也不会替你解决冲突

## 写什么、不写什么

| 放进去 | 例子 |
|---|---|
| 稳定不变的偏好 | 中文回复、报错原文不翻译（你已经有了） |
| 可执行的断言 | 改完 TS 要跑 `bun typecheck`；不要直接改 `dist/` |
| 项目事实 | 后端在 `apps/api`，数据库迁移用 `drizzle` |
| 反复纠正过的错误 | “别用 `Get-ChildItem -Recurse` 扫全盘，太慢” |

| 别放进去 | 原因 |
|---|---|
| “写高质量代码”“注意安全” | 模型无法执行这种表述，只会变成无关内容 |
| 只在一个任务里用一次的流程 | 那是 command |
| 需要禁止改文件的场景 | 那是 agent（靠权限边界，`AGENTS.md` 只是文字建议） |
| 大段代码范例 | 占用上下文，改成指向文件路径 |

判断标准很简单：**`AGENTS.md` 里的每一条，都应该能被验证是否遵守了。** 写“简洁”是无效的，写“函数超过 40 行就拆”才是可执行的。

## 分层写法

**全局**（`~/.config/opencode/AGENTS.md`）：只放跨项目的东西，控制在 **10～15 行**。你现在这 3 条就不错，保持克制。

**项目**（`<项目根>/AGENTS.md`）：放构建命令、目录结构、禁改文件、提交规范。这个可以写长，因为只有打开那个项目时才会加载。

你有三个工作目录（`C:\Users\Eojnus`、`C:\Coding`、`Documents\默认项目`），三个项目的规矩显然不同，所以项目级比全局级更值得写。

如果某个项目还有独立的规范文档，也可以用 `instructions` 挂进来，不用把内容复制进 `AGENTS.md`：

```jsonc
{
  "instructions": ["CONTRIBUTING.md", "docs/guidelines/*.md"],
}
```

## 一个项目模板

```md
# 项目说明

## 技术栈
- 前端 React 19 + Vite，后端 Hono，包管理用 pnpm

## 常用命令
- 开发：`pnpm dev`
- 类型检查：`pnpm typecheck`（改完 TS 必须跑）
- 测试：`pnpm test -- <文件>`

## 约定
- 数据库查询集中在 `src/db/`，不要在路由里直接写 SQL
- `src/generated/` 是生成的，不要手改
- 提交前跑 `pnpm lint`

## 环境
- Windows + PowerShell，不要给 bash 专有语法
```

最后一条对你有实际价值：AI 默认经常生成 `&&`、`rm -rf`、`export FOO=1` 这类 PowerShell 不认或行为不同的写法。

## 三周推进节奏

**第 1 周**：全局文件保持不动，给最常用的那个项目先写一份 `AGENTS.md`。

**第 2 周**：观察有没有哪句话你**每次开新会话都要重复说**。有，就补进去。

**第 3 周**：回头看。如果发现某段内容变成了“先 A 再 B 再 C”的固定三步，那它是 command；如果发现你想要的是“这个模式下禁止改文件”，那才是 agent。

## 验证写对了没

开一个新会话，直接问：

> 根据 AGENTS.md，这个项目改完代码要跑什么命令？哪些目录不能动？

答不出来，说明文件没被加载，或者路径放错了；答得出来但答错了，说明写得太含糊。

另外一个实用细节：改全局或上层目录的 `AGENTS.md`，下一个请求就生效，不用重开会话；但**已经加载过的嵌套 `AGENTS.md`** 改完要开新会话才生效。

---

要不要我在你切到 Build 后，先扫一遍 `C:\Coding` 和 `Documents\默认项目` 的实际结构，各写一份项目级 `AGENTS.md` 初稿？这比空想模板准得多。全局那份我建议先别动。

## 🙋 我

你去只读参考一下吧，然后给我agentmd初稿，不要改动任何文件

## 🤖 AI

只读看完了，`C:\Coding` 下两个目录、`Documents\默认项目` 是空的。有几个发现值得你先知道，因为它们直接决定了草稿怎么写。

## 一、三个地方写的版本号互相打架

| 位置 | 存档格式版本 |
|---|---|
| 代码 `src/content/config.ts:731` | **19** |
| `README.md` | v18 |
| `AGENTS.md`（v0.4 段） | **10** |

同一个项目，三个数字。任何 AI 读到 `AGENTS.md` 里的 10，都会拿错迁移基线。这不是笔误，是这类文档的必然结局——**只要求写“当前状态”的文档，一定会烂**。

## 二、你的项目 `AGENTS.md` 已经 202 行 / 15KB

它第 3～6 行自己写着：

> 本文后面的「v0.3 边界」「v0.4 说明」等段落是历史记录，已经完成的功能不再是本轮禁止项。

也就是说，文件已经需要一段“免责声明”才能读懂了。15KB 中文大约 **4000～5000 tokens**，每次请求都注入一次。你 116 步的用量里，有相当一部分是在反复读一份过期文档。

## 三、两个目录是同一份代码的新旧副本

`AGENTS.md` 只差 18 行（正好是 v0.4 资本系统那段），其余结构一致。`塔科夫之狼V0.3.4` 是冻结快照，但目录里没有任何标记说明这一点，AI 进去会当成活项目改。

## 四、一个小问题

`start.ps1` 头部注释还写着「云港市 · 本地启动脚本」，`start.cmd` 写「Cloudport City」，而 `BRANDING` 是「塔科夫之狼 / 塔科夫市」。`src` 里已经没有「云港」了，只剩启动脚本的注释。不影响运行，但和你的“命名单一来源”约定不一致。

---

# 草稿 A：全局 `~/.config/opencode/AGENTS.md`

你原有 3 条保留，下面标了新增。**总共 ~20 行**，这是它该有的体量。

```md
# 全局偏好

## 语言
- 始终使用简体中文回复，除非我明确要求其他语言。
- 代码、命令、文件路径、报错原文保持原样，不要翻译。
- 思考语言不设限制，不要求用中文推理。

## 环境
- Windows + PowerShell。给命令时不要用 bash 专有语法（`&&`、`export FOO=1`、`rm -rf`、`$(...)`）。
- 按项目锁文件选择包管理器（有 `package-lock.json` 就用 npm），不要混装。
- 路径含中文或空格时加引号。

## 回答方式
- 先给结论，再给依据；不要复述我已经知道的背景。
- 未验证的结论标注「未验证」，不要把推测写成事实。
- 涉及多个文件时，先列出要动的文件，再动手。

## 工作方式
- 进入项目先读项目根的 `AGENTS.md`，遵守其中的约束。
- 改代码前先读相关文件，不要凭文件名猜实现。
- 只改与任务相关的文件；不顺手重构、不批量格式化。
- 跨模块改动、换依赖、改数据结构，先给方案再实施。

## 验证与声明
- 区分并如实说明：代码审查通过 / 类型检查通过 / 构建通过 / 实际运行验证 / 需要我自己验收。
- 禁止把没跑过的验证说成「已测试」。
- 命令失败时先贴原始报错，再给修复建议。

## 危险操作
- 未经我明确要求，不执行 `git reset --hard`、`git push --force`、删除目录、批量改写。
- 提交前先看 `git status`，不要把无关改动一起提交。
```

**为什么不加更多**：每加一条都要付“无关任务里的噪音”成本。比如“函数不超过 40 行”对游戏代码合适，对写脚本就是负担——这种应该进项目文件。

---

# 草稿 B：项目 `C:\Coding\wolf-city-block-realism\AGENTS.md`（重构版）

这是替换版，不是追加版。**202 行 → 约 85 行**，核心改动是：**把“当前版本状态”全部赶出去**，只留长期成立的规则。

```md
# AGENTS

本文件只写长期有效的规则。版本相关的决策进 `docs/decisions.md`，
接口与结算细节进 `docs/contracts.md`，模块职责进 `docs/architecture.md`。
冲突时以这三份文档为准，本文件只做约束和索引。

**维护规则：不要在本文件里写具体版本号、`formatVersion` 数值、或「本轮做什么」。
写完就该过期的东西，一律写进 `docs/decisions.md`。**

## 项目

- 《塔科夫之狼》：单人 3D 城市生活 / 创业经营 / 资本投资模拟，浏览器本地运行，无后端、无联机。
- 技术栈：Three.js + TypeScript（strict）+ Vite + 原生 HTML/CSS + IndexedDB。
- 环境：Windows + PowerShell；npm 与 `package-lock.json`；Node 20.19+ 或 22.12+。

## 命令

| 用途 | 命令 |
| --- | --- |
| 安装依赖 | `npm ci` |
| 开发（5173） | `npm run dev`，或双击 `start.cmd` |
| 类型检查 | `npm run typecheck` |
| 构建（含 typecheck） | `npm run build` |
| 预览构建产物（4173） | `npm run preview` |
| 局部验证 | `npx tsx scripts/smoke.ts` |

- 没有 lint、没有测试框架、没有 `npm test`。不要引入。
- `scripts/smoke.ts` 是一次性验证脚本，不是回归套件；不要扩建它的覆盖面。
- `dist/` 必须经 HTTP 访问，不要直接双击 `dist/index.html`。
- 构建与局部验证通过 ≠ 游戏体验已验证。

## 目录职责

| 目录 | 职责 |
| --- | --- |
| `src/core/` | 时钟、日历、金钱、状态容器、只读类型。纯逻辑，不含业务 |
| `src/features/<模块>/` | 业务切片：状态 + 纯函数，按模块隔离 |
| `src/app/` | 跨模块编排、玩家命令、结算顺序、视图模型 |
| `src/world/` `src/ui/` | 表现层：场景、HUD、面板、样式 |
| `src/content/config.ts` | 所有数值参数与 `BRANDING` |
| `src/infrastructure/` | 存档读写、数据库、迁移、校验 |
| `docs/` | 架构、契约、决策、尺度约定 |

业务优先在 `src/features/<模块>/` 内完成；跨模块协调只写在 `src/app/`；
表现层可自由修改，但不得读写经济状态，只调用命令、只渲染视图模型。

## 硬性禁止

**时间与经济**
- 禁止绕开 `app/timeAdvance.advanceGameTime` 推进时间；所有入口（自然流逝、上班、休息、睡觉）共用同一执行顺序。
- 禁止用 `setInterval` / `setTimeout` 驱动行情、计息、月结；只认游戏分钟。
- 禁止让渲染帧率决定经济结果。
- 禁止把「打开业务面板」当作暂停：面板只锁人物操作，模拟继续。
- 禁止绕过 `features/finance` 直接改余额；跨模块一律经 `src/app/` 编排，不得互读内部数据。
- 禁止用全局事件总线隐式串联扣款、发薪、房租、行情。

**模块边界**
- 禁止在 `src/core/` 引入业务模块、Three.js、DOM 或浏览器存储。
- 禁止为未来系统预埋空壳类、假接口、占位状态。

**资源与命名**
- 禁止内联数字，参数一律进 `src/content/config.ts`。
- 禁止在其他文件写死品牌名、城市名或派生设施名，一律引用 `BRANDING`。
- 禁止使用许可证不清晰的第三方资源；「免费下载」不等于允许使用。新增资源同步更新 `public/assets/SOURCES.md`（来源、作者、许可证、署名要求）。

**存档兼容**
- 存档格式版本以代码中 `SAVE.formatVersion` 为准，**不要信任任何文档里写的数字**。
- 禁止改存档 `format`、IndexedDB 名称 / 仓库 / 键、公司 id、账户 id、股票代码、交互 id、资源路径。
- 禁止对整个存档 JSON 做字符串全局替换；公司名、产品名、流水备注等玩家自定义文字原样保留。
- 禁止在没有真实格式变化时写空迁移框架；有变化时迁移函数与校验器必须同时更新，且迁移链完整保留。

## 改前必须停下来确认

1. 需要改变 `src/core/` 的职责边界（例如让核心知道工资、房租、账号）。
2. 需要新增或修改公共接口签名，且波及两个以上业务模块。
3. 需要引入新框架、状态管理库、物理引擎、ECS、依赖注入容器、事件总线。
4. 需要改变存档格式版本。

提出时说明：问题、影响范围、最小修改建议，然后等待确认。

## 测试原则

「非必要不测试、必要时最小范围测试」：

- 不做全流程回归、长时间模拟、性能压测、多浏览器矩阵测试。
- 不为简单界面、配置、可直接判断的逻辑写测试；不追求覆盖率。
- 修复后只验证受影响的最小范围。
- 交付前**必须**跑一次 `npm run typecheck` 与 `npm run build`；只有失败时才在修复后重跑。
- 资金原子性、重复月结、跨月归属、存档恢复优先用代码审查确认；有具体疑点时才写一次性局部验证，验证脚本用完即删。

## 交付要求

- 必须如实区分：代码审查完成 / 类型检查通过 / 构建通过 / 实际执行过局部验证 / 留给用户运行验收。
- 禁止宣称未实际验证的功能「已测试通过」。
- 修改核心或接口时，同步更新 `docs/architecture.md`、`docs/contracts.md`、`docs/decisions.md`。

## 现行不变量（摘要，细节见 contracts）

- 只有 `store.run(draft => …)`、初始化与迁移可以写状态；`state` 与订阅回调是 `DeepReadonly<GameState>`，不得用 `any` 或双重断言绕过。
- 查询路径不得补建状态：用 `techViewOf` / `holdingViewOf`；`ensureTechCompany` / `holdingOf` 只出现在草稿、初始化、迁移里。
- 余额变更一律经 `transferFunds`；消费预留只能用 `transferReservedFunds(..., reservationRef)`；`releaseFunds` 只释放指定单据。
- 股份所有权看 `equity`；游戏速度看 `clock.speed`（`settings.speed` 只是兼容镜像）。
- 日界 / 月界一律用 `dateAtMinute` 判断（`minuteOfDay === 0`），不得用累计分钟整除，也不得靠改起始时间绕开。
- 产品属性两个口径不得混用：市场销量用加权品质 Q，发布冲击用等权平均 A。
- 在售股份只有 `stock.forSaleShares(market, 做市库存)` 一个口径。
- 界面草稿只存在内存，不进 `GameState`、不进存档；结构指纹不变时原地更新，不靠冻结整栏或延长刷新间隔掩盖问题。
- 不可逆操作（清算等）必须有一次明确确认，确认逻辑放 `app` 层，业务层执行时仍需重新校验。
```

## 被踢出去的内容去哪了

| 原段落 | 行数 | 去处 |
|---|---|---|
| v0.3 科技企业经营边界 | 28 | `docs/decisions.md`（标为已完成阶段） |
| 本轮新增的检查纪律 | 9 | 合并进"测试原则" |
| v0.3.3 追加约定 | 14 | 品牌 / 存档兼容 → 上面"硬性禁止"；其余进 decisions |
| v0.4 资本系统（含 formatVersion 10） | 50 | `docs/contracts.md` 已覆盖；只留一句指针 + 摘要 |
| 角色（架构师 GPT Work / 实现负责人） | 6 | 删除 |

**角色那段我建议直接删**：它描述的是“谁负责”，对 agent 的行为没有任何约束力，纯占上下文。你现在也没有按那个分工在跑。

---

# 草稿 C：旧副本 `C:\Coding\塔科夫之狼V0.3.4\AGENTS.md`

整个替换成这几行即可：

```md
# AGENTS

> **冻结副本，仅供历史参考，不再开发。**

- 这是 v0.3.4 的代码快照，不要在本目录实现新功能或修 bug。
- 需要改动请去 `C:\Coding\wolf-city-block-realism`（当前分支 `feature/city-block-realism`）。
- 本目录的规则已过期（缺 v0.4 资本系统），一切以主目录为准。
```

---

## 落地说明

我没有修改任何文件。要写的话是三个路径：

```
~/.config/opencode/AGENTS.md                              ← 草稿 A（你原有 3 条保留）
C:\Coding\wolf-city-block-realism\AGENTS.md               ← 草稿 B（替换）
C:\Coding\塔科夫之狼V0.3.4\AGENTS.md                      ← 草稿 C（替换）
```

两点建议：

1. **草稿 B 先别直接覆盖**。它是从你原文压缩的，但删了 100 多行，你自己得扫一遍确认没删掉你还在用的规则。要更稳的做法是先把原文件复制成 `docs/agents-history.md` 存档，再替换。
2. `Documents\默认项目` 是空的，**先别放 `AGENTS.md`**。空目录里写规则，等你真开始做东西时全是错的。

要我把这三份写进去吗？切到 Build 我就动手（草稿 B 会先备份原文）。

## 🙋 我

算了，先用opencode默认的agent好了

## 🤖 AI

可以，这是最省心的选择。默认的 `build` + `plan` 对单人开发项目完全够用，先跑起来比先搭体系重要。

就两点提醒：

- `AGENTS.md` 跟 agent 是两回事，**不管你用哪个 agent 它都会注入**。所以你项目里那份 15KB 的文件仍然会生效——它不会因为“用默认 agent”就消失。哪天觉得上下文变慢或 AI 老引用过期规则，再回头处理它。
- 上一轮的三份草稿留在对话里，不会丢。真要用了直接说一声。

有别的需要随时叫我。

## 🙋 我

我用opencode的免费deepseek4.1 flash 只有200k上下文窗口啊，这是否会对我的开发有影响呢？比如刚才给你看的项目，是不是每次做一个小改动就要开个新窗口来

## 🤖 AI

200k 够用，而且你担心的方向不太对。真正的约束不是“窗口多大”，是“单次往里塞了什么”。

我确认了你的实际配置：`ctx=200000`，`output=32000`。也就是说可用输入大约 168k。

## 先算你的固定开销

| 项目 | 估算 tokens |
|---|---|
| 系统提示 + 工具定义 + 技能清单 | 8–12k |
| 全局 `AGENTS.md`（3 行） | ~0.2k |
| **项目 `AGENTS.md`（15KB）** | **~4k** |
| 单次读 500 行 TS | ~6k |
| 一次 grep 结果 | 2–5k |
| 工具输出单次上限（51KB） | ~17k |
| **`contracts.md` 全文（100KB）** | **~25k** |
| `architecture.md` 全文（53KB） | ~13k |
| `decisions.md` 全文（86KB） | ~21k |

一次普通改动：15k 基线 + 6k 读文件 + 5k 搜索 ≈ **26k**，还剩 140k。这个余量聊一整天都够。

**危险场景是这样的**：AI 为了改一个结算函数，把 `contracts.md` 和 `architecture.md` 整份读了（38k），再 grep 三次全仓库（15k），再读五个文件（30k）——一口气 100k 没了，然后开始 compaction，细节全丢。

所以问题不在 200k，在**读法**。

## 三个真实风险（按严重程度）

**1. 整读大文档**

你三份 docs 加起来 240KB ≈ 60k tokens。让 AI“看看 contracts”它就真会整份读，一次吃掉 15% 窗口。

正确姿势：指名章节。

```
只读 docs/contracts.md 里「十五、资本契约」那一段，不要读全文
```

你的文档有 28 个 `##` 章节，本来就是给分段读准备的。

**2. 工具输出**

默认单次工具结果上限 51KB ≈ 17k tokens。我上一轮那条 `session export` 返回 150KB，被截断后还是塞进来约 40k tokens——**一次调用就吃掉五分之一窗口**，而且里面大部分是无用内容。这条教训很实在。

**3. compaction 丢细节**

到阈值会自动压缩，默认只保留最近约 15k tokens 原文，其余变摘要。结论会留下，**精确的函数名、字段名、你强调过的“禁止绕开 X”会丢**。

这也解释了一件事：为什么关键约束要写在 `AGENTS.md` 里而不是靠对话记忆——文件在磁盘上，压缩不会动它。所以那份 15KB 的文件虽然贵，但它是“抗压缩”的；只是里面一半是过期内容，性价比才低。

## 什么时候该开新会话

不是“每个小改动”，是**按任务分窗**：

| 情况 | 处理 |
|---|---|
| 同一个功能、同一批文件，连续改 | 留在当前会话 |
| 一个功能做完了，去改不相关的模块 | **开新会话** |
| 要换一个项目目录 | 开新会话 |
| AI 开始重复问你回答过的、或引用过期版本号 | 立刻开新会话，别抢救 |
| 会话已经很长（`<leader>s` 看状态） | 主动 `<leader>c` 压缩，或开新的 |

经验值：**一个会话专注一个功能**，通常 30–60 分钟，做完了就换。你现在的量级（116 步 / 6 会话）其实很正常。

## 四个能立刻省一半上下文的做法

1. **探索和实现分两个会话**。`plan` 里翻代码、读文档，方案确认后开新会话让 `build` 执行。探索产生的几十个文件读取全留在那个会话里，不带进实现。
2. **搜索交给子 agent**。“用 explore 找出所有处理月结的地方，只给我文件路径和函数名”——它翻文件的过程不进你的主会话，只回摘要。
3. **读文件带范围**。“读 `timeAdvance.ts` 的 1–80 行”比整读省 70%。
4. **别让它整读 docs**，指名章节。

## 回到你的问题

> 是不是每次做一个小改动就要开个新窗口

不用。小改动连续做，一个会话能撑很多轮。你真正该改的习惯是：**别让 AI 一口气读三份大文档、别让它翻遍整个仓库**。

顺便说，这也是上轮那个项目 `AGENTS.md` 值得瘦身的原因——不是为了省那 4k，是因为那 4k 里有 2k 是错的（版本号 10 vs 实际 19），错的上下文比没有上下文更贵。

## 🙋 我

可以把这个上下文窗口改大嘛，嘿嘿

## 🤖 AI

窗口大小是**模型属性**，客户端改不了——你不能把 200k 调成 400k，那是服务端决定的。

但你的模型列表里**有免费的 1M 窗口模型**：

| 模型 | 上下文 | 输出上限 | 价格 |
|---|---|---|---|
| `opencode/beam-free` | **1,048,576** | 131k | 免费 |
| `opencode/nemotron-3.5-super-vl-free` | **1,048,576** | 131k | 免费 |
| `opencode/nemotron-3-ultra-free` | 1,000,000 | 128k | 免费 |
| `opencode/nemotron-3.5-lightning-free` | 262,144 | 262k | 免费 |
| `opencode/flint-40b-free` | 262,144 | 65k | 免费 |
| `opencode/deepseek-v4.1-flash-free` | 200,000 | 32k | 免费 ← 你现在这个 |

换法两种：

- 会话里按 `Ctrl+X` 再按 `M` 打开模型列表，直接选
- 或写进 `~/.config/opencode/opencode.json` 当默认：

```jsonc
{ "model": "opencode/beam-free" }
```

换模型不丢当前会话的历史。

## 不过先别急着换

**1. 长上下文的质量会衰减**

这是所有模型的通病（lost in the middle）：塞 800k 进去，模型对中间那段内容的注意力明显弱于开头结尾。1M 窗口的实际有效区间通常远小于 1M。**窗口大 ≠ 记得住**。

**2. 延迟**

一次请求要 prefill 几十万 tokens，首字延迟会从几秒变成几十秒。免费模型本来就有排队，叠起来体验会很差。

**3. 你的问题不是窗口不够**

上一轮算过：你一次普通改动占 26k / 168k，用了 15%。真正吃掉上下文的是“整读三份 docs”和“一次 150KB 的 export”，这两个换 1M 也一样会发生——只是从“第 3 次才炸”变成“第 12 次才炸”。

## 什么时候 1M 真的有用

只有一种场景值得：**需要一口气看整个代码库的任务**。比如：

- 全仓库审计“有没有绕过 `advanceGameTime` 推进时间的地方”
- 大规模重命名/迁移
- “把这个 128 文件的模块职责重新梳理一遍”

这种任务你现在用 `explore` 子 agent 分批做也行，只是慢一点。

## 我的建议

**主力继续用 deepseek-v4.1-flash**，它输出上限 32k、上下文 200k，对日常改动绰绰有余，而且它在你这个项目上已经跑出上下文了（缓存命中率看着不错，`cache.read` 是 `input` 的 9 倍）。

**遇到“要吞整个仓库”的活，临时按 `Ctrl+X` `M` 切到 `beam-free`**，做完切回来。免费模型之间切换没有成本。

顺便说，编码能力我没法从 API 字段判断，`nemotron` 那几个偏通用多模态，实际写代码行不行得你自己试一轮。想试的话给个明确的小任务对比一下，别拿关键重构去试。

## 🙋 我

opencode有没有什么插件之类的，让这个变得更好用

## 🤖 AI

你已经是 `v2.2.0`，**零插件**，内置 30 个插件在跑（`opencode plugin list --builtin` 能看到全部）。

先说个反直觉的结论：**你想要的“更好用”，大部分不在插件里，在内置配置里。** 插件是加新能力（新工具、新面板、hook），不是修配置。很多人装了一堆插件，其实只是没开 `formatter`。

## 一、先开这四个内置配置

针对你现在的情况（200k 窗口 + 15KB AGENTS.md + 单人大项目），性价比排序：

```jsonc
// ~/.config/opencode/opencode.json
{
  "$schema": "https://opencode.ai/config.json",

  // 1. 压缩工具输出上限。默认单次 2000 行 / 51KB ≈ 17k tokens
  //    降到 400 行，最坏情况省一半以上
  "tool_output": { "max_lines": 400, "max_bytes": 20000 },

  // 2. 压缩时多留点原文，少丢细节
  "compaction": { "auto": true, "keep": { "tokens": 20000 } },

  // 3. 权限护栏：生成物不许改，危险命令要问
  "permissions": [
    { "action": "edit", "resource": "dist/**", "effect": "deny" },
    { "action": "edit", "resource": "node_modules/**", "effect": "deny" },
    { "action": "shell", "resource": "git push *", "effect": "ask" },
    { "action": "shell", "resource": "rm -rf *", "effect": "ask" }
  ],

  // 4. 后台写压缩摘要，压缩时不卡）
  "experimental": { "background_compaction": true }
}
```

第 3 条对你项目特别有用——`dist/` 是构建产物，`AGENTS.md` 里写了不能改，但那是文字约束；`permissions` 是硬约束，AI 根本调用不了。

`formatter: true` 我**不建议**开：你项目没有 prettier/eslint，开了也是空转。

## 二、插件能加什么

| 类型 | 能力 |
|---|---|
| **Server 插件** | 新工具、拦截/改写工具调用、会话生命周期 hook、RPC 给外部调用 |
| **TUI 插件** | 改界面、加面板、加命令、快捷键 |
| **GUI 插件** | 桌面端加面板和设置项 |
| 注册项 | 插件可以自带 agent、command、skill |

装法：

```sh
opencode plugin add opencode-xxx      # 全局
opencode plugin list                  # 看装了啥（你现在是 No plugins found）
```

也可以直接扔文件进去，**自动发现不用配置**：

```
~/.config/opencode/plugins/*.ts       # 全局
.opencode/plugins/*.ts                # 项目级
```

## 三、三个必须知道的坑

**1. V2 换了插件 API**

V2 的破坏性变更只有两个：服务端 API 和**插件 API**。所以 GitHub 上大量 opencode 插件是 V1 时代的，装上去不报错但**完全没反应**。装完一定要 `opencode plugin list` 确认真的加载了。

**2. 没有官方插件商店**

官方文档只讲怎么装、怎么写，没有目录。找插件只能靠 npm / GitHub 搜 `opencode plugin`。这意味着质量参差。

**3. 插件能执行任意代码**

它跑在你的 shell 权限里，能读写文件、能发网络请求。只装你看得懂源码的，或者别人推荐的。

## 四、针对你，我建议的其实是“自己写”的插件

你的需求很具体，现成的多半对不上。三个候选，按性价比排：

**A. 改完 `.ts` 自动 typecheck，把错误直接回灌给 AI**

你项目 `tsconfig` 是 strict + `noUnusedLocals`，AI 经常写出未使用变量、类型不匹配，要来回两轮才发现。这个 hook 能让它在提交前自己看到错误。**对你收益最大。**

**B. 会话结束/任务完成时系统通知**

你在等它改 128 个文件里的某个模块时，会切窗口。通知能省很多来回切。

**C. TUI 面板显示当前上下文用量**

直接看到“还剩多少”，比 `<leader>s` 翻一层更直观。你关心 200k 的话这个挺对症。

## 五、还有一个不是插件的办法

如果你想要的是“AI 记住我做过的决定”，那不该用插件，用 **`docs/decisions.md`** ——你已经有了，86KB。插件的记忆不可靠，文件可靠。

---

要我写哪个？我建议从 **A** 开始：本地 `.ts` 文件扔 `~/.config/opencode/plugins/`，几十行，不联网、不依赖任何包、你自己能读懂。要动手就说一声，我连同配置一起给你，改完不用重启（watch 会自己重载）。

## 🙋 我

就来一些TUI插件吧，你从github上给我找几个star数高的我看看，先不要安装

## 🤖 AI

没装，只查了。下面按 star 排序，都是 **TUI 插件**（终端界面类），并标注了 V2 兼容性——这个最关键，因为 V2 换过插件 API，一堆老插件装上去不报错但没反应。

## V2 可用的 TUI 插件（按 star）

| Star | 项目 | 干什么 | V2 状态 | 最近推送 |
|---|---|---|---|---|
| 1067 | [slkiser/opencode-quota](https://github.com/slkiser/opencode-quota) | 侧边栏 + 用量窗口：配额、token、成本、上下文占用 | ✅ README 明写 "Built for OpenCode 2" | 10-28（今天） |
| 856 | [mohak34/opencode-notifier](https://github.com/mohak34/opencode-notifier) | 完成/报错/需要授权时响铃 + 系统通知 | ✅ 明写 V2 用法 | 10-24 |
| 311 | [Hotakus/opencode-visual-cache](https://github.com/Hotakus/opencode-visual-cache) | 实时缓存命中率侧边栏 + 底部状态栏（命中原生主题色，中文） | ✅ 明写同时支持 1.x / 2.x | 09-30 |
| 135 | [Hotakus/opencode-subagent-magazine](https://github.com/Hotakus/opencode-subagent-magazine) | 子 agent 实时监控侧边栏，像弹匣一样显示进度 | ✅ 明写支持 2.x | 10-08 |
| 118 | [lkonga/opencode-retitle](https://github.com/lkonga/opencode-retitle) | `/retitle` 重新生成会话标题（`ctrl+shift+r`） | ✅ 以 V2 为主实现 | 10-24 |

## V2 存疑（能用但没跟上，慎装）

| Star | 项目 | 问题 |
|---|---|---|
| 107 | [ishaksebsib/opencode-tree](https://github.com/ishaksebsib/opencode-tree) | 分支对话树视图。README 用 `opencode plugin <pkg>`（缺 `add`）和 `tui.json` 配置，最后一次推送 5 月，像是 V1 时代文档 |
| 94 | [floze-the-genius/opencode-tps-meter](https://github.com/floze-the-genius/opencode-tps-meter) | 实时 TPS 表，纯 JS，7 月后没动 |
| 90 | [anomalyco/oc-plugin-rainbow](https://github.com/anomalyco/oc-plugin-rainbow) | 官方组织出的彩虹主题特效，4 月后没动，纯装饰 |

## 一个容易踩的坑

**TUI 插件不是装在 `opencode.json`，是装在 `cli.json`。**

```jsonc
// ~/.config/opencode/cli.json
{
  "$schema": "https://opencode.ai/v2/cli.json",
  "plugins": ["opencode-visual-cache", "@slkiser/opencode-quota"]
}
```

而且这类插件**不要用 `opencode plugin add`**——那条命令是给 server 插件用的。TUI 插件写进 `cli.json` 后，下次启动 opencode 会自动拉包加载。

顺带说，你现在 `cli.json` 里只有主题和 `animations`，`plugins` 是空的，加这一行不会影响现有配置。

## 不是 TUI，但对你更对症的一个

[**Tarquinen/opencode-dynamic-context-pruning**](https://github.com/Tarquinen/opencode-dynamic-context-pruning) —— **4437 star**，全榜最高。

它不在 TUI 分类里，但干的是你真正关心的事：**动态裁剪上下文**，把过期的工具输出自动清掉，而不是等 compaction 一把火烧掉细节。安装方式已经是 V2 语法：

```sh
opencode plugin add @tarquinen/opencode-dcp@latest
```

⚠️ 但 README 自己写了：**开发重心已经转到另一个产品 Sleev**，新功能不再进这个插件。所以它更像"稳定但半停更"，不是"活跃维护"。

## 我的建议：先看这三个

1. **opencode-quota** —— 你要盯 200k，这是最直接的仪表盘
2. **opencode-visual-cache** —— 你 `cache.read` 是 `input` 的 9 倍，命中率直接关系到花费和速度
3. **opencode-subagent-magazine** —— 如果你开始用 `explore` 子 agent 翻代码，能看见它在干嘛

**notifier 那个先别急**：它 README 里说 V2 已经内置了通知插件（`opencode.notifications`），装之前要先从 `cli.json` 里禁用内置的，否则双份提示。但你当前 v2.2.0 的内置列表里我没找到这一项（91 个内置插件全查了），说明它可能在更新的版本里才有——这条信息是 README 说的，不是我在你机器上验证到的，装之前值得先确认一下。

要我细看哪个的源码或者 README，或者等你想装了再动？

## 🙋 我

因为我没有电脑，要去网吧用电脑来code，所以每次都要换电脑用，我能不能把我的opencode像一个项目一样上传到github仓库呀，每次用新电脑时都可以直接从仓库把opencode拉进网吧的新电脑里

## 🤖 AI

可以，而且这件事的边界很清楚：**配置文件很小，值得同步；会话数据库绝对不能同步。**

我先查了你的实际情况：

| 路径 | 内容 | 大小 | 进仓库？ |
|---|---|---|---|
| `~/.config/opencode/` | AGENTS.md、opencode.json、cli.json、skills/ | **3.5 MB / 34 文件** | ✅ 全部 |
| `~/.config/opencode/service.json` | 本机服务注册信息 | 64 B | ❌ 机器相关 |
| `~/.local/state/opencode/model.json` | 上次选的模型 | 很小 | ✅ 可选 |
| `~/.local/state/opencode/prompt-history.jsonl` | 你输入过的所有 prompt | 未知 | ⚠️ 可能含密钥，别同步 |
| `~/.local/share/opencode/opencode.db` | **25 MB：全部会话 + 凭据** | 25 MB | ❌ 绝不 |
| `opencode.db-wal` | 同上，未落盘部分 | 15 MB | ❌ |
| `log/ shell/ tool-output/ repos/` | 缓存与日志 | — | ❌ |

关键点：**你机器上没有单独的 `auth.json`**，凭据在 `opencode.db` 里和会话数据混在一起。所以“同步数据库”就等于“把登录凭据和全部聊天记录一起推上 GitHub”。不行。

## 仓库结构

```
opencode-env/          ← 私有仓库
├─ config/
│   ├─ AGENTS.md
│   ├─ opencode.json
│   ├─ cli.json
│   ├─ skills/         （3.5MB，直接 git 就好，不用 LFS）
│   ├─ agents/         （现在没有，先留空目录）
│   └─ commands/
├─ bootstrap.ps1       ← 新电脑一条命令装好
├─ save.ps1            ← 回到旧电脑时把改动推上去
├─ .gitignore
└─ README.md
```

## bootstrap.ps1（新电脑上跑这个）

```powershell
# 用法：把仓库 clone 到任意目录，然后 .\bootstrap.ps1
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$dest = Join-Path $env:USERPROFILE '.config\opencode'

# 1. opencode 本身
if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    throw '没找到 Node/npm，先装 Node LTS：winget install OpenJS.NodeJS.LTS'
  }
  npm install -g @opencode/cli
}

# 2. 配置
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item "$repo\config\*" -Destination $dest -Recurse -Force
Remove-Item (Join-Path $dest 'service.json') -ErrorAction SilentlyContinue

Write-Host "配置已就位：$dest" -ForegroundColor Green
opencode --version
```

`save.ps1` 反着来：把 `$dest` 里的配置拷回 `config/`，排除 `service.json` 和插件状态目录，然后 `git add -A; git commit; git push`。

我已经查过你这台机器：opencode 是 `npm i -g @opencode/cli` 装的（二进制在 Node 目录里），Node 24.20.0，git 和 gh 都有。所以新机器上**先装 Node** 是唯一的前置条件。

## 网吧环境的三条硬提醒

**1. 凭据别进仓库，哪怕 private**

GitHub 有 secret scanning，会直接拒推。而且 private 仓库一旦误设成 public、或者你某次 `git log` 贴出去，账号就没了。

正确做法：**每台新机器 `opencode auth login` 重新登一次**，不要同步任何 token。

**2. 仓库用 private，PAT 用细粒度**

clone 私有仓库要认证，Windows 的 Git Credential Manager 会把 token 存进系统凭据管理器。走人前记得：

```powershell
cmdkey /list | findstr git
git credential-manager erase
```

或者用 **fine-grained PAT，只授权那一个仓库、只给 Contents 读权限**，过期设 7 天。

**3. 网吧机器可能装不上**

- Node 装不了（无管理员权限）→ 用 Node 的 zip 便携版，解压到用户目录，`$env:PATH` 临时加进去
- 网吧有还原卡 → 你的配置重启就没，所以**每次都要跑 bootstrap**，这也正是这个方案的价值
- USB 被禁用 → 只能走 GitHub

## 会话历史怎么办

不同步数据库 = 每次都是全新会话，没有 `/resume`，看不到上次聊到哪。

三个选择：

1. **接受**（我推荐）：靠 `docs/decisions.md` 记结论，而不是靠聊天记录。你项目里已经有这个习惯了。
2. **手工导出**：重要会话用 `Ctrl+X` `X` 导出成 md，提交进项目仓库当笔记。
3. **同步 DB**：技术上可行（关掉 opencode 后拷 `opencode.db`），但 25MB 且含凭据，每次都是二进制冲突。不建议。

## 一个可能更省事的替代：U 盘

如果网吧允许插 U 盘：

```
U盘/
├─ opencode/        ← 便携版 opencode
├─ config/          ← 同一套配置
└─ projects/        ← 项目
```

插上就能跑，配置和凭据都不落在网吧机器上，也不用每次 clone。缺点是 U 盘丢了全没，而且要确认网吧不禁 USB。**这个方案安全性和速度都优于 GitHub 方案**，只是依赖 U 盘。

---

现在 `gh` 没登录（`You are not logged into any GitHub hosts`），所以我没法直接给你建仓库。

你可以选：

- **A**：我先把仓库骨架和两个脚本写到本地目录（`C:\Users\Eojnus\opencode-env`），你自己 `gh auth login` 之后推
- **B**：你先登录，我连仓库一起建好
- **C**：先做 U 盘方案，我帮你把便携目录搭起来

选哪个？另外提醒一句：脚本里我一律用 `$env:USERPROFILE`，不写死 `C:\Users\Eojnus`——网吧的账户名不会是这个。

## 🙋 我

我不太懂，你在简单扼要的给我说一遍，哪些是要上传的，能保存什么东西

## 🤖 AI

一句话：**能保存“你怎么用”，不能保存“你聊过什么”。**

## ✅ 要上传的（5 样，一共 3.5MB）

| 东西 | 是什么 |
|---|---|
| `AGENTS.md` | 你定的规则（中文回复那些） |
| `opencode.json` | 装了哪些插件、用哪个模型 |
| `cli.json` | 主题、快捷键 |
| `skills/` | 你装的 8 个技能 |
| `agents/`、`commands/` | 以后自己建的，现在还没有 |

这些放在 `C:\Users\Eojnus\.config\opencode\`，**整个文件夹打包上传就行**。

## ❌ 不要上传的

| 东西 | 为什么 |
|---|---|
| `opencode.db` | 25MB，**你的聊天记录和登录凭据都在里面** |
| 日志、缓存 | 没用 |

## 实际效果

**新电脑上**：装好 Node → 拉仓库 → 跑一个脚本 → 主题、规则、技能、插件全回来，跟原来一样。

**不会回来的**：以前的聊天记录，还有登录状态。登录要重新做一次（免费模型直接就能用，所以基本无感）。

## 你只需要做三件事

1. 建一个**私有**仓库（GitHub 上点 New repository，选 Private）
2. 上传 `.config\opencode` 文件夹（可以改名成 `config`）
3. 下次新电脑：clone → 跑脚本 → 开始写代码

其中第 3 步的脚本我给你写好，现在只差第 1 步——`gh` 没登录，我建不了仓库。

**要不要我先把脚本和文件夹在本地准备好？** 你登录 GitHub 之后推上去就行。

## 🙋 我

你帮我弄吧，要我提供什么呢

## 🤖 AI

我已经把本地部分都建好了，放在 `C:\Users\Eojnus\opencode-env`：

```
opencode-env/
├─ config/
│  ├─ AGENTS.md
│  ├─ opencode.json
│  ├─ cli.json
│  ├─ skills/           (8 个技能，3.4 MB)
│  ├─ agents/
│  └─ commands/
├─ bootstrap.ps1        新电脑一条命令恢复
├─ save.ps1             本机改动推回仓库
├─ .gitignore           挡掉 service.json、db、token
├─ .gitattributes
└─ README.md
```

**已经验证过的事：**

- 40 个文件、3.39 MB，git 已初始化（分支 `main`），全部暂存
- 敏感文件扫描：**零命中**（`service.json` 里那个 `password` 没进来，`opencode.db` 也没进来）
- 两个脚本用 PowerShell 语法解析器检查通过

> 顺带一个坑：`.ps1` 里写中文必须存成 **UTF-8 with BOM**，否则 PowerShell 5.1 会按 GBK 读，直接报“缺少右括号”的语法错误。我第一版就踩了，已经修好。

## 现在只差一步：登录 GitHub

在终端里跑：

```powershell
gh auth login
```

按提示选：

1. **GitHub.com**
2. **HTTPS**
3. **Login with a web browser**
4. 复制它给的 8 位码，浏览器里粘贴，授权

跑完告诉我一声。之后我来做剩下的：

- 读取你的 GitHub 用户名，配置 git 身份
- 提交（第一次 commit）
- `gh repo create opencode-env --private --source . --push` 建**私有**仓库并推上去

## 我需要你提供的

就两样：

| 需要 | 说明 |
|---|---|
| `gh auth login` 完成 | 必须，不然推不上去 |
| 仓库名 | 默认用 `opencode-env`，想换告诉我 |

**不要在聊天里贴 token 或密码**——`gh auth login` 的浏览器流程自己完成就行，我全程不需要看到任何凭据。

登录完说一声，我接着弄。

## 🙋 我

我想用 authentication token来登录，告诉我github网页去哪里找这个token

## 🤖 AI

Token 不需要“找”，需要**自己生成**，而且它只显示一次。

## 两个入口

| 类型 | 直链 | 适合 |
|---|---|---|
| **Classic** | https://github.com/settings/tokens/new | 能建新仓库，一次搞定 |
| **Fine-grained** | https://github.com/settings/personal-access-tokens/new | 更安全，但只能访问已存在的仓库 |

手动导航路径也一样：**右上头像 → Settings → 左侧最下面 Developer settings → Personal access tokens**。

## 方案 A：Classic（最省事，建议先用这个）

1. 打开 https://github.com/settings/tokens/new
2. **Note**：填 `opencode-env`
3. **Expiration**：选 **7 days**（别选 No expiration）
4. **Scopes**：只勾一个 **`repo`**（整块勾上，包含下面所有子项）
5. 拉到最底 **Generate token**
6. 页面上出现 `ghp_xxxxxxxx...`，**立刻复制**——刷新就再也看不到了

## 方案 B：Fine-grained（更安全，但要多一步）

1. 先去 https://github.com/new 手动建一个空仓库：名字 `opencode-env`，**选 Private**，不要勾 README
2. 打开 https://github.com/settings/personal-access-tokens/new
3. **Token name**：`opencode-env`
4. **Expiration**：7 days
5. **Repository access**：选 **Only select repositories** → 只勾 `opencode-env`
6. **Permissions** → **Repository permissions** → 找到 **Contents**，设成 **Read and write**
7. Generate

> Fine-grained token 通常**不能创建新仓库**（只能操作已存在的），所以方案 B 必须先手动建仓库。

## 拿到 token 后怎么登录

在你自己的终端里跑（**别贴给我**）：

```powershell
$t = Read-Host "粘贴 token" -AsSecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($t))
$plain | gh auth login --with-token
Remove-Variable plain, t
```

然后验证：

```powershell
gh auth status
```

看到 `Logged in to github.com account 你的用户名` 就成了。

## 两个提醒

**1. token 等同于密码**

它的权限等于你账号的权限。别存进任何文件、别提交、别发给别人（包括我）。用完可以在 https://github.com/settings/tokens 直接 Delete。

**2. 用完记得登出**

网吧机器上尤其重要：

```powershell
gh auth logout
```

---

登录完（`gh auth status` 通过）跟我说一声，我就接着做：配置 git 身份 → 首次提交 → 建私有仓库 → 推上去。

如果你走的是方案 B，顺便把仓库地址给我（形如 `https://github.com/你的用户名/opencode-env`），我直接用它当 remote。

## 🙋 我

我登录好了

## 🤖 AI

弄好了。仓库已建好并推送成功：

**https://github.com/eojnus/opencode-env**（Private ✅）

远端确认：`main` 分支、2 个提交、6 个顶层条目。

## 里面有什么

```
opencode-env/
├─ config/
│  ├─ AGENTS.md
│  ├─ opencode.json       （含你装的 quota 插件）
│  ├─ cli.json
│  ├─ skills/             （8 个技能，3.4 MB）
│  ├─ agents/
│  └─ commands/
├─ bootstrap.ps1          新电脑一条命令恢复
├─ save.ps1               本机改动推回去
├─ .gitignore
├─ .gitattributes
└─ README.md
```

没进去的：`service.json`（里面那个 password）、`opencode.db`、日志、缓存。

## 新电脑上怎么用

```powershell
git clone https://github.com/eojnus/opencode-env
cd opencode-env
.\bootstrap.ps1
```

跑完 `opencode` 就能用，配置、技能、插件全在。

## 以后改完配置

```powershell
cd C:\Users\Eojnus\opencode-env
.\save.ps1
```

## 过程中遇到的一个问题

你机器的全局 git 配了 `http.proxy = http://127.0.0.1:7890`（Clash 之类），但代理没开，所以第一次推送直接失败。我已经在 `save.ps1` 里加了 `-c http.proxy= -c https.proxy=` 绕过，顺手也在 README 写了排查说明。**你以后自己手动 push 也会撞上这个**，记得加那两个参数。

---

## ⚠️ 现在该做的一件事：处理那个 token

我刚看到你的 token 权限范围，比需要的大得多：

```
admin:enterprise, admin:org, admin:public_key, delete_repo, delete:packages, audit_log, ...
```

这等于把整个 GitHub 账号的钥匙交出去了（能删仓库、能改组织设置）。虽然只在这一台机器上，但网吧环境不值得赌。

建议：

1. 去 https://github.com/settings/tokens 把刚建的那个 **Delete** 掉
2. 需要的话重开一个：只勾 `repo`，7 天过期
3. 现在这台机器上跑一下：

```powershell
gh auth logout
```

> 注意：登出后 `save.ps1` 就推不上了，等你要用时再登录。留在这台公共电脑上的凭据越少越好。

## 最后提醒

- **聊天记录不在仓库里**，换电脑后是全新会话，这是故意的（DB 里有登录凭据）
- 新机器上如果 `opencode` 提示需要登录，跑 `opencode auth login`；免费模型一般不需要
- 前置条件只有 Node，网吧装不了 Node 的话先告诉我，我给你换成便携版方案

要不要现在顺手把 `bootstrap.ps1` 在这台机器上跑一遍做个回归测试？它会先备份现有配置再覆盖，安全。

## 🙋 我

能把聊天记录弄进去更好，说实话，聊天记录里毫无隐私存在

