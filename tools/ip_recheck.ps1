param(
  [switch]$WithIndex
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
  Write-Host "[IP-RECHECK] $msg"
}

Write-Step "Start"

Write-Step "Regenerate third-party license summary"
& dart run tools/generate_third_party_licenses_summary.dart

Write-Step "Regenerate SHA-256 evidence log"
& pwsh -NoProfile -ExecutionPolicy Bypass -File tools/generate_ip_evidence_hashes.ps1

$summaryPath = "docs/THIRD_PARTY_LICENSES_SUMMARY.md"
if (Test-Path -LiteralPath $summaryPath) {
  $text = Get-Content -LiteralPath $summaryPath -Raw
  $unknownCount = ([regex]::Matches($text, "\| .* \| Unknown \(review\) \|")).Count
  $missingNone = $text -match "## Missing License Files \(Manual Review Needed\)\s*\r?\n\s*- None"
  Write-Step "Summary: Unknown(review) rows = $unknownCount"
  Write-Step "Summary: Missing license files = $(if ($missingNone) { 'None' } else { 'Check summary section' })"
}

if ($WithIndex) {
  Write-Step "Validate INDEX format"
  & pwsh -NoProfile -File tools/validate_index.ps1

  Write-Step "Export INDEX to CSV/JSON"
  & dart run tools/export_index.dart
}

Write-Step "Done"