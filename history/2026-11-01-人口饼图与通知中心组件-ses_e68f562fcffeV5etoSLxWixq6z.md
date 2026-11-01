# 人口饼图与通知中心组件

- 会话 ID：`ses_e68f562fcffeV5etoSLxWixq6z`
- 时间：2026-11-01 20:16
- 目录：`C:\Users\Administrator`
- 模型：`opencode-go/deepseek-v4.1-flash`

---

## 🙋 我

You are a subagent spawned by another session.
工作区：C:\CODING-worktrees\mechanisms-foundation（TypeScript + Phaser + Electron 的经济模拟游戏，桌面端 1100×700 到 1440×900）。只改本工作区，不运行 git 命令，不 npm install。

任务：实现两个**自包含** UI 组件（本轮不接入现有界面，下一轮由同一会话继续集成）。只创建/修改：`src/ui/charts/pie.ts`（新建）、`src/ui/notifications.ts`（新建）、`src/ui/styles.css`（只在文件末尾追加一节，不要改动已有规则）。

先读：`src/ui/panels.ts`（现有面板的 HTML/类名风格）、`src/ui/styles.css` 的变量与 `.hud`/`.rail`/`.panel`/`.toast` 样式、`src/ui/format.ts`（`esc`、`num`、`pct`、`money`）、`src/data/config.ts`（`ui` 节）。整体是深色、青绿+金色点缀的控制台风格，使用 Kenney 素材与 `Kenney Future` 字体；保持现有视觉语言，不要引入外部库或网络字体。

### 1. 人口饼图 `src/ui/charts/pie.ts`

导出：
```ts
export interface PieSegment { id: string; label: string; value: number; color: string; }
export interface PieInput {
  segments: PieSegment[];      // 互斥口径，调用方保证（就业/失业/非劳动力）
  total: number;               // 互斥口径合计
  centerLabel: string;         // 中心大数字，如 "12.0 万"
  centerCaption: string;       // 中心说明，如 "总人口"
  ariaLabel: string;
  note?: string;               // 口径说明，例如"就业 + 失业 + 非劳动力 = 总人口；劳动力与总人口不可相加"
}
export function renderPopulationPie(input: PieInput): string;
```
要求：
- 纯 SVG donut（环形）图，不要 canvas，不要第三方库；用 `<circle>` + `stroke-dasharray/stroke-dashoffset` 分段，段间留 1.5–2px 间隙；数值为 0 的段不渲染但仍出现在图例里（显示 0）。
- **动态**：数据变化时用 CSS transition 平滑过渡（对 `stroke-dasharray`/`stroke-dashoffset` 做 700ms ease-out）；首次渲染有轻微展开动画。用 `@media (prefers-reduced-motion: reduce)` 关闭所有过渡与动画。
- **悬停浮动**：鼠标悬停某扇区时该扇区沿角平分线向外平移 4–6px 并轻微加亮，其他扇区略微变暗；显示 tooltip：类别名、人数（千分位）、占比（1 位小数）。tooltip 必须用组件内部绝对定位的 HTML 元素（不要依赖 panel 外容器），并保证不被 `overflow:hidden` 裁掉（用 `position:fixed`? 不行——面板滚动时错位；用扇区 `<g>` 内 `foreignObject` 会麻烦。建议：SVG 外层 `position:relative`，tooltip `position:absolute`，并用 `pointer-events:none`，由 JS 在 `mouseenter/mousemove` 时定位；面板滚动时 tooltip 随内容移动是可接受的）。
- **可访问**：每个扇区 `tabindex="0"`、`role="img"`、`aria-label="就业 52,300 人，占 43.6%"`；键盘 focus 时同样高亮并显示 tooltip；`<svg role="group" aria-label>`；提供图例列表（类别色块、人数、比例），图例不依赖 hover 也能读到全部数据。
- 组件只返回 HTML 字符串，但 hover 需要事件：请在 `pie.ts` 中同时导出 `bindPieInteractions(root: HTMLElement): () => void`，由调用方在插入 innerHTML 后调用一次（返回清理函数）；实现用事件委托（`pointerover`/`pointerout`/`focusin`/`focusout`/`pointermove`），不要依赖全局单例。
- 颜色由调用方传入；默认建议在调用方用 `#5fe3c0`（就业）、`#f2c14e`（失业）、`#6f8bb5`（非劳动力）。请同时导出 `POPULATION_PIE_COLORS` 常量。
- 数字格式：人数用 `Intl.NumberFormat('zh-CN')`，占比 `(value/total*100).toFixed(1)+'%'`；total 为 0 时显示空环与"暂无数据"，不得除零。

