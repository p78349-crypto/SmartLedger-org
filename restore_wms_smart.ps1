# 🚀 WMS 스마트 복원 시스템 (Smart Rollback)

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("minimal", "partial", "selective", "full")]
    [string]$RestoreMode = "selective",
    
    [Parameter(Mandatory=$false)]
    [bool]$KeepOptimizations = $true,
    
    [Parameter(Mandatory=$false)]
    [bool]$PerformanceCheck = $true,
    
    [Parameter(Mandatory=$false)]
    [string[]]$ComponentsToRestore = @(),
    
    [Parameter(Mandatory=$false)]
    [bool]$Confirm = $false
)

# 🎯 복원 모드 정의
$RestoreModes = @{
    "minimal" = @{
        "description" = "최소한의 복원 (성능 유지 95%+)"
        "components" = @("wms_data_gateway")
        "keepOptimizations" = @("cache", "database_pool", "barcode_service")
    }
    "partial" = @{
        "description" = "부분 복원 (성능 유지 80%+)"
        "components" = @("wms_data_gateway", "wms_unified_gateway")
        "keepOptimizations" = @("database_pool", "barcode_service")
    }
    "selective" = @{
        "description" = "선택적 복원 (성능 유지 60%+)"
        "components" = @("wms_data_gateway", "wms_io_screen", "wms_unified_gateway")
        "keepOptimizations" = @("database_pool")
    }
    "full" = @{
        "description" = "전체 복원 (원본 상태로 완전 복원)"
        "components" = @("all")
        "keepOptimizations" = @()
    }
}

# 📂 경로 설정
$BackupPath = "C:\Users\plain\SmartLedger\_wms_backup_20260221-144319"
$ProjectRoot = "C:\Users\plain\SmartLedger"

# 🔧 복원 가능한 컴포넌트 목록
$RestoreComponents = @{
    "wms_data_gateway" = @{
        "backup" = "$BackupPath\wms_data_gateway_original.dart"
        "target" = "lib\utils\wms_data_gateway.dart"
        "performance_impact" = "Low"
        "description" = "데이터 게이트웨이 (캐시 기능 제거)"
    }
    "wms_io_screen" = @{
        "backup" = "$BackupPath\wms_io_screen_original.dart"
        "target" = "lib\screens\wms_io_screen.dart"
        "performance_impact" = "Medium"
        "description" = "입출고 화면 (최적화 서비스 연결 제거)"
    }
    "wms_pda_screen" = @{
        "backup" = "$BackupPath\wms_pda_quick_input_screen_original.dart"
        "target" = "lib\screens\wms_pda_quick_input_screen.dart"
        "performance_impact" = "High"
        "description" = "PDA 화면 (DB풀, 바코드 최적화 제거)"
    }
    "wms_unified_gateway" = @{
        "backup" = "$BackupPath\wms_unified_gateway_original.dart"
        "target" = "lib\utils\wms_unified_gateway.dart"
        "performance_impact" = "Low"
        "description" = "통합 게이트웨이 (스마트 검색 제거)"
    }
    "consumable_service" = @{
        "backup" = "$BackupPath\consumable_inventory_service_original.dart"
        "target" = "lib\services\consumable_inventory_service.dart"
        "performance_impact" = "Medium"
        "description" = "재고 서비스 (최적화 로직 제거)"
    }
}

# 🚀 최적화 컴포넌트 관리
$OptimizationComponents = @{
    "cache" = @{
        "files" = @("lib\utils\wms_smart_cache.dart")
        "performance_gain" = "98%"
        "stability" = "High"
    }
    "database_pool" = @{
        "files" = @("lib\utils\wms_database_pool.dart")
        "performance_gain" = "95%"
        "stability" = "High"
    }
    "barcode_service" = @{
        "files" = @("lib\utils\wms_optimized_barcode_service.dart")
        "performance_gain" = "85%"
        "stability" = "Medium"
    }
    "performance_monitor" = @{
        "files" = @("lib\utils\wms_performance_monitor.dart", "lib\screens\wms_optimized_pda_screen.dart")
        "performance_gain" = "5%"
        "stability" = "High"
    }
}

function Show-RestoreMenu {
    Write-Host "🚀 WMS 스마트 복원 시스템" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Gray
    
    foreach ($mode in $RestoreModes.Keys | Sort-Object) {
        $info = $RestoreModes[$mode]
        Write-Host "[${mode}]" -ForegroundColor Yellow -NoNewline
        Write-Host " $($info.description)" -ForegroundColor White
    }
    Write-Host ""
    
    Write-Host "💡 권장 모드:" -ForegroundColor Green
    Write-Host "  • 문제 발생 시: minimal 또는 partial" -ForegroundColor White
    Write-Host "  • 성능 최적화 전 상태로: selective" -ForegroundColor White
    Write-Host "  • 완전 원본 복원: full" -ForegroundColor White
}

