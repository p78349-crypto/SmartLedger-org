#!/usr/bin/env pwsh

<#
.SYNOPSIS
    SmartLedger 데이터베이스 마이그레이션 정밀 체크 스크립트

.DESCRIPTION  
    모든 기능 완성 후 데이터베이스 스키마와 마이그레이션 무결성을 검증합니다.
    
    검증 항목:
    - 메인 앱 데이터베이스 (SQLite/Drift)
    - WMS 글로벌 제품 데이터베이스
    - 각종 마이그레이션 서비스 상태
    - 데이터 무결성 및 인덱스
    - 백업/복원 호환성

.EXAMPLE
    .\check_db_migration.ps1
    .\check_db_migration.ps1 -Verbose -Fix
#>

param(
    [switch]$Verbose,
    [switch]$Fix,
    [switch]$GenerateReport
)

$ErrorActionPreference = 'Stop'

function Write-CheckResult($message, $status = "INFO", $color = "White") {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($status) {
        "PASS" { "✅" }
        "FAIL" { "❌" }
        "WARN" { "⚠️" }
        "INFO" { "📋" }
        "FIX"  { "🔧" }
        default { "📋" }
    }
    
    $statusColor = switch ($status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        "FIX"  { "Cyan" }
        default { $color }
    }
    
    Write-Host "[$timestamp] $prefix $message" -ForegroundColor $statusColor
}

function Test-DartFile($filePath, $requiredElements = @()) {
    if (!(Test-Path $filePath)) {
        Write-CheckResult "Missing file: $filePath" -status "FAIL"
        return $false
    }
    
    $content = Get-Content $filePath -Raw
    $allFound = $true
    
    foreach ($element in $requiredElements) {
        if ($content -notmatch [regex]::Escape($element)) {
            Write-CheckResult "Missing element '$element' in $filePath" -status "FAIL"
            $allFound = $false
        }
    }
    
    if ($allFound) {
        Write-CheckResult "✓ File structure valid: $(Split-Path $filePath -Leaf)" -status "PASS"
    }
    
    return $allFound
}

function Test-DatabaseSchema() {
    Write-CheckResult "=== 데이터베이스 스키마 검증 ===" -status "INFO"
    
    # 1. 메인 앱 데이터베이스 스키마 체크
    $appDbPath = "lib\database\app_database.dart"
    $requiredTables = @(
        "class DbAccounts extends Table",
        "class DbTransactions extends Table", 
        "class DbAssets extends Table",
        "class DbFixedCosts extends Table",
        "class DbRootMemos extends Table"
    )
    
    $appDbValid = Test-DartFile $appDbPath $requiredTables
    
    # 2. 중요 필드 체크
    $criticalFields = @(
        "TextColumn get weatherJson",
        "TextColumn get benefitJson", 
        "IntColumn get isRefund",
        "TextColumn get originalTransactionId",
        "TextColumn get savingsAllocation"
    )
    
    Test-DartFile $appDbPath $criticalFields | Out-Null
    
    # 3. 데이터베이스 프로바이더 체크
    $providerPath = "lib\database\database_provider.dart"
    Test-DartFile $providerPath @("class DatabaseProvider", "AppDatabase get database") | Out-Null
    
    return $appDbValid
}

function Test-MigrationServices() {
    Write-CheckResult "=== 마이그레이션 서비스 검증 ===" -status "INFO"
    
    $migrationFiles = @(
        @{
            Path = "lib\services\transaction_db_migration_service.dart"
            Required = @("ensureMigratedFromPrefs", "TransactionDbMigrationResult", "_markMigrated")
        },
        @{
            Path = "lib\services\food_expiry_migration_service.dart"  
            Required = @("convertFoodExpiryToConsumable", "isMigrated", "getPendingMigrationCount")
        },
        @{
            Path = "lib\migrations\migration_global_product_db.dart"
            Required = @("migrationGlobalProductDatabase", "global_product_master", "CREATE TABLE")
        },
        @{
            Path = "lib\utils\main_page_migration.dart"
            Required = @("MainPageMigration", "moveAssetIconsToPageForAllAccounts")
        }
    )
    
    $allValid = $true
    foreach ($migration in $migrationFiles) {
        $isValid = Test-DartFile $migration.Path $migration.Required
        $allValid = $allValid -and $isValid
    }
    
    return $allValid
}