### 2. 通知中心 `src/ui/notifications.ts`

导出：
```ts
export interface NotificationItem {
  id: string; title: string; body: string; tickLabel: string;
  kind: 'dividend' | 'vote' | 'major' | 'agreement' | 'market' | string;
  priority: 'normal' | 'important';
  read: boolean;
  audienceLabel: string;          // 如 "个人" / "岚港食品厂" / "岚港 · 市长事务"
}
export interface SystemNotice { id: string; tone: 'info' | 'warning' | 'error'; text: string; }
export class NotificationCenter {
  constructor(host: HTMLElement);   // host 是位于顶部 HUD 正下方的容器
  setData(items: NotificationItem[], notices: SystemNotice[]): void;
  onMarkRead(cb: (id: string) => void): void;
  onMarkAllRead(cb: () => void): void;
  open(): void;
  close(): void;
  isOpen(): boolean;
  destroy(): void;
}
```
要求：
- 样式位置：容器紧贴顶部 HUD 下方，水平靠右（或靠左，与 HUD 对齐），`position: absolute/fixed` 不遮挡左侧城市索引和右侧面板；高度约 32–40px。
- **有事件时只显示小图标**（铃铛/信封式图标 + 未读数量徽标），绝不自动展开详情。无事件时显示极简的静默状态图标（暗淡，无徽标）或留空，不能出现长文本。
- 点击图标才打开详情窗口：小窗口（宽 320–380px，最大高 60vh，内部滚动），可**拖动**（拖动窗口标题栏，用 Pointer Events，限制在视口内，触屏也可），可关闭（× 按钮、Esc），窗口位置在本次会话内保持（组件内部状态即可）。
- 窗口内：顶部标题"通知"、未读数、全部已读按钮；系统提示（`SystemNotice`，例如"自动存档已暂停"）置顶用醒目但不刺眼的样式；通知按未读优先、时间倒序；未读有视觉标记；点击单条标记已读；`priority === 'important'` 有明确但克制的强调；空状态文案自然（"暂时没有需要你处理的消息"）。
- 键盘：图标按钮可 Tab 聚焦，Enter/Space 打开；窗口内焦点不逃逸（简单做法：打开时聚焦窗口标题，Esc 关闭并把焦点还给图标）；`aria-live="polite"` 通知未读数变化；`aria-expanded`。
- 文案只呈现玩家需要的信息（标题/正文由调用方提供），组件不要添加技术术语或模拟日志。
- 全部样式写进 `styles.css` 末尾新增小节，类名统一前缀 `.notif-` 与 `.pop-pie-`，不要复用/覆盖 `.toast`/`.modal` 的现有规则。使用现有 CSS 变量（如已有）或自行定义局部变量，保持深色玻璃质感与 Kenney 按钮风格。
- 减少动画偏好：`@media (prefers-reduced-motion: reduce)` 下关闭 transition/animation。

### 3. 自检
- 不要接入 `ui.ts`/`panels.ts`（下一轮集成），因此这两个文件应能在不破坏现有构建的前提下独立编译（只 import 类型与 `esc` 等纯函数）。
- 尝试运行 `npx tsc -p tsconfig.json --noEmit`；如果因**其他并行开发文件**报错（例如 `securities.ts`、`agreements.ts`、`simulation.ts`），忽略它们，只确保你新增的两个文件本身没有类型错误（可临时用 `npx tsc --noEmit src/ui/charts/pie.ts src/ui/notifications.ts --target ES2022 --module ESNext --moduleResolution bundler --strict --skipLibCheck` 之类单独检查，但不要改 tsconfig）。
- 完成后回复：导出 API、交互说明、CSS 类名前缀、你实际运行的命令与结果、以及下一轮集成所需的 HTML 挂载点建议。不要 git 提交。

