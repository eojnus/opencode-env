# opencode-env

我的 OpenCode 环境备份。换电脑时一条命令恢复。

## 新电脑上怎么用

```powershell
git clone <本仓库地址>
cd opencode-env
.\bootstrap.ps1
```

脚本会：检查并安装 opencode → 备份原有配置 → 把 `config/` 复制到 `~/.config/opencode`。

前置条件只有一个：**装了 Node/npm**。没有的话先 `winget install OpenJS.NodeJS.LTS`。

## 改完配置怎么存回去

```powershell
.\save.ps1
.\save.ps1 -Message "加了新技能"
```

## 这里存了什么

| 文件 | 内容 |
| --- | --- |
| `config/AGENTS.md` | 全局规则 |
| `config/opencode.json` | 插件、默认模型 |
| `config/cli.json` | 主题、快捷键、TUI 插件 |
| `config/skills/` | 技能 |
| `config/agents/` | 自定义 agent（可空） |
| `config/commands/` | 自定义命令（可空） |

## 这里**不**存什么

- `opencode.db` —— 聊天记录 + 登录凭据，**永远不要提交**
- `service.json` —— 本机服务密码
- 日志、缓存、shell 输出
- 任何形式的 token / API key

所以新电脑上**聊天历史是空的**，需要的话在新机器上重新 `opencode auth login`。

## 安全提醒

- 本仓库必须设为 **Private**
- 不要在任何 commit 里放 `service.json` 或 token（`.gitignore` 已挡，但提交前仍要 `git status` 看一眼）
- 用完公共电脑记得清 git 凭据：`git credential-manager erase`，或在 Windows 凭据管理器里删掉对应条目

## 常见问题

**push 报 `Failed to connect to github.com:443 over proxy 127.0.0.1`**

本机 git 配了本地代理（Clash 之类）但代理没开。`save.ps1` 已经绕过代理推送，手动操作时用：

```powershell
git -c http.proxy= -c https.proxy= push
```
