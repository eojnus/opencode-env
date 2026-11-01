# 实现政府牵头跨城协议模块

- 会话 ID：`ses_e68f5ff6affepIOejiosGuBhRg`
- 时间：2026-11-01 20:16
- 目录：`C:\Users\Administrator`
- 模型：`opencode-go/deepseek-v4.1-flash`

---

## 🙋 我

You are a subagent spawned by another session.
工作区：C:\CODING-worktrees\mechanisms-foundation（TypeScript 模拟游戏）。只改本工作区，不要运行 git 命令，不要 npm install。

任务：新建 `src/simulation/agreements/agreements.ts` 和 `tests/agreements.test.ts`。**只创建这两个文件**，不要修改其他任何文件（其他人正在并行改 simulation/save/types/ui）。

先读：`src/simulation/contracts/types.ts`（新类型 `TradeAgreement`、`AgreementParticipant`、`AgreementItem`、`TradeFlow`、`GoodId`）、`src/data/config.ts`（`agreements` 配置节）、`src/simulation/markets/markets.ts`（`offeredStock`）、`src/simulation/trade/trade.ts`（点对点贸易的原子提交风格）、`src/simulation/companies/company.ts`、`src/data/demo-data.ts`（`RECIPES`、`PRODUCTIVITY`）。

需求背景：政府可以牵头跨城多企业贸易协议，让本市多家企业与其他城市多家企业协商买/卖商品。**每家企业都可以拒绝参加**；各企业资金、库存、义务独立；协议记录参与方、商品、数量、价格、履约状态；失败不能留下部分扣款或部分货物转移。市长选举尚未实现，协议由"市政府"或明确标注的演示场景发起即可，不要把玩家当成市长。

实现导出函数（签名固定，供主循环调用）：

```ts
export interface AgreementResult { ok: boolean; error?: string; agreement?: TradeAgreement; }
export function proposeAgreement(world: WorldState, sponsorCityId: string, partnerCityId: string, config: DemoConfig, tick: number, createdBy: 'government' | 'demo'): AgreementResult;
export function decideParticipant(world: WorldState, agreementId: string, companyId: string, accept: boolean, tick: number, config: DemoConfig, log?: LogEntry[]): AgreementResult;
export function applyAutoDecisions(world: WorldState, agreementId: string, config: DemoConfig, tick: number, log?: LogEntry[]): void;
export function executeAgreements(world: WorldState, config: DemoConfig, tick: number, log: LogEntry[]): TradeFlow[];
export function cancelAgreement(world: WorldState, agreementId: string, tick: number, reason: string): AgreementResult;
export function maybeAutoPropose(world: WorldState, config: DemoConfig, tick: number, log: LogEntry[], rngNext?: () => number): void;
export function agreementsForCompany(world: WorldState, companyId: string): TradeAgreement[];
```

