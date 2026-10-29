# 安装 winget

- 会话 ID：`ses_e784adcbaffe6D9dEnwRbu3jkM`
- 时间：2026-10-29 20:49
- 目录：`C:\Users\Administrator`
- 模型：`opencode/deepseek-v4.1-flash-free`

---

## 🙋 我

给我安装winget

## 🤖 AI

我先检查一下当前系统的状态。

## 🤖 AI

系统是 Win10 22H2，已存在 `DesktopAppInstaller`，但版本停留在 1.0.30251.0（还没有 winget 的旧版）。我检查一下依赖包和网络。

## 🤖 AI

依赖包齐全（VCLibs UWPDesktop x64、UI.Xaml 2.8），网络也通。现在下载最新的 winget 安装包。

## 🤖 AI

最新版是 v1.29.380。开始下载安装包（217 MB，可能需要几分钟）。

## 🤖 AI

GitHub 直连速度太慢（约 25 KB/s），900 秒只下了 22 MB。我检查已下载的进度，并测速几个镜像。

## 🤖 AI

`gh-proxy.com` 响应最快。先测一下它的实际下载速度。

## 🤖 AI

速度 1.63 MB/s，够快。现在从已有的 21.9 MB 处续传剩余部分。

## 🤖 AI

下载完成（207.2 MB）。现在安装。

## 🤖 AI

缺少 `Microsoft.WindowsAppRuntime.1.8` 框架包。先看官方依赖清单。

## 🤖 AI

需要 Windows App Runtime 1.8。我下载官方依赖包（97 MB），里面包含所需的 msix。

## 🤖 AI

依赖已就绪，重新安装 winget。

## 🤖 AI

winget 已可用（v1.29.380），但 `%LOCALAPPDATA%\Microsoft\WindowsApps` 不在 PATH 里，所以直接输入 `winget` 会找不到。我把它加到用户 PATH。

## 🤖 AI

源检索也正常。现在清理下载的临时文件（约 300 MB）。

## 🤖 AI

安装完成 ✅

## 结果

| 项目 | 状态 |
|---|---|
| winget 版本 | **v1.29.380** |
| 原版本 | 1.0.30251.0（旧版，不带 winget） |
| 系统 | Windows 10 22H2 (19045.6332) x64 |
| 依赖 | VCLibs UWPDesktop 已有；补装了 **Windows App Runtime 1.8** (8000.616.304.0) |

## 过程说明

1. 系统里虽然已有 `Microsoft.DesktopAppInstaller`，但版本太老，没有 `winget` 可执行文件。
2. GitHub 直连速度只有 25 KB/s，改用 `gh-proxy.com` 镜像（1.6 MB/s）完成 207 MB 安装包下载。
3. 首次安装报 `0x80073CF3`：缺少 `Microsoft.WindowsAppRuntime.1.8` 框架包。从官方 `DesktopAppInstaller_Dependencies.zip` 取 x64 依赖装上后，重新安装成功。
4. 已验证 `winget --info` 和 `winget search` 均正常。
5. 临时文件（约 300 MB）已清理。

## 注意

当前已打开的终端里 PATH 还是旧环境，`winget` 可能仍提示找不到命令。**新开一个 PowerShell / CMD 窗口**即可直接使用，因为用户 PATH 中已包含 `%LOCALAPPDATA%\Microsoft\WindowsApps`。

常用命令示例：

```powershell
winget search 关键词
winget install --id Microsoft.PowerToys -e
winget upgrade --all
```

## 🙋 我

开了新的powershell还是不能winget指令啊

## 🤖 AI

我诊断一下具体是 PATH 没生效，还是 alias 没注册。

## 🤖 AI

我这边实测是通的：

- alias 文件正常（`IO_REPARSE_TAG_APPEXECLINK` → `...DesktopAppInstaller_1.29.380.0_x64...\winget.exe`）
- 用户 PATH 里确实有 `%LOCALAPPDATA%\Microsoft\WindowsApps`
- 用只含该目录的 PATH 启动 `cmd`，`winget --version` 返回 `v1.29.380`

所以问题出在你那个终端进程本身。我看看你的终端是哪个。

## 🤖 AI

你有个 PowerShell 窗口（PID 24116，21:14 启动）。我直接读它的环境变量，确认它拿到的 PATH 是什么。

## 🤖 AI

找到根因了。你那个 PowerShell 窗口拿到的 PATH 是：

```
...;C:\Users\Administrator\AppData\Roaming\npm        ← 末尾没有 WindowsApps
```

而注册表里现在是有的。也就是说 **explorer.exe 的环境块是旧的**，它启动的所有终端都继承这份过期环境，所以新窗口也没有 `winget`。我来刷新它。

## 🤖 AI

确认了：`explorer.exe`（PID 4780，20:25 启动）的环境块里缺少 `WindowsApps`，所以它开出来的每个终端都继承这份旧环境。只有重启 explorer 才能让它重新读取注册表 PATH。桌面和任务栏会闪一下，已打开的资源管理器窗口会关闭。

## 🤖 AI

新的 explorer 进程环境已包含 `WindowsApps`。我再做一次端到端验证：让 explorer 直接启动一个脚本跑 `winget --version`。

## 🤖 AI

已解决 ✅ 我给你新开了一个 PowerShell 窗口，直接在里面敲 `winget --version` 就行。

## 真正的原因

winget 早就装好了，装的是 v1.29.380。问题不在安装，而在于**环境变量没有刷新**。

我读取了各进程内存里的实际环境块，对比结果如下：

| 进程 | PATH 里的 `WindowsApps` |
|---|---|
| 注册表 `HKCU\Environment` | ✅ 有（`%LOCALAPPDATA%\Microsoft\WindowsApps`） |
| explorer.exe（PID 4780，20:25 启动） | ❌ **没有** |
| 你那个 PowerShell（PID 24116） | ❌ 没有（继承自 explorer） |

Windows 的 PATH 在进程启动那一刻就固定下来了。`explorer.exe` 是在那条 PATH 被写入之前启动的，它一直拿着旧的副本；之后你开的每个终端都是它的子进程，所以全都没有 `winget`。这也解释了为什么「开新窗口」一直没用，因为新窗口继承的仍然是同一份旧环境。

## 我做了什么

1. 重启 `explorer.exe`，让它重新读取注册表里的 PATH（桌面和任务栏闪了一下，这是正常现象）。
2. 验证新 explorer 的环境块已包含 `WindowsApps`。
3. 端到端验证：让 explorer 启动一个脚本执行 `winget --version`，输出 `v1.29.380`，PATH 检查也通过了。
4. 清理了测试文件。

## 注意

**之前开着的 PowerShell 窗口直接关掉重开**，它们的环境已经固定，改不回来了。以后不会再出现这个问题，因为现在 explorer 里有正确的 PATH 了。

顺带说一句，之前安装时的 `0x80073CF3` 报错也解决了，补装了 `Microsoft.WindowsAppRuntime.1.8` 依赖包。

