<#
  把本机 ~/.config/opencode 的改动回存到仓库，并推送到 GitHub。

  用法：
    .\save.ps1                        # 自动提交信息
    .\save.ps1 -Message "加了新技能"
    .\save.ps1 -NoHistory             # 不导出聊天记录

  同步内容：AGENTS.md / opencode.json / cli.json / skills / agents / commands / history
  不同步：service.json、opencode.db、登录凭据、缓存
#>
[CmdletBinding()]
param(
    [string]$Message,
    [switch]$NoHistory
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$dest = Join-Path $env:USERPROFILE '.config\opencode'
$src  = Join-Path $repo 'config'

function Write-Step($text) { Write-Host "==> $text" -ForegroundColor Cyan }
function Write-Warn($text) { Write-Host "!!  $text" -ForegroundColor Yellow }
function Write-Fail($text) { Write-Host "xx  $text" -ForegroundColor Red }

# git 往 stderr 打 warning 时，PowerShell 会把它当成异常；统一在这里收口
function Invoke-Git {
    param([string[]]$Arguments)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & git @Arguments 2>&1 | Out-String
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prev
    }
    if ($code -ne 0) {
        Write-Host $out -ForegroundColor Red
        Write-Fail ("git " + ($Arguments -join ' ') + " 失败（exit $code）")
        exit 1
    }
    return $out
}

if (-not (Test-Path $dest)) { Write-Fail "找不到 $dest"; exit 1 }

# ---------------------------------------------------------------- 1. 回存配置
Write-Step '从本机配置同步到仓库'
foreach ($f in @('AGENTS.md', 'opencode.json', 'cli.json')) {
    $p = Join-Path $dest $f
    if (Test-Path $p) { Copy-Item $p (Join-Path $src $f) -Force }
}
foreach ($d in @('skills', 'agents', 'commands')) {
    $p = Join-Path $dest $d
    if (Test-Path $p) {
        $target = Join-Path $src $d
        New-Item -ItemType Directory -Force -Path $target | Out-Null
        Copy-Item (Join-Path $p '*') $target -Recurse -Force
    }
}

# ---------------------------------------------------------------- 2. 聊天记录
if (-not $NoHistory) {
    $exporter = Join-Path $repo 'export-sessions.ps1'
    if (Test-Path $exporter) {
        Write-Step '导出聊天记录到 history/'
        & $exporter
    }
}

# ---------------------------------------------------------------- 3. 防泄漏检查
Write-Step '检查敏感文件'
$changes = Invoke-Git @('-C', $repo, 'status', '--porcelain')
$bad = $changes -split "`n" | Where-Object { $_ -match 'service\.json|auth\.json|\.db$|\.env|\.pem$|\.key$' }
if ($bad) {
    $bad | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    Write-Fail '检测到疑似敏感文件，已中止。请检查 .gitignore 后再试。'
    exit 1
}

if ([string]::IsNullOrWhiteSpace($changes)) {
    Write-Host '没有新改动，尝试同步远端状态。' -ForegroundColor Green
    Invoke-Git @('-C', $repo, '-c', 'http.proxy=', '-c', 'https.proxy=', 'push') | Out-Null
    exit 0
}

# ---------------------------------------------------------------- 4. 提交
if (-not (Invoke-Git @('-C', $repo, 'config', 'user.email'))) {
    Write-Warn '还没设置 git 身份。先运行：'
    Write-Host '  git config --global user.name  "你的名字"'
    Write-Host '  git config --global user.email "你的邮箱"'
    exit 1
}

if (-not $Message) { $Message = 'sync: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm') }

Invoke-Git @('-C', $repo, 'add', '-A') | Out-Null
Invoke-Git @('-C', $repo, 'commit', '-m', $Message) | Out-Null

# 本机 git 可能配了失效的本地代理（如 127.0.0.1:7890），显式绕过再推
Invoke-Git @('-C', $repo, '-c', 'http.proxy=', '-c', 'https.proxy=', 'push') | Out-Null

Write-Host ''
Write-Host '已推送。换电脑时 clone 后跑 bootstrap.ps1 即可。' -ForegroundColor Green
