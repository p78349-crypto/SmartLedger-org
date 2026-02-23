#!/usr/bin/env pwsh
# SmartLedger 작업 검증 스크립트 (Rule 2 자동화)
# 사용법: .\verify_work.ps1

Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🔍 SmartLedger 작업 검증 (Rule 2)" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 1: flutter analyze
Write-Host "1️⃣  코드 분석 (flutter analyze)..." -ForegroundColor Yellow
$analyzeOutput = flutter analyze 2>&1
$analyzeResult = $LASTEXITCODE

Write-Host $analyzeOutput
Write-Host ""

if ($analyzeResult -eq 0 -and $analyzeOutput -match "No issues found") {
    Write-Host "✅ Step 1 PASS: No issues found!" -ForegroundColor Green
    $step1Pass = $true
} else {
    Write-Host "❌ Step 1 FAIL: 오류 발견! 수정 후 재시도" -ForegroundColor Red
    $step1Pass = $false
}

Write-Host ""

# Step 2: flutter build (Step 1이 패스한 경우만 진행)
if ($step1Pass) {
    Write-Host "2️⃣  APK 빌드 (flutter clean; flutter build apk --release)..." -ForegroundColor Yellow
    Write-Host "(이 과정은 1-2분 소요됩니다)" -ForegroundColor Gray
    Write-Host ""
    
    flutter clean 2>&1 | Out-Null
    $buildOutput = flutter build apk --release 2>&1
    $buildResult = $LASTEXITCODE
    
    # 빌드 출력에서 마지막 부분만 표시
    $buildOutput | Select-Object -Last 5 | ForEach-Object { Write-Host $_ }
    Write-Host ""
    
    if ($buildResult -eq 0) {
        Write-Host "✅ Step 2 PASS: APK 빌드 성공!" -ForegroundColor Green
        $step2Pass = $true
    } else {
        Write-Host "❌ Step 2 FAIL: 빌드 실패! flutter analyze 재확인" -ForegroundColor Red
        $step2Pass = $false
    }
} else {
    Write-Host "⏭️  Step 2 생략 (Step 1 실패)" -ForegroundColor Yellow
    $step2Pass = $false
}

Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan

if ($step1Pass -and $step2Pass) {
    Write-Host "🎉 모든 검증 완료!" -ForegroundColor Green
    Write-Host ""
    Write-Host "✅ flutter analyze: No issues found"
    Write-Host "✅ flutter build: APK 생성 완료"
    Write-Host ""
    Write-Host "이전 작업에 건드리지 마세요!"
    Write-Host "새로운 작업은 Rule 1부터 시작하세요!"
    exit 0
} else {
    Write-Host "❌ 검증 실패!" -ForegroundColor Red
    Write-Host ""
    if (-not $step1Pass) {
        Write-Host "→ flutter analyze 오류 수정 필요"
    }
    if (-not $step2Pass) {
        Write-Host "→ 빌드 실패, 콘솔 메시지 확인"
    }
    exit 1
}
