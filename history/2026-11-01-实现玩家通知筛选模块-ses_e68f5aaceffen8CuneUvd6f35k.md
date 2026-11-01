# 实现玩家通知筛选模块

- 会话 ID：`ses_e68f5aaceffen8CuneUvd6f35k`
- 时间：2026-11-01 20:16
- 目录：`C:\Users\Administrator`
- 模型：`opencode-go/deepseek-v4.1-flash`

---

## 🙋 我

You are a subagent spawned by another session.
工作区：C:\CODING-worktrees\mechanisms-foundation（TypeScript 模拟游戏）。只改本工作区，不要运行 git 命令，不要 npm install。

任务：新建 `src/simulation/notifications/notifications.ts` 和 `tests/notifications.test.ts`。**只创建这两个文件**，不要修改其他文件（多人并行开发中）。

先读：`src/simulation/contracts/types.ts`（`PlayerNotification`、`NotificationAudience`、`NotificationKind`、`WorldState`、`HolderRef`、`ShareHolding`、`PlayerState`）、`src/data/config.ts`（`notifications` 配置节）。

背景：玩家通知按身份筛选——(a) 玩家个人相关；(b) 玩家有关企业（分红、其有权参与的表决、重大变化）；(c) 玩家担任市长的城市事件。玩家只是少量持股时，只通知分红、其有权参与的投票和重大变化；**无投票权的持有人不得收到要求其投票的通知**。界面不展示模拟步骤或技术日志。少量持股阈值与"重大变化"标准是**暂定可配置**方案（`config.notifications.majorStakeThreshold`），注释中明确。

数据事实：
- 股份权威数据在 `world.securities`：`classes: ShareClass[]`（`kind: 'voting' | 'nonVoting'`，`issuedShares`），`holdings: ShareHolding[]`（`companyId`、`shareClassId`、`holder: HolderRef`、`shares`）。
- 玩家的持股可在 `world.player.holdings` 里找到镜像，但投票权必须按 `world.securities.holdings` + 对应 class 的 `kind === 'voting'` 计算，且 `holder.type === 'player'`。
- 玩家担任市长：`world.player.roles.mayorCityId`（可能是 null）。
- 经营控制：`world.governance.controls` 中 `operator` 为 `HolderRef`（type 'player'）的公司视为玩家控制。

实现导出（签名固定）：

```ts
export interface PlayerNoticeInput {
  audience: 'personal' | 'company' | 'city';
  kind: 'dividend' | 'vote' | 'major' | 'agreement' | 'market';
  priority?: 'normal' | 'important';
  companyId?: string;
  cityId?: string;
  title: string;
  body: string;
}
export function playerStakeOf(world: WorldState, companyId: string): number;      // 玩家持股 / 公司总发行股数（两类合计）
export function playerVotingSharesOf(world: WorldState, companyId: string): number;
export function playerControlsCompany(world: WorldState, companyId: string): boolean;
export function notificationVisible(world: WorldState, config: DemoConfig, input: PlayerNoticeInput): boolean;
export function notifyPlayer(world: WorldState, config: DemoConfig, input: PlayerNoticeInput): PlayerNotification | null;
export function markNotificationRead(world: WorldState, id: string): boolean;
export function markAllNotificationsRead(world: WorldState): void;
export function unreadNotificationCount(world: WorldState): number;
export function visibleNotifications(world: WorldState): PlayerNotification[]; // 新的在前，未读优先？返回按 tick 倒序、同 tick 按 id 倒序，UI 自行排序
```

可见性规则（暂定，写在文件头部注释）：
- `personal`：总是可见（如玩家分红、玩家操作结果）。
- `company` + `vote`：仅当 `playerVotingSharesOf > 0`（无投票权不通知表决）。
- `company` + `dividend`：仅当玩家持有该公司任意股份（两类之一 > 0）。
- `company` + `major`：玩家持股比例 ≥ `config.notifications.majorStakeThreshold`，或玩家控制该公司，或（事件为控制权/董事会变化且玩家有投票权）。为了让调用方区分，major 事件允许 `priority: 'important'` 表示控制权/经营异常；实现：若 `playerStakeOf >= 阈值 || playerControlsCompany` 可见；否则若 `priority === 'important'` 且 `playerVotingSharesOf > 0` 也可名。注释里说明。
- `company` + `market`（融资要约等）：`playerStakeOf >= 阈值` 或 `playerControlsCompany`。
- `company` + `agreement`：`playerControlsCompany` 或 `playerStakeOf >= 阈值`。
- `city`：仅当 `world.player.roles.mayorCityId === input.cityId`（玩家不是市长时城市通知一律丢弃；市长选举未实现，这是待定身份）。
- `dividend` 金额低于 `config.notifications.minDividendAmount` 时不通知（由调用方决定是否调用；本函数只按可见性过滤）。
- 公司/城市引用无效（id 不存在）时丢弃并返回 false。

