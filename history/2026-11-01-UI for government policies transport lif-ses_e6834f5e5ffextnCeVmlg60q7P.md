# UI for government policies transport lifecycle

- 会话 ID：`ses_e6834f5e5ffextnCeVmlg60q7P`
- 时间：2026-11-01 23:47
- 目录：`C:\Users\Administrator`
- 模型：`opencode-go/deepseek-v4.1-flash`

---

## 🙋 我

You are a subagent spawned by another session.
工作区：C:\CODING-worktrees\city-government-transport（分支 feature/city-government-transport）。只改界面文件，不要改 src/simulation/**、src/data/**、src/app/gameStore.ts。

## 背景
模拟层已完成 v0.3：企业自动经营风格、企业成立/倒闭、候选人/领导人、15 项政策、城内/城际公路铁路容量。GameStore 已提供只读视图与命令方法（见下）。现在需要把这些能力接入现有控制台 UI，保持现有 Kenney 风格和布局，不做整体重设计。

## 必须使用的 store API（已实现，不要修改）
- `store.saveFormatVersion: number`
- `store.policyView(cityId)` → `{ city, isPlayerMayor, leader: string, lastSelection: string, active: ActivePolicy[], history: PolicyHistoryEntry[], definitions: { id,name,domain,target,effect,spendsTreasury,maturity,defaultBudget,available,reason }[] }`
- `store.selectPolicy(policyId, { budget?, taxDirection?: 'cut'|'raise', transportTarget?: string })` → boolean
- `store.stopPolicy(policyId)` → boolean
- `store.runForMayor(cityId)` → boolean
- `store.transportView(cityId)` → `{ city, links: { id, fromCityId, toCityId, mode:'road'|'rail', level, maxLevel, construction, partner, capacity, estimate:{ok,error?,cost,months,targetLevel,label} }[], corridors: {withCityId,capacity,demand,penaltyRate}[], intracity: { cityId, roadLevel, railLevel, maxLevel, construction, capacity, stats:{demand,capacity,utilization,deliveryEfficiency}|null, estimateRoad, estimateRail } | null, stats: { demand, capacity, penaltyRate, capacityLossTotal, freightSubsidy, maintenancePaid, corridors, trades, intracity, note } }`
- `store.investTransport(target: string)` → boolean，target = `'intracity:road'`、`'intracity:rail'` 或城际线路 id（例如 `greenfield|ironvale:road`，直接取 links[i].id）
- `store.lifecycleView(cityId)` → `{ limits:{companies,maxCompanies,governmentFoundings,maxGovernmentFoundings,population}, foundings, liquidations, canFoundInvestorGroup }`
- `store.foundCompany(founderType:'investorGroup'|'company'|'government', companyId?)` → boolean
- `store.expandCapacity(companyId)` → boolean
- `store.companyAiView(companyId)` → `{ style,styleLabel,styleDescription,decision,plan:{tick,style,utilization,targetJobs,expectedWageCost,hiringSubsidyPerHire,retentionSubsidyPerEmployee,investment,reasons:string[]}|null, lossMonths, ageMonths, expansionEstimate, expansionCost } | null`
- `store.fiscalLedger` → 最近财政流水（倒序，{kind,amount,source,tick,policyId?}）
- 既有：`store.mayorCityId`、`store.setMayorDemo(cityId|null)`、`store.companiesForCity(cityId)`、`store.selectedCity`、`store.world`。

ActivePolicy 字段：`{ id, cityId, policyId, budget, spent, monthsRemaining, startedTick, status, targetSector, taxDirection, transportTarget, effects: Record<string, number>, reason, note }`。

## 任务
1. 在 `src/ui/panels.ts` 的城市右侧面板（`renderRightCity`）加入两个新 section，位置在“城市概况”之后、“市场快照/协议”之前：
   - 政府与政策 `data-testid="government-section"`
     - 显示：现任领导人/玩家市长状态、最近的 AI 选择原因（lastSelection）、财政流水摘要（最多 6 条，支出为负、收入为正）。
     - 非玩家市长：只读展示生效政策与最近选择原因，并显示“当前由政府自主施政；参选后可自己选择政策”，提供 `data-action="run-for-mayor" data-testid="run-for-mayor"` 按钮。
     - 玩家市长：显示“政策由你选择”，并为 15 项政策各渲染一行：名称、领域、作用对象、效果说明、默认预算。按钮 `data-action="start-policy" data-policy-id="<id>" data-testid="policy-<id>"`，不可用时 disabled 并显示 reason。
       - 税收调整需要两个按钮：`data-tax-direction="raise"` 与 `data-tax-direction="cut"`（同样 data-action="start-policy" data-policy-id="taxAdjustment"）。
       - 交通基础设施投资需要 `data-transport-target`：默认 `intracity:road`；另给 `intracity:rail`；若 store.transportView 的 links 可用，可为每条 `estimate.ok` 的线路加一个按钮（`data-transport-target="<link.id>"`）。
     - 生效政策行：显示 已支出/预算、剩余月份、效果摘要（effects 里金额用 toFixed(0)，其他最多 2 位小数），并有 `data-action="stop-policy" data-policy-id="<id>"` 停止按钮。
     - 15 项政策必须全部可见，不能只显示前几项；不要把技术错误原文展示给玩家，reason 用简短中文。
   - 交通 `data-testid="transport-section"`
     - 概览：本月城际运输需求/容量/惩罚比例/收益损失合计/财政补偿/维护支出（中文，不要显示“invariant”等技术词）。
     - 城际线路表：伙伴城市、方式（公路/铁路）、等级、容量、建设进度（monthsRemaining）、升级成本/工期；按钮 `data-action="invest-transport" data-target="<link.id>" data-testid="transport-link-<id>"`，资金不足或建设中 disabled 并显示原因。
     - 城内交通：道路/铁路等级、配送容量、上期配送利用率与配送效率；按钮 `data-action="invest-transport" data-target="intracity:road"` / `"intracity:rail"`，`data-testid="intracity-road"` / `"intracity-rail"`。
     - 用一句话说明“容量不是成交上限；超载只减少卖方该笔收益，买方付款不变（暂定方案）”。
2. 企业创办与退出：在 `renderCompanies` 或城市面板新增 `data-testid="company-lifecycle"` 区块：
   - 显示 本城企业数/上限、政府已创办数/上限、居民投资群体是否可出资。
   - 三个按钮：`data-action="found-company" data-founder="investorGroup"`、`data-founder="company"`（若本城有企业则附 `data-company-id="<最富有的本城企业id>"`）、`data-founder="government"`；`data-testid="found-<type>"`。
   - 最近成立记录（最多 3 条）与最近倒闭记录（最多 3 条，显示员工释放数、债务减免、股东分配、库存注销金额）。
3. 企业详情（`renderCompanyDetail`）加入 `data-testid="company-ai"` 区块：
   - 风格标签与说明、最近决策原因（companyAiView.decision）、计划要点（利用率、岗位需求、补贴后月用工成本、计划投资）、连续亏损月数。
   - 扩产按钮 `data-action="expand-capacity" data-company-id="<id>" data-testid="expand-capacity-<id>"`，显示预计新增产能与成本；资金不足禁用。
4. `src/ui/ui.ts` 的 `handleAction` 增加 case：
   - `start-policy`：读取 `data-policy-id`，读取可选 `data-tax-direction`、`data-transport-target`；调用 `store.selectPolicy`。
   - `stop-policy`：`store.stopPolicy`。
   - `run-for-mayor`：`store.runForMayor(store.selectedCityId)`。
   - `invest-transport`：`store.investTransport(element.dataset.target)`。
   - `found-company`：`store.foundCompany(founder as any, element.dataset.companyId)`。
   - `expand-capacity`：`store.expandCapacity(element.dataset.companyId)`。
   所有命令后已由 store 触发 emit；不要自行修改 world。
5. `renderSystems` 现在的“政治 · 科技 · 房地产 / 系统未实现”已过时：至少把政治卡片改为显示真实领导人、任期与支持率，status 文案改为“已接入（演示）”；科技卡片显示研发等级会随政策变化；不要把政策说成未实现。可用 store 参数或 city 里已有字段（city.politics）。
6. 在 `src/ui/styles.css` 增加必要样式，复用现有变量/类风格，保证：
   - 1100×700 视口无横向溢出；
   - 政策列表 15 项可滚动/折行，不挤压其他面板；
   - 移动端既有断点不破。
7. 不要删除现有 data-testid 与 data-action（`notif-toggle`、`btn-tick`、`company-row-*`、`company-detail-*`、`agreements-section`、`toggle-mayor-demo` 等必须保留）。

## 验证
完成后必须运行：
- `npx tsc -p tsconfig.json --noEmit`
- `npm run build`（构建渲染层）
- `npx vitest run`（92 项现有测试必须全部通过）
如果发现 store API 不足，不要改 store；在交付说明中指出需要什么。

## 交付
用中文简述：新增的 section、所有 data-action/data-testid、样式改动、构建与测试结果、任何未完成项。不要提交 git。

## 🤖 AI

我先查看项目结构和现有 UI 代码。

## 🤖 AI

现在我已了解代码结构。开始实现，先更新 `panels.ts` 的 `renderSystems` 与新增区块。

## 🤖 AI

Now add the lifecycle block into the companies section:

## 🤖 AI

现在插入 `company-ai` 区块。先定位 KPI 网格结束处：

## 🤖 AI

已完成 v0.3 政府/交通/企业能力接入控制台 UI，只改了界面文件（`src/ui/panels.ts`、`src/ui/ui.ts`、`src/ui/styles.css`、`src/ui/modals.ts`），未触碰 `src/simulation/**`、`src/data/**`、`src/app/gameStore.ts`，未提交 git。

## 新增 section 与入口

**城市右侧面板（`renderRightCity`，位于“城市概况”之后、“市场快照/协议”之前）**
- `data-testid="government-section"`：领导人/党派/任期/支持率、最近选择原因、财政流水（最多 6 条，收入正/支出负）、生效政策（已支出/预算、剩余月份、效果摘要、停止按钮）。
  - 非玩家市长：只读 + “当前由政府自主施政；参选后可自己选择政策” + 参选按钮。
  - 玩家市长：显示“政策由你选择”，**15 项政策全部渲染**在可滚动列表里（名称/领域/对象/效果/默认预算），税收给“上调/下调”两个按钮，交通给“城内道路/城内铁路/每条可升级城际线路”按钮。
- `data-testid="transport-section"`：本月需求/容量/惩罚比例/收益损失/财政补偿/维护支出；城际线路表（伙伴、方式、等级·容量、状态/建设进度、升级成本与工期、投资按钮）；城内道路/铁路等级、容量、上期利用率与效率；底部注明“容量不是成交上限；超载只减少卖方该笔收益，买方付款不变（暂定方案）”。

**企业**
- `renderCompanies` 内新增 `data-testid="company-lifecycle"`：企业数/上限、政府创办数/上限、居民投资群体可出资状态；三个创办按钮；最近 3 条成立记录与最近 3 条倒闭记录（员工释放、债务减免、股东分配、库存注销）。
- `renderCompanyDetail` 内新增 `data-testid="company-ai"`：风格标签与说明、最近决策、计划要点（利用率/岗位/补贴后月用工成本/计划投资）、连续亏损月数、扩产按钮（预计新增产能与成本，企业现金不足禁用）。

**其他文案一致性**：`renderSystems` 政治卡改为真实领导人/任期/支持率，科技卡随研发状态变化，状态徽标改为“已接入（演示）”；同时修正了市长演示条、协议说明和“参数”弹窗中“选举/科技系统未实现”的过期表述。

## 新增 data-action / data-testid
- `data-action`：`start-policy`（含 `data-policy-id`、`data-tax-direction="raise|cut"`、`data-transport-target`）、`stop-policy`、`run-for-mayor`、`invest-transport`（`data-target`）、`found-company`（`data-founder` + 可选 `data-company-id`）、`expand-capacity`（`data-company-id`）。
- `data-testid`：`government-section`、`transport-section`、`run-for-mayor`、`policy-<id>`（税收：`policy-taxAdjustment` / `policy-taxAdjustment-cut`；交通：`policy-transportInvestment` / `policy-transportInvestment-rail`）、`stop-policy-<policyId>`、`transport-link-<linkId>`、`intracity-road`、`intracity-rail`、`company-lifecycle`、`found-investorGroup`、`found-company`、`found-government`、`company-ai`、`expand-capacity-<companyId>`。
- 既有 `notif-toggle`、`btn-tick`、`company-row-*`、`company-detail-*`、`agreements-section`、`toggle-mayor-demo`、`mayor-demo-toggle` 全部保留。

## 样式
在 `styles.css` 末尾新增 v0.3 样式块，复用现有变量与 `.ken-btn`：政策列表独立滚动（`max-height: clamp(240px, 42vh, 380px)`，含 1180/720 高度断点）、15 项政策折行不挤压其他面板；交通表 `table-layout: fixed` + 列宽约束、长文本换行/省略；财政流水、生命周期、AI 计划两列网格；1100×700 下右栏内容不产生页面级横向溢出。所有新按钮都带 `data-focus-key`，保留原有焦点恢复机制。

## 验证结果
- `npx tsc -p tsconfig.json --noEmit`：通过（无输出）。
- `npm run build`：通过（仅 Vite 既有 chunk >500 kB 警告）。
- `npx vitest run`：**19 个测试文件 / 137 项全部通过**（任务提到 92 项；工作区里 v0.3 测试已增加到 137 项）。期间观察到并行会话在改模拟层时曾短暂出现 `policies/transport` 失败，最终该次运行全绿，与 UI 改动无关。

## 需要 store 侧留意的点（未改 store）
1. `selectPolicy('transportInvestment')` 会走 `canStartPolicy` 的“同时生效政策上限/冷却”限制，而 `investTransport` 不会；因此政策列表里的交通按钮在已有 2 项政策时可能被禁用，但下方交通 section 的投资按钮仍可开工。若希望两者一致，需要模拟层明确交通投资是否占用政策名额。
2. `companyAiView.expansionCost` 未扣除设备与扩产补助，UI 按它判断“资金不足”，可能出现按钮禁用但实际补助后能扩产的情况。

## 🙋 我

验收补充（只改 UI 文件）：任务书要求“玩家成为市长时，由玩家选择政策和分配资金”。目前政策行只有默认预算按钮，玩家不能分配金额。请补上：

1. 玩家市长时，每个需要预算的政策行增加一个金额输入：
   - `<input type="number" data-policy-budget="<policyId>" data-testid="policy-budget-<policyId>" min="0" step="10000" value="<defaultBudget>">`
   - 标签写“预算（信用点）”，放在按钮前；不要用浏览器默认巨大样式，复用现有输入/表单风格。
   - 对 `taxAdjustment`（无预算）与 `transportInvestment`（按工程造价，不按预算）不显示预算输入。
2. `start-policy` 的 UI 处理器读取同一政策行内的 `input[data-policy-budget]` 值，传给 `store.selectPolicy(policyId, { budget: Number(value), taxDirection, transportTarget })`：
   - 值无效/为空/<=0 时用该政策 defaultBudget（可用 `data-default-budget` 属性）；
   - 不要在前端静默截断到财政余额——由模拟层拒绝并 toast 原因（现有行为）。
   - 注意同一页面可能有多个同名政策按钮（税收两个方向、交通多个目标），预算输入只与 policyId 对应，不要重复渲染多个输入。
3. 生效政策行继续显示 已支出/预算 与剩余月份；玩家停止政策后重新选择可再次分配预算。
4. 非玩家市长不显示任何预算输入（只读）。
5. 在 1100×700 下不产生横向溢出；输入宽度固定在合理范围（例如 120–140px），15 项列表仍可滚动。

验证：`npx tsc -p tsconfig.json --noEmit`、`npm run build`、`npx vitest run`（当前应为 149 项全过）。完成用中文报告改动位置与结果，不要提交 git。

## 🤖 AI

已补上“玩家市长分配政策预算”的界面与交互，仍只改 UI 文件，未提交 git。

## 改动位置

**1. `src/ui/panels.ts` — 政策行预算输入**
- 在 `renderGovernmentSection` 的 `policyCards` 中，为**需要预算的政策**（15 项中除 `taxAdjustment`、`transportInvestment` 外的 13 项）各渲染唯一一个预算输入，位于按钮前：
  - `input type="number"`
  - `data-policy-budget="<policyId>"`
  - `data-testid="policy-budget-<policyId>"`
  - `data-default-budget="<defaultBudget>"`
  - `min="0" step="10000" value="<defaultBudget>"`
  - 外层 `<label class="policy-budget-field"><span>预算（信用点）</span> … </label>`
- 政策不可用时输入同步 `disabled`。
- 税收调整只有“上调/下调”两个按钮、交通只有各目标按钮，均**不渲染预算输入**；同一政策行只渲染一个输入。
- 生效政策行仍显示“已支出 / 预算 / 剩余月份”，停止后可重新选择并分配新预算（每次重渲染按默认值恢复）。
- 非玩家市长不渲染政策列表，因此没有任何预算输入（只读）。

**2. `src/ui/ui.ts` — `start-policy` 处理器**
- 通过 `element.closest('.policy-item')` 找到同一政策行，读取 `input[data-policy-budget="<policyId>"]`。
- 值有效且 `> 0` → 使用输入值；为空、非法或 `<= 0` → 使用 `data-default-budget`；输入不存在（税收/交通）→ 不传 `budget`。
- 不按财政余额截断，余额不足仍交给 `store.selectPolicy` 拒绝并 toast。
- 组装 `{ budget, taxDirection, transportTarget }` 调用 `store.selectPolicy`。

**3. `src/ui/styles.css` — 输入样式与响应式**
- 新增 `.policy-budget-field` 及 `input` 样式：深色底、1px 边框、4px 圆角、等宽数字、22px 高度，宽度 **128px**（≤1180px 断点下 **120px**），并处理 hover / `:focus-visible` / `:disabled`，使用 `color-scheme: dark` 避免浏览器默认巨大控件。
- 输入与按钮同处 `.policy-actions` 的换行布局，15 项政策列表仍独立滚动，不挤压其他面板。

## 验证结果
- `npx tsc -p tsconfig.json --noEmit`：通过。
- `npm run build`：通过（仅既有 chunk >500 kB 警告）。
- `npx vitest run`：**22 个测试文件 / 149 项全部通过**。
- 额外渲染自检：玩家市长时预算输入 **13 个**（对应 13 项政策，无重复），税收/交通无输入；非玩家市长 **0 个**；`value` 与 `data-default-budget` 一致。

