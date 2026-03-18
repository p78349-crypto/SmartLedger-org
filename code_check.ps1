# ============================================================
# SmartLedger 코드 검수 스크립트 (커닝페이퍼 자동화)
# 관련 규칙: AI_CODE_RULES.md (SSOT v3), INFRA_PERFORMANCE_RULES.md
# 사용법: .\code_check.ps1 [-Path lib/specific/folder]
# ============================================================

param(
    [string]$Path = "lib"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Red    = "Red"
$Yellow = "Yellow"
$Green  = "Green"
$Cyan   = "Cyan"
$White  = "White"

$pass = 0; $warn = 0; $fail = 0

function Report([string]$Status, [string]$Rule, [string]$Msg) {
    switch ($Status) {
        "PASS" {
            Write-Host "  [PASS] " -NoNewline -ForegroundColor $Green
            $script:pass++
        }
        "WARN" {
            Write-Host "  [WARN] " -NoNewline -ForegroundColor $Yellow
            $script:warn++
        }
        "FAIL" {
            Write-Host "  [FAIL] " -NoNewline -ForegroundColor $Red
            $script:fail++
        }
    }
    Write-Host "[$Rule] " -NoNewline -ForegroundColor $White
    Write-Host $Msg
}

Write-Host ""
Write-Host "========================================" -ForegroundColor $Cyan
Write-Host " SmartLedger Code Check" -ForegroundColor $Cyan
Write-Host " $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $Cyan
Write-Host "========================================" -ForegroundColor $Cyan
Write-Host ""

# ----------------------------------------------------------
# 1. A2: 파일 크기 (300줄 제한)
# ----------------------------------------------------------
Write-Host "[A2] 파일 크기 검사 (300줄 제한)..." -ForegroundColor $Cyan

$dartFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.dart" |
    Where-Object { $_.Name -notmatch '\.(g|freezed)\.dart$' }

$overFiles = @()
$warnFiles = @()

foreach ($f in $dartFiles) {
    $lines = @(Get-Content $f.FullName).Count
    $isTest = $f.FullName -match '[/\\]test[/\\]'
    $limit = if ($isTest) { 500 } else { 300 }
    $warnLimit = if ($isTest) { 400 } else { 250 }

    if ($lines -gt $limit) {
        $overFiles += [PSCustomObject]@{
            File  = $f.FullName.Replace($PWD.Path + "\", "")
            Lines = $lines
            Limit = $limit
        }
    } elseif ($lines -gt $warnLimit) {
        $warnFiles += [PSCustomObject]@{
            File  = $f.FullName.Replace($PWD.Path + "\", "")
            Lines = $lines
            Limit = $limit
        }
    }
}

if ($overFiles.Count -eq 0 -and $warnFiles.Count -eq 0) {
    Report "PASS" "A2" "전체 파일 300줄 이내"
} else {
    foreach ($o in $overFiles) {
        Report "FAIL" "A2" "$($o.File) = $($o.Lines)줄 (제한 $($o.Limit))"
    }
    foreach ($w in $warnFiles) {
        Report "WARN" "A2" "$($w.File) = $($w.Lines)줄 (경고 구간)"
    }
}

# ----------------------------------------------------------
# 2. A1: 80자 제한
# ----------------------------------------------------------
Write-Host ""
Write-Host "[A1] 80자 초과 라인 검사..." -ForegroundColor $Cyan

$longLineFiles = @()

foreach ($f in $dartFiles) {
    $content = Get-Content $f.FullName
    $longLines = @()
    $lineNum = 0
    foreach ($line in $content) {
        $lineNum++
        # import/URL/문자열 리터럴 예외
        if ($line -match '^\s*import\s' -or
            $line -match '^\s*export\s' -or
            $line -match 'https?://' -or
            $line -match "^\s*'[^']{60,}'\s*[,;)]*\s*$" -or
            $line -match '^\s*"[^"]{60,}"\s*[,;)]*\s*$') {
            continue
        }
        if ($line.Length -gt 80) {
            $longLines += $lineNum
        }
    }
    if ($longLines.Count -gt 0) {
        $longLineFiles += [PSCustomObject]@{
            File  = $f.FullName.Replace($PWD.Path + "\", "")
            Count = $longLines.Count
            First = ($longLines | Select-Object -First 3) -join ","
        }
    }
}

if ($longLineFiles.Count -eq 0) {
    Report "PASS" "A1" "전체 파일 80자 이내"
} else {
    $totalLong = ($longLineFiles | Measure-Object -Property Count -Sum).Sum
    if ($totalLong -le 10) {
        Report "WARN" "A1" "${totalLong}건 초과 (파일 $($longLineFiles.Count)개)" 
    } else {
        Report "FAIL" "A1" "${totalLong}건 초과 (파일 $($longLineFiles.Count)개)" 
    }
    foreach ($lf in ($longLineFiles | Sort-Object Count -Descending |
                     Select-Object -First 5)) {
        Write-Host "         $($lf.File): $($lf.Count)건 (L$($lf.First))" `
            -ForegroundColor $Yellow
    }
}

# ----------------------------------------------------------
# 3. A4: flutter analyze 에러
# ----------------------------------------------------------
Write-Host ""
Write-Host "[A4] flutter analyze..." -ForegroundColor $Cyan

try {
    $analyzeOut = & flutter analyze 2>&1 | Out-String
    $errorCount = 0
    $warnCount  = 0
    if ($analyzeOut -match '(\d+)\s+issue.*found') {
        $issueMatch = [regex]::Match($analyzeOut, '(\d+)\s+issue')
        $errorCount = [int]$issueMatch.Groups[1].Value
    }
    if ($analyzeOut -match 'No issues found') {
        Report "PASS" "A4" "flutter analyze — No issues found"
    } elseif ($errorCount -gt 0) {
        Report "FAIL" "A4" "flutter analyze — $errorCount issue(s)"
    } else {
        Report "WARN" "A4" "flutter analyze 결과 확인 필요"
    }
} catch {
    Report "WARN" "A4" "flutter analyze 실행 실패 (Flutter SDK 경로 확인)"
}

# ----------------------------------------------------------
# 4. R1: 동시성 패턴 (auth/policy 서비스)
# ----------------------------------------------------------
Write-Host ""
Write-Host "[R1] 동시성 직렬화 패턴 검사..." -ForegroundColor $Cyan

$authFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.dart" |
    Where-Object { $_.Name -match '(auth|policy|pin_service|password)' -and
                   $_.Name -notmatch '\.(g|freezed)\.dart$' }

$concurrencyOk = 0; $concurrencyBad = 0

foreach ($f in $authFiles) {
    $content = Get-Content $f.FullName -Raw
    if ($content -match '_runPolicySerialized|_policyQueue|Completer|Mutex|Lock') {
        $concurrencyOk++
    } elseif ($content -match 'async\s') {
        $concurrencyBad++
        Report "WARN" "R1" "$($f.Name) — 직렬화 패턴 미확인 (async 존재)"
    }
}

if ($concurrencyBad -eq 0 -and $concurrencyOk -gt 0) {
    Report "PASS" "R1" "auth/policy 파일 $concurrencyOk개 직렬화 패턴 확인"
} elseif ($concurrencyOk -eq 0 -and $concurrencyBad -eq 0) {
    Report "PASS" "R1" "대상 파일 없음 (해당 없음)"
}

# ----------------------------------------------------------
# 5. R1-2: DB 트랜잭션 래핑
# ----------------------------------------------------------
Write-Host ""
Write-Host "[R1-2] DB 트랜잭션 래핑 검사..." -ForegroundColor $Cyan

$dbFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.dart" |
    Where-Object { $_.Name -match '(db_store|repository|dao|database)' -and
                   $_.Name -notmatch '\.(g|freezed)\.dart$' }

$txOk = 0; $txWarn = 0

foreach ($f in $dbFiles) {
    $content = Get-Content $f.FullName -Raw
    $hasBatch = $content -match 'batch\b|upsertMany|insertAll|updateAll|deleteAll'
    $hasTx    = $content -match 'transaction\s*\('
    if ($hasBatch -and -not $hasTx) {
        $txWarn++
        Report "WARN" "R1-2" "$($f.Name) — 배치 작업에 transaction() 미사용"
    } elseif ($hasBatch -and $hasTx) {
        $txOk++
    }
}

if ($txWarn -eq 0) {
    Report "PASS" "R1-2" "DB 배치 작업 트랜잭션 래핑 확인 (${txOk}개 파일)"     
}  

# ----------------------------------------------------------
# 6. C: UI-로직 분리
# ----------------------------------------------------------
Write-Host ""
Write-Host "[C] UI-로직 분리 검사..." -ForegroundColor $Cyan

$screenFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.dart" |
    Where-Object { $_.Name -match '(screen|page|view)\.dart$' -and
                   $_.Name -notmatch '\.(g|freezed)\.dart$' }

$mixedFiles = @()

foreach ($f in $screenFiles) {
    $content = Get-Content $f.FullName -Raw
    # DB 직접 호출, HTTP 클라이언트 직접 사용 등 = 로직 혼재
    $hasDbCall   = $content -match '\bdb\.\w+\(|\.select\(|\.insert\(|\.update\(|\.delete\('
    $hasHttp     = $content -match 'http\.get|http\.post|Dio\(\)|\.fetch\('
    $hasSharedPref = $content -match 'SharedPreferences\.'
    if ($hasDbCall -or $hasHttp -or $hasSharedPref) {
        $mixedFiles += $f.Name
    }
}

if ($mixedFiles.Count -eq 0) {
    Report "PASS" "C" "Screen/Page 파일에 직접 DB/HTTP 호출 없음"
} else {
    foreach ($mf in $mixedFiles) {
        Report "WARN" "C" "$mf — UI에 로직 혼재 의심"
    }
}

# ----------------------------------------------------------
# 결과 요약
# ----------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor $Cyan
Write-Host " 검수 결과 요약" -ForegroundColor $Cyan
Write-Host "========================================" -ForegroundColor $Cyan
Write-Host "  PASS: $pass" -ForegroundColor $Green
Write-Host "  WARN: $warn" -ForegroundColor $Yellow
Write-Host "  FAIL: $fail" -ForegroundColor $Red
Write-Host ""

if ($fail -gt 0) {
    Write-Host "  ⛔ ${fail}건 FAIL — 수정 필수" -ForegroundColor $Red
    exit 1
} elseif ($warn -gt 0) {
    Write-Host "  ⚠ ${warn}건 WARN — 검토 권장" -ForegroundColor $Yellow
    exit 0
} else {
    Write-Host "  ✅ 전항목 PASS" -ForegroundColor $Green
    exit 0
}
