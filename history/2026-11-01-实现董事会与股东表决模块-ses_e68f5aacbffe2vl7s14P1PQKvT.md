# 实现董事会与股东表决模块

- 会话 ID：`ses_e68f5aacbffe2vl7s14P1PQKvT`
- 时间：2026-11-01 20:16
- 目录：`C:\Users\Administrator`
- 模型：`opencode-go/deepseek-v4.1-flash`

---

## 🙋 我

You are a subagent spawned by another session.
工作区：C:\CODING-worktrees\mechanisms-foundation（TypeScript 模拟游戏）。只改本工作区，不要运行 git 命令，不要 npm install。

任务：新建 `src/simulation/corporate-governance/governance.ts` 和 `tests/governance.test.ts`。**只创建这两个文件**，不要修改其他文件（多人并行开发中）。

先读：`src/simulation/contracts/types.ts`（`Board`、`BoardSeat`、`Motion`、`MotionVote`、`CompanyControl`、`GovernanceState`、`HolderRef`、`ShareClass`、`ShareHolding`、`ShareKind`）、`src/data/config.ts`（`governance` 节）、`src/simulation/core/math.ts`（`allocateProportionally`、`round2`、`clamp`）。

背景：需要最小可运行的董事会、议案和表决，并让至少一项企业决策受表决结果影响。股东、董事、经营控制权必须分开：**持股不等于控制企业**。企业默认由职业经理人经营（`CompanyControl.operator === 'management'`），持股只产生投票权与董事席位。席位分配、票制、控制权规则都是**暂定演示方案**，必须在文件头注释写明。

证券数据（权威）：`world.securities.classes`（每个企业 `voting` / `nonVoting` 两类，`issuedShares`）与 `world.securities.holdings`（`shareClassId`、`holder`、`shares`）。投票权只来自 `kind === 'voting'` 的股份。股份持有人可能是 `player`、`company`、`investorGroup`。

为避免与正在并行编写的 `src/simulation/securities/securities.ts` 冲突，**不要 import 它**；在本文件内实现私有辅助函数读取 `world.securities`（这是治理模块对只读数据的局部投影，注释注明权威仍在 securities）。需要的辅助：`votingHoldersOf(world, companyId)`（返回 `{holder, shares}[]`，按 shares 降序、holder.type+id 升序）、`holderVotingShares(world, companyId, holder)`、`holderLabel(world, holder)`（玩家→"玩家 · 名字"；企业→企业名；居民投资实体→实体名；未知→id）、`holderIsValid(world, holder)`。

实现导出（签名固定）：

```ts
export function ensureGovernance(world: WorldState, config: DemoConfig, tick: number): void;
export function refreshBoards(world: WorldState, config: DemoConfig, tick: number): Board[];
export function boardFor(world: WorldState, companyId: string): Board | null;
export function openDividendPolicyMotion(world: WorldState, config: DemoConfig, tick: number): Motion | null;
export function castVote(world: WorldState, motionId: string, holder: HolderRef, vote: 'for' | 'against' | 'abstain', tick: number): { ok: boolean; error?: string };
export function autoCastVotes(world: WorldState, config: DemoConfig, tick: number): void;
export function closeMotions(world: WorldState, config: DemoConfig, tick: number, log: LogEntry[]): Motion[];
export function proposeOperatorMotion(world: WorldState, companyId: string, proposedBy: HolderRef, operator: HolderRef | 'management', tick: number, config: DemoConfig, log?: LogEntry[]): { ok: boolean; error?: string; motion?: Motion };
export function governanceFor(world: WorldState, companyId: string): { board: Board | null; control: CompanyControl | null; motions: Motion[] };
```

