# Local Backup Scheduler
# Creates local backups every 3 hours without pushing to GitHub
# Created: 2025-01-03

$ProjectRoot = $PSScriptRoot
$BackupDir = Join-Path (Split-Path $ProjectRoot -Parent) "SmartLedger_backups"
$LogFile = Join-Path $ProjectRoot "local-backup.log"

# Create backup directory if it doesn't exist
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

function Write-Log {
    param([string]$Message)
    $Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $LogMessage = "[$Timestamp] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

function Create-LocalBackup {
    Write-Log "Starting local backup..."
    
    $Timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $BackupPath = "$BackupDir\local-backup-$Timestamp"
    
    try {
        # Create backup directory
        New-Item -ItemType Directory -Path $BackupPath | Out-Null
        
        # Backup source directories
        $dirs = @("lib", "test", "tools", "android", "ios", "windows", "web", "linux", "macos")
        foreach ($dir in $dirs) {
            $src = Join-Path $ProjectRoot $dir
            if (Test-Path $src) {
                Write-Log "  Copying $dir/ directory..."
                Copy-Item -Path $src -Destination (Join-Path $BackupPath $dir) -Recurse -Force
            }
        }
        
        # Backup important files
        Write-Log "  Copying configuration files..."
        Copy-Item -Path (Join-Path $ProjectRoot "pubspec.yaml") -Destination (Join-Path $BackupPath "pubspec.yaml") -Force
        Copy-Item -Path (Join-Path $ProjectRoot "pubspec.lock") -Destination (Join-Path $BackupPath "pubspec.lock") -Force
        Copy-Item -Path (Join-Path $ProjectRoot "analysis_options.yaml") -Destination (Join-Path $BackupPath "analysis_options.yaml") -Force
        
        # Count files
        $FileCount = (Get-ChildItem -Path $BackupPath -Recurse -File).Count
        Write-Log "  Backup created successfully: $FileCount files"
        Write-Log "  Location: $BackupPath"
        
        # Cleanup old backups (keep last 10)
        $OldBackups = Get-ChildItem -Path $BackupDir -Directory -Filter "local-backup-*" | 
            Sort-Object Name -Descending | 
            Select-Object -Skip 10
        
        foreach ($Backup in $OldBackups) {
            Write-Log "  Removing old backup: $($Backup.Name)"
            Remove-Item -Path $Backup.FullName -Recurse -Force
        }
        
        Write-Log "Local backup completed successfully"
        
    } catch {
        Write-Log "ERROR: Backup failed - $_"
        exit 1
    }
}

# Main execution
Write-Log "========== Local Backup Scheduler Started =========="
Create-LocalBackup
Write-Log "========== Local Backup Completed =========="
