#!/usr/bin/env pwsh
# SmartLedger 하루 작업 완료 스크립트 (Rule 5 자동화)
# 사용법: .\finalize_work.ps1

Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✨ SmartLedger 하루 작업 완료 (Rule 5)" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# Step 1: flutter analyze (최종 확인)
Write-Host "1️⃣  최종 코드 분석..." -ForegroundColor Yellow
$analyzeOutput = flutter analyze 2>&1
Write-Host $analyzeOutput

if ($LASTEXITCODE -eq 0 -and $analyzeOutput -match "No issues found") {
    Write-Host "✅ 코드 상태: 정상 (0 issues)" -ForegroundColor Green
} else {
    Write-Host "⚠️  코드 오류 있음! 수정 후 재시도" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: git status (변경사항 확인)
Write-Host "2️⃣  변경사항 확인..." -ForegroundColor Yellow
$gitStatus = git status --short
if ($gitStatus) {
    Write-Host "📝 변경된 파일:"
    $gitStatus | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "✅ 모든 변경사항이 커밋됨" -ForegroundColor Green
}

Write-Host ""

# Step 3: 최종 백업
Write-Host "3️⃣  최종 백업 생성..." -ForegroundColor Yellow

$sourceFolder = 'C:\Users\plain\SmartLedger'
$backupRoot = 'C:\Users\plain\SmartLedger_backups'
$timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$backupName = "SmartLedger_backup_Final_$timestamp"
$backupPath = Join-Path $backupRoot $backupName

if (!(Test-Path $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
}

$startTime = Get-Date
Copy-Item -Path $sourceFolder -Destination $backupPath -Recurse -Force
$duration = (Get-Date - $startTime).TotalSeconds

Write-Host "✅ 백업 생성 완료" -ForegroundColor Green
Write-Host "📂 위치: $backupPath"
Write-Host "⏱️  소요시간: $($duration)초"

Write-Host ""

# Step 4: 백업 목록 확인
Write-Host "4️⃣  백업 목록 확인..." -ForegroundColor Yellow
$backups = Get-ChildItem -Path $backupRoot -Directory | Sort-Object CreationTime -Descending | Select-Object -First 3
Write-Host "💾 최근 3개 백업:"
$backups | ForEach-Object {
    $size = (Get-ChildItem -Path $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "  • $($_.Name) (~$([Math]::Round($size, 1))MB)"
}

Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "🎉 오늘의 작업 완료!" -ForegroundColor Green
Write-Host ""
Write-Host "✅ flutter analyze: No issues found"
Write-Host "✅ 최종 백업: 생성됨"
Write-Host "✅ 코드 상태: 안정적"
Write-Host ""
Write-Host "내일 작업할 때:"
Write-Host "1. .\backup_before_work.ps1 \"작업내용\" (먼저 백업)"
Write-Host "2. 코드 수정"
Write-Host "3. .\verify_work.ps1 (검증)"
Write-Host "4. .\finalize_work.ps1 (완료)"
Write-Host ""
Write-Host "================== 안전한 코딩! ====================" -ForegroundColor Green