## 🤖 AI

我会先读取现有的界面文件，以匹配视觉语言和代码风格。

## 🤖 AI

现在我已经了解了项目结构和视觉规范。接下来实现饼图组件。

## 🤖 AI

现在追加样式；只改文件末尾。

## 🤖 AI

类型检查已通过。接下来我会在临时目录生成一个静态预览，做视觉自检，不修改工作区文件。

## 🤖 AI

视觉自查发现整体符合控制台风格。现在我要完善两处：让数据变化能真正通过 `@starting-style` 做环形过渡，而不仅是在重新挂载时缩放；并微调悬停位移与键盘聚焦状态。

## 🤖 AI

验证环形图的补间动画是否真正生效，因此截取首帧约 250ms 处的画面。

## 🤖 AI

已完成三个文件的实现与自检，未改动 `ui.ts` / `panels.ts`，未运行 git 命令，未执行 npm install。

## 1. 新增/修改文件

- `src/ui/charts/pie.ts`（新建）
- `src/ui/notifications.ts`（新建）
- `src/ui/styles.css`（仅在文件末尾追加 `.pop-pie-*` 与 `.notif-*` 两节，未改动已有规则）

## 2. 导出 API

### 饼图 `src/ui/charts/pie.ts`

```ts
export interface PieSegment { id: string; label: string; value: number; color: string; }
export interface PieInput {
  segments: PieSegment[];
  total: number;
  centerLabel: string;
  centerCaption: string;
  ariaLabel: string;
  note?: string;
}
export const POPULATION_PIE_COLORS = {
  employed: '#5fe3c0',
  unemployed: '#f2c14e',
  nonLabor: '#6f8bb5',
} as const;
export function renderPopulationPie(input: PieInput): string;
export function bindPieInteractions(root: HTMLElement): () => void;
```

### 通知中心 `src/ui/notifications.ts`

```ts
export interface NotificationItem { ... }
export interface SystemNotice { ... }
export class NotificationCenter {
  constructor(host: HTMLElement);
  setData(items: NotificationItem[], notices: SystemNotice[]): void;
  onMarkRead(cb: (id: string) => void): void;
  onMarkAllRead(cb: () => void): void;
  open(): void;
  close(): void;
  isOpen(): boolean;
  destroy(): void;
}
```

## 3. 交互说明

### 饼图

- 纯 SVG 环形图，`<circle pathLength="100">` + `stroke-dasharray/stroke-dashoffset` 分段；间隙约 1.5–2px。
- 值为 0 的段不进入 SVG，但图例保留「0 人」；`total = 0` 时绘制空环、中心显示「暂无数据」，图例占比显示「—」，无除零。
- 悬停沿角平分线外移 7 个 SVG 用户单位（132–158px 下约 4.6–5.5px），扇区加亮、其余扇区降至 42% 不透明度。
- tooltip 是 `.pop-pie` 内绝对定位的 HTML 元素，`pointer-events:none`，由 `pointerover/pointermove/focusin` 定位并限制在组件边界内；面板滚动时随内容移动。
- 键盘：每个扇区 `tabindex="0" role="img"`，`focus-visible` 时同样高亮并显示 tooltip；`svg role="group"` 提供整体描述；图例独立呈现全部数据。
- 动态过渡：CSS `stroke-dasharray/stroke-dashoffset` 700ms ease-out；通过模块内几何缓存 + `@starting-style`，即使面板整块 `innerHTML` 重绘，也会从上一帧弧长补间到新值；数据未变时不会重复动画。首次渲染从 0 展开。
- `bindPieInteractions` 使用事件委托，返回清理函数，不依赖全局单例。
- `prefers-reduced-motion` 下关闭过渡、动画与悬停位移。

### 通知中心

