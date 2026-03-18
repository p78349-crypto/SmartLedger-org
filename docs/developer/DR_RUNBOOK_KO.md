# SmartLedger 장애복구(DR) 런북

## 1) 목적
- 장애 발생 시 서비스 복구 시간을 최소화한다.
- 코드/아티팩트/키/문서 복구를 표준 절차로 고정한다.
- 배포 업로드 없이도 로컬 복구 검증이 가능하도록 한다.

## 2) 복구 목표
- RTO(목표 복구 시간): 60분 이내(로컬 기준)
- RPO(목표 데이터 손실 허용): 마지막 성공 백업 시점

## 3) 장애 등급
- Sev-1: 빌드/실행 불가, 데이터 접근 불가, 서명/키 문제로 릴리즈 중단
- Sev-2: 일부 기능 실패, 빌드는 가능
- Sev-3: 성능/경고 수준 이슈

## 4) 즉시 대응(공통)
1. 변경 중지: 신규 작업/업로드 중단
2. 현재 상태 캡처
   - git status --short
   - 최근 백업 목록 확인
3. 가장 최근 정상 백업 지점 선택
4. 복구 작업 시작

## 5) 표준 DR 실행 절차
### A. 복구 자산 확인
1. 로컬 백업 폴더
   - backups/
2. 압축 백업 폴더
   - %USERPROFILE%\SmartLedger_backups
3. 릴리즈 키/리포트
   - backups/keystore_reset_*/

### B. 오케스트레이션 건전성 점검(무중단)
1. Dry-run

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\orchestrate_lifecycle.ps1 -Stage full -DryRun
```

2. 품질 단계만 빠르게 실행

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\orchestrate_lifecycle.ps1 -Stage quality
```

### C. 릴리즈 서명 장애 복구
1. 서명 상태 점검

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_android_release_signing.ps1
```

2. 키 재초기화(필요 시)

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup_android_release_signing.ps1 -KeystoreFileName smartledger-release-20260303.jks -GenerateKeystore -StorePassword <STORE_PASS> -KeyPassword <KEY_PASS> -KeyAlias smartledger -ForceOverwrite
```

3. 환경변수 주입 후 재검증

```powershell
$env:SLD_STORE_PASSWORD="<STORE_PASS>"
$env:SLD_KEY_PASSWORD="<KEY_PASS>"
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_android_release_signing.ps1
```

### D. 빌드/아티팩트 복구
1. APK 복구 검증

```powershell
flutter build apk --release
```

2. AAB 복구 검증

```powershell
flutter build appbundle --release
```

3. 해시 검증

```powershell
Get-FileHash .\build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256
Get-FileHash .\build\app\outputs\bundle\release\app-release.aab -Algorithm SHA256
```

### E. 프로젝트 백업 재생성

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\backup_project.ps1 -Compress
```

## 6) Git 원복 시나리오(필요 시)
주의: 로컬 미커밋 변경이 사라질 수 있으므로 백업 후 실행

```powershell
git fetch --all --prune
git checkout chore/style-lints-2026-01-12
git reset --hard origin/chore/style-lints-2026-01-12
git clean -fd
```

## 7) DR 완료 기준
- flutter analyze: No issues found
- release APK/AAB 빌드 성공
- 서명 점검 스크립트 통과
- 최신 압축 백업 1개 이상 생성
- 복구 로그(시간/원인/조치/결과) 기록

## 8) DR 훈련(권장 주기)
- 주 1회: Stage quality + 백업 생성
- 월 1회: 키 점검 + AAB 재생성 + 해시 기록
- 릴리즈 전: Stage full 완료

## 9) 이번 세션 기준 확인된 복구 자산
- 최근 로컬 DR 폴더: backups/keystore_reset_20260317_200719
- 최근 압축 백업: %USERPROFILE%\SmartLedger_backups\SmartLedger_backup_2026-03-17_195554.zip
- 오케스트레이션 Dry-run: 정상 완료
