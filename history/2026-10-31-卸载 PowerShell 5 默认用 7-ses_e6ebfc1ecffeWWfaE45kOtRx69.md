# 卸载 PowerShell 5 默认用 7

- 会话 ID：`ses_e6ebfc1ecffeWWfaE45kOtRx69`
- 时间：2026-10-31 17:17
- 目录：`C:\Users\Administrator`
- 模型：`opencode/deepseek-v4.1-flash-free`

---

## 🙋 我

把powershell5给我卸载，默认用powershell7

## 🤖 AI

我先确认一下当前环境：PowerShell 7 是否已安装、Windows PowerShell 的版本，之后再决定怎么处理“卸载”和“默认”。

## 🤖 AI

当前状态已经清楚了：

- 已安装 **PowerShell 7.6.6**，路径是 `C:\Program Files\PowerShell\7\pwsh.exe`，并且在 PATH 中排在 5.1 前面
- `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`（5.1）仍然存在
- **Windows PowerShell 2.0 引擎**处于启用状态（这是安全隐患，可以移除）
- 系统里**没有安装 Windows Terminal**，所以“默认终端”只能从 PATH 和文件关联这两处入手

先把可以安全移除的部分处理掉：

## 🤖 AI

PS 2.0 引擎已关闭，并且不需要重启。现在查看还有哪些地方仍在用 5.1：