- 顶部 HUD 下方右侧的小铃铛按钮，高 34px；有未读时显示金色数字徽标，只有系统提示时显示小圆点，无事件时图标变暗且无徽标。
- 点击才打开 360px 宽、最大 `min(60vh, 520px)` 的窗口；面板内部滚动。
- 标题栏 Pointer Events 拖动，`touch-action:none`，限制在视口内；窗口位置保存在组件内部，关闭重开后保持。
- 关闭方式：×、Esc、点击窗口外；Esc/关闭按钮会把焦点还给铃铛。
- 系统提示置顶；通知按未读优先、`tickLabel` 倒序；未读有左侧色条 + 圆点 + 屏幕阅读器「未读」；重要条目有金色边框、「重要」标签和金色标记。
- 点击单条就地标记已读（不重排、不丢焦点），全部已读按钮置灰逻辑正确；空状态为「暂时没有需要你处理的消息」。
- 焦点在窗口内循环；`aria-live="polite"` 播报未读数变化，`aria-expanded` 同步开合状态。
- `setData` 会克隆传入数据，已读状态需调用方通过 `onMarkRead/onMarkAllRead` 持久化，否则下次 `setData` 会覆盖。

## 4. CSS 类名前缀

- 饼图：`.pop-pie`、`.pop-pie-plot`、`.pop-pie-svg`、`.pop-pie-seg`、`.pop-pie-legend`、`.pop-pie-row`、`.pop-pie-tip` 等。
- 通知：`.notif-dock`、`.notif-center`、`.notif-toggle`、`.notif-badge`、`.notif-window`、`.notif-head`、`.notif-item` 等。
- 未复用或覆盖 `.toast` / `.modal` 规则；沿用现有 `--panel`、`--line`、`--teal`、`--gold`、`--mono` 等变量。

## 5. 验证

实际运行的命令与结果：

```bash
npx tsc --noEmit src/ui/charts/pie.ts src/ui/notifications.ts \
  --target ES2022 --module ESNext --moduleResolution bundler \
  --strict --skipLibCheck --noUncheckedIndexedAccess \
  --lib ES2022,DOM,DOM.Iterable
# exit 0

npx tsc -p tsconfig.json --noEmit
# exit 0（完整项目当前通过）
```

另外用临时目录中的 esbuild 预览页 + Edge headless 做了视觉与行为自检（临时文件已清理，未写入工作区）：

- 1440×900、1100×700 截图检查布局、通知窗口与右侧面板间距。
- 实测环形补间：30ms 时 `dash=0px,100px`，900ms 时到目标值，700ms 过渡真实生效。
- 键盘聚焦扇区：高亮 + tooltip 内容「非劳动力 46,000 人 46.8%」；失焦后高亮与 tooltip 清除。
- 通知：单条已读（3→2）、全部已读（→0、徽标隐藏）、Esc 关闭并把焦点还给铃铛、拖动 (+70,+40) 后关闭重开位置保持。

## 6. 下一轮集成挂载建议

### 饼图挂载

在右侧面板「城市概况」中预留稳定容器，例如：

```html
<section class="panel-section">
  <div class="section-head">
    <div><span class="kicker">POPULATION</span><h2>人口结构</h2></div>
    <span class="section-tag">口径：互斥</span>
  </div>
  <div id="city-population-pie"></div>
</section>
```

渲染时：

```ts
cleanupPie?.(); // 上一次 bindPieInteractions 的返回值
pieHost.innerHTML = renderPopulationPie({
  segments: [
    { id: 'employed', label: '就业', value: city.population.employed, color: POPULATION_PIE_COLORS.employed },
    { id: 'unemployed', label: '失业', value: city.population.unemployed, color: POPULATION_PIE_COLORS.unemployed },
    { id: 'nonLabor', label: '非劳动力', value: city.population.nonLabor, color: POPULATION_PIE_COLORS.nonLabor },
  ],
  total: city.population.total,
  centerLabel: qty(city.population.total),
  centerCaption: '总人口',
  ariaLabel: `${city.name}人口结构`,
  note: '就业 + 失业 + 非劳动力 = 总人口；劳动力与总人口不可相加。',
});
cleanupPie = bindPieInteractions(pieHost);
```

注意：`ariaLabel` 建议包含城市名且每个图表唯一；几何缓存以此区分实例。

