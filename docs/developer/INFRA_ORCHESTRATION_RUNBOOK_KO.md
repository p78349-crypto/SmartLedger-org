# 인프라 오케스트레이션 런북 (순차진행)

SmartLedger의 로컬/배포/운영 단계를 한 흐름으로 실행하기 위한 런북입니다.

## 목적
- 품질 게이트 → 릴리즈 준비 → 배포 후 운영 점검을 순차 실행
- 기존 스크립트를 재사용하여 실패 지점을 빠르게 식별

## 진입점
- 오케스트레이터: `scripts/orchestrate_lifecycle.ps1`

## 단계 구성
1. `quality`
   - `flutter pub get`
   - `scripts/ci_local.ps1` (format/analyze/test)
2. `release`
   - `scripts/check_android_release_signing.ps1`
   - `scripts/build_release_obfuscate.ps1 -Platform android`
   - `scripts/backup_artifacts.ps1`
3. `ops`
   - `flutter analyze`
   - `flutter test test/services/auth_policy_concurrency_test.dart`
   - `scripts/run_local_backup.ps1`
   - (옵션) `local_security_check.ps1`

> 모든 단계는 **fail-fast**로 동작합니다. 한 단계라도 실패하면 즉시 중단됩니다.

## 실행 예시

### 1) 전체 순차 실행 (권장)
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\orchestrate_lifecycle.ps1 -Stage full
```

### 2) 단계별 실행
```powershell
# 품질만
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\orchestrate_lifecycle.ps1 -Stage quality

# 릴리즈만
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\orchestrate_lifecycle.ps1 -Stage release

# 운영 점검만
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\orchestrate_lifecycle.ps1 -Stage ops
```

### 3) 운영 보안 스캔 포함
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\orchestrate_lifecycle.ps1 -Stage ops -EnableSecurityScan
```

## 자주 쓰는 옵션
- `-SkipSigningCheck` : 서명 확인 단계 생략
- `-SkipBuild` : 릴리즈 빌드 생략
- `-SkipArtifactBackup` : 아티팩트 백업 생략
- `-SkipProjectBackup` : 운영 단계 프로젝트 백업 생략
- `-DryRun` : 실제 실행 없이 단계 출력만 확인

## 운영 기준 (배포 후)
- 최소 1일 1회 `-Stage ops` 실행
- 장애/이상 징후 시 `-Stage quality` 재실행 후 원인 분리
- 릴리즈 전에는 `-Stage full` 완료를 배포 게이트로 사용

## 실패 대응 가이드
- `quality` 실패: 코드 수정 후 `-Stage quality` 재실행
- `release` 실패:
  - 서명 실패 시 `scripts/setup_android_release_signing.ps1` 재설정
  - 빌드 실패 시 `flutter analyze`, `flutter test` 재확인
- `ops` 실패: 직전 백업 복구 가능 여부 확인 후 조치
