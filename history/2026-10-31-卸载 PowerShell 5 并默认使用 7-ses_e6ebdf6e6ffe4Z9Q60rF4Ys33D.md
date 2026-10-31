# 卸载 PowerShell 5 并默认使用 7

- 会话 ID：`ses_e6ebdf6e6ffe4Z9Q60rF4Ys33D`
- 时间：2026-10-31 17:19
- 目录：`C:\Users\Administrator`
- 模型：`opencode/deepseek-v4.1-flash-free`

---

## 🙋 我

把powershell5给我卸载，默认用powershell7

## 🤖 AI

我先看一下当前系统里 PowerShell 的实际安装情况，再决定能卸到什么程度。

## 🤖 AI

我已经查清了当前的状态，但有一个重要事实需要你先确认：

**Windows PowerShell 5.1 无法卸载。** 它是 Windows 的系统组件（在注册表里没有卸载项，文件位于 `C:\Windows\System32\WindowsPowerShell\v1.0`，并受系统保护）。强行删除会破坏 WinRM、组策略、部分安装器的 .NET 调用，而且系统更新会把它复原。

你的机器现状是：
- PowerShell 7.6.6（`C:\Program Files\PowerShell\7\pwsh.exe`）✅ 已安装，已在 PATH 里
- Windows PowerShell 5.1（`10.0.19041.3996`）
- 没装 Windows Terminal，所以没有“默认 profile”可改；默认入口是 Win+X 菜单、开始菜单和 .ps1 关联

所以能做的“卸载”实际是**让 PS7 成为默认、把 PS5.1 入口全部换掉或禁止**。这一步需要你选择强度：

## 🤖 AI

明白，按“换默认入口”来做。先摸清现有注册表和快捷方式的实际值，避免改错。

## 🤖 AI

现状已经确认清楚：Win+X 里的 `01a`/`02a` 两个快捷方式、开始菜单中的 4 个 `.lnk`，以及 `.ps1` 的关联（当前指向 `Microsoft.PowerShellScript.1` → 用记事本打开）。我先做完整备份，再逐项修改。

## 🤖 AI

`.ps1` 上有一个 `UserChoice` 锁定了旧的 ProgID（这是资源管理器级别的绑定），需要清掉它，自定义关联才会生效。

## 🤖 AI

`UserChoice` 被系统用 Deny ACE 锁死（不能删、不能改 DACL）。但它的哈希只绑定 ProgID 名，所以正确做法是**给这个 ProgID 加一个按用户覆盖的命令**，不需要动 `UserChoice`。

## 🤖 AI

`.ps1` 已确认走 PowerShell 7.6.6 Core（用真实 ShellExecute 验证通过）。接下来关闭遗留的 PowerShell 2.0 引擎。

## 🤖 AI

V2 引擎已禁用，5.1 本体未受影响。最后刷新 Win+X 菜单缓存，并检查有没有 VS Code 之类的终端默认项需要一起改。

## 🤖 AI

已完成。先说明关键事实：**PowerShell 5.1 无法卸载**——它是 Windows 的系统组件（注册表里没有卸载项，文件在 `C:\Windows\System32\WindowsPowerShell\v1.0`，受系统保护）。所以我把“卸载”落成了“把 PS5 的所有入口换成 PS7”，按你选的方案执行。

## 已完成的改动

| 项目 | 改动前 | 改动后 |
|---|---|---|
| Win+X 菜单（2 个入口） | `powershell.exe` | `C:\Program Files\PowerShell\7\pwsh.exe`，管理员标记按原样保留 |
| 开始菜单 | `Windows PowerShell` + `(x86)` + 两个 ISE | 全部移除，只留 `PowerShell 7 (x64)` |
| `.ps1` 双击打开 | 记事本（`Microsoft.PowerShellScript.1`） | `pwsh.exe -NoLogo -File "%1"` |
| PowerShell 2.0 引擎 | Enabled | Disabled（`-Version 2` 已拒绝启动） |

验证结果：
- `AssocQueryString` 解析出的 `.ps1` 打开命令 = `"C:\Program Files\PowerShell\7\pwsh.exe" -NoLogo -File "%1"`
- 用真实 ShellExecute 触发一个探测脚本，回写的是 `7.6.6 / Core`，确认走的是 PS7
- `powershell.exe` 本身仍能启动（`5.1.19041.6328`），没有被破坏
- 已重启 explorer，Win+X 菜单刷新生效

## 两点需要你知道

1. **双击 `.ps1` 现在会直接执行脚本**，不再是用记事本打开。右键菜单里保留了「Edit」（用记事本编辑）。
2. `powershell` 这个命令名仍然存在，指向 5.1。部分安装器、组策略、旧版 `.msi` 会显式调用它，所以没动。如果你连这个也不想让它被调用，可以再加一层 ACL 拒绝执行，但那属于不受支持的操作，需要时再说。

