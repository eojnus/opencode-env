# 应用 opencode-env 配置

- 会话 ID：`ses_e6ec05dffffeSx5BoLa5HmWgoN`
- 时间：2026-10-31 17:17
- 目录：`C:\Users\Administrator`
- 模型：`opencode/deepseek-v4.1-flash-free`

---

## 🙋 我

github/eojnus/opencode-env从这里给我把opencode的一切配置拉下来应用

## 🤖 AI

已按仓库 README 的恢复流程完成配置，并做了验证。

## 做了什么

1. **获取仓库**：本机没有 `git`，因此改用 tarball 下载 `eojnus/opencode-env`（main 分支）并解压。
2. **备份原配置**：`C:\Users\Administrator\.config\opencode.backup-20261031-1720`（原有内容只有 `service.json`）。
3. **恢复配置**到 `C:\Users\Administrator\.config\opencode`：
   - `AGENTS.md`（全局规则）
   - `opencode.json`（插件 `@slkiser/opencode-quota`）
   - `cli.json`（主题、鼠标、会话、tabs、diff 等终端设置）
   - `skills/`：8 个技能全部拷入
   - `agents/`、`commands/`：仓库里只有 `.gitkeep`，即空目录
4. **保留本机凭据**：`service.json` 未被覆盖（仓库也不包含它）。
5. **留存仓库副本**：`C:\Users\Administrator\opencode-env`，其中 `history/`（聊天记录导出）可随时翻阅。

## 验证结果

| 项目 | 状态 |
| --- | --- |
| `opencode.json` / `cli.json` JSON 解析 | 通过 |
| OpenCode 服务 | v2.2.5，`http://127.0.0.1:28894` 正常 |
| quota 插件 | 已加载，`opencode-quota v6.0.0` |
| 技能注册 | 8 个全部识别（3d-sky-background、build-hybrid-game-assets、design-first-ui-prompting、optimize-threejs-games、threejs、threejs-landscape、threejs-towers、threejs-weather） |

配置由 OpenCode 自动热加载，**不需要重启**。

## 需要你留意的三点

1. `cli.json` 里 `session.permissions` 是 `"autoaccept"`，即自动接受所有权限请求——这是仓库原样配置，安全上偏宽松，是否保留由你决定。
2. `session.verbosity: "low"` 不在 V2 的 CLI 设置文档里，会被忽略，不影响使用。
3. `history/` 只是 Markdown 导出，**不能**变回可继续的会话；会话记录本体在 `opencode.db`，仓库有意不含它。

另外本机仍没有 `git`，以后想用 `save.ps1` 把改动推回仓库，需要先装：`winget install Git.Git`。要我装吗？

## 🙋 我

安装

## 🤖 AI

安装已完成。没有 winget，我改用官方便携版 Git。

## 安装结果

| 项目 | 内容 |
| --- | --- |
| 版本 | Git `2.56.0.windows.4`（git-for-windows 官方最新 release） |
| 位置 | `C:\Users\Administrator\PortableGit`（便携版，无需管理员、无注册表安装） |
| PATH | 已写入用户级 PATH：`C:\Users\Administrator\PortableGit\cmd` |
| 附带组件 | Git Bash、SSH、Git Credential Manager 均可用 |
| git 身份 | `Eojnus <68176476+eojnus@users.noreply.github.com>`（GitHub noreply 邮箱，避免暴露真实邮箱；要改就 `git config --global user.email "..."`） |

## 仓库也一并变成真 clone

之前是解压的压缩包副本，现在换成了标准 clone：

```
C:\Users\Administrator\opencode-env
## main...origin/main   ← 工作区干净，与远端同步
origin  https://github.com/eojnus/opencode-env
```

`save.ps1` 用的是 `$PSScriptRoot` 定位仓库，所以路径不用改，直接可用。

## 一个需要注意的点

PATH 是写到注册表的，**当前正在运行的 opencode 服务仍持有旧环境变量**，所以在本次会话里直接敲 `git` 还是会提示找不到（我用全路径验证过，功能正常）。处理方式二选一：

- 关掉并重开 opencode（推荐，一次搞定）
- 或者在新开的终端里执行，也能直接识别 `git`

之后上传配置就很简单：

```powershell
cd C:\Users\Administrator\opencode-env
.\save.ps1 -Message "同步本机配置"
```

首次 `push` 会由 Git Credential Manager 弹出 GitHub 登录窗口，登录一次后凭据会记住。如果想卸载这套 Git，删掉 `C:\Users\Administrator\PortableGit` 目录和 PATH 里那一项即可。