规则（全部标为暂定演示规则）：
- `proposeAgreement`：验证两个城市不同且存在。为跨城买卖配对：遍历伙伴城市（卖方）企业的 `offeredStock(company, good) > 0` 的商品，在发起城市找需要该商品作为生产投入的买方企业（`RECIPES[buyer.recipeOutput].inputs` 含该商品），需求量 = `生产目标 * 配方用量 - 库存`（用 `company.capacity * company.utilization` 近似生产目标，不要 import production.ts 以免循环依赖，可自行计算并加注释）。数量 = `min(需求, 卖方可售库存 * config.agreements.maxSellerShare, 按买方资金可负担的量)`，向下取整，< `config.agreements.minQuantity` 跳过。价格 = 买方城市市场价 ×（1 + 运输加成），运输加成复用 `config.intercity`：按城市 `region` 坐标距离估算（与 `markets/intercity.ts` 的 `cityDistanceKm` 同样的公式与标记，自己实现私有函数）。每对买卖方生成一个 `AgreementItem`（status 'pending'，months = config.agreements.months）。参与者去重，按公司 id 排序，side 由其在 items 中扮演的角色决定（既买又卖则记为 'buyer' 并在 note 中说明，暂定）。最多 6 个 items，避免协议过大。记录 `createdBy`，`status: 'proposed'`，`createdTick`。若没有任何 item 返回 `{ ok: false, error: '没有可协商的买卖配对' }`，不得修改世界。
- `applyAutoDecisions`：对每个 pending 参与者按暂定规则决定：卖方接受条件为 `unitPrice >= 卖方城市该商品市价 * config.agreements.sellerMinPriceFactor`；买方接受条件为 `unitPrice <= 买方城市该商品市价 * config.agreements.buyerMaxPriceFactor` 且 `cash >= 一个月的对应采购价值`。记录 `decidedTick` 与一句可读 note（例如"接受：价格在可接受区间"）。被拒绝参与者的所有 items 设为 'declined' 并记录 `lastNote`。全部参与者都决定后：若有至少一个 item 仍 pending/active 且买卖双方都接受 → 协议 `status='active'`；否则 `status='cancelled'` 并说明原因。拒绝不产生任何资金/库存变化。
- `decideParticipant`：公开命令，允许 UI 或测试让某企业接受/拒绝；校验协议存在、公司是参与方、当前 decision 为 pending 或允许翻转；提交后若全部决定完成则按上面规则定状态。被拒绝的参与者不产生义务；其 items 全部 'declined'。
- `executeAgreements`：只处理 `status === 'active'` 的协议，按协议创建顺序、item 顺序逐项执行。每个 item 每月最多执行一次（用 `monthsExecuted` 与 `tick` 去重：增加字段不可行，类型已固定——用 `lastNote` 不行；因此请在 item 上不新增字段，改为在函数内用一个局部 Set 以 `item.id + tick` 去重，并且每期每个 item 只执行一次，主循环每 tick 只调用一次即可）。每月数量 = `qtyPerMonth`；先验证：卖方企业存在、库存 >= 数量、买方企业存在、现金 >= 数量 × 单价。全部通过才提交：卖方库存减、买方库存加、买方现金减、卖方现金加、双方 `lastMonth.inputCost/revenue` 更新、`deliveredQty += qty`、`paidValue += value`、`monthsExecuted += 1`，并 push 一条 `TradeFlow`（`routeId: 'agreement:' + agreement.id`, fromCityId 卖方城市, toCityId 买方城市, fromCompanyId 卖方, toCompanyId 买方, good, qty, unitPrice, value）。任一验证失败：该 item `status='failed'`，`lastNote` 写明原因（库存不足/资金不足），**不做任何资金或库存变化**，不产生 flow。成功且 `monthsExecuted >= months` → `status='fulfilled'`。协议内所有 items 都 fulfilled/failed/declined 且没有 pending → 协议 `status='completed'`（有失败项时 completed 并在 note 注明"部分履约失败"）。
- `maybeAutoPropose`：当 `config.agreements.autoPropose` 为真、活跃（proposed/active）协议数 < `config.agreements.maxActive`、并且当前 tick 距离上一条协议创建 >= 3 个月时，选城市对（固定顺序：按城市 id 排序的两两组合，轮转选择），调用 proposeAgreement('government')，然后 applyAutoDecisions。不要用 Math.random；可用传入的 `rngNext` 做平局选择，没有则确定性选择。创建/决策时向 log push 可读的 `kind: 'trade'` 消息。
- `cancelAgreement`：把 proposed/active 改为 cancelled，未完成的 items 置 'failed'（lastNote: 取消），无资金变化。

约束：钱和数量用 `round2`；排序确定；不产生负库存/负现金；不新增任何 WorldState 字段（类型已定，不能改 types.ts）。注释中明确"政府牵头协议与接受/拒绝规则均为暂定演示方案，最终规则待用户决定"。

测试 `tests/agreements.test.ts` 覆盖：提议后世界资金/库存不变；拒绝参与不产生义务且无资金变化；接受后按 item 逐项原子履约（成功时库存与资金守恒：买方现金减少 == 卖方现金增加）；库存不足时该 item 失败且双方现金与库存完全不变；取消协议无资金变化。可直接用 `Simulation.create().state`（若全项目暂未编译通过，先写好测试，我会统一修）。

完成后回复：文件、规则要点、测试用例名、运行过的命令与结果（未运行请说明）。不要 git 提交。

## 🤖 AI

I'll start by reading the required files to understand the types and existing patterns.

## 🤖 AI

Now I have what I need. Writing the implementation:

## 🤖 AI

另一位 agent 正在修改 `initializer.ts`（当前因缺少 `createInvestorGroups` 而未编译通过）。于是我用临时脚本独立验证协议逻辑：

## 🤖 AI

<summary>
已按规格创建两个文件（只新增，未改动其他人负责的文件）：

- `src/simulation/agreements/agreements.ts`：实现 7 个导出函数（含 `AgreementResult`），政府牵头的跨城多企业贸易协议，逐条原子履约，拒绝/失败/取消均无资金或库存副作用；未新增任何 WorldState 字段、未 import production.ts（`productionTarget` 以 `capacity × utilization` 本地近似并注释说明）、运输加成复用 `config.intercity` 并按 `intercity.ts` 的同一距离公式私有实现。所有规则注释标明"暂定演示方案，最终规则待用户决定"，发起方只有 `government`/`demo`，不涉及市长或玩家身份。
- `tests/agreements.test.ts`：5 个测试用例，基于 `Simulation.create().state` 构造"青原谷物合作社 → 岚港食品厂"唯一撮合链路（620 单位 grain，单价 104.74）。

