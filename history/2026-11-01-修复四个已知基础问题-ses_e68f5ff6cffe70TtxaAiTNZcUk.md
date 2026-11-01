# 修复四个已知基础问题

- 会话 ID：`ses_e68f5ff6cffe70TtxaAiTNZcUk`
- 时间：2026-11-01 20:16
- 目录：`C:\Users\Administrator`
- 模型：`opencode-go/deepseek-v4.1-flash`

---

## 🙋 我

You are a subagent spawned by another session.
工作区：C:\CODING-worktrees\mechanisms-foundation （TypeScript 模拟游戏，分支 feature/mechanisms-foundation）。只改本工作区，不要运行任何 git 命令，不要 npm install。

背景：这是"多城市经济模拟"原型。公共类型 `src/simulation/contracts/types.ts` 刚被升级到 v0.2：`Company` 新增 `previousMonth: CompanyMonthlyStats`（上一完整结算月统计）、`dividendPayoutRatio`；`CompanyMonthlyStats` 新增 `dividendIncome`；`DEMO_CONFIG`（`src/data/config.ts`）新增 `production.laborCapacityFactor`（1.08）、`company.purchaseCreditMode`。其他并行开发者正在改 `core/simulation.ts`、`core/save.ts`、`core/invariants.ts`、`core/initializer.ts`、`finance/finance.ts`、`securities/*`、`investors/*`、`agreements/*`、`notifications/*`、`ui/*`。**你只能改下面列出的文件，避免冲突。**

你的任务（只做这四个已复现缺陷，另加一个暂定行为）：

1. `src/simulation/companies/planning.ts`：经营计划目前读取 `company.lastMonth`，但 `simulation.ts` 在本期开始时已推进并重置 `lastMonth`（现在会先把旧值复制到 `previousMonth`）。改为读取 `company.previousMonth` 的 `produced/sold/exported`。不要改其他逻辑或数值。

2. `src/simulation/production/production.ts`：
   a. 零员工仍能生产：`runProduction` 的产出必须同时受当期员工限制。增加导出函数 `laborCapacity(company, city)`，返回 `company.employees * PRODUCTIVITY[company.recipeOutput] * city.technology.productivityMultiplier * config.production.laborCapacityFactor`（用 round2）。`runProduction` 的 `output = Math.min(productionTarget(company), laborCapacity(...))`，再按原料与配方限制。员工为 0 时产出必须为 0，且不消耗原料、不产生 ProductionRecord。
   b. 采购前借款（用户尚未决定，必须保留明确、可追溯的暂定行为）：当前 `runInputPurchasing` 在确认有缺口但市场无供应时也会 `ensureLiquidity` 借款。改为"结算式采购融资"：先只用自有现金（保留 `wageReserve`）下单；本地/跨城采购完成后，按**实际成交金额**补足现金，最多借入 `min(实际采购支出, 现金缺口到 wage*1.5)`，即借款只与实际成交挂钩。无任何成交时现金和债务完全不变。在函数上方的注释中写明：这是暂定行为（`DEMO_CONFIG.company.purchaseCreditMode === 'on-settlement'`），"无供应时是否允许独立备资借款"仍待用户决定，并说明影响（成交型融资不会让企业在无供应时凭空增加债务，但企业不能提前囤积现金）。
   c. 不要改生产配方、价格、市场撮合，也不要改 `productionTarget` 的语义（除员工上限）。

3. `src/simulation/population/population.ts`：`migrationAttractiveness` 中政治支持率方向错误（支持率越高吸引力越低）。改为 `+ city.politics.approval * config.population.approvalMigrationWeight`。保持其余项不变。加一行注释说明支持率含义：更高的支持率表示治理更好，应提高吸引力；但这是演示假设，不是最终规则。

4. 出口统计口径：`src/simulation/trade/trade.ts` 第 82-84 行把跨城合同成交量同时计入 `lastMonth.sold` 和 `lastMonth.exported`，导致经营计划里 `sold + exported` 重复计算。改为：跨城合同只增加 `exported`（不增加 `sold`）。`src/simulation/markets/intercity.ts` 中卖给他城买家的成交目前只增加 `sold`；请改为：当 `options.buyerCompanyId` 指向的买方企业所在城市与卖方城市不同（或 `options.consumer === true` 且这是跨城补货）时，增加 `exported`，否则增加 `sold`。保持本地成交计 `sold`。注意 `sold` 仍用于市场"成交量"语义的地方不要破坏（例如 `seller.company.lastMonth.sold` 只影响企业统计，不影响 `city.market[good].sold` 台账）。

