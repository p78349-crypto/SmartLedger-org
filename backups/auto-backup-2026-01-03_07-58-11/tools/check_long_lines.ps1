[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
  'PSAvoidAssignmentToAutomaticVariable',
  'Matches',
  Justification = 'Does not assign to $Matches; false positive in some analyzers.'
)]
param(
  [string]$Root = 'lib',
  [int]$MaxLen = 80,
  [string]$Filter = '*.dart'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Root)) {
  throw "Root path not found: $Root"
}

$minLen = $MaxLen + 1
$pattern = ".{$minLen,}"

$files = Get-ChildItem -Path $Root -Recurse -File -Filter $Filter
$longLineHits = $files |
  Select-String -Pattern $pattern |
  Where-Object {
      $line = $_.Line
      if ($null -eq $line) { return $true }
      $t = $line.TrimStart()
      # Ignore Dart import/export/part directives which can't be wrapped
      return -not ($t -match '^(import|export|part)\s')
    }

if ($null -eq $longLineHits -or $longLineHits.Count -eq 0) {
  Write-Host "OK: No lines longer than $MaxLen chars in $Root ($Filter)"
  exit 0
}

$repoRoot = (Get-Location).Path

Write-Host "Found $($longLineHits.Count) long lines (> $MaxLen chars)"

foreach ($m in $longLineHits) {
  $relPath = $m.Path
  if ($relPath.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    $relPath = $relPath.Substring($repoRoot.Length).TrimStart('\','/')
  }
  $len = 0
  if ($null -ne $m.Line) { $len = $m.Line.Length }
  Write-Host ("{0}:{1} (len={2}): {3}" -f $relPath, $m.LineNumber, $len, $m.Line)
}

exit 1
