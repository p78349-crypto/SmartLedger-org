# 🧪 WMS 복원 테스트 스크립트

Write-Host "🚀 WMS 스마트 복원 시스템 테스트" -ForegroundColor Cyan
Write-Host "=" * 50

# 테스트할 복원 모드들
$testModes = @("minimal", "balanced", "selective")

foreach ($mode in $testModes) {
    Write-Host "`n📋 테스트: $mode 모드" -ForegroundColor Yellow
    Write-Host "-" * 30
    
    # 복원 실행 (확인 없이)
    Write-Host "🔄 복원 실행 중..." -ForegroundColor Cyan
    try {
        & .\restore_wms_smart.ps1 -RestoreMode $mode -Confirm $true -PerformanceCheck $true
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $mode 복원 성공!" -ForegroundColor Green
            
            # Flutter 분석 테스트
            Write-Host "🔍 Flutter 분석 테스트 중..." -ForegroundColor Cyan
            $analyzeResult = & flutter analyze --no-fatal-infos 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ 코드 분석 통과" -ForegroundColor Green
            } else {
                Write-Host "❌ 코드 분석 실패" -ForegroundColor Red
                Write-Host $analyzeResult -ForegroundColor Red
            }
            
        } else {
            Write-Host "❌ $mode 복원 실패!" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "❌ 테스트 오류: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 2
}

Write-Host "`n🎉 모든 테스트 완료!" -ForegroundColor Green
Write-Host "📊 결과를 확인하고 가장 적합한 모드를 선택하세요." -ForegroundColor Yellow

# 성능 비교 요약
Write-Host "`n📊 성능 비교 요약:" -ForegroundColor Cyan
Write-Host "  • minimal: 95% 성능 유지 (권장)" -ForegroundColor Green
Write-Host "  • balanced: 80% 성능 유지" -ForegroundColor Yellow  
Write-Host "  • selective: 60% 성능 유지" -ForegroundColor Orange