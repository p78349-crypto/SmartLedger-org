Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][scriptblock]$Action
  )

  Write-Host ("--- {0} ---" -f $Name)
  & $Action
  if ($LASTEXITCODE -ne 0) {
    throw ("Step failed: {0} (exit {1})" -f $Name, $LASTEXITCODE)
  }
}

$stamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
Write-Host ("=== QUALITY_GATE_START {0} ===" -f $stamp)

Invoke-Step -Name 'flutter analyze' -Action { flutter analyze }

Invoke-Step -Name 'flutter test' -Action { flutter test }
Invoke-Step -Name 'validate INDEX' -Action {
  pwsh -NoProfile -ExecutionPolicy Bypass -File "${PSScriptRoot}/validate_index.ps1"
}

Invoke-Step -Name 'check feature visibility' -Action {
  pwsh -NoProfile -ExecutionPolicy Bypass -File "${PSScriptRoot}/check_feature_visibility.ps1"
}

Write-Host '=== QUALITY_GATE_OK ==='
