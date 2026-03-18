param(
  [switch]$IncludeLongLines,
  [switch]$IncludeDcm
)

$ErrorActionPreference = 'Stop'

function Invoke-NativeChecked {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Label,
    [Parameter(Mandatory = $true)]
    [scriptblock]$Action
  )

  & $Action
  if ($LASTEXITCODE -ne 0) {
    throw "$Label failed (exit code: $LASTEXITCODE)"
  }
}

try {
  Set-Location (git rev-parse --show-toplevel)
} catch {
}

Write-Host '== SmartLedger Local CI =='

Write-Host "`n[1/5] Format gate (lib/test)"
Invoke-NativeChecked -Label 'Format gate' -Action {
  dart format --output=none --set-exit-if-changed lib test
}

Write-Host "`n[2/5] Dart analyze"
Invoke-NativeChecked -Label 'Dart analyze' -Action {
  dart analyze
}

Write-Host "`n[3/5] Flutter analyze"
Invoke-NativeChecked -Label 'Flutter analyze' -Action {
  flutter analyze
}

Write-Host "`n[4/5] Flutter test"
Invoke-NativeChecked -Label 'Flutter test' -Action {
  flutter test
}

if ($IncludeDcm) {
  Write-Host "`n[5/5] dart_code_metrics"
  Invoke-NativeChecked -Label 'DCM activate' -Action {
    dart pub global activate dart_code_metrics | Out-Host
  }
  Invoke-NativeChecked -Label 'DCM analyze' -Action {
    dart pub global run dart_code_metrics:metrics analyze lib test --reporter=console
  }
}

if ($IncludeLongLines) {
  Write-Host "`n[extra] Long line scan (80+ chars in lib/)" 
  Invoke-NativeChecked -Label 'Long line scan' -Action {
    pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\scan_long_lines.ps1
  }
}

Write-Host "`nOK: local CI gates passed."
