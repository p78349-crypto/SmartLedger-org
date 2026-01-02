# Flutter Project Backup Script
# Created: 2025-12-06
# Project: vccode1 - Multi-Account Household Ledger

param(
    [string]$BackupDir = "C:\Users\plain\vccode1_backups",
    [switch]$IncludeData,
    [switch]$Compress
)

function Invoke-RoboCopyDir {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [string[]]$ExcludeDirs,
        [string[]]$ExcludeFiles
    )

    if (-not (Test-Path $Source)) {
        return
    }

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null

    $args = @(
        $Source,
        $Destination,
        "/E",
        "/COPY:DAT",
        "/DCOPY:DAT",
        "/R:1",
        "/W:1",
        "/NFL",
        "/NDL",
        "/NJH",
        "/NJS",
        "/NP"
    )

    if ($ExcludeDirs -and $ExcludeDirs.Count -gt 0) {
        $args += "/XD"
        $args += $ExcludeDirs
    }
    if ($ExcludeFiles -and $ExcludeFiles.Count -gt 0) {
        $args += "/XF"
        $args += $ExcludeFiles
    }

    & robocopy @args | Out-Null

    # Robocopy exit codes: 0-7 are success, 8+ are failures.
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy failed ($LASTEXITCODE): $Source -> $Destination"
    }
}

# Color output function
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Start message
Write-ColorOutput Green "========================================="
Write-ColorOutput Green "  Flutter Project Backup Started"
Write-ColorOutput Green "========================================="
Write-Host ""

# Generate timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupName = "vccode1_backup_$timestamp"
$backupPath = Join-Path $BackupDir $backupName

# Create backup directory
Write-Host "Creating backup directory..." -ForegroundColor Yellow
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
}
New-Item -ItemType Directory -Force -Path $backupPath | Out-Null

# Project path
$projectPath = "C:\Users\plain\vccode1"

# Directories to exclude
$excludeDirs = @(
    "build",
    ".dart_tool",
    ".idea",
    ".vscode",
    "node_modules",
    ".git",
    ".gradle",
    "Pods",
    "DerivedData",
    "ephemeral",
    ".symlinks"
)

# Files to exclude
$excludeFiles = @(
    "*.iml",
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
    ".packages"
)

Write-Host "Copying project files..." -ForegroundColor Yellow

# Backup source code
$sourceDirs = @(
    "lib",
    "test",
    "android",
    "ios",
    "windows",
    "web",
    "linux",
    "macos",
    "tools"
)

foreach ($dir in $sourceDirs) {
    $sourcePath = Join-Path $projectPath $dir
    if (Test-Path $sourcePath) {
        $destPath = Join-Path $backupPath $dir
        Write-Host "  - Copying $dir..." -ForegroundColor Cyan
        Invoke-RoboCopyDir -Source $sourcePath -Destination $destPath -ExcludeDirs $excludeDirs -ExcludeFiles $excludeFiles
    }
}

# Backup configuration files
$configFiles = @(
    "pubspec.yaml",
    "pubspec.lock",
    "analysis_options.yaml",
    "README.md",
    ".gitignore",
    ".metadata"
)

Write-Host "Copying configuration files..." -ForegroundColor Yellow
foreach ($file in $configFiles) {
    $filePath = Join-Path $projectPath $file
    if (Test-Path $filePath) {
        Write-Host "  - Copying $file..." -ForegroundColor Cyan
        Copy-Item -Path $filePath -Destination $backupPath -Force
    }
}

# Backup documentation files
Write-Host "Copying documentation files..." -ForegroundColor Yellow
$docFiles = Get-ChildItem -Path $projectPath -Filter "*.md" -File
foreach ($file in $docFiles) {
    Write-Host "  - Copying $($file.Name)..." -ForegroundColor Cyan
    Copy-Item -Path $file.FullName -Destination $backupPath -Force
}

# PowerShell script backup
$psFiles = Get-ChildItem -Path $projectPath -Filter "*.ps1" -File
foreach ($file in $psFiles) {
    Write-Host "  - Copying $($file.Name)..." -ForegroundColor Cyan
    Copy-Item -Path $file.FullName -Destination $backupPath -Force
}