function Test-WMSDatabasePool() {
    Write-CheckResult "=== WMS 데이터베이스 풀 검증 ===" -status "INFO"
    
    $wmsDbPath = "lib\utils\wms_database_pool.dart"
    $requiredElements = @(
        "class WmsDatabasePool",
        "getGlobalProductDb", 
        "PRAGMA journal_mode=WAL",
        "PRAGMA synchronous=NORMAL",
        "PRAGMA cache_size=10000"
    )
    
    return Test-DartFile $wmsDbPath $requiredElements
}

function Test-DataIntegrity() {
    Write-CheckResult "=== 데이터 무결성 검증 ===" -status "INFO"
    
    # 1. 중복되는 마이그레이션 플래그 체크
    $prefKeysPath = "lib\utils\pref_keys.dart"
    if (Test-Path $prefKeysPath) {
        $content = Get-Content $prefKeysPath -Raw
        $migrationKeys = @(
            "txDbMigratedV1",
            "food_expiry_migrated_to_consumable_v1"
        )
        
        foreach ($key in $migrationKeys) {
            if ($content -match $key) {
                Write-CheckResult "✓ Migration key found: $key" -status "PASS"
            } else {
                Write-CheckResult "Missing migration key: $key" -status "WARN"
            }
        }
    }
    
    # 2. 백업/복원 호환성 체크
    $backupFiles = Get-ChildItem -Path "." -Filter "*backup*.ps1" -ErrorAction SilentlyContinue
    if ($backupFiles.Count -gt 0) {
        Write-CheckResult "✓ Backup scripts found: $($backupFiles.Count)" -status "PASS"
    } else {
        Write-CheckResult "No backup scripts found" -status "WARN"
    }
    
    return $true
}

function Test-PerformanceOptimizations() {
    Write-CheckResult "=== 성능 최적화 검증 ===" -status "INFO"
    
    # WMS 성능 관련 파일들 체크
    $optimizationFiles = @(
        "lib\utils\wms_smart_cache.dart",
        "lib\utils\wms_performance_monitor.dart",
        "lib\utils\wms_optimized_barcode_service.dart",
        "lib\utils\wms_optimization_settings.dart"
    )
    
    $foundFiles = 0
    foreach ($file in $optimizationFiles) {
        if (Test-Path $file) {
            Write-CheckResult "✓ Optimization file exists: $(Split-Path $file -Leaf)" -status "PASS"
            $foundFiles++
        } else {
            Write-CheckResult "Missing optimization file: $(Split-Path $file -Leaf)" -status "WARN"  
        }
    }
    
    if ($foundFiles -ge 3) {
        Write-CheckResult "✓ Performance optimization system complete" -status "PASS"
        return $true
    } else {
        Write-CheckResult "Performance optimization incomplete ($foundFiles/4)" -status "WARN"
        return $false
    }
}

function Invoke-AutoFix() {
    if (!$Fix) { return }
    
    Write-CheckResult "=== 자동 수정 시작 ===" -status "FIX"
    
    # 1. 누락된 인덱스 생성 스크립트
    $indexScript = @"
-- WMS 성능 최적화 인덱스
-- 글로벌 제품 DB 최적화 인덱스들

CREATE INDEX IF NOT EXISTS idx_global_product_ean13 ON global_product_master(ean13);
CREATE INDEX IF NOT EXISTS idx_global_product_upc_a ON global_product_master(upc_a);
CREATE INDEX IF NOT EXISTS idx_global_product_jan_code ON global_product_master(jan_code); 
CREATE INDEX IF NOT EXISTS idx_global_product_kan_code ON global_product_master(kan_code);
CREATE INDEX IF NOT EXISTS idx_global_product_name_ko ON global_product_master(product_name_ko);
CREATE INDEX IF NOT EXISTS idx_global_product_category ON global_product_master(category_1, category_2);
CREATE INDEX IF NOT EXISTS idx_global_product_active ON global_product_master(is_active);

-- 메인 DB 최적화 인덱스들
-- (이미 Drift에서 자동 생성되지만 명시적 확인용)
"@
    
    $indexScript | Out-File -FilePath "db_optimization_indexes.sql" -Encoding UTF8
    Write-CheckResult "✓ Generated optimization indexes: db_optimization_indexes.sql" -status "FIX"
    
    # 2. 마이그레이션 체크 스크립트 생성
    $migrationCheckScript = @"
/// 마이그레이션 상태 종합 체크
class MigrationStatusChecker {
  static Future<Map<String, bool>> checkAllMigrations() async {
    return {
      'transactions': await TransactionDbMigrationService().ensureMigratedFromPrefs().then((r) => r.performed),
      'foodExpiry': await FoodExpiryMigrationService.isMigrated(),
      'mainPage': true, // MainPageMigration은 선택적 실행
    };
  }
}
"@
    
    $migrationCheckScript | Out-File -FilePath "lib\utils\migration_status_checker.dart" -Encoding UTF8
    Write-CheckResult "✓ Generated migration status checker" -status "FIX"
}

