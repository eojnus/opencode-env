# opencode-env

OpenCode 的环境备份仓库：**全局配置、技能、插件清单、聊天记录**。
换电脑时用它恢复，不用重配一遍。

**本仓库是 Public**：clone / 浏览不需要登录 GitHub，只有推送才需要认证。

> 这个 README 是写给**后来的 AI 助手**看的。人类只需要说一句
> 「照仓库 README 把我的环境装好」或「照 README 把环境传上去」。

---

## 一、仓库里有什么

```
opencode-env/
├─ config/                     ← 要恢复的东西
│  ├─ AGENTS.md                全局规则
│  ├─ opencode.json            插件、默认模型
│  ├─ cli.json                 主题、快捷键、TUI 插件
│  ├─ tui.json                 TUI 插件（oh-my-opencode-slim）
│  ├─ oh-my-opencode-slim.json 编排器/子 agent 的预设与模型
│  ├─ skills/                  技能（8 个）
│  ├─ agents/                  自定义 agent（可能为空）
│  └─ commands/                自定义命令（可能为空）
├─ history/                    ← 聊天记录导出（Markdown，自动生成，不要手改）
├─ bootstrap.ps1               新机器一键恢复
├─ save.ps1                    本机改动 → 新分支 → 合并 main
├─ export-sessions.ps1         单独导出聊天记录
└─ .gitignore / .gitattributes
```

---

## 二、往仓库上传（本机 → GitHub）

### 给 AI 的指令

用户说「把环境传上去」时，按下面执行。

**必须遵守的两条规则：**

1. **每次上传都开一个新分支，不要直接提交到 `main`**
2. **合并到 `main` 之后，分支要保留，不要删除**

### 分支命名

```
sync/YYYYMMDD-HHMMSS
```

例：`sync/20261028-234501`

### 流程

```powershell
$repo = "C:\Users\Eojnus\opencode-env"

# 0. 本机有失效代理时，网络操作一律加这两个参数
$net = @('-c','http.proxy=','-c','https.proxy=')

# 1. 同步 main
git -C $repo fetch origin
git -C $repo checkout main
git -C $repo @net pull --ff-only origin main

# 2. 开新分支
git -C $repo checkout -b sync/20261028-234501

# 3. 拷贝文件（见下方白名单）
# 4. 提交
git -C $repo add -A
git -C $repo commit -m "sync: 2026-10-28 23:45"

# 5. 推送分支（保留，不要删）
git -C $repo @net push -u origin sync/20261028-234501

# 6. 合并回 main
git -C $repo checkout main
git -C $repo merge --no-ff sync/20261028-234501 -m "merge: sync/20261028-234501"
git -C $repo @net push origin main
```

> PowerShell 里 `git -C $repo @net pull ...` 的 `@net` 是数组展开；如果目标 AI 用的是别的 shell，等价于
> `git -C <repo> -c http.proxy= -c https.proxy= pull --ff-only origin main`。

**最省事的做法**：直接跑 `.\save.ps1`，它已经把上面整套流程做完了。

### 上传白名单（只拷这些）

从 `%USERPROFILE%\.config\opencode\` 复制到 `config/`：

| 来源 | 目标 |
| --- | --- |
| `AGENTS.md` | `config/AGENTS.md` |
| `opencode.json` | `config/opencode.json` |
| `cli.json` | `config/cli.json` |
| `tui.json` | `config/tui.json` |
| `oh-my-opencode-slim.json` | `config/oh-my-opencode-slim.json` |
| `skills/` | `config/skills/`（整个目录） |
| `agents/` | `config/agents/` |
| `commands/` | `config/commands/` |

不拷贝：`*.json.bak` 自动备份、`.opencode.json.write-lock/` 之类的运行时锁目录。

另外由 `export-sessions.ps1` 生成 `history/`。

### 绝对不要上传

| 文件 | 位置 | 原因 |
| --- | --- | --- |
| `opencode.db` / `.db-wal` / `.db-shm` | `%USERPROFILE%\.local\share\opencode\` | 聊天记录 + **登录凭据** |
| `service.json` | `%USERPROFILE%\.config\opencode\` | 本机服务密码 |
| `auth.json`、`credentials.json` | 各处 | 登录凭据 |
| `log/`、`shell/`、`tool-output/`、`repos/` | `%USERPROFILE%\.local\share\opencode\` | 缓存与日志 |
| 任何 token / API key | 各处 | 账号安全 |

`.gitignore` 已经挡住这些，但**提交前仍然要 `git status` 看一眼**。

---

## 三、在新电脑上恢复（GitHub → 本机）

### 给 AI 的指令

用户说「照仓库 README 把环境装好」时，按下面执行。

### 1. 确认前置条件

- **Node/npm 已安装**（`node -v`、`npm -v`）
- 没有的话：`winget install OpenJS.NodeJS.LTS`，或从 https://nodejs.org 装 LTS

### 2. 安装 OpenCode

```powershell
npm install -g @opencode/cli
opencode --version
```

装完找不到命令就**重开终端**（PATH 需要刷新）。

### 3. 恢复配置

仓库是公开的，**不需要登录就能 clone**：

```powershell
git clone https://github.com/eojnus/opencode-env
```

**方式 A：跑脚本**

```powershell
cd opencode-env
.\bootstrap.ps1
```

脚本被策略拦截时：

```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

**方式 B：直接复制**

```powershell
$dest = Join-Path $env:USERPROFILE '.config\opencode'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item .\config\* $dest -Recurse -Force
# 如果目标机器已有配置，先备份
```

**注意路径**：配置目录是 `%USERPROFILE%\.config\opencode`，
**不是** OpenCode 程序所在目录（程序通常在 `AppData\...\nodejs\` 或 `~/.cache/opencode/bin`）。拷错地方不生效。

### 4. 收尾

- `.gitkeep` 这类占位文件可以删掉，不影响
- 聊天记录不是可恢复会话，`history/` 只供阅读和检索
- 免费模型一般不需要登录；需要时再 `opencode auth login`

---

## 四、常见问题

**push 报 `Failed to connect to github.com:443 over proxy 127.0.0.1`**

本机 git 配了本地代理（Clash 之类）但代理没开。所有网络操作加 `-c http.proxy= -c https.proxy=`，
或者直接用 `save.ps1`（它已内置绕过）。

**PowerShell 报「缺少右 }」**

`.ps1` 里有中文时必须是 **UTF-8 with BOM** 编码，否则 PowerShell 5.1 按 GBK 读会语法错。改完脚本记得保持 BOM。

**`git push` 提示 no upstream branch**

```powershell
git push -u origin <分支名>
```

**想撤销上一次同步**

main 上有完整历史，用 `git revert <commit>` 生成反向提交，不要 `reset --hard` + 强推。

---

## 五、安全

- 本仓库是 **Public**：任何人都能读到 `config/` 和 `history/`（聊天记录）。**上传前必须确认没有敏感内容**，一旦推上去就等于公开，事后改回私有也无法收回搜索引擎缓存。
- **绝不能**提交：`opencode.db`（含登录凭据）、`service.json`（本机密码）、任何 token / API key、真实邮箱与密码
- 上传前检查 `git status`，`save.ps1` 也会自动扫描并中止
- 推送需要认证；在公共电脑上推完记得 `gh auth logout`，并清理 git 凭据：
  `git credential-manager erase`
- 曾经的 `opencode.db` **从未**进入本仓库；以后也不要加进来