### 通知中心挂载

在 `ui.ts` 的 `SKELETON` 中，紧跟 `</header>`、放在 `.stage` 之前：

```html
<div id="notification-host"></div>
```

`NotificationCenter` 构造时会自动给 host 加 `.notif-dock`（`position: fixed; top: calc(var(--hud-h) + 8px); right: calc(var(--rail-r) + 22px)`），不要把 host 放进带 CSS `transform` 的祖先里。

初始化与数据同步：

```ts
const notifications = new NotificationCenter(document.getElementById('notification-host')!);
notifications.onMarkRead((id) => { /* 写回通知模型，再 setData */ });
notifications.onMarkAllRead(() => { /* 全部已读写回 */ });
notifications.setData(items, notices); // 每次 store 变化后调用；不会自动展开
```

`NotificationItem.tickLabel` 建议传可排序的时间标签（如 `tickDate(tick)`），排序逻辑依赖它做倒序；系统提示可直接映射 `SystemNotice`（如自动存档暂停 → `warning`）。销毁界面时调用 `notifications.destroy()`。

未进行 git 提交。

## 🙋 我

继续在 C:\CODING-worktrees\mechanisms-foundation（TypeScript + Phaser + Electron 经济模拟，深色控制台风格）完成 UI 集成。只改 `src/ui/ui.ts`、`src/ui/panels.ts`、`src/ui/styles.css`（可新增 `src/ui` 下的纯展示辅助文件，但不要改 `src/simulation/**`、`src/app/gameStore.ts`、`src/data/**`）。不要运行 git；不要 npm install。

你上一轮已完成 `src/ui/charts/pie.ts`（`renderPopulationPie`、`bindPieInteractions`、`POPULATION_PIE_COLORS`）与 `src/ui/notifications.ts`（`NotificationCenter`、`NotificationItem`、`SystemNotice`），本轮把它们接入现有控制台，并为新的企业股权/董事会/股票交易/政府协议/市长演示数据增加面板。

先读：`src/ui/ui.ts`（DOM 骨架、事件委托、渲染循环、模态）、`src/ui/panels.ts`（左右面板渲染）、`src/ui/format.ts`（esc/num/qty/pct/money/tickDate 等）、`src/app/gameStore.ts`（新增命令与视图）、`src/simulation/contracts/types.ts`（`Company`、`ShareClass`、`ShareHolding`、`Motion`、`Board`、`TradeAgreement`、`PlayerNotification`）、`src/simulation/securities/securities.ts`（`companyHolders`、`openOrdersFor`、`openOffersFor`、`bookPrice`）、`src/data/config.ts`（`notifications`/`governance`/`investors`/`agreements`）。

## 1. 通知中心（必须满足）

- 在 `SKELETON` 的 `</header>` 之后、`.stage` 之前加入 `<div id="notification-host"></div>`；`mount()` 中构造 `NotificationCenter`，不要放进任何带 transform 的祖先。
- `onMarkRead((id) => { this.store.markNotificationRead(id); })`、`onMarkAllRead(() => this.store.markAllNotificationsRead())`。
- 每次 store 变化后调用 `setData(items, notices)`，**不得自动展开窗口**，不得摧毁重建组件（保持拖动位置与开合状态）。
- 映射：
  - `this.store.notifications` → `NotificationItem`：`id/title/body/kind/priority/read` 直接映射；`tickLabel = tickDate(notice.tick)`；`audienceLabel`：personal → `个人`；company → 企业名；city → `城市名 · 市长事务`。
  - `this.store.systemNotices` → `SystemNotice[]`（已含 tone 与易懂文案）。
- 有未读只显示小图标与徽标；窗口可拖动/关闭/点击外部关闭/Esc；键盘焦点行为沿用组件实现。
- 新增 `data-testid="notif-toggle"` 与 `data-testid="notif-window"`（可加在组件根元素/按钮上，若不便改组件则用查询类名，但 smoke 需要稳定选择器——优先在 `NotificationCenter` 模板里加这两个 testid，属于你负责的文件）。

## 2. 人口环形图

