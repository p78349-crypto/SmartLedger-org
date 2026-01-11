param(
  [switch]$IncludeLongLines,
  [switch]$IncludeDcm
)

$ErrorActionPreference = 'Stop'

try {
  Set-Location (git rev-parse --show-toplevel)
} catch {
}

Write-Host '== SmartLedger Local CI =='

Write-Host '\n[1/5] Format gate (lib/test)'
dart format --output=none --set-exit-if-changed lib test

Write-Host '\n[2/5] Dart analyze'
dart analyze

Write-Host '\n[3/5] Flutter analyze'
flutter analyze

Write-Host '\n[4/5] Flutter test'
flutter test

if ($IncludeDcm) {
  Write-Host '\n[5/5] dart_code_metrics'
  dart pub global activate dart_code_metrics | Out-Host
  dart pub global run dart_code_metrics:metrics analyze lib test --reporter=console
}

if ($IncludeLongLines) {
  Write-Host '\n[extra] Long line scan (80+ chars in lib/)'
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\scan_long_lines.ps1
}

Write-Host '\nOK: local CI gates passed.'
