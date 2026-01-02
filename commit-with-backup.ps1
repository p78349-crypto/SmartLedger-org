# 작업 완료 후 자동 백업 및 커밋 스크립트
# 간단한 사용법: .\commit-with-backup.ps1 -Message "커밋 메시지"

param(
    [Parameter(Mandatory=$true)]
    [string]$Message
)

$ProjectRoot = (Get-Location).Path
$BackupDir = Join-Path $ProjectRoot "backups"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

Write-Host ""
Write-Host "========================" -ForegroundColor Cyan
Write-Host "Step 1: Validation" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Flutter analysis
Write-Host "Running static analysis..." -ForegroundColor Yellow
$AnalysisResult = flutter analyze --no-pub 2>&1 | Select-Object -First 10
if ($LASTEXITCODE -eq 0) {
    Write-Host "PASSED: Analysis" -ForegroundColor Green
} else {
    Write-Host "FAILED: Analysis" -ForegroundColor Red
    Write-Host $AnalysisResult
    exit 1
}

Write-Host ""
Write-Host "========================" -ForegroundColor Cyan
Write-Host "Step 2: Git Commit" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""

# Step 2: Git commit
Write-Host "Commit message: $Message" -ForegroundColor White
git add .
git commit -m $Message
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED: Commit" -ForegroundColor Red
    exit 1
}

$CommitHash = git rev-parse HEAD
Write-Host "SUCCESS: Commit" -ForegroundColor Green
Write-Host "Commit SHA: $CommitHash" -ForegroundColor Yellow

Write-Host ""
Write-Host "========================" -ForegroundColor Cyan
Write-Host "Step 3: Auto Backup" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""

# Step 3: Auto backup
$BackupName = "auto-backup-$Timestamp"
$BackupPath = Join-Path $BackupDir $BackupName

New-Item -ItemType Directory -Force -Path $BackupPath | Out-Null
Write-Host "Creating backup: $BackupName" -ForegroundColor White

# Backup directories
$DirsToBackup = @("lib", "test", "tools")
foreach ($Dir in $DirsToBackup) {
    $SourcePath = Join-Path $ProjectRoot $Dir
    if (Test-Path $SourcePath) {
        Copy-Item -Path $SourcePath -Destination $BackupPath -Recurse -Force | Out-Null
        Write-Host "  BACKED UP: $Dir" -ForegroundColor Green
    }
}

# Backup config files
$FilesToBackup = @("pubspec.yaml", "pubspec.lock", "analysis_options.yaml")
foreach ($File in $FilesToBackup) {
    $SourcePath = Join-Path $ProjectRoot $File
    if (Test-Path $SourcePath) {
        Copy-Item -Path $SourcePath -Destination $BackupPath -Force | Out-Null
    }
}

Write-Host ""
Write-Host "========================" -ForegroundColor Green
Write-Host "ALL TASKS COMPLETED!" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Message: $Message" -ForegroundColor White
Write-Host "  SHA: $CommitHash" -ForegroundColor White
Write-Host "  Backup: $BackupPath" -ForegroundColor White
Write-Host ""
