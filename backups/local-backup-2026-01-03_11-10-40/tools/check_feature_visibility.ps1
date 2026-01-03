Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
  # tools/ is at repo root.
  return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
}

function Get-ExcludedRouteNames {
  param(
    [Parameter(Mandatory = $true)][string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return @()
  }

  $lines = Get-Content -LiteralPath $Path -Encoding UTF8
  return $lines |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith('#') }
}

$repoRoot = Get-RepoRoot
$appRoutesPath = Join-Path $repoRoot 'lib/navigation/app_routes.dart'
$catalogPath = Join-Path $repoRoot 'lib/utils/main_feature_icon_catalog.dart'
$excludePath = Join-Path $repoRoot 'tools/feature_visibility_exclude_routes.txt'

if (-not (Test-Path -LiteralPath $appRoutesPath)) {
  throw "Missing file: $appRoutesPath"
}
if (-not (Test-Path -LiteralPath $catalogPath)) {
  throw "Missing file: $catalogPath"
}

$appRoutesText = Get-Content -LiteralPath $appRoutesPath -Raw -Encoding UTF8
$catalogText = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8

# Parse AppRoutes static const values.
# Handles multi-line string assignments because we allow whitespace/newlines.
$routeRegex = [regex]::new(
  "static\s+const\s+([A-Za-z0-9_]+)\s*=\s*'([^']+)'\s*;",
  [System.Text.RegularExpressions.RegexOptions]::Singleline
)

$routeMatches = $routeRegex.Matches($appRoutesText)
$routeMap = @{}
foreach ($m in $routeMatches) {
  $name = $m.Groups[1].Value
  $path = $m.Groups[2].Value
  # If a duplicate appears, keep the first (shouldn't happen).
  if (-not $routeMap.ContainsKey($name)) {
    $routeMap[$name] = $path
  }
}

if ($routeMap.Count -eq 0) {
  throw "No routes parsed from $appRoutesPath (regex mismatch?)"
}

# Parse referenced routes in MainFeatureIconCatalog.
$refRegex = [regex]::new(
  "routeName\s*:\s*AppRoutes\.([A-Za-z0-9_]+)",
  [System.Text.RegularExpressions.RegexOptions]::Singleline
)

$refMatches = $refRegex.Matches($catalogText)
$visibleRouteNames = New-Object System.Collections.Generic.HashSet[string]
foreach ($m in $refMatches) {
  [void]$visibleRouteNames.Add($m.Groups[1].Value)
}

$excluded = Get-ExcludedRouteNames -Path $excludePath
$excludedSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($r in $excluded) {
  [void]$excludedSet.Add($r)
}

$allRouteNames = $routeMap.Keys | Sort-Object

# Sanity: catalog references should exist.
$unknownRefs = @()
foreach ($r in $visibleRouteNames) {
  if (-not $routeMap.ContainsKey($r)) {
    $unknownRefs += $r
  }
}

if ($unknownRefs.Count -gt 0) {
  Write-Host 'ERROR: main_feature_icon_catalog references unknown routes:'
  $unknownRefs | Sort-Object | ForEach-Object { Write-Host ("  - AppRoutes.{0}" -f $_) }
  exit 1
}

# Core check: any route not visible and not explicitly excluded is a failure.
$missing = @()
foreach ($r in $allRouteNames) {
  if ($visibleRouteNames.Contains($r)) { continue }
  if ($excludedSet.Contains($r)) { continue }
  $missing += $r
}

if ($missing.Count -gt 0) {
  Write-Host 'ERROR: Some routes are not exposed on any main page.'
  Write-Host 'Policy: new user-facing features must be exposed via MainFeatureIconCatalog.'
  Write-Host ''
  Write-Host 'Fix options:'
  Write-Host '  1) Add icons in lib/utils/main_feature_icon_catalog.dart (recommended), or'
  Write-Host '  2) If intentionally hidden, add the route name to tools/feature_visibility_exclude_routes.txt'
  Write-Host ''
  Write-Host 'Missing routes:'
  foreach ($r in ($missing | Sort-Object)) {
    $p = $routeMap[$r]
    Write-Host ("  - AppRoutes.{0} = '{1}'" -f $r, $p)
  }
  exit 1
}

Write-Host ("OK: Feature visibility check passed ({0} routes, {1} visible, {2} excluded)." -f $routeMap.Count, $visibleRouteNames.Count, $excludedSet.Count)
