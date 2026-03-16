param(
    [ValidateSet('quality','release','ops','full')]
    [string]$Stage = 'full',
    [ValidateSet('none','once','watch')]
    [string]$OpsDashboard = 'none',
    [switch]$SkipSigningCheck,
    [switch]$SkipBuild,
    [switch]$SkipArtifactBackup,
    [switch]$SkipProjectBackup,
    [switch]$EnableSecurityScan,
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
        Write-Host "[DRY-RUN] Skipped" -ForegroundColor Yellow
        return
    }

    $global:LASTEXITCODE = 0
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "Step failed: $Name (exit code: $LASTEXITCODE)"
    }
}

function Ensure-Command {
    param([string]$CommandName)
    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        throw "Command not found: $CommandName"
    }
}

function Resolve-PythonCommand {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        return 'python'
    }
    if (Get-Command py -ErrorAction SilentlyContinue) {
        return 'py'
    }
    throw 'Python runtime not found (python/py).'
}

function Run-QualityStage {
    Invoke-Step -Name 'Preflight: flutter pub get' -Action {
        Ensure-Command -CommandName 'flutter'
        flutter pub get
    }

    Invoke-Step -Name 'Quality Gate: scripts/ci_local.ps1' -Action {
        pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\ci_local.ps1
    }
}

function Run-ReleaseStage {
    if (-not $SkipSigningCheck) {
        Invoke-Step -Name 'Release Check: Android signing readiness' -Action {
            pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_android_release_signing.ps1
        }
    }

    if (-not $SkipBuild) {
        Invoke-Step -Name 'Release Build: obfuscated Android APK' -Action {
            pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_release_obfuscate.ps1 -Platform android
        }
    }

    if (-not $SkipArtifactBackup) {
        Invoke-Step -Name 'Release Backup: artifacts zip' -Action {
            pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\backup_artifacts.ps1
        }
    }
}

function Run-OpsStage {
    Invoke-Step -Name 'Ops Health: flutter analyze' -Action {
        flutter analyze --no-fatal-infos
    }

    Invoke-Step -Name 'Ops Health: lock concurrency smoke test' -Action {
        flutter test test/services/auth_policy_concurrency_test.dart
    }

    if (-not $SkipProjectBackup) {
        Invoke-Step -Name 'Ops Backup: project backup snapshot' -Action {
            pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_local_backup.ps1
        }
    }

    if ($EnableSecurityScan) {
        Invoke-Step -Name 'Ops Security: local_security_check.ps1' -Action {
            pwsh -NoProfile -ExecutionPolicy Bypass -File .\local_security_check.ps1
        }
    }

    if ($OpsDashboard -ne 'none') {
        Invoke-Step -Name "Ops Dashboard: tools/ops-health-dashboard.py ($OpsDashboard)" -Action {
            $pythonCmd = Resolve-PythonCommand
            if ($OpsDashboard -eq 'once') {
                & $pythonCmd .\tools\ops-health-dashboard.py --once
                return
            }
            & $pythonCmd .\tools\ops-health-dashboard.py --interval 2
        }
    }
}

Write-Host ""
Write-Host 'SmartLedger Lifecycle Orchestration' -ForegroundColor Green
Write-Host "Project Root: $projectRoot"
Write-Host "Stage: $Stage"
Write-Host "OpsDashboard: $OpsDashboard"

switch ($Stage) {
    'quality' {
        Run-QualityStage
    }
    'release' {
        Run-ReleaseStage
    }
    'ops' {
        Run-OpsStage
    }
    'full' {
        Run-QualityStage
        Run-ReleaseStage
        Run-OpsStage
    }
}

Write-Host ""
Write-Host 'Lifecycle orchestration completed.' -ForegroundColor Green