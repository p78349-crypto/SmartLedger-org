param(
    [string]$BackupDir = "C:\Users\plain\vccode1_utils_backups",
    [switch]$Compress
)

function Write-Log($message, $color = "White") {
    Write-Host $message -ForegroundColor $color
}

$projectPath = "C:\Users\plain\vccode1"
$utilsPath = Join-Path $projectPath "lib\utils"

if (-not (Test-Path $utilsPath)) {
    Write-Log "Utils directory not found: $utilsPath" "Red"
    exit 1
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupName = "utils_backup_$timestamp"
$backupPath = Join-Path $BackupDir $backupName

Write-Log "Creating utils backup at $backupPath" "Yellow"
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
}
New-Item -ItemType Directory -Force -Path $backupPath | Out-Null

$destUtilsPath = Join-Path $backupPath "utils"
Copy-Item -Path $utilsPath -Destination $destUtilsPath -Recurse -Force

Write-Log "Generating manifest..." "Yellow"
$manifestPath = Join-Path $backupPath "utils_manifest.txt"
Get-ChildItem -Path $destUtilsPath -Recurse | ForEach-Object {
    $_.FullName.Replace($backupPath + "\", "")
} | Set-Content -Path $manifestPath

$infoContent = @"
Utils Backup Information
========================

Backup Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Backup Name: $backupName
Source Path: $utilsPath
Backup Path: $backupPath
File Count: $(Get-ChildItem -Path $destUtilsPath -Recurse | Measure-Object).Count

Restore Notes:
1. Copy the 'utils' folder back to lib/utils if needed.
2. Review utils_manifest.txt for expected file list.
3. Run flutter test to ensure guard tests still pass.
"@

$infoPath = Join-Path $backupPath "README.txt"
$infoContent | Out-File -FilePath $infoPath -Encoding UTF8

if ($Compress) {
    Write-Log "Compressing backup..." "Yellow"
    $zipPath = "$backupPath.zip"
    Compress-Archive -Path $backupPath -DestinationPath $zipPath -Force
    Remove-Item -Path $backupPath -Recurse -Force
    Write-Log "Utils backup complete: $zipPath" "Green"
} else {
    Write-Log "Utils backup complete: $backupPath" "Green"
}

Write-Log "Recent utils backups:" "Yellow"
if (Test-Path $BackupDir) {
    Get-ChildItem -Path $BackupDir | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object {
        $size = if ($_.PSIsContainer) {
            $folderSize = (Get-ChildItem -Path $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
            "{0} MB" -f ([math]::Round($folderSize / 1MB, 2))
        } else {
            "{0} MB" -f ([math]::Round($_.Length / 1MB, 2))
        }
        Write-Log "  - $($_.Name) ($size) - $($_.LastWriteTime)" "Cyan"
    }
}