规则（暂定）：
- `ensureGovernance`：为缺少 Board/Control 记录的企业补齐（幂等）：Control = `{ operator: 'management', basis: 'management', sinceTick: tick, note: '演示：职业经理人经营，持股不等于控制权。' }`；Board 由 `refreshBoards` 生成。
- `refreshBoards`：每个企业按投票权持股分配 `config.governance.boardSeats` 个席位（最大余数法，用 `allocateProportionally`；只考虑 voting shares > 0 的持有人；若持有人数少于席位数，按 1 人 1 席补足后仍有空位则留空）。席位记录 `votingShares`、`sinceTick`（沿用旧席位若同一持有人已在任，保留 sinceTick），`chair` = 投票权最多的持有人（并列按 holder id）。`lastElectionTick = tick`。董事席位分配不是控制权。
- `openDividendPolicyMotion`：对每家企业（按 id 排序），若满足：`company.lastMonth.profit > config.governance.minProfitForMotion`、没有 open 的 dividendPolicy 议案、且当前 `company.dividendPayoutRatio < 1`，则由董事会主席（没有主席则投票权最大持有人；再没有则跳过）提出"提高股息派发比例至 1.0"的议案：`kind='dividendPolicy'`, `params={ ratio: 1 }`, `status='open'`, `createdTick=tick`, `closesAtTick = tick + config.governance.motionOpenTicks`, `votes=[]`, `result=''`, `note` 说明暂行规则。每 tick 最多提出 3 个（按企业 id 顺序），避免刷屏。
- `castVote`：校验 motion 存在且 open、holder 当前持有该公司投票权股份 > 0、同一持有人只能投一次（已投则允许改票：覆盖原记录并更新 weight，注释说明这是演示便利）。记录 `votingShares` = 当前投票权股数（若为 0 拒绝）。不修改 motion 状态。
- `autoCastVotes`：为 open 议案中**尚未投票**的持有人自动投票（player 除外，玩家由 UI 决定，缺席视为弃权）：居民投资实体按"支持提高股息"（vote 'for'，因现金流偏好，暂定）；企业持有人 vote 'against'（倾向保留资金，暂定）；其他类型 'abstain'。按 holder 排序保证确定性。
- `closeMotions`：对 `status==='open'` 且 `tick >= closesAtTick` 的议案计票：支持票权重 > 反对票权重 → passed；否则 rejected（含平票与无人投票）。通过后应用效果：
  - dividendPolicy：`company.dividendPayoutRatio = clamp(Number(params.ratio), 0, 1)`，log 记录"股东表决通过：股息派发比例调整为 X"。
  - operatorAppointment：把 `world.governance.controls` 中该企业的 operator 改为 `params.operatorType === 'management' ? 'management' : { type: params.operatorType, id: params.operatorId }`，`basis='boardAppointment'`。
  记录 `decidedTick`、`result`（人类可读中文）。不通过的议案不改企业状态，也写 log。返回本期关闭的议案。
- `proposeOperatorMotion`：仅当 proposedBy 是当前投票权持有人（>0）或董事会成员时允许；不能替换已存在的 open operatorAppointment 议案。参数 `operator` 序列化进 `params`（'management' 用 `operatorType:'management'`；具体持有人用 `operatorType`/`operatorId`）。
- 所有 log 用 `kind: 'player'`（与玩家相关）或 `'government'`；消息用可读中文，不出现内部字段名。

测试 `tests/governance.test.ts` 覆盖：席位按投票权分配且合计不超过席位数；同一持股人不能同时既无投票权又获得席位（nonVoting-only 持有人不得进入董事会）；议案投票按股份加权，通过后 `company.dividendPayoutRatio` 改变（可观察决策受影响）；反对票多时不通过且比例不变；无投票权持有人投票被拒绝；operator 议案通过后 control.operator 改变且 basis 正确；`ensureGovernance` 幂等。用 `Simulation.create().state`（若全项目暂未编译通过属正常，先写好测试）。

约束：金额/比例用 round2；遍历与并列全部按 id 确定性排序；不用 Math.random/Date.now；不新增 WorldState 字段。完成后回复：文件、规则、测试名、运行命令与结果（未运行说明原因）。不要 git 提交。

