param(
    [switch]$IncludeRelease,
    [switch]$EnableSecurityScan,
    [switch]$SkipBackup,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $projectRoot

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "========== $Name ==========" -ForegroundColor Cyan

    if ($DryRun) {
        Write-Host '[DRY-RUN] Skipped' -ForegroundColor Yellow
        return
    }

    $global:LASTEXITCODE = 0
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "Step failed: $Name (exit code: $LASTEXITCODE)"
    }
}

function Require-ReleaseSecrets {
    $hasStore = -not [string]::IsNullOrWhiteSpace($env:SLD_STORE_PASSWORD)
    $hasKey = -not [string]::IsNullOrWhiteSpace($env:SLD_KEY_PASSWORD)

    if (-not ($hasStore -and $hasKey)) {
        throw 'Release 복구에는 SLD_STORE_PASSWORD/SLD_KEY_PASSWORD가 필요합니다.'
    }
}

Write-Host ''
Write-Host 'SmartLedger DR Quick Recover' -ForegroundColor Green
Write-Host "Project Root: $projectRoot"
Write-Host "IncludeRelease: $IncludeRelease"
Write-Host "EnableSecurityScan: $EnableSecurityScan"
Write-Host "SkipBackup: $SkipBackup"

Invoke-Step -Name 'Snapshot: git status' -Action {
    git status --short
}

Invoke-Step -Name 'DR Quality: orchestrate quality' -Action {
    pwsh -NoProfile -ExecutionPolicy Bypass -File `
        .\scripts\orchestrate_lifecycle.ps1 -Stage quality
}

if ($IncludeRelease) {
    Invoke-Step -Name 'DR Release: signing readiness' -Action {
        Require-ReleaseSecrets
        pwsh -NoProfile -ExecutionPolicy Bypass -File `
            .\scripts\check_android_release_signing.ps1
    }

    Invoke-Step -Name 'DR Release: rebuild APK/AAB' -Action {
        flutter build apk --release
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        flutter build appbundle --release
    }
}

if (-not $SkipBackup) {
    Invoke-Step -Name 'DR Backup: compressed snapshot' -Action {
        pwsh -NoProfile -ExecutionPolicy Bypass -File .\backup_project.ps1 `
            -Compress
    }
}

Invoke-Step -Name 'DR Ops: orchestrate ops' -Action {
    $args = @(
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        '.\\scripts\\orchestrate_lifecycle.ps1',
        '-Stage',
        'ops'
    )

    if ($EnableSecurityScan) {
        $args += '-EnableSecurityScan'
    }

    pwsh @args
}

Write-Host ''
Write-Host 'DR quick recover completed.' -ForegroundColor Green
