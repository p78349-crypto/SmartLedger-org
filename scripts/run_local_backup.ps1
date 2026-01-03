try { $top = (git rev-parse --show-toplevel) } catch { $top = Get-Location }
if (-not $top) { $top = Get-Location }
Set-Location $top

if (Test-Path 'backup_project.ps1') {
  Write-Host 'FOUND_SCRIPT'
  try { & pwsh -NoProfile -ExecutionPolicy Bypass -File 'backup_project.ps1' } catch { & powershell -NoProfile -ExecutionPolicy Bypass -File 'backup_project.ps1' }
} else {
  $t = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
  $dest = Join-Path $top ("backups\\local-backup-$t")
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  robocopy $top $dest /E /XD .git backups | Out-Null
  Write-Host "Backup created at: $dest"
}
