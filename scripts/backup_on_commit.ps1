param()

# Backup hook: if staged files >= 3, run repo's backup script or create a copy
try {
    $top = (git rev-parse --show-toplevel) 2>$null
} catch {
    $top = Get-Location
}
if (-not $top) { $top = Get-Location }
Set-Location $top

$staged = git diff --cached --name-only 2>$null
$count = 0
if ($staged) { $count = ($staged | Measure-Object -Line).Lines }

Write-Host "[backup_on_commit] Staged files count: $count"

if ($count -ge 3) {
    Write-Host "[backup_on_commit] >=3 staged files — running backup..."
    $backupScript = Join-Path $top 'backup_project.ps1'
    if (Test-Path $backupScript) {
        Write-Host "[backup_on_commit] Found backup script, invoking: $backupScript"
        try {
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $backupScript
        } catch {
            try { & powershell -NoProfile -ExecutionPolicy Bypass -File $backupScript } catch {
                Write-Host "[backup_on_commit] Failed to execute backup script: $_"
            }
        }
    } else {
        Write-Host "[backup_on_commit] backup_project.ps1 not found — creating folder copy backup."
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $dest = Join-Path $top ("backups/auto-backup-$timestamp")
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        # Use robocopy to copy repo contents excluding .git and backups
        try {
            robocopy $top $dest /E /XD .git backups | Out-Null
            Write-Host "[backup_on_commit] Local backup created at: $dest"
        } catch {
            Write-Host "[backup_on_commit] robocopy failed: $_"
        }
    }
} else {
    Write-Host "[backup_on_commit] Less than 3 staged files — skipping automatic backup."
}
