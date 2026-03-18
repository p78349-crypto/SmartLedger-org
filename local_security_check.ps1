# 로컬 보안 점검 스크립트 (Gitleaks + Semgrep)
# 실행 조건: Docker Desktop이 실행 중이어야 합니다.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ReportDir = "security_reports"
$GitleaksReport = Join-Path $ReportDir "gitleaks_report.json"
$SemgrepReport = Join-Path $ReportDir "semgrep_report.json"

if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir | Out-Null
}

function Test-CommandAvailable {
    param([Parameter(Mandatory = $true)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

Write-Host "로컬 보안 점검 시작 (결과: $ReportDir)" -ForegroundColor Cyan

if (-not (Test-CommandAvailable -Name "docker")) {
    Write-Host "[오류] docker 명령을 찾을 수 없습니다. Docker Desktop 설치/실행 후 재시도하세요." -ForegroundColor Red
    exit 2
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[오류] Docker daemon에 연결할 수 없습니다. Docker Desktop 실행 상태를 확인하세요." -ForegroundColor Red
    exit 3
}

$hasFindings = $false
$hasExecutionError = $false

# 1) Gitleaks
Write-Host "`n[1/2] Gitleaks secret scan" -ForegroundColor Yellow
docker run --rm -v "${PWD}:/path" zricethezav/gitleaks:latest detect --source="/path" -v --report-path="/path/$GitleaksReport"
$gitleaksExit = $LASTEXITCODE

switch ($gitleaksExit) {
    0 {
        Write-Host "[OK] Gitleaks 통과 (secret 노출 없음)" -ForegroundColor Green
    }
    1 {
        $hasFindings = $true
        Write-Host "[WARN] Gitleaks findings 발견 ($GitleaksReport 확인)" -ForegroundColor Yellow
    }
    default {
        $hasExecutionError = $true
        Write-Host "[ERROR] Gitleaks 실행 실패 (exit=$gitleaksExit)" -ForegroundColor Red
    }
}

# 2) Semgrep
Write-Host "`n[2/2] Semgrep SAST scan" -ForegroundColor Yellow
docker run --rm -v "${PWD}:/src" returntocorp/semgrep semgrep --config=p/dart --sarif --output="/src/$SemgrepReport"
$semgrepExit = $LASTEXITCODE

switch ($semgrepExit) {
    0 {
        Write-Host "[OK] Semgrep 통과" -ForegroundColor Green
    }
    1 {
        $hasFindings = $true
        Write-Host "[WARN] Semgrep findings 발견 ($SemgrepReport 확인)" -ForegroundColor Yellow
    }
    default {
        $hasExecutionError = $true
        Write-Host "[ERROR] Semgrep 실행 실패 (exit=$semgrepExit)" -ForegroundColor Red
    }
}

Write-Host "`n보안 점검 완료" -ForegroundColor Cyan
Write-Host "- Gitleaks report: $GitleaksReport"
Write-Host "- Semgrep report : $SemgrepReport"

if ($hasExecutionError) {
    exit 4
}

if ($hasFindings) {
    exit 1
}

exit 0