- 在右侧「城市概况」增加「人口结构」区块，区域视图和城市视图都要出现（`panels.ts` 中抽 `renderPopulationSection(city)`，插在 `renderKpis` 之后）。
- 三个**互斥**口径：就业 `employed`、失业 `unemployed`、非劳动力 `nonLabor`；`total = city.population.total`；图例与中心数字用现有 `qty/num` 格式。
- `note` 明确写：`就业 + 失业 + 非劳动力 = 总人口；劳动力（就业 + 失业）不与总人口相加。`
- `ariaLabel` 含城市名，保证不同城市实例唯一。
- 交互绑定：在 `GameUI.mount()` 中对**持久容器** `this.rightScroll` 调用一次 `bindPieInteractions(this.rightScroll)`（面板内容重绘不会失效）；不要每次 renderAll 重复绑定。若你判断需要按 host 重建，必须保存并调用上一次的 cleanup，避免重复监听。
- 新增 `data-testid="population-pie"` 容器。

## 3. 企业详情扩展（panels.ts 的 `renderCompanyDetail`）

保持现有信息，新增以下区块（在损益/岗位/库存/注资之后，顺序自定，注意信息层级；不要挤掉现有企业注资测试 id `company-invest-*`）：

a. **股权结构**（`data-testid="company-holders"`）
   - 用 `store.securitiesView(company.id)`：账面价、股东列表（`companyHolders` 结果，按总持股降序）。
   - 每行：持有人名称、有表决权股数、仅分红股数、合计占比；持有人名称规则：player → `玩家`；company → 企业名；investorGroup → 名称（**不展示实体现金/内部明细**，只显示持股）。
   - 顶部显示两类股份发行量（来自 `world.securities.classes`，可按 kind 汇总）与「企业作为买方只能持有有表决权股份」的说明。
   - 玩家持股/表决权单独一行。

b. **董事会与经营控制**（`data-testid="company-governance"`）
   - `store.governanceView(company.id)`：board.seats 按持有人聚合（同一持有人多席显示席位数）、chair、`control.operator` 与 `basis`。
   - 明确文案：`持股产生表决权与董事席位；经营控制权默认属于职业经理人，须经议案表决才能变更（演示规则）。`
   - 若玩家有表决权，提供 `data-action="propose-operator"`：`data-company-id`、`data-operator="player"` 与 `data-operator="management"` 两个按钮（文案：`提议由玩家经营（演示）` / `提议恢复职业经理人`），标注“需表决通过”。

c. **议案与表决**（`data-testid="company-motions"`）
   - 列出该企业 `open` 议案（最多 3 条）与最近 2 条已结束议案；每条显示标题、状态（待表决/已通过/已否决）、截止期 `T{closesAtTick}`、赞成/反对票数与赞成/反对权重、议案说明。
   - 若 `store.playerVotingSharesOf(company.id) > 0` 且议案 open：三个按钮 `data-action="vote-motion"` + `data-motion-id` + `data-vote="for|against|abstain"`，并标出玩家当前选择（若已投）。
   - 若玩家无表决权：显示“你没有该公司的表决权，不会收到表决要求。”不得显示投票按钮。

d. **股票交易**（`data-testid="company-trading"`）
   - 显示账面价、玩家两类持股、可交易的挂单（`openOrdersFor` 前 6 条：方向/类别/剩余股数/限价/下单期）。
   - 买入/卖出按钮：`data-action="trade-shares"`，属性 `data-company-id`、`data-kind="voting|nonVoting"`、`data-side="buy|sell"`、`data-shares`。每类、每方向给 `100` 与 `1000` 两档；限价由 `panels` 计算：买入 `bookPrice * 1.02`、卖出 `bookPrice * 0.98`（保留 2 位小数，传给 action 用 `data-limit-price`）。
   - 文案区分：`一级融资（注资）资金进入企业；二级买卖资金只进入卖方，企业不会因此获得资金。`
   - 融资要约（`store.securitiesView(...).offers`）：显示商品类要约信息；若 `investor` 是玩家，附 `data-action="accept-offer"` / `"decline-offer"` + `data-offer-id`；不冒充玩家可接受其他主体的要约。

