# SmartLedger DR 체크리스트 (1페이지)

## 목적
- 장애 발생 시 60분 내 복구를 목표로 표준 절차를 수행한다.
- 업로드는 제외하고, 로컬 품질/빌드/백업 복구만 수행한다.

## 0. 장애 선언
- [ ] 장애 등급 지정 (Sev-1/2/3)
- [ ] 신규 작업 중지
- [ ] 담당자 1인 오너 지정

## 1. 현재 상태 캡처
- [ ] 현재 상태 기록

```powershell
git status --short
```

- [ ] 최근 백업 확인

```powershell
Get-ChildItem backups -Directory |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 5 Name,LastWriteTime

Get-ChildItem $env:USERPROFILE\SmartLedger_backups |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 5 Name,Length,LastWriteTime
```

## 2. DR 모의/실행 (품질)
- [ ] 품질 단계 실행

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File \
  .\scripts\orchestrate_lifecycle.ps1 -Stage quality
```

- [ ] analyze 통과 확인 (No issues found)

## 3. 서명/릴리즈 복구 (필요 시)
- [ ] 서명 점검

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File \
  .\scripts\check_android_release_signing.ps1
```

- [ ] 릴리즈 APK/AAB 재생성

```powershell
$env:SLD_STORE_PASSWORD="<STORE_PASS>"
$env:SLD_KEY_PASSWORD="<KEY_PASS>"
flutter build apk --release
flutter build appbundle --release
```

## 4. 해시 검증
- [ ] APK/AAB SHA256 기록

```powershell
Get-FileHash .\build\app\outputs\flutter-apk\app-release.apk \
  -Algorithm SHA256
Get-FileHash .\build\app\outputs\bundle\release\app-release.aab \
  -Algorithm SHA256
```

## 5. 백업 재생성
- [ ] 압축 백업 생성

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File \
  .\backup_project.ps1 -Compress
```

## 6. 완료 기준
- [ ] flutter analyze 통과
- [ ] 릴리즈 빌드 성공
- [ ] 최신 압축 백업 1개 이상 생성
- [ ] 조치 로그 기록 (원인/시간/결과)

## 부록: 빠른 실행
- DR 퀵 스크립트

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File \
  .\scripts\dr_quick_recover.ps1
```
