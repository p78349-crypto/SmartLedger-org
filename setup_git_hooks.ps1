# Git Hooks Setup Script
# Enable/Disable automatic backup and commit validation
# Created: 2025-01-03

param(
    [ValidateSet('enable', 'disable', 'status')]
    [string]$Action = 'status'
)

$ProjectRoot = (Get-Location).Path
$GitHooksDir = Join-Path $ProjectRoot ".git\hooks"
$HooksToSetup = @("pre-commit", "post-commit")

Write-Host "🔧 Git Hooks 설정 도구" -ForegroundColor Cyan
Write-Host "프로젝트: $ProjectRoot" -ForegroundColor Yellow
Write-Host ""

function Enable-GitHooks {
    Write-Host "📝 Git Hooks 활성화 중..." -ForegroundColor Green
    
    foreach ($Hook in $HooksToSetup) {
        $HookPath = Join-Path $GitHooksDir $Hook
        $HookPsPath = "$HookPath.ps1"
        
        # PowerShell 스크립트가 있으면 배치 파일 생성
        if (Test-Path $HookPsPath) {
            $BatchContent = @"
@echo off
REM Git Hook: $Hook
REM PowerShell 스크립트 실행
pwsh -NoProfile -ExecutionPolicy Bypass -File "$HookPsPath" %*
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
"@
            Set-Content -Path $HookPath -Value $BatchContent -Encoding UTF8
            Write-Host "✅ 활성화됨: $Hook" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "🎯 Git Hooks 설정 완료!" -ForegroundColor Green
    Write-Host "- Pre-Commit: 커밋 전 분석/검증 실행" -ForegroundColor Yellow
    Write-Host "- Post-Commit: 커밋 후 자동 백업 생성" -ForegroundColor Yellow
}

function Disable-GitHooks {
    Write-Host "🛑 Git Hooks 비활성화 중..." -ForegroundColor Yellow
    
    foreach ($Hook in $HooksToSetup) {
        $HookPath = Join-Path $GitHooksDir $Hook
        if (Test-Path $HookPath) {
            Remove-Item -Path $HookPath -Force
            Write-Host "DISABLED: $Hook" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "Git Hooks Disabled" -ForegroundColor Yellow
}

function Show-Status {
    Write-Host "Git Hooks Status:" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($Hook in $HooksToSetup) {
        $HookPath = Join-Path $GitHooksDir $Hook
        $HookPsPath = "$HookPath.ps1"
        
        $Status1 = if (Test-Path $HookPath) { "ENABLED" } else { "DISABLED" }
        $Status2 = if (Test-Path $HookPsPath) { "EXISTS" } else { "MISSING" }
        
        Write-Host "$Hook : $Status1 (Script: $Status2)" -ForegroundColor Yellow
    }
}

switch ($Action) {
    'enable' {
        Enable-GitHooks
    }
    'disable' {
        Disable-GitHooks
    }
    'status' {
        Show-Status
    }
}

Write-Host ""
Write-Host "Usage:" -ForegroundColor Cyan
Write-Host "  powershell -File setup_git_hooks.ps1 -Action enable" -ForegroundColor Yellow
Write-Host "  powershell -File setup_git_hooks.ps1 -Action disable" -ForegroundColor Yellow
Write-Host "  powershell -File setup_git_hooks.ps1 -Action status" -ForegroundColor Yellow