# Data backup (optional)
if ($IncludeData) {
    Write-Host "Backing up user data..." -ForegroundColor Yellow
    $dataBackupPath = Join-Path $backupPath "user_data"
    New-Item -ItemType Directory -Force -Path $dataBackupPath | Out-Null
    
    Write-Host "  Note: User data should be backed up using app's backup feature" -ForegroundColor Yellow
    Write-Host "  (App > Backup/Restore > Backup)" -ForegroundColor Yellow
}

# Create backup info file
Write-Host "Creating backup info file..." -ForegroundColor Yellow
$infoContent = @"
Backup Information
==================

Backup Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Backup Name: $backupName
Project Path: $projectPath
Backup Path: $backupPath

Included Directories:
$($sourceDirs -join "`n")

Excluded Directories:
$($excludeDirs -join "`n")

Excluded File Patterns:
$($excludeFiles -join "`n")

Data Backup: $(if ($IncludeData) { "Included" } else { "Not Included" })

Restore Instructions:
1. Copy backup folder to desired location
2. Open terminal in backup folder
3. Run: flutter pub get
4. Run: flutter pub run build_runner build --delete-conflicting-outputs
5. Run: flutter run -d windows

Notes:
- User data should be backed up using app's backup/restore feature
- build/ folder is not backed up, rebuild required after restore
- .dart_tool/ folder will be auto-generated by pub get
"@

$infoPath = Join-Path $backupPath "BACKUP_INFO.txt"
$infoContent | Out-File -FilePath $infoPath -Encoding UTF8

# Calculate backup size
Write-Host "Calculating backup size..." -ForegroundColor Yellow
$backupSize = (Get-ChildItem -Path $backupPath -Recurse | Measure-Object -Property Length -Sum).Sum
$backupSizeMB = [math]::Round($backupSize / 1MB, 2)

# Compress (optional)
if ($Compress) {
    Write-Host "Compressing backup files..." -ForegroundColor Yellow
    $zipPath = "$backupPath.zip"
    Compress-Archive -Path $backupPath -DestinationPath $zipPath -Force
    
    # Remove original folder
    Remove-Item -Path $backupPath -Recurse -Force
    
    $zipSize = (Get-Item $zipPath).Length
    $zipSizeMB = [math]::Round($zipSize / 1MB, 2)
    
    Write-Host ""
    Write-ColorOutput Green "========================================="
    Write-ColorOutput Green "  Backup Complete!"
    Write-ColorOutput Green "========================================="
    Write-Host ""
    Write-Host "Backup File: $zipPath" -ForegroundColor Cyan
    Write-Host "Original Size: $backupSizeMB MB" -ForegroundColor Cyan
    Write-Host "Compressed Size: $zipSizeMB MB" -ForegroundColor Cyan
    Write-Host "Compression Ratio: $([math]::Round(($zipSizeMB / $backupSizeMB) * 100, 1))%" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-ColorOutput Green "========================================="
    Write-ColorOutput Green "  Backup Complete!"
    Write-ColorOutput Green "========================================="
    Write-Host ""
    Write-Host "Backup Path: $backupPath" -ForegroundColor Cyan
    Write-Host "Backup Size: $backupSizeMB MB" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "See BACKUP_INFO.txt for backup details" -ForegroundColor Yellow
Write-Host ""

# Show existing backups
Write-Host "Existing Backups:" -ForegroundColor Yellow
Get-ChildItem -Path $BackupDir | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object {
    $size = if ($_.PSIsContainer) {
        $folderSize = (Get-ChildItem -Path $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
        "$([math]::Round($folderSize / 1MB, 2)) MB"
    } else {
        "$([math]::Round($_.Length / 1MB, 2)) MB"
    }
    Write-Host "  - $($_.Name) ($size) - $($_.LastWriteTime)" -ForegroundColor Cyan
}

Write-Host ""
Write-ColorOutput Green "Backup script completed successfully!"
Write-Host ""

# Usage examples
Write-Host "Usage Examples:" -ForegroundColor Yellow
Write-Host "  Basic backup: .\backup_project.ps1" -ForegroundColor Cyan
Write-Host "  Compressed backup: .\backup_project.ps1 -Compress" -ForegroundColor Cyan
Write-Host "  Include data: .\backup_project.ps1 -IncludeData" -ForegroundColor Cyan
Write-Host "  All options: .\backup_project.ps1 -Compress -IncludeData" -ForegroundColor Cyan
Write-Host ""