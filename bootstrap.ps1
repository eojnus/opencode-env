<#
  在新电脑上恢复我的 OpenCode 环境。

  用法：
    git clone <仓库地址>
    cd opencode-env
    .\bootstrap.ps1

  会做三件事：
    1. 检查 opencode 是否已安装，没有就用 npm 装
    2. 备份这台机器现有的配置（如果有）
    3. 把仓库里的 config/ 复制到 ~/.config/opencode

  不会恢复：聊天记录、登录状态（需要重新 opencode auth login）
#>
[CmdletBinding()]
param(
    # 只拷贝配置，不安装 opencode
    [switch]$ConfigOnly
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$src  = Join-Path $repo 'config'
$dest = Join-Path $env:USERPROFILE '.config\opencode'

function Write-Step($text) { Write-Host "==> $text" -ForegroundColor Cyan }
function Write-Warn($text) { Write-Host "!!  $text" -ForegroundColor Yellow }
function Write-Fail($text) { Write-Host "xx  $text" -ForegroundColor Red }

if (-not (Test-Path $src)) { Write-Fail "找不到 $src，请在仓库根目录运行"; exit 1 }

# ---------------------------------------------------------------- 1. opencode
if (-not $ConfigOnly) {
    if (Get-Command opencode -ErrorAction SilentlyContinue) {
        Write-Step "opencode 已安装：$((Get-Command opencode).Source)"
    }
    else {
        Write-Step '未找到 opencode，尝试安装'
        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            Write-Fail '没找到 Node/npm。请先安装 Node LTS，再重跑本脚本。'
            Write-Host '  winget install OpenJS.NodeJS.LTS'
            Write-Host '  或在 https://nodejs.org 下载 LTS 安装包'
            exit 1
        }
        npm install -g @opencode/cli
        # npm 全局目录可能刚被创建，需要刷新 PATH
        $env:PATH = "$env:PATH;$env:APPDATA\npm"
        if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
            Write-Warn '装完了但当前终端还找不到 opencode，请关掉终端重开，再跑一次本脚本'
            exit 1
        }
    }
}

# ---------------------------------------------------------------- 2. 备份旧配置
if (Test-Path $dest) {
    $existing = Get-ChildItem $dest -Force -ErrorAction SilentlyContinue
    if ($existing) {
        $backup = "$dest.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
        Copy-Item $dest $backup -Recurse -Force
        Write-Step "已备份原配置到：$backup"
    }
}
else {
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
}

# ---------------------------------------------------------------- 3. 拷配置
Write-Step "复制配置到 $dest"
Copy-Item (Join-Path $src '*') -Destination $dest -Recurse -Force

# 空目录 .gitkeep 不需要
Get-ChildItem $dest -Recurse -Filter '.gitkeep' -Force -ErrorAction SilentlyContinue | Remove-Item -Force

Write-Host ''
Write-Host '完成。' -ForegroundColor Green
Write-Host "配置目录：$dest"
if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    Write-Warn '请重开终端后再运行 opencode'
}
else {
    Write-Host '下一步：运行 opencode 检查是否正常；如需登录，运行 opencode auth login'
}