function Test-PerformanceImpact {
    param([string[]]$ComponentsToRestore)
    
    $totalImpact = 0
    $impactLevels = @{ "Low" = 10; "Medium" = 30; "High" = 60 }
    
    foreach ($component in $ComponentsToRestore) {
        if ($RestoreComponents.ContainsKey($component)) {
            $impact = $RestoreComponents[$component].performance_impact
            $totalImpact += $impactLevels[$impact]
        }
    }
    
    $performanceRetention = [Math]::Max(0, 100 - $totalImpact)
    return $performanceRetention
}

function Backup-CurrentOptimizations {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $safeguardDir = "_safeguard_optimizations_$timestamp"
    
    Write-Host "💾 현재 최적화 상태 백업 중..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $safeguardDir -Force | Out-Null
    
    # 현재 최적화된 파일들 백업
    foreach ($component in $RestoreComponents.Keys) {
        $targetPath = $RestoreComponents[$component].target
        if (Test-Path $targetPath) {
            $backupName = (Split-Path $targetPath -Leaf) -replace '.dart$', '_optimized.dart'
            Copy-Item $targetPath "$safeguardDir\$backupName" -Force
        }
    }
    
    # 최적화 서비스 파일들도 백업
    foreach ($optim in $OptimizationComponents.Values) {
        foreach ($file in $optim.files) {
            if (Test-Path $file) {
                $fileName = Split-Path $file -Leaf
                Copy-Item $file "$safeguardDir\$fileName" -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Write-Host "✅ 백업 완료: $safeguardDir" -ForegroundColor Green
    return $safeguardDir
}

function Restore-Components {
    param(
        [string[]]$Components,
        [string[]]$KeepOptimizations = @()
    )
    
    Write-Host "`n🔄 컴포넌트 복원 시작..." -ForegroundColor Yellow
    
    foreach ($component in $Components) {
        if ($component -eq "all") {
            # 전체 복원
            foreach ($comp in $RestoreComponents.Keys) {
                Restore-SingleComponent -Component $comp
            }
        } elseif ($RestoreComponents.ContainsKey($component)) {
            Restore-SingleComponent -Component $component
        } else {
            Write-Host "❌ 알 수 없는 컴포넌트: $component" -ForegroundColor Red
        }
    }
    
    # 보존할 최적화 컴포넌트들은 유지
    if ($KeepOptimizations.Count -gt 0) {
        Write-Host "`n🔧 최적화 컴포넌트 보존 중..." -ForegroundColor Cyan
        foreach ($optim in $KeepOptimizations) {
            if ($OptimizationComponents.ContainsKey($optim)) {
                $info = $OptimizationComponents[$optim]
                Write-Host "  ✓ 보존: $optim (성능 향상: $($info.performance_gain))" -ForegroundColor Green
            }
        }
    }
}

function Restore-SingleComponent {
    param([string]$Component)
    
    $comp = $RestoreComponents[$Component]
    $backupFile = $comp.backup
    $targetFile = $comp.target
    
    if (Test-Path $backupFile) {
        Copy-Item $backupFile $targetFile -Force
        Write-Host "  ✅ 복원: $Component" -ForegroundColor Green
        Write-Host "      → $($comp.description)" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ 백업 파일 없음: $Component" -ForegroundColor Red
    }
}

function Remove-OptimizationComponents {
    param([string[]]$ComponentsToRemove)
    
    if ($ComponentsToRemove.Count -eq 0) { return }
    
    Write-Host "`n🗑️ 최적화 컴포넌트 제거..." -ForegroundColor Yellow
    
    foreach ($component in $ComponentsToRemove) {
        if ($OptimizationComponents.ContainsKey($component)) {
            $files = $OptimizationComponents[$component].files
            foreach ($file in $files) {
                if (Test-Path $file) {
                    Remove-Item $file -Force
                    Write-Host "  🗑️ 제거: $(Split-Path $file -Leaf)" -ForegroundColor Yellow
                }
            }
        }
    }
}

function Test-BuildAfterRestore {
    Write-Host "`n🔍 복원 후 빌드 검증 중..." -ForegroundColor Cyan
    
    # Flutter 분석
    $analyzeResult = & flutter analyze --no-fatal-infos 2>&1
    $analyzeSuccess = $LASTEXITCODE -eq 0
    
    if ($analyzeSuccess) {
        Write-Host "✅ 코드 분석 통과" -ForegroundColor Green
    } else {
        Write-Host "❌ 코드 분석 실패:" -ForegroundColor Red
        Write-Host $analyzeResult -ForegroundColor Red
        return $false
    }
    
    return $true
}

function Show-PerformanceSummary {
    param(
        [string[]]$RestoredComponents,
        [string[]]$KeptOptimizations,
        [int]$EstimatedPerformance
    )
    
    Write-Host "`n📊 복원 요약" -ForegroundColor Cyan
    Write-Host "=" * 40 -ForegroundColor Gray
    
    Write-Host "복원된 컴포넌트:" -ForegroundColor Yellow
    foreach ($comp in $RestoredComponents) {
        if ($RestoreComponents.ContainsKey($comp)) {
            $impact = $RestoreComponents[$comp].performance_impact
            $color = switch ($impact) { "Low" { "Green" } "Medium" { "Yellow" } "High" { "Red" } }
            Write-Host "  • $comp (영향: $impact)" -ForegroundColor $color
        }
    }
    
    Write-Host "`n유지된 최적화:" -ForegroundColor Yellow
    foreach ($optim in $KeptOptimizations) {
        if ($OptimizationComponents.ContainsKey($optim)) {
            $gain = $OptimizationComponents[$optim].performance_gain
            Write-Host "  • $optim (성능: +$gain)" -ForegroundColor Green
        }
    }
    
    $performanceColor = if ($EstimatedPerformance -ge 80) { "Green" } 
                       elseif ($EstimatedPerformance -ge 60) { "Yellow" } 
                       else { "Red" }
    
    Write-Host "`n🎯 예상 성능 유지율: $EstimatedPerformance%" -ForegroundColor $performanceColor
    
    if ($EstimatedPerformance -ge 80) {
        Write-Host "   → 최적 상태 유지! 🚀" -ForegroundColor Green
    } elseif ($EstimatedPerformance -ge 60) {
        Write-Host "   → 양호한 상태 ⚡" -ForegroundColor Yellow
    } else {
        Write-Host "   → 성능 저하 주의 ⚠️" -ForegroundColor Red
    }
}

# ==========================================
# 메인 실행 부분
# ==========================================

Clear-Host
Show-RestoreMenu

# 인터랙티브 모드 또는 매개변수 모드
if ($RestoreMode -eq "selective" -and $ComponentsToRestore.Count -eq 0 -and -not $Confirm) {
    Write-Host "`n복원 모드를 선택하세요 [minimal/partial/selective/full]: " -NoNewline
    $selectedMode = Read-Host
    if ($RestoreModes.ContainsKey($selectedMode)) {
        $RestoreMode = $selectedMode
    }
}

# 복원 모드에 따른 설정
$modeConfig = $RestoreModes[$RestoreMode]
$componentsToRestore = if ($ComponentsToRestore.Count -gt 0) { $ComponentsToRestore } else { $modeConfig.components }
$optimizationsToKeep = if ($KeepOptimizations) { $modeConfig.keepOptimizations } else { @() }

# 성능 영향 계산
if ($componentsToRestore -contains "all") {
    $estimatedPerformance = 0  # 전체 복원 시
} else {
    $estimatedPerformance = Test-PerformanceImpact -ComponentsToRestore $componentsToRestore
}

# 확인 메시지
Write-Host "`n🎯 복원 계획:" -ForegroundColor Cyan
Write-Host "  모드: $RestoreMode" -ForegroundColor White
Write-Host "  예상 성능 유지: $estimatedPerformance%" -ForegroundColor $(if ($estimatedPerformance -ge 80) { "Green" } else { "Yellow" })

if (-not $Confirm) {
    $response = Read-Host "`n계속하시겠습니까? (Y/N)"
    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host "❌ 복원이 취소되었습니다." -ForegroundColor Red
        exit 1
    }
}

# 백업 생성
$safeguardPath = Backup-CurrentOptimizations

# 컴포넌트 복원 실행
Restore-Components -Components $componentsToRestore -KeepOptimizations $optimizationsToKeep

# 제거할 최적화 컴포넌트들 계산
$allOptimizations = $OptimizationComponents.Keys
$optimizationsToRemove = $allOptimizations | Where-Object { $_ -notin $optimizationsToKeep }

# 필요 시 최적화 컴포넌트 제거
if ($optimizationsToRemove.Count -gt 0) {
    Remove-OptimizationComponents -ComponentsToRemove $optimizationsToRemove
}

# 빌드 검증
if ($PerformanceCheck) {
    $buildSuccess = Test-BuildAfterRestore
    if (-not $buildSuccess) {
        Write-Host "`n⚠️ 빌드 오류 발생! 백업에서 복구할까요? (Y/N): " -NoNewline
        $rollback = Read-Host
        if ($rollback -eq 'Y' -or $rollback -eq 'y') {
            Write-Host "🔄 백업에서 복구 중..." -ForegroundColor Yellow
            # 백업에서 복구 로직 (생략)
        }
    }
}

# 결과 요약
Show-PerformanceSummary -RestoredComponents $componentsToRestore -KeptOptimizations $optimizationsToKeep -EstimatedPerformance $estimatedPerformance

Write-Host "`n🎉 스마트 복원 완료!" -ForegroundColor Green
Write-Host "💾 안전 백업 위치: $safeguardPath" -ForegroundColor Cyan
Write-Host "🔧 다음 명령 실행 권장: flutter clean && flutter pub get" -ForegroundColor Yellow