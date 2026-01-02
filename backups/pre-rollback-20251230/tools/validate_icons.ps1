# PowerShell icon validator - mirrors tools/validate_icons.py
# Usage: .\tools\validate_icons.ps1
Set-StrictMode -Version Latest

$Root = (Get-Item "$(Split-Path -Path $MyInvocation.MyCommand.Path -Parent)").Parent.FullName
$Catalog = Join-Path $Root 'lib\utils\main_feature_icon_catalog.dart'
$Manifest = Join-Path $Root 'assets\icons\metadata\icons.json'

if (-not (Test-Path $Catalog)) { Write-Error "Catalog not found: $Catalog"; exit 2 }
if (-not (Test-Path $Manifest)) { Write-Error "Manifest not found: $Manifest"; exit 2 }

$catalogText = Get-Content -Raw -Encoding UTF8 $Catalog
$ids = [regex]::Matches($catalogText, "id:\s*'([^']+)'") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$ids = $ids | Where-Object { $_ -ne $null -and $_ -ne '' }

$manifestJson = Get-Content -Raw -Encoding UTF8 $Manifest | ConvertFrom-Json
$manifestEntries = @{}
foreach ($e in $manifestJson.icons) { $manifestEntries[$e.id] = $e }

Write-Host "Found $($ids.Count) ids in catalog"
Write-Host "Found $($manifestEntries.Keys.Count) entries in manifest"

$idsWithoutManifest = $ids | Where-Object { -not $manifestEntries.ContainsKey($_) }
if ($idsWithoutManifest.Count -gt 0) {
  Write-Host "`nCatalog IDs without manifest entries:"
  $idsWithoutManifest | ForEach-Object { Write-Host " - $_" }
}
else {
  Write-Host "`nAll catalog IDs have manifest entries."
}

$missing = $false
Write-Host "`nChecking manifest asset files..."
foreach ($k in $manifestEntries.Keys) {
  $assetPath = Join-Path $Root $manifestEntries[$k].assetPath
  if (-not (Test-Path $assetPath)) {
    Write-Error "Missing asset for manifest id=$k path=$($manifestEntries[$k].assetPath)"
    $missing = $true
  }
}

if ($missing) {
  Write-Error "Validation failed: missing asset files."
  exit 2
}

Write-Host "`nValidation completed. No missing files detected."; exit 0
