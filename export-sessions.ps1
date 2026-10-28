<#
  把 OpenCode 的历史会话导出成 Markdown，放进仓库的 history/ 目录。

  用法：
    .\export-sessions.ps1             # 只导出还没导出的
    .\export-sessions.ps1 -Force      # 全部重导
    .\export-sessions.ps1 -Limit 50   # 只看最近 50 个会话

  说明：
    - 只保留「你问的」和「AI 答的」文字，丢掉工具输出和思考过程
    - 不包含登录凭据（凭据在 opencode.db 里，这里从不读它）
#>
[CmdletBinding()]
param(
    [int]$Limit = 200,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repo   = $PSScriptRoot
$outDir = Join-Path $repo 'history'

function Write-Step($text) { Write-Host "==> $text" -ForegroundColor Cyan }
function Write-Warn($text) { Write-Host "!!  $text" -ForegroundColor Yellow }

if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

# ---------------------------------------------------------------- 会话列表
Write-Step '读取会话列表'
$raw = & opencode api get "/api/session?limit=$Limit" 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { Write-Warn "调用 opencode api 失败：$raw"; exit 1 }
$sessions = ($raw | ConvertFrom-Json).data

if (-not $sessions) { Write-Warn '没有会话'; exit 0 }
Write-Step "共 $($sessions.Count) 个会话"

$utf8 = New-Object System.Text.UTF8Encoding($false)
$exported = 0
$skipped = 0
$warned = @()

foreach ($s in $sessions) {
    $created = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$s.time.created).ToLocalTime()
    $date = $created.ToString('yyyy-MM-dd')
    $title = if ([string]::IsNullOrWhiteSpace($s.title)) { '未命名' } else { $s.title }
    $safe = ($title -replace '[\\/:*?"<>|\r\n]', '-') -replace '\s+', ' '
    if ($safe.Length -gt 40) { $safe = $safe.Substring(0, 40) }
    $file = Join-Path $outDir "$date-$safe-$($s.id).md"

    if ((Test-Path $file) -and -not $Force) { $skipped++; continue }

    $payload = & opencode api get "/api/experimental/session/$($s.id)/export" 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { Write-Warn "跳过 $($s.id)：导出失败"; continue }
    $data = ($payload | ConvertFrom-Json).data

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# $title")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("- 会话 ID：``$($s.id)``")
    [void]$sb.AppendLine("- 时间：$($created.ToString('yyyy-MM-dd HH:mm'))")
    [void]$sb.AppendLine("- 目录：``$($s.location.directory)``")
    [void]$sb.AppendLine('- 模型：' + $(if ($s.model) { "``$($s.model.providerID)/$($s.model.id)``" } else { '未知' }))
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine()

    foreach ($m in $data.messages) {
        if ($m.type -eq 'user') {
            if ([string]::IsNullOrWhiteSpace($m.text)) { continue }
            [void]$sb.AppendLine('## 🙋 我')
            [void]$sb.AppendLine()
            [void]$sb.AppendLine($m.text.Trim())
            [void]$sb.AppendLine()
        }
        elseif ($m.type -eq 'assistant') {
            $textParts = @($m.content | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text })
            $text = ($textParts -join "`n").Trim()
            if ([string]::IsNullOrWhiteSpace($text)) { continue }
            [void]$sb.AppendLine('## 🤖 AI')
            [void]$sb.AppendLine()
            [void]$sb.AppendLine($text)
            [void]$sb.AppendLine()
        }
    }

    $body = $sb.ToString()

    # 粗查疑似密钥，提醒但不禁用
    if ($body -match 'ghp_[A-Za-z0-9]{20,}|github_pat_|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|(password|passwd|api[_-]?key)\s*[:=]\s*\S{8,}') {
        $body = "<!-- 警告：本次导出里疑似包含密钥，提交前请人工检查 -->`n`n" + $body
        $warned += $file
    }

    [IO.File]::WriteAllText($file, $body, $utf8)
    $exported++
}

Write-Host ''
Write-Host "导出 $exported 个，跳过 $skipped 个（已存在）。" -ForegroundColor Green
Write-Host "目录：$outDir"
if ($warned.Count -gt 0) {
    Write-Host ''
    Write-Warn "以下文件疑似含密钥，提交前请检查："
    $warned | ForEach-Object { Write-Host "  $_" }
}
