param(
  [string]$OutFile = "docs/IP_EVIDENCE_SHA256_2025-12-27.txt"
)

$ErrorActionPreference = "Stop"

function Get-Sha256Line {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return "MISSING  $Path"
  }
  $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
  return "$h  $Path"
}

$targets = @(
  "pubspec.lock",
  ".dart_tool/package_config.json",
  "tools/_flutter_version.txt",
  "tools/_dart_version.txt",
  "docs/IP_COMPLIANCE_CHECK_2025-12-27.md",
  "docs/THIRD_PARTY_LICENSES_SUMMARY.md",
  "tools/generate_third_party_licenses_summary.dart",
  "tools/generate_ip_evidence_hashes.ps1"
)

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# IP Evidence SHA-256 Log")
$lines.Add("# Generated: $(Get-Date -Format o)")
$lines.Add("# Note: Keep this file together with the referenced artifacts.")
$lines.Add("")

foreach ($t in $targets) {
  $lines.Add((Get-Sha256Line -Path $t))
}

$dir = Split-Path -Parent $OutFile
if ($dir -and -not (Test-Path -LiteralPath $dir)) {
  New-Item -ItemType Directory -Path $dir | Out-Null
}

$lines | Set-Content -LiteralPath $OutFile -Encoding UTF8
Write-Output "Wrote: $OutFile"
