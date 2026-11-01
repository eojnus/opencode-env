# Fix smoke script save version assertion

- 会话 ID：`ses_e6834f5e1ffe1BvytAHriw1g9r`
- 时间：2026-11-01 23:47
- 目录：`C:\Users\Administrator`
- 模型：`opencode-go/deepseek-v4.1-flash`

---

## 🙋 我

You are a subagent spawned by another session.
工作区：C:\CODING-worktrees\city-government-transport（分支 feature/city-government-transport）。

只修改 `scripts/mechanisms-smoke.cjs` 及必要时 `scripts/smoke-main.cjs` 中同类硬编码；不要改 src/**、tests/**、docs/**。

## 问题
`scripts/mechanisms-smoke.cjs` 末尾存档往返部分把 `formatVersion: 2` 硬编码在返回值里（搜索 `formatVersion: 2`）。当前游戏存档格式已是 v4（`SAVE_FORMAT_VERSION` 在 `src/simulation/contracts/types.ts`，且 `window.__lanwan.store.saveFormatVersion` 已暴露为 getter）。硬编码输出会伪造验证结论。

## 要求
1. 删除 `formatVersion: 2` 这类硬编码断言/输出。
2. 存档往返时，脚本必须：
   - 调用 `store.saveSlot('manual-1')`；
   - 从磁盘读取**本次实际产生的存档文件**。脚本里已有 `savesDir = path.join(app.getPath('userData'), 'saves')`；读取 `path.join(savesDir, 'manual-1.json')`（先确认实际文件名；如 hook 使用别的扩展名，列出目录后按 slot 匹配）。把文件内容 `JSON.parse`，取 `formatVersion`。
   - 读取 `window.__lanwan.store.saveFormatVersion` 作为当前游戏格式。
   - 断言：文件存在且 JSON 可解析；文件 `formatVersion` 是整数；`file.formatVersion === storeFormatVersion`。把 `fileFormatVersion`、`storeFormatVersion`、`fileGameVersion`、`dateSaved/dateAdvanced/dateAfterLoad` 写入结果对象。
   - 若文件缺失、不可读或版本不一致：把 `result.save.ok = false`、`result.save.error` 写成可读原因，打印结果后 `process.exitCode = 1`，并确保窗口销毁/应用退出（不要静默通过）。
3. 顺带确认结果里没有其他硬编码的验证结论（例如把“通过”写死）。如果发现类似硬编码，用实际读取/断言替代。
4. 脚本仍需在隔离的临时 user data 目录运行（保留现有 `artifacts/mechanisms-smoke-user-data`），不得触碰真实存档。

## 注意
现在构建产物 `dist/` 可能不是最新的；你只需修改脚本本身，并说明验证方式。若希望本地验证，先运行 `npm run build`，再运行 `npm run smoke:mechanisms`（需要图形环境；若无法在后台可靠运行，请说明未执行）。

## 交付
用中文报告：改动位置（行）、新的断言逻辑、是否实际运行过以及输出摘要、未执行的原因。不要提交 git。

## 🤖 AI

我先查看相关脚本文件。

## 🤖 AI

已按要求只改了脚本。以下是报告。

<summary>
把 `scripts/mechanisms-smoke.cjs` 存档往返段落中硬编码的 `formatVersion: 2` 改为“从磁盘实际存档文件 + `store.saveFormatVersion` 双向读取后比对”的真断言；失败时输出可读原因并非零退出。顺带清掉 `scripts/smoke-main.cjs` 中一处写死的占位值。`src/**`、`tests/**`、`docs/**` 未改动，未执行 git 操作。
</summary>

<changes>
- `scripts/mechanisms-smoke.cjs`
  - 删除原第 358 行 `formatVersion: 2`（原存档往返整段原为 350–359 行）。
  - 新存档段（现 350–446 行）：
    - 渲染进程内执行 `saveSlot('manual-1')` → 记录 `dateSaved` → `tick()` 记录 `dateAdvanced` → `loadSlot('manual-1')` → 记录 `dateAfterLoad`，并读取 `store.saveFormatVersion`（现 353–371 行）。
    - Node 侧建立 `result.save` 对象（`saved/loaded/dateSaved/dateAdvanced/dateAfterLoad/datesRestored/storeFormatVersion/filePath/savesDirListing/fileBytes/fileFormatVersion/fileGameVersion/ok/error`，现 372–388 行）。
    - 断言链（389–446 行）：`saved`/`loaded` 为真 → `storeFormatVersion` 为整数 → `savesDir` 存在并列出目录内容 → 定位 `path.join(savesDir,'manual-1.json')`（如无则按同槽位 `.json` 兜底匹配，排除 `.bak`/`.tmp`）→ 文件非空 → `JSON.parse` 成功 → `parsed.formatVersion` 为整数 → `file.formatVersion === storeFormatVersion`。`datesRestored` 只作为事实记录（`dateSaved === dateAfterLoad`），不作为硬门槛。
    - 任一断言失败：写入 `save.ok=false` 与中文 `save.error`（389–446 行）。
  - 收尾（467–479 行）：`exitCode = result.save.ok ? 0 : 1`；仍先完整 `console.log(JSON.stringify(result))`，再 `win.destroy()`；失败时追加 `result.failures`、`console.error` 原因、`process.exitCode = 1` 并 `app.exit(1)`，不再静默通过。
  - 隔离数据目录保持不变：仍 `app.setPath('userData', artifacts/mechanisms-smoke-user-data)` + `registerSaveHandlers(() => savesDir)`（第 16–21 行未动），真实存档不受影响。
  - 已确认文件中不再有 `formatVersion: 2`；其余 `ok: true` 仅出现在 `click()` 辅助函数的真实点击返回（第 42 行），不是写死的验收结论；“不作为悬停验收通过”是注释，属真实兜底逻辑。
- `scripts/smoke-main.cjs`
  - 第 243–247 行：删除渲染进程返回对象里写死的 `bytesPreserved: false` 占位（该值原本随后被真实比较结果覆盖，但避免结果对象中出现伪造值）。该脚本没有 `formatVersion` 硬编码，未扩大改动。
</changes>

<verification>
- Performed: `node --check scripts/mechanisms-smoke.cjs`、`node --check scripts/smoke-main.cjs`
- Result: passed（语法 OK）
- Performed: 离线校验脚本 `C:\Users\Administrator\AppData\Local\Temp\opencode\verify-mech-save.cjs`——用 `new Function` 直接执行从 `mechanisms-smoke.cjs` 抽取的**实际断言源代码块**（stub 掉 `read`/`win`/`fs` 目录），跑 6 个用例
- Result: passed，全部符合预期：
  - `v4 一致` → `ok:true, fileFormatVersion:4, storeFormatVersion:4, datesRestored:true`
  - `v2 vs store 4`（旧硬编码场景）→ `ok:false`，`存档文件 formatVersion=2 与 store.saveFormatVersion=4 不一致`
  - `store.saveFormatVersion` 非整数 → `ok:false`（“不是整数”）
  - 文件缺失 → `ok:false`（“本次保存后未找到 manual-1 存档文件；目录内容：[]”）
  - 非法 JSON → `ok:false`（“存档文件不是有效 JSON：…（Expected property name …）”）
  - `formatVersion:"4"` 非整数 → `ok:false`（“存档文件 formatVersion 不是整数："4"”）
- Performed: `npm run build` → **失败**，但与本任务无关：`tests/policies.test.ts(34,19) TS2304 Cannot find name 'CompanyMonthlyStats'`、`(237,21) TS1308 await 只能在 async 函数中`（既有测试类型错误，未修改 tests）。
- Performed: 绕过 typecheck 单独构建 `npm run build:renderer` + `npm run build:electron`
- Result: passed（`dist/renderer`、`dist/electron` 生成成功），因此脚本运行所需的构建产物已就绪。
- Performed: `npm run smoke:mechanisms`
- Result: **未执行成功（环境缺失）**——`node_modules/electron/dist` 只有 `locales`，无 `electron.exe`/`path.txt`，`electron` 报 “Electron failed to install correctly”；补跑 `node node_modules/electron/install.js` 退出码 0 但二进制仍未落地（疑似下载被拦截）。故端到端 GUI 冒烟未跑，`artifacts/mechanisms-smoke-user-data` 未被创建。在有 Electron 二进制的图形环境中可直接 `npm run smoke:mechanisms` 复验；期望输出 `save.ok=true`、`save.fileFormatVersion === save.storeFormatVersion`（当前应为 4），失败时进程退出码 1。
</verification>

补充：`dist/` 是我刚构建出来的（原本不存在），属于构建产物；如需保持工作区干净可自行删除。未做任何 git 提交。

