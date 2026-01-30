# SmartLedger 빌드 및 설치 스크립트

Write-Host "=== SmartLedger 빌드 시작 ===" -ForegroundColor Cyan

# 1. ADB 경로 추가
$env:PATH += ";C:\Users\plain\AppData\Local\Android\Sdk\platform-tools"

# 2. 기기 연결 확인
Write-Host "`n[1/4] 기기 연결 확인..." -ForegroundColor Yellow
$devices = adb devices | Select-String -Pattern "device$"
if ($devices.Count -eq 0) {
    Write-Host "❌ 연결된 기기가 없습니다!" -ForegroundColor Red
    Write-Host "   - USB 디버깅을 확인하세요" -ForegroundColor Gray
    Write-Host "   - 'USB 디버깅 허용' 팝업을 수락하세요" -ForegroundColor Gray
    exit 1
}
Write-Host "✅ 기기 연결됨: $($devices[0])" -ForegroundColor Green

# 3. 의존성 업데이트
Write-Host "`n[2/4] 의존성 업데이트..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 의존성 업데이트 실패" -ForegroundColor Red
    exit 1
}
Write-Host "✅ 의존성 업데이트 완료" -ForegroundColor Green

# 4. APK 빌드
Write-Host "`n[3/4] APK 빌드 중..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 빌드 실패" -ForegroundColor Red
    exit 1
}
Write-Host "✅ 빌드 완료" -ForegroundColor Green

# 5. 설치
Write-Host "`n[4/4] APK 설치 중..." -ForegroundColor Yellow
flutter install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 설치 실패" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ SmartLedger 설치 완료!" -ForegroundColor Green
Write-Host "APK 위치: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Gray