## 备份与还原

备份在 `C:\Users\Administrator\ps-migration-backup\20261031-172249\`（快捷方式原件 + 三份注册表导出）。

还原只需：
```powershell
# 快捷方式
Copy-Item 'C:\Users\Administrator\ps-migration-backup\20261031-172249\*.lnk' "$env:LOCALAPPDATA\Microsoft\Windows\WinX\Group3\" -Force
reg import 'C:\Users\Administrator\ps-migration-backup\20261031-172249\hkcr-psscript.reg'
# 移除按用户覆盖
Remove-Item 'HKCU:\Software\Classes\Microsoft.PowerShellScript.1' -Recurse -Force
# 恢复 PS2 引擎（可选）
Enable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -NoRestart
```

顺带一提：OpenCode 自己的终端本来就走 `pwsh`，这台机器也没装 Windows Terminal 和 VS Code，所以没有额外的默认位置要改。

## 🙋 我

我要安装一个msi程序，弹以下报错是怎么回事Add-AppxPackage: 在模块 'Appx' 中找到了 'Add-AppxPackage' 命令，但由于以下错误而无法加载该模块: [Operation is not supported on this platform. (0x80131539)]

## 🤖 AI

转义被吞了，我改用脚本文件来测。

## 🤖 AI

找到了。你的 `Downloads` 里确实有个 **`Codex-Windows-x64.msix`**（980 MB，17:28 下载）。先看清楚这个包再动手。

## 🤖 AI

这是 **ChatGPT 桌面版**（包名 `OpenAI.Codex`，显示名 ChatGPT，签名有效）。它用的是 `.msix` 格式 —— 这就是 `Add-AppxPackage` 的来源。我用 5.1 装它。

## 🤖 AI

搞定了，**已经帮你装上**。下面是这个报错的来龙去脉。

## 一、先纠正一点：那个文件不是 MSI

`C:\Users\Administrator\Downloads\Codex-Windows-x64.msix` —— 是 **MSIX**（AppX 包格式），不是 MSI。它是 **ChatGPT 桌面版**（包名 `OpenAI.Codex`，版本 `26.1021.3705.0`，签名有效）。MSIX 的标准安装命令就是 `Add-AppxPackage`，所以报错出现在这里。

## 二、为什么报 `0x80131539`

`0x80131539` = `COR_E_PLATFORM_NOT_SUPPORTED`（平台不支持）。

`Appx` 模块是 **Windows PowerShell 5.1 专属**的。它底层包装的是 .NET Framework 里的 `Windows.Management.Deployment` / WinRT 互操作。而 PowerShell 7 跑在 .NET 8 上，根本没有这套 API 绑定，所以模块一加载就抛 `PlatformNotSupportedException`。

实机验证：

| | `Import-Module Appx` | 结果 |
|---|---|---|
| `pwsh` 7.6.6 | 抛 `System.PlatformNotSupportedException` | 你看到的报错 |
| `powershell.exe` 5.1 | OK，枚举到 58 个已装包 | 正常 |

报错文案「找到了 Add-AppxPackage 命令，但无法加载模块」也是因为这个：PS7 的 `PSModulePath` 里包含 `C:\Windows\System32\WindowsPowerShell\v1.0\Modules`，所以它能"看见"这个模块，但加载时炸了。

## 三、为什么会正好碰到

因为刚才把 **Win+X 菜单换成了 PowerShell 7**。你从那里执行安装命令，跑的就是 PS7。以前那个位置是 5.1，所以同样的命令是能过的。

这也正好解释了为什么 5.1 不能真删 —— Appx 这一整组 cmdlet 只活在 5.1 里。

## 四、安装结果

用 5.1 执行 `Add-AppxPackage`，22 秒装完：

```
Name            : OpenAI.Codex
Version         : 26.1021.3705.0
Status          : Ok
InstallLocation : C:\Program Files\WindowsApps\OpenAI.Codex_26.1021.3705.0_x64__2p2nqsd0c76g0
CodexSandboxService.OpenAI.Codex   Running   Automatic
```

开始菜单里找 **ChatGPT** 即可启动。

## 五、以后装 msix 的正确姿势

在 PS7 里要显式转给 5.1：

```powershell
powershell.exe -NoProfile -Command "Add-AppxPackage -Path 'C:\path\to\app.msix'"
```

在 5.1 窗口里则可以直接 `Add-AppxPackage -Path ...`。如果包来自第三方且证书没进信任库，会报 `0x800B0109`，那种情况需要先把包里的 `.cer` 导入「受信任人」。

## 六、顺带发现一个坑

你的 **Windows PowerShell 5.1 执行策略是全 Undefined**，即默认的 `Restricted` —— 刚才我试着用 `-File` 跑一个 `.ps1` 直接被拒。这意味着任何安装器只要调用 `powershell.exe -File xxx.ps1` 就会失败（`-Command` 不受影响）。

要不要我把它改成 `RemoteSigned`？这不会降低安全性（本地脚本照常跑，网上下载的仍需签名），但能免掉一类安装失败。

## 🙋 我

给我安装github上的oh-my-opencode-slim，别看错了，要最高星星数量的

## 🤖 AI

最高星的是 **`alvinunreal/oh-my-opencode-slim`**（10,027 ★），其余同名仓库都是 fork（1 ★）。现在读它的安装文档。

## 🤖 AI

安装方式是 npm 包形式：`npx oh-my-opencode-slim@latest install`。先看运行时环境和 CLI 选项。

## 🤖 AI

这个插件默认配的是 OpenAI / OpenCode Go 模型，而你这台机器只有 DeepSeek 和 opencode 免费模型。先确认配置格式再动手。

## 🤖 AI

现在执行安装（非交互模式）。

## 🤖 AI

插件已装好，OpenCode 已热加载（新 skills 已经出现了）。现在看它生成的文件，并把默认模型改成你实际可用的。

## 🤖 AI

装好了。先确认你担心的"看错仓库"这件事：

| 仓库 | 星 | 说明 |
|---|---|---|
| **`alvinunreal/oh-my-opencode-slim`** | **10,027** | 正主，MIT，`master` 分支，今天还在提交 |
| `pxzleo/oh-my-opencode-slim` | 1 | 同名 fork |
| `ninipa/oh-my-dsh-slim` | 18 | 移植到别的 harness |

装的是第一个，npm 包 `oh-my-opencode-slim@3.0.6`。

## 做了什么

用官方安装器（非交互）：

```
npx oh-my-opencode-slim@latest install --no-tui --background-subagents=yes
```

改动清单：

- `~/.config/opencode/opencode.json` → `plugins` 加了 `oh-my-opencode-slim`，并开了 `lsp: true`
- 生成 `~/.config/opencode/oh-my-opencode-slim.json`
- 预热插件缓存到 `~/.cache/opencode/packages/oh-my-opencode-slim@latest`
- 写入用户级环境变量 `OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true`、`OPENCODE_ENABLE_EXA=1`
- OpenCode 已热加载（这轮对话里已经能看到它带的 `deepwork`、`simplify`、`codemod`、`reflect` 等 skill 和 `context7`、`gh_grep` 两个 MCP）

`doctor --json` 校验：`ok: true`，preset 解析正常。

## 一个必须处理的坑

安装器默认生成的是 **OpenAI 预设**（`openai/gpt-6.1-sol`）和 **OpenCode Go 预设**，而你这台机器只认证了 DeepSeek，可用模型只有：

```
deepseek/deepseek-v4-pro   deepseek/deepseek-flash
opencode/deepseek-v4.1-flash-free   opencode/glm-5.3-flash-free
opencode/mimo-v2.6-flash-free   opencode/nemotron-3.5-*-free
```

如果直接用默认预设，五个 agent 全部报"模型不可用"。所以我加了一个 `deepseek` 预设并设为激活：

| Agent | 模型 | 理由 |
|---|---|---|
| orchestrator | `deepseek/deepseek-v4-pro` | 规划/调度，要最强判断力 |
| oracle | `deepseek/deepseek-v4-pro` | 架构评审 |
| explorer | `deepseek/deepseek-flash` | 检索要快 |
| designer | `opencode/glm-5.3-flash-free` | UI 产出 |
| fixer | `deepseek/deepseek-v4-pro` | 实现 |

原来的 `openai` / `opencode-go` 预设仍然保留着，随时可以 `/preset openai` 切回去。想改模型直接编辑 `~/.config/opencode/oh-my-opencode-slim.json`，改完 v2 会自动热重载。

## 你接下来要做的

1. **重启 OpenCode**。环境变量是用户级的，只对新进程生效 —— 后台 subagent 和 Exa 搜索要重启后才真正打开。
2. 启动后输入 `ping all agents` 验证五个 agent 是否在线。

## 两个提醒

- 插件的 `setDefaultAgent` 默认是 `true`，新会话的默认 agent 会变成 **Orchestrator**（不是你现在的 build/plan）。不想被改就在配置顶层加 `"setDefaultAgent": false`。
- 配置原件已备份到 `C:\Users\Administrator\ps-migration-backup\opencode-cfg-20261031-174518\`，回滚直接拷回去即可。

要我把 `setDefaultAgent` 关掉，或者把模型映射换成你偏好的组合吗？

