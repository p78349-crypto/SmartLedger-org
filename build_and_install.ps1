# SmartLedger 빌드 및 설치 스크립트

Write-Host "=== SmartLedger 빌드 시작 ===" -ForegroundColor Cyan

$packageName = "com.example.smartledger"
$logDir = Join-Path $PSScriptRoot "logs"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = Join-Path $logDir "build_install_$timestamp.log"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

Start-Transcript -Path $logPath -Force | Out-Null

try {

# 1. ADB 경로 추가
$env:PATH += ";C:\Users\plain\AppData\Local\Android\Sdk\platform-tools"

# 2. 기기 연결 확인
Write-Host "`n[1/4] 기기 연결 확인..." -ForegroundColor Yellow
$devices = adb devices | Select-String -Pattern "device$"
if ($devices.Count -eq 0) {
    Write-Host "❌ 연결된 기기가 없습니다!" -ForegroundColor Red
    Write-Host "   - USB 디버깅을 확인하세요" -ForegroundColor Gray
    Write-Host "   - 'USB 디버깅 허용' 팝업을 수락하세요" -ForegroundColor Gray
    throw "No connected device"
}
Write-Host "✅ 기기 연결됨: $($devices[0])" -ForegroundColor Green

# 3. 의존성 업데이트
Write-Host "`n[2/4] 의존성 업데이트..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 의존성 업데이트 실패" -ForegroundColor Red
    throw "flutter pub get failed"
}
Write-Host "✅ 의존성 업데이트 완료" -ForegroundColor Green

# 4. APK 빌드
Write-Host "`n[3/4] APK 빌드 중..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 빌드 실패" -ForegroundColor Red
    throw "flutter build apk --release failed"
}
Write-Host "✅ 빌드 완료" -ForegroundColor Green

# 5. 설치
Write-Host "`n[4/4] APK 설치 중..." -ForegroundColor Yellow
flutter install --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ 설치 1차 실패, 상세 원인 확인 중..." -ForegroundColor Yellow

    $installOutput = flutter install --release 2>&1
    $installOutput | ForEach-Object { Write-Host $_ }

    if ($LASTEXITCODE -ne 0 -and ($installOutput -join "`n") -match "INSTALL_FAILED_UPDATE_INCOMPATIBLE") {
        Write-Host "🔄 서명 불일치 감지: 기존 앱 제거 후 재설치 시도" -ForegroundColor Yellow
        adb uninstall $packageName | Out-Null

        flutter install --release
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ 재설치 실패" -ForegroundColor Red
            throw "flutter install --release retry failed"
        }
    }
    elseif ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 설치 실패" -ForegroundColor Red
        throw "flutter install --release failed"
    }
}

Write-Host "`n✅ SmartLedger 설치 완료!" -ForegroundColor Green
Write-Host "APK 위치: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Gray
}
catch {
    Write-Host "`n❌ 빌드/설치 스크립트 실패: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
finally {
    Stop-Transcript | Out-Null
    Write-Host "로그 파일: $logPath" -ForegroundColor Gray
}