</summary>

<changes>
- `src/simulation/agreements/agreements.ts`（新建）:
  - `proposeAgreement`：校验城市不同且存在；伙伴城市企业为卖方、发起城市企业为买方；需求量 = `capacity*utilization*配方用量 - 库存`；数量 = min(需求, `offeredStock*maxSellerShare`, 现金可负担量) 向下取整，< `minQuantity` 跳过；价格 = 买方城市市价 × (1+运输加成)；最多 6 条 item（额外按买方已承诺现金/卖方同商品已承诺库存去重，防止超额占用）；参与者去重按 id 排序，双重角色记 `buyer` 并写明 note；无配对返回 `没有可协商的买卖配对` 且不写世界（只有成功路径才初始化/写入 `world.agreements`）。
  - `applyAutoDecisions`：卖方 `unitPrice >= 卖方市价*sellerMinPriceFactor`；买方 `unitPrice <= 买方市价*buyerMaxPriceFactor` 且现金 ≥ 一个月采购额；记录 `decidedTick` 与可读 note；拒绝者全部 items → `declined`；全部表态后有可行条目 → `active`（items → `active`），否则 `cancelled`；推入 `kind:'trade'` 日志。
  - `decideParticipant`：校验协议/参与方/状态，`proposed` 阶段可翻转；拒绝同样将 items 置 `declined`；全部决定后统一收尾定状态。
  - `executeAgreements`：仅 `status==='active'`，按 `createdTick` + id、item 顺序执行；局部 `Set<itemId@tick>` 去重；先验证卖方存在/库存、买方存在/现金；全部通过才一次性提交库存、现金、`lastMonth.inputCost/revenue`、`deliveredQty`、`paidValue`、`monthsExecuted`；失败仅置 item `failed` + 原因；成功满期置 `fulfilled`；无未完成 item 时协议 `completed`，有失败项注明"部分履约失败"；产出 `TradeFlow(routeId: 'agreement:'+id)`。
  - `cancelAgreement`：`proposed`/`active` → `cancelled`，未完成 items → `failed`（lastNote 含"协议取消"），无资金变化。
  - `maybeAutoPropose`：`autoPropose` 开启、活跃协议 < `maxActive`、距上条创建 ≥ 3 月；城市对按 id 排序两两组合轮转（可选 `rngNext` 仅选起点），成功后自动决策并记录 `kind:'trade'` 日志；不使用 `Math.random`。
  - `agreementsForCompany`：按 `createdTick` + id 返回企业参与的协议。
- `tests/agreements.test.ts`（新建）: 5 个用例，见下方用例名。
</changes>

<verification>
- 已运行 `npx vitest run tests/agreements.test.ts` → **失败（外部原因，非本模块）**：5 个用例均在 `Simulation.create()` 内部报 `ReferenceError: createInvestorGroups is not defined`（`src/simulation/core/initializer.ts:248`，另一位 agent 正在并行修改该文件，未完成）。测试代码本身未被执行到。
- 已用临时脚本（已删除，`tsx` 直接 import 本模块 + 手工构造最小 WorldState）验证全部逻辑，**6/6 通过**：提议无副作用、拒绝无义务、原子履约且现金守恒（value=64938.8）、库存不足完全无变化、取消失效无资金变化、无配对返回错误且不写世界。
- 已运行 `npx tsc --noEmit --strict --noUncheckedIndexedAccess --target ES2022 --module ESNext --moduleResolution Bundler --skipLibCheck --verbatimModuleSyntax src/simulation/agreements/agreements.ts` → **通过**（无输出）。
- 已运行 `npx tsc -p tsconfig.json --noEmit` 并过滤 `agreements` → 无任何涉及这两个新文件的错误；项目整体仍因他人并行改动的 `simulation.ts`（缺 `dividendIncome`）、`investors.ts`、`securities.ts` 和旧测试报错。
- 未运行 `npm install`，未执行任何 git 命令。

测试用例名（`tests/agreements.test.ts`）：
1. `提议协议不会改变任何企业的资金与库存`
2. `拒绝参加不产生义务，也不改变资金与库存`
3. `接受后按条目原子履约：货物与资金同时转移且现金守恒`
4. `库存不足时该条目失败，双方现金与库存完全不变`
5. `取消协议不改变资金与库存`

提醒：等 `initializer.ts` 的 `createInvestorGroups` / `WorldState` 新字段补齐后，请重跑该测试文件；`maybeAutoPropose` 未单独写测试（不在指定覆盖清单内）。
</verification>

