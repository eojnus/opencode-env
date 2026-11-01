# opencode-env 配置应用到本机

- 会话 ID：`ses_e6a29923fffeKks54gaO7CmCBn`
- 时间：2026-11-01 14:40
- 目录：`C:\Users\Administrator`
- 模型：`opencode/deepseek-v4.1-flash-free`

---

## 🙋 我

给我把github.com/eojnus/opencode-env里面的配置全都给我应用到本机opencode

## 🤖 AI

我会先研究这个仓库，再应用它的配置。

## 🤖 AI

README 提供了完整的恢复流程。接下来我先 clone 仓库，再查看实际内容。

## 🤖 AI

Git 未安装，但 Node 和 OpenCode（v2.2.5）都在。我改用下载 zip 包的方式获取仓库。

## 🤖 AI

仓库内容已确认：8 个技能、5 个配置文件，另有一个 bootstrap 脚本。现在运行恢复脚本（OpenCode 已安装，只恢复配置）。

## 🤖 AI

配置已生效，插件也已被加载。接下来做最后一步验证：检查日志里有没有加载错误。

## 🤖 AI

已全部应用完成并验证生效。

**做了哪些事**

1. 本机没装 `git`，改用 GitHub zip 下载仓库，解压到 `%TEMP%\opencode-env-src\opencode-env-main`
2. 运行官方 `bootstrap.ps1 -ConfigOnly`：先把原配置整份备份到 `C:\Users\Administrator\.config\opencode.bak-20261101-144057`，再复制配置
3. 原有的 `service.json`（本机服务密码）保留未动

**已还原到 `C:\Users\Administrator\.config\opencode\`**

| 文件 | 内容 |
| --- | --- |
| `opencode.json` | 插件 `@slkiser/opencode-quota`、`oh-my-opencode-slim`，`lsp: true` |
| `cli.json` | nord 主题、system 模式、鼠标/动画、思考隐藏、自动接受权限等 |
| `tui.json` | TUI 插件 `oh-my-opencode-slim` |
| `oh-my-opencode-slim.json` | 4 套预设（openai / opencode-go / deepseek / ds），当前激活 `ds` |
| `AGENTS.md` | 全局偏好（简体中文回复等） |
| `skills/` | 8 个技能：3d-sky-background、build-hybrid-game-assets、design-first-ui-prompting、optimize-threejs-games、threejs、threejs-landscape、threejs-towers、threejs-weather |
| `agents\`、`commands\` | 空（源仓库只有 `.gitkeep`，已清除） |

**验证结果**

- 服务 `opencode v2.2.5` 运行正常：`/api/info` 有响应
- 插件日志 `oh-my-opencode-slim.20261101T065041-22176.log`：`health check passed {agents:5, tools:10, mcps:2}`、`bundled skills 11 个`、5 个 agent 已注册、2 个 MCP 已注册
- 主日志无 error / failed / invalid
- 新技能与 AGENTS.md 已在本会话内热加载生效（无需重启）

**没做的事（按仓库 README 的说明）**

- `history/` 里的聊天记录是导出的 Markdown，只供检索，不是可恢复会话，因此没有导入
- 模型登录未处理：`ds` 预设用的 `deepseek/*`、`opencode/*` 需要凭据时再跑 `opencode auth login`
- 仓库自带的 `save.ps1`（把本机改动推回 GitHub）依赖 `git`，本机还没装；以后要同步需先 `winget install Git.Git`