## 4. 政府牵头协议（城市视图）

- 在 `renderRightCity` 追加「跨城贸易协议」区块（`data-testid="agreements-section"`）；`renderRightRegion` 也显示（选中城市时），可复用同一函数。
- 顶部明确：`市政府牵头（演示入口）。市长选举尚未实现，这里不代表玩家已当选。`
- 组织协议：为 `store.agreementPartners(city.id)` 的每个伙伴城市渲染按钮 `data-action="organize-agreement" data-partner-city-id`，文案如 `与铁谷协商（演示）`。
- 列表用 `store.agreementsForCity(city.id)`（最新在前，最多 6 条）：标题、状态（协商中/生效/完成/取消）、发起城市→伙伴城市、参与企业及各自 decision（接受/拒绝/待定）、每个 item 的商品名/月数量/单价/已交付/状态（待履约/履约中/完成/失败/被拒绝）与失败原因（lastNote，中文可读）。
- 对 `proposed`/`active` 协议：每个参与企业提供 `data-action="decide-agreement"` + `data-agreement-id`、`data-company-id`、`data-accept="true|false"`，按钮文案必须标注 `演示：代企业表态`；`active`/`proposed` 另提供 `data-action="withdraw-agreement"`（取消协议）。
- 未决/拒绝不得让玩家误以为已经产生买卖义务，用文案说明。

## 5. 市长演示身份

- 在城市面板（区域与城市视图都可）加明显但克制的「演示身份」开关：`data-action="toggle-mayor-demo"`；当前城市已是 `store.mayorCityId` 时显示“退出市长演示”，否则“以市长身份查看（演示）”。
- 激活时显示徽标/提示：`演示：市长身份 · 选举系统未实现`。不得把玩家无条件当成市长。

## 6. UI 事件与日志

- `ui.ts` 的 `handleAction` 增加上述 action：`trade-shares`（读取 `data-kind/side/shares/limit-price`，调用 `store.tradeShares`）、`accept-offer`/`decline-offer`、`vote-motion`、`propose-operator`、`organize-agreement`、`decide-agreement`、`withdraw-agreement`、`toggle-mayor-demo`。调用后 `renderRightPanel()` 已由 store 订阅触发，勿重复。
- 日志区：隐藏 `kind === 'system'` 的条目，以及包含“不变量/事务/校验”的技术文案；标题可保持“城市动态 · 月度快照”。不要展示模拟步骤或内部校验结果。
- 不要新增玩家看不懂的技术词（securities、invariant、holdings、tick 等）；“演示/暂定规则”要明确标注。

## 7. 视觉与可访问性

- 新面板沿用现有 `.panel-section`、`.kpi-grid`、`.table-wrap`、`.chips`、`ken-btn` 等风格；表格在小屏（1100×700）不横向溢出，必要时用两列网格或短标签。
- 按钮有 `title`/`aria-label`；表格有 `<caption>` 或 `aria-label`；投票/交易按钮有 `data-focus-key` 以保持重绘焦点（沿用现有模式）。
- 遵守 `prefers-reduced-motion`。

## 8. 验证

- 运行 `npm run typecheck` 与 `npm run build`，必须通过（当前项目基线是通过的）。
- 用 `npm run dev:web` 或构建后 Electron 截图自检：1440×900 与 1100×700；通知图标在 HUD 正下方且不遮挡左右栏；饼图悬停有浮动与数值；企业详情新区块不溢出；点击交易/投票/协议按钮不报错（可只做静态渲染检查）。
- 保留现有 smoke 依赖的 testid：`hud-date`、`btn-tick`、`btn-pause`、`btn-save`、`btn-load`、`city-card-*`、`btn-enter-city`、`btn-back-region`、`layer-*`、`company-invest-*`、`company-detail-*`、`modal-save`。
- 完成后回复：改动文件、新增 action 与 testid 列表、布局决定、实际运行命令与结果、已知取舍。不要 git 提交。

## 🤖 AI

现在开始接入。先给通知组件补上稳定的 testid，然后接入 `ui.ts`。

