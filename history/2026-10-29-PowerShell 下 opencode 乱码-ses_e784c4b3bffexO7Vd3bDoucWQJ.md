# PowerShell 下 opencode 乱码

- 会话 ID：`ses_e784c4b3bffexO7Vd3bDoucWQJ`
- 时间：2026-10-29 20:47
- 目录：`C:\Users\Administrator`
- 模型：`opencode/deepseek-v4.1-flash-free`

---

## 🙋 我

这个电脑上powershell用opencode乱码是怎么回事，帮我有限排查修复一下

## 🤖 AI

我先查一下你这台机器上 PowerShell 与终端的编码配置。

## 🤖 AI

当前机器的编码设置已经暴露出关键点了，我再确认几处。

## 🤖 AI

找到关键点了：PowerShell 有自己的控制台子键，字体被固定成了 `Lucida Console`（不含中文字形）。一并修掉。

## 🤖 AI

排查完了，也修好了。结论如下。

## 根因

不是 opencode 自身的问题，是你的**控制台编码 + 字体**双重不匹配：

| 检查项 | 修复前 | 问题 |
|---|---|---|
| 控制台代码页 | `936` (GB2312) | `opencode.exe` 实际是 Bun 1.4.4 打包的原生程序，输出的是 **UTF-8 字节**，被控制台按 GBK 解码 → 乱码 |
| `HKCU\Console\...powershell.exe` 字体 | `Lucida Console` | 该字体**没有任何中文字形**，即使编码对了也会显示方块 |
| PowerShell 输出编码 | `gb2312` | 管道传给外部程序的文本同样走 GBK |
| 系统 ACP | `936` | 全局就不是 UTF-8（未开 Beta UTF-8） |

PowerShell 5.1 的 profile 也是空的，所以没有任何地方做纠正。

## 已做的修改（都在用户级，可回滚）

1. **注册表控制台设置**，共 3 处（根键 + 32/64 位 PowerShell 专属子键）：
   - `CodePage = 65001`
   - `FaceName = NSimSun`（新宋体，含中文与制表符字形）
   - `FontFamily = 54`

2. **新建 PowerShell profile** `C:\Users\Administrator\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`：
   ```powershell
   if ($Host.Name -eq "ConsoleHost") {
       try { $null = chcp 65001 } catch {}
       try {
           $utf8 = New-Object System.Text.UTF8Encoding $false
           [Console]::OutputEncoding = $utf8
           $OutputEncoding = $utf8
       } catch {}
   }
   ```
   这样即使注册表被别的软件改回去，每个新会话也会自动切到 UTF-8。

原值已备份到 `%TEMP%\opencode-fix-backup.txt`。

## 验证（必须做）

**把所有 PowerShell 窗口全部关掉**（代码页和字体是窗口创建时读取的，不能热生效），重新打开一个：

```powershell
chcp                                          # 应显示 65001
[Console]::OutputEncoding.WebName             # 应显示 utf-8
opencode
```

中文应该正常了。

## 如果还有问题

如果中文正常了，但 TUI 的**边框、进度点、图标变成方块**，那是 conhost（老控制台）字体缺字形导致的，`NSimSun` 补不了盲文点和 Nerd 图标。这种情况建议装 Windows Terminal：

```powershell
winget install --id Microsoft.WindowsTerminal -e
```

opencode 这类全屏 TUI 在 Windows Terminal 里的渲染和输入体验也比 conhost 好很多，推荐直接换。

## 回滚

```powershell
Remove-Item "C:\Users\Administrator\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
Remove-ItemProperty 'HKCU:\Console' -Name CodePage,FaceName,FontFamily
Remove-ItemProperty 'HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe' -Name CodePage,FaceName,FontFamily
Remove-ItemProperty 'HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe' -Name CodePage,FaceName,FontFamily
```

补充一点：如果你平时是在 VS Code / Cursor 的**集成终端**里跑 opencode，上面这些不生效，那种情况要在编辑器设置里改终端编码和字体（`terminal.integrated.fontFamily` 加上中文等宽字体）。可以先看 `$env:TERM_PROGRAM` 是不是 `vscode` 来确认。要我继续处理终端渲染这块吗？

## 🙋 我

检查一下skill

## 🤖 AI

文件本身的字节是完好的：刚才看到的 `鈥?` 是我这边 shell 输出走 GBK 造成的显示假象，文件里实际是标准 `—`。我继续做结构化检查。

## 🙋 我

只要skill名单即可，不用看内容

## 🤖 AI

当前可用的 skill 共 **9 个**：

**本地**（`C:\Users\Administrator\.config\opencode\skills`）
1. `3d-sky-background`
2. `build-hybrid-game-assets`
3. `optimize-threejs-games`
4. `threejs`
5. `threejs-landscape`
6. `threejs-towers`
7. `threejs-weather`

**内置**
8. `opencode`
9. `report`

7 个本地目录的 frontmatter 都正常，没有缺失或重复项。