5. 新增测试 `tests/bugfixes.test.ts`（vitest，风格参考 `tests/simulation.test.ts`）。至少覆盖：
   - 上月销售影响经营计划：构造两个相同世界，直接设置某企业 `previousMonth.produced/sold/exported` 不同，调用 `planCompanies`，断言利用率变化方向不同（另一个世界 lastMonth 为 0 也不影响结果，证明读的是 previousMonth）。
   - 零员工生产：取一个能源企业，把 employees/roles 设为 0，`runProduction` 后产出为 0，原料不变；再给回员工则产出 > 0。
   - 支持率方向：同一城市 approval 40 与 80 时 `migrationAttractiveness` 后者更高。
   - 采购借款：构造一个无任何供应（清空所有企业该商品库存或让城市市场无卖家）但有缺口的场景，调用 `runInputPurchasing` 后企业 cash/debt 不变；有供应时成交且借款 ≤ 实际采购支出。
   测试里可直接 import 模块函数、构造 `Simulation.create().state`。若因为并行开发导致全项目暂时无法编译，不要修改你的范围外文件；把测试写好，最后我会统一修复类型错误。

约束：金额/数量用 `round2`；遍历顺序按 id 排序保证确定性；不引入 Math.random；不新增全局状态。完成后回复：改动文件清单、每个问题的修复方式、新增测试用例名、你实际运行了哪些命令及结果（若无法运行请如实说明原因）。不要提交 git。

## 🤖 AI

我先查看工作区结构和相关文件。

## 🤖 AI

现在处理生产模块：

## 🤖 AI

<summary>
已完成 4 个复现缺陷修复和采购融资暂定行为改造，新增 5 个测试并全部通过。改动严格限制在指定文件内，未执行任何 git 命令或安装依赖。
</summary>

<changes>
- `src/simulation/companies/planning.ts`：经营计划的销售率改为读取 `company.previousMonth.produced/sold/exported`（本期开始时 `lastMonth` 已被重置），其它逻辑和数值未动。
- `src/simulation/production/production.ts`
  - 新增导出 `laborCapacity(company, city, config = DEMO_CONFIG)`，按 `employees × PRODUCTIVITY × city.technology.productivityMultiplier × config.production.laborCapacityFactor` 计算并 `round2`。
  - `runProduction` 改为 `output = Math.min(productionTarget(company), laborCapacity(...))` 后再受原料/配方限制；员工为 0 时在消耗原料前 `continue`，不产记录。
  - `runInputPurchasing` 删除采购前 `ensureLiquidity`，改为只用自有现金（保留 `wageReserve`）下单；成交后按实际支出补足现金，借款上限 `min(实际采购支出, 补到 wage*1.5 的现金缺口, 可用信贷额度)`，无成交时现金/债务完全不变。函数上方补充了暂定行为说明（`purchaseCreditMode === 'on-settlement'`、待用户决定的"无供应时是否允许独立备资借款"及其影响）。
  - 未改配方、价格、撮合逻辑或 `productionTarget` 语义。
- `src/simulation/population/population.ts`：`migrationAttractiveness` 中支持率项由负号改为正号，并加注释说明这是"高支持率=治理更好=吸引力更高"的演示假设。
- `src/simulation/trade/trade.ts`：跨城合同成交只累加 `exporter.lastMonth.exported`，不再同时累加 `sold`。
- `src/simulation/markets/intercity.ts`：以卖方城市与买方所在城市（`buyer.cityId`，无企业买方时用 `buyerCity.id`，居民跨城补货因此计出口）比较，不同则累加 `exported`，相同则累加 `sold`；仍只对卖方自身产出计入企业统计，`city.market[good].sold` 台账逻辑不受影响。
- `tests/bugfixes.test.ts`：新增 5 个测试用例。
</changes>

<verification>
- 新增测试用例名（`tests/bugfixes.test.ts`）：
  1. `经营计划读取 previousMonth，而不是本月初已重置的 lastMonth`（两个世界 `lastMonth` 故意反向设置，A 利用率上升、B 下降）
  2. `零员工企业不产出、不消耗原料；恢复员工后恢复产出`（能源企业 + 有原料投入的食品企业；恢复后产出 > 0 且 ≤ laborCapacity）
  3. `政治支持率越高，迁入吸引力越高`（approval 40 vs 80，并校验差值）
  4. `无供应时采购不改变现金和债务（成交式融资，不预先借款）`
  5. `有供应时成交，借款不超过实际采购支出`（另断言本地成交计 `sold`、不计 `exported`）
- 已执行：`npx vitest run tests/bugfixes.test.ts` → 5/5 通过。
- 已执行：`npx tsc -p tsconfig.json --noEmit` → 失败，错误全部位于范围外并行开发文件（`core/initializer.ts`、`core/simulation.ts`、`securities/securities.ts` 及既有 `tests/dividends.test.ts`、`tests/trade-atomic.test.ts`），我的 5 个源文件与新增测试无类型错误。按约定未修改范围外文件。
- 未运行全量 `npm test`，避免受并行开发未完成状态的干扰。
</verification>

