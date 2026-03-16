# 가계부 키백업/복구 이중 사용 가이드 (앱 + 서버)

이 문서는 **가계부 앱(EXTRACTED)** 과 **백엔드 서버(mobile-approval-server)** 두 곳에서 동일한 키백업 구조를 운영할 때의 실행 방법을 기록합니다.

## 1) 대상 구성

- 앱: `WMS_VALUE/EXTRACTED`
  - 로컬 암호 처리: `lib/utils/password_key_backup_service.dart`
  - 서버 호출: `lib/utils/password_key_backup_api_client.dart`
  - 통합 흐름: `lib/utils/password_key_backup_coordinator.dart`
  - 오프라인 안전 래퍼: `lib/utils/online_password_key_backup_facade.dart`
  - 서버 헬스체크: `lib/utils/ledger_health_client.dart`
- 서버: `mobile-approval-server`
  - API: `ledger_api.py`
  - DB 스키마: `ledger_schema.py`
  - 점검 스크립트: `examples/key_backup_e2e.py`

## 2) 공통 전제

- 서버 기본 주소 예: `http://127.0.0.1:8787`
- 앱에서 사용하는 ledger base URL: `<서버>/api/ledger`
- 관리자 키 필요:
  - 환경변수 `MOBILE_APPROVAL_ADMIN_KEY`
  - 또는 API 호출 시 `adminKey`/`X-Admin-Key`

## 3) 서버 측 사용 방법

### 3.1 서버 실행

```powershell
cd .\mobile-approval-server
python .\app.py
```

### 3.2 헬스체크

```powershell
Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:8787/api/ledger/health"
```

정상 응답 예시:

```json
{"status":"ok","time":"2026-02-28T..."}
```

### 3.3 키백업 API 순서

1. `POST /api/ledger/key-backup/bootstrap`
2. `POST /api/ledger/key-backup/recover`
3. 비밀번호 변경 시 `POST /api/ledger/key-backup/rotate`

### 3.4 E2E 자동 점검

```powershell
python .\examples\key_backup_e2e.py --base-url "http://127.0.0.1:8787" --admin-key "<관리자키>"
```

## 4) 앱 측 사용 방법

### 4.1 기본 객체 생성

```dart
final facade = OnlinePasswordKeyBackupFacade(
  ledgerBaseUrl: 'http://127.0.0.1:8787/api/ledger',
  adminKey: '<관리자키>',
);
```

### 4.2 계정 생성 직후 bootstrap

```dart
final result = await facade.bootstrapAccount(
  accountId: accountId,
  password: password,
);
```

- `result.isSuccess == true`: 복구키 안내 화면으로 이동
- `result.isOffline == true`: 네트워크/서버 연결 안내

### 4.3 비밀번호 로그인 복구

```dart
final result = await facade.restoreWithPassword(
  accountId: accountId,
  password: password,
);
```

### 4.4 복구키 기반 복구

```dart
final result = await facade.restoreWithRecoveryKey(
  accountId: accountId,
  recoveryKeyBase64: recoveryKey,
);
```

### 4.5 비밀번호 변경(rotate)

```dart
final result = await facade.rotatePassword(
  accountId: accountId,
  currentPassword: currentPassword,
  newPassword: newPassword,
);
```

## 5) 운영 체크리스트

- [ ] 서버 `GET /api/ledger/health` 응답 확인
- [ ] 앱 시작 시 health 확인 후 오프라인 분기 처리
- [ ] 계정 생성 시 bootstrap 성공 여부 로그 확인
- [ ] 복구키 1회 표시 및 사용자 보관 안내
- [ ] 비밀번호 변경 시 rotate 호출 확인
- [ ] 정기적으로 `examples/key_backup_e2e.py` 실행

## 6) 장애 대응

- `offline`: 서버 미기동/VPN 미연결/방화벽 확인
- `403 Forbidden`: 관리자 키 또는 권한(role) 확인
- `404 key backup not found`: bootstrap 선행 여부 확인
- `400 accountId mismatch`: payload.accountId와 요청 accountId 일치 확인

## 7) 공용 E2E 실행 문서

- 앱+서버 통합 런북: `docs/reports/KEY_BACKUP_E2E_RUNBOOK_2026-02-28.md`

---
최종 갱신: 2026-02-28

추가 체크리스트: `DUAL-APP-PASSWORD-RECOVERY-CHECKLIST.md`