## 🤖 AI

我先阅读上下文文件，了解委托范围与规则。

## 🤖 AI

上下文清楚。现在我开始按固定签名与暂定规则编写治理模块。

## 🤖 AI

有一个测试没有把目标企业的派发比例调到低于 1，导致提案条件不成立。现在修正这个测试用例的初始化。

## 🤖 AI

<summary>
已在指定工作区仅新增两个文件，实现最小可运行的董事会、议案与表决闭环：企业默认由职业经理人经营，持股仅产生投票权与董事席位；股息政策议案是首个可观察受表决影响的企业决策。未改动任何其他文件，未运行 git，未执行 npm install，也未 import 并行开发的 `securities.ts`（治理模块内部只读投影 `world.securities`）。

</summary>
<changes>
- `src/simulation/corporate-governance/governance.ts`：新建。文件头注明席位分配、票制、控制权均为暂定演示方案，并声明证券权威仍在 `world.securities`。
  - 私有辅助：`votingHoldersOf`、`holderVotingShares`、`holderLabel`、`holderIsValid`（仅统计 `kind === 'voting'`，按股数降序、类型 + id 升序；玩家 id 兼容 `player` 与玩家名）。
  - `ensureGovernance`：幂等补齐 `CompanyControl`（`management` / `management` / 演示备注）与 `Board`。
  - `refreshBoards`：最大余数法分配 `boardSeats` 席；持有人少于席位时一人一席、剩余留空；同一持有人持多席时重复列出（`BoardSeat` 无席位数字段）；保留在任 `sinceTick`；`chair` 为投票权最多者（并列按 holder 类型 + id）；`lastElectionTick = tick`。
  - `openDividendPolicyMotion`：利润达标、无 open 同类议案、比例 < 1 时由主席/最大投票权持有人提案，每 tick 最多 3 个，返回首个提案。
  - `castVote`：校验 open、持股人有效、当前投票权股数 > 0；同一持有人改票覆盖旧记录并更新权重。
  - `autoCastVotes`：跳过玩家；居民投资实体投赞成、企业投反对、其他弃权，按 holder 排序保证确定性。
  - `closeMotions`：按权重计票，赞成 > 反对才通过；股息议案写入 `dividendPayoutRatio`，经营者议案改写 `operator` 并置 `basis='boardAppointment'`；通过/否决均写中文日志（`kind: 'player'`）。
  - `proposeOperatorMotion`：仅投票权持有人或董事可提案，禁止并存多个 open 经营者议案，经营者参数序列化进 `params`。
  - `governanceFor`：返回董事会、控制权、按创建 tick + id 排序的议案。
- `tests/governance.test.ts`：新建 7 个用例，使用 `Simulation.create().state`，测试内自建证券/投资实体夹具（当前 initializer 尚未生成 v0.2 数据，因此不依赖并行实现）：
  1. `按投票权股份分配席位，合计不超过席位数，且无投票权持有人不进入董事会`
  2. `表决按股份加权，通过后企业股息派发比例发生变化`
  3. `反对票权重更多时不通过，企业股息派发比例保持不变`
  4. `无投票权股份持有人投票被拒绝，也不进入董事会`
  5. `未投票的非玩家持有人按暂定立场自动投票`
  6. `通过后 control.operator 改变且 basis 为董事会任命`
  7. `ensureGovernance 幂等，并在重新选举时保留在任董事的起始 tick`

</changes>
<verification>
- Performed: `npx vitest run tests/governance.test.ts`
- Result: passed（1 个测试文件、7 个测试全部通过）
- Performed: `npx tsc -p tsconfig.json --noEmit`（检查新增文件类型）
- Result: 新增的 `governance.ts` 与 `governance.test.ts` 无类型错误；项目整体仍因并行开发中的 `initializer.ts`、`securities.ts`、`investors.ts`、旧测试缺 `dividendIncome` 而失败，属预期的并行未完成状态。
</verification>

