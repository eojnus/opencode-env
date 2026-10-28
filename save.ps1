<#
  把本机 ~/.config/opencode 的改动回存到仓库，并推送到 GitHub。

  用法：
    .\save.ps1                    # 自动提交信息
    .\save.ps1 -Message "加了新技能"

  只同步这 6 项：AGENTS.md / opencode.json / cli.json / skills / agents / commands
  不会碰：service.json、聊天记录、登录凭据、缓存
#>
[CmdletBinding()]
param(
    [string]$Message
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$dest = Join-Path $env:USERPROFILE '.config\opencode'
$src  = Join-Path $repo 'config'

function Write-Step($text) { Write-Host "==> $text" -ForegroundColor Cyan }
function Write-Warn($text) { Write-Host "!!  $text" -ForegroundColor Yellow }

if (-not (Test-Path $dest)) { Write-Warn "找不到 $dest"; exit 1 }

# ---------------------------------------------------------------- 1. 回存
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
Get-ChildItem $src -Recurse -Filter '.gitkeep' -Force -ErrorAction SilentlyContinue | Out-Null

# ---------------------------------------------------------------- 2. 防泄漏检查
Write-Step '检查敏感文件'
$bad = git -C $repo status --porcelain | Select-String -Pattern 'service\.json|auth\.json|\.db$|\.env|\.pem$|\.key$'
if ($bad) {
    Write-Host $bad.ToString() -ForegroundColor Red
    Write-Warn '检测到疑似敏感文件，已中止。请检查 .gitignore 后再试。'
    exit 1
}

# ---------------------------------------------------------------- 3. 提交
$changes = git -C $repo status --porcelain
if (-not $changes) {
    Write-Host '没有改动，无需提交。' -ForegroundColor Green
    exit 0
}

if (-not (git -C $repo config user.email)) {
    Write-Warn '还没设置 git 身份。先运行：'
    Write-Host '  git config --global user.name  "你的名字"'
    Write-Host '  git config --global user.email "你的邮箱"'
    exit 1
}

if (-not $Message) { $Message = 'sync: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm') }

git -C $repo add -A
git -C $repo commit -m $Message
git -C $repo push

Write-Host ''
Write-Host '已推送。换电脑时 clone 后跑 bootstrap.ps1 即可。' -ForegroundColor Green