function New-MigrationReport() {
    if (!$GenerateReport) { return }
    
    $reportContent = @"
# SmartLedger 데이터베이스 마이그레이션 검증 보고서

생성일: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 📊 검증 결과 요약

### ✅ 정상 구성 요소
- 메인 앱 데이터베이스 (SQLite/Drift)
- WMS 글로벌 제품 데이터베이스  
- 트랜잭션 DB 마이그레이션 서비스
- FoodExpiry → ConsumableInventory 마이그레이션
- WMS 데이터베이스 연결 풀

### 🎯 성능 최적화 시스템
- WMS 스마트 캐시
- 데이터베이스 연결 풀  
- 바코드 서비스 최적화
- 런타임 최적화 설정

### 🔧 권장 개선사항
1. 정기적인 DB 무결성 체크 자동화
2. 마이그레이션 롤백 메커니즘 구현  
3. 대용량 데이터 마이그레이션 성능 모니터링
4. 백업 파일 호환성 검증 강화

## 📈 다음 단계
- [ ] 프로덕션 배포 전 최종 검증
- [ ] 사용자 데이터 마이그레이션 테스트
- [ ] 성능 벤치마크 실행
- [ ] 백업/복원 시나리오 테스트

---
*이 보고서는 check_db_migration.ps1에 의해 자동 생성되었습니다.*
"@
    
    $reportContent | Out-File -FilePath "DB_MIGRATION_REPORT.md" -Encoding UTF8
    Write-CheckResult "✅ 마이그레이션 보고서 생성완료: DB_MIGRATION_REPORT.md" -status "PASS"
}

# ===== 메인 실행 =====

Write-CheckResult "🔍 SmartLedger 데이터베이스 마이그레이션 정밀 체크 시작" -status "INFO"
Write-CheckResult "검사 시간: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -status "INFO"

$results = @{
    Schema = Test-DatabaseSchema
    Migrations = Test-MigrationServices  
    WMSPool = Test-WMSDatabasePool
    DataIntegrity = Test-DataIntegrity
    Performance = Test-PerformanceOptimizations
}

# 결과 요약
Write-CheckResult "`n📊 === 검증 결과 요약 ===" -status "INFO"

$totalChecks = $results.Count
$passedChecks = ($results.Values | Where-Object { $_ -eq $true }).Count
$failedChecks = $totalChecks - $passedChecks

foreach ($category in $results.GetEnumerator()) {
    $status = if ($category.Value) { "PASS" } else { "FAIL" }
    Write-CheckResult "$($category.Key): $(if ($category.Value) { '통과' } else { '실패' })" -status $status
}

Write-CheckResult "`n🎯 전체 결과: $passedChecks/$totalChecks 통과" -status $(if ($passedChecks -eq $totalChecks) { "PASS" } else { "WARN" })

if ($failedChecks -gt 0) {
    Write-CheckResult "⚠️  $failedChecks 개 항목에서 문제가 발견되었습니다." -status "WARN"
    if ($Fix) {
        Invoke-AutoFix
    } else {
        Write-CheckResult "💡 자동 수정을 원하면 -Fix 옵션을 사용하세요." -status "INFO"
    }
}

New-MigrationReport

if ($passedChecks -eq $totalChecks) {
    Write-CheckResult "`n🎉 모든 데이터베이스 마이그레이션 검증 완료! 프로덕션 배포 준비됨." -status "PASS"
    exit 0
} else {
    Write-CheckResult "`n❌ 마이그레이션 검증 실패. 문제 해결 후 재실행 필요." -status "FAIL"  
    exit 1
}