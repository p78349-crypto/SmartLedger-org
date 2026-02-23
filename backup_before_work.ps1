#!/usr/bin/env pwsh
# SmartLedger 중요 작업 전 자동 백업 스크립트
# 사용법: .\backup_before_work.ps1 "작업 이름"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkName = "unnamed_work"
)

$sourceFolder = 'C:\Users\plain\SmartLedger'
$backupRoot = 'C:\Users\plain\SmartLedger_backups'
$timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$backupName = "SmartLedger_before_${WorkName}_$timestamp"
$backupPath = Join-Path $backupRoot $backupName

# 백업 폴더 생성
if (!(Test-Path $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
}

# 백업 실행
Write-Host "🔄 백업 시작: $WorkName" -ForegroundColor Cyan
Write-Host "📁 원본: $sourceFolder"
Write-Host "💾 백업: $backupPath"
Write-Host ""

$startTime = Get-Date
Copy-Item -Path $sourceFolder -Destination $backupPath -Recurse -Force -ErrorAction Stop
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host "✅ 백업 완료!" -ForegroundColor Green
Write-Host "⏱️  소요시간: $($duration)초"
Write-Host "📂 복구 필요 시: $backupPath 참고"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "이제 작업을 시작하세요!"
Write-Host "Rule 2: flutter analyze → build 필수 확인"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
