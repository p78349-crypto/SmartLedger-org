try { $top = (git rev-parse --show-toplevel) } catch { $top = Get-Location }
if (-not $top) { $top = Get-Location }
Set-Location $top

$t = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$destRoot = Join-Path $top 'backups\releases'
New-Item -ItemType Directory -Path $destRoot -Force | Out-Null

$artifacts = @(
  @{ path = Join-Path $top 'build\app\outputs\flutter-apk\app-release.apk'; name = 'app-release' },
  @{ path = Join-Path $top 'build\app\outputs\bundle\release\app-release.aab'; name = 'app-release-aab' }
)

$created = @()
foreach ($a in $artifacts) {
  if (Test-Path $a.path) {
    $zip = Join-Path $destRoot ($a.name + '-' + $t + '.zip')
    Compress-Archive -Path $a.path -DestinationPath $zip -Force
    Write-Host "ARTIFACT_BACKUP: $zip"
    $created += $zip
  } else {
    Write-Host "ARTIFACT_MISSING: $($a.path)"
  }
}

if ($created.Count -eq 0) { Write-Host 'NO_ARTIFACTS_BACKED_UP' } else { Write-Host 'BACKUP_COMPLETE' }
