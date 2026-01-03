# Auto Commit and Backup Script
# Runs every 2 hours to commit and push to GitHub
# Created: 2025-01-03

param(
    [switch]$SkipAnalysis
)

$ProjectRoot = "C:\Users\plain\SmartLedger"
$LogFile = Join-Path $ProjectRoot "auto-commit.log"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Log function
function Write-Log {
    param([string]$Message)
    $LogMessage = "[$Timestamp] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

Write-Log "========================================"
Write-Log "Auto Commit Started"
Write-Log "========================================"

cd $ProjectRoot

# Check if there are changes
$Changes = git status --porcelain
if ([string]::IsNullOrWhiteSpace($Changes)) {
    Write-Log "No changes detected. Skipping commit."
    Write-Log "========================================"
    exit 0
}

Write-Log "Changes detected:"
Write-Log $Changes

# Step 1: Validation
if (-not $SkipAnalysis) {
    Write-Log "Running analysis..."
    $AnalysisOutput = flutter analyze --no-pub 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Analysis failed. Aborting commit."
        Write-Log $AnalysisOutput
        Write-Log "========================================"
        exit 1
    }
    Write-Log "Analysis passed"
}

# Step 2: Git Commit
Write-Log "Committing changes..."
$CommitMessage = "Auto-commit: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git add .
git commit -m $CommitMessage
if ($LASTEXITCODE -ne 0) {
    Write-Log "Commit failed"
    Write-Log "========================================"
    exit 1
}

$CommitHash = git rev-parse HEAD
Write-Log "Commit successful: $CommitHash"

# Step 3: Create Backup
Write-Log "Creating backup..."
$BackupDir = Join-Path $ProjectRoot "backups"
$BackupName = "auto-backup-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
$BackupPath = Join-Path $BackupDir $BackupName

New-Item -ItemType Directory -Force -Path $BackupPath | Out-Null

$DirsToBackup = @("lib", "test", "tools")
foreach ($Dir in $DirsToBackup) {
    $SourcePath = Join-Path $ProjectRoot $Dir
    if (Test-Path $SourcePath) {
        Copy-Item -Path $SourcePath -Destination $BackupPath -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

$FilesToBackup = @("pubspec.yaml", "pubspec.lock", "analysis_options.yaml")
foreach ($File in $FilesToBackup) {
    $SourcePath = Join-Path $ProjectRoot $File
    if (Test-Path $SourcePath) {
        Copy-Item -Path $SourcePath -Destination $BackupPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

Write-Log "Backup created: $BackupPath"

# Step 4: Push to GitHub
Write-Log "Pushing to GitHub..."
$PushOutput = git push origin main 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Log "Push failed:"
    Write-Log $PushOutput
    Write-Log "========================================"
    exit 1
}

Write-Log "Push successful"
Write-Log "========================================"
Write-Log "Auto commit completed successfully!"
Write-Log "========================================"
