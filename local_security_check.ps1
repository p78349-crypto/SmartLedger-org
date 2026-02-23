# 로컬 보안 점검 스크립트 (Gitleaks & Semgrep)
# 실행 조건: Docker Desktop이 실행 중이어야 합니다.

$ReportDir = "security_reports"
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir | Out-Null
}

Write-Host "🔍 로컬 보안 점검을 시작합니다... (결과는 $ReportDir 폴더에 저장됩니다)" -ForegroundColor Cyan

# 1. Gitleaks (비밀키 검사)
Write-Host "`n[1/2] 🔑 Gitleaks 비밀키 검사 실행 중..." -ForegroundColor Yellow
# Docker를 사용하여 Gitleaks 실행
docker run --rm -v "${PWD}:/path" zricethezav/gitleaks:latest detect --source="/path" -v --report-path="/path/$ReportDir/gitleaks_report.json"
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ Gitleaks에서 비밀키 유출 의심 항목이 발견되었습니다! ($ReportDir/gitleaks_report.json 확인)" -ForegroundColor Red
} else {
    Write-Host "✅ Gitleaks 검사 통과 (비밀키 유출 없음)" -ForegroundColor Green
}

# 2. Semgrep (정적 분석)
Write-Host "`n[2/2] 🛡️ Semgrep 정적 분석(SAST) 실행 중..." -ForegroundColor Yellow
# Docker를 사용하여 Semgrep 실행 및 SARIF 리포트 생성
docker run --rm -v "${PWD}:/src" returntocorp/semgrep semgrep --config=p/dart --sarif --output="/src/$ReportDir/semgrep_report.json"
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ Semgrep 분석 중 취약점이 발견되었습니다! ($ReportDir/semgrep_report.json 확인)" -ForegroundColor Red
} else {
    Write-Host "✅ Semgrep 분석 완료 ($ReportDir/semgrep_report.json 생성됨)" -ForegroundColor Green
}

Write-Host "`n🎉 모든 로컬 보안 점검이 완료되었습니다." -ForegroundColor Cyan
Write-Host "💡 팁: 생성된 'semgrep_report.json' 파일은 VS Code의 'SARIF Viewer' 확장 프로그램을 통해 편리하게 확인할 수 있습니다." -ForegroundColor DarkGray