`notifyPlayer`：可见才创建通知：id 形如 `n${tick}-${companyId ?? cityId ?? 'personal'}-${序号}` 且必须确定性（用 `world.notifications.length` 与自增序号组合，避免 Date.now/Math.random），`read: false`，push 到 `world.notifications`，超过 `config.notifications.maxEntries` 时从最旧删除。不可见返回 null 且不修改世界。

测试 `tests/notifications.test.ts` 覆盖：
- 无投票权持股（只有 nonVoting）时投票通知被丢弃；有投票权时可见。
- 低于 5% 阈值时 major 日常经营通知被丢弃，但分红通知可见；达到阈值可见。
- 玩家不是市长时城市通知被丢弃；`roles.mayorCityId` 设为该城后可见。
- 未读数、标记已读、全部已读、超过上限裁剪。
- 通知不包含"模拟步骤/校验"类内容（这条用断言 message/body 来自调用方即可，不必强行检查）。
用 `Simulation.create().state` 构造（若全项目暂时编译不过是正常的，先写好，我会统一修）。

约束：不修改 types.ts/config.ts；不引入 Math.random/Date.now；不做 UI 字符串拼接之外的逻辑。完成后回复：文件、规则、测试名、运行命令与结果（未运行说明原因）。不要 git 提交。

## 🤖 AI

我会先读取所需的契约和配置文件。

## 🤖 AI

现在我来创建 notifications 模块。

## 🤖 AI

<summary>
已按要求只新建两个文件：玩家通知模块与对应测试。实现按身份筛选通知（个人、持股企业、市长城市），投票权严格按 `securities.holdings` + 股份类别 `kind` 判定，通知 id 确定性生成，含已读、未读统计、上限裁剪与倒序展示。未修改其他文件，未运行 git 命令。

规则要点（文件头注释已写明【暂定/可配置】）：
- personal 始终可见。
- company+vote：`playerVotingSharesOf > 0`，无投票权持有人不会收到表决通知。
- company+dividend：持有任意类别股份（`playerStakeOf > 0`）。
- company+major：持股 ≥ `majorStakeThreshold` 或玩家控制公司；`priority: 'important'` 时，有投票权的小股东也可见（用于控制权/董事会变化）。
- company+market / agreement：持股 ≥ 阈值或玩家控制公司。
- city：仅 `player.roles.mayorCityId === cityId`。
- 无效公司/城市 id 丢弃；`minDividendAmount` 由调用方判断。
- `notifyPlayer` 用 `tick + 公司/城市/personal + 自增序号` 生成确定性 id，超过 `maxEntries` 从最旧裁剪。
- `visibleNotifications` 按 tick 倒序、同 tick 按序号倒序返回副本（未读不优先，UI 自行排序）。
</summary>
<changes>
- src/simulation/notifications/notifications.ts: 新建通知模块，导出 `PlayerNoticeInput`、`playerStakeOf`、`playerVotingSharesOf`、`playerControlsCompany`、`notificationVisible`、`notifyPlayer`、`markNotificationRead`、`markAllNotificationsRead`、`unreadNotificationCount`、`visibleNotifications`。
- tests/notifications.test.ts: 新建 12 个测试，覆盖无投票权表决、5% 阈值、important 例外、控制权、市长身份、无效引用、已读/全部已读、上限裁剪、顺序、文案透传。
</changes>
<verification>
- Performed: `npx vitest run tests/notifications.test.ts`
- Result: 通过（12/12）。
- Performed: `npx tsc -p tsconfig.json --noEmit`（检查新增文件相关报错）
- Result: 全项目退出码 2，报错来自并行开发中的其他文件；输出中没有任何 `notifications.ts` / `notifications.test.ts` 的报错，新增两文件类型检查干净。
</verification>

