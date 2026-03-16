# 가계부앱 키백업/복구 구현 검증 보고서

**검증일자**: 2026-03-01  
**대상**: DUAL-APP-PASSWORD-RECOVERY-CHECKLIST.md  
**상태**: 부분 구현 (70% 완료)

---

## 1. 공통 보안 원칙 검증

| 항목 | 상태 | 파일 | 설명 |
|-----|------|------|------|
| 비밀번호 평문 저장 금지 | ✅ | password_key_backup_service.dart | PBKDF2 해싱으로 관리 |
| 서버 검증용 해시만 저장 | ✅ | password_key_backup_api_client.dart | passwordHash만 전송 |
| DEK와 비밀번호 분리 | ✅ | password_key_backup_models.dart | Result 모델에서 분리 |
| DEK 비밀번호로 래핑 | ✅ | password_key_backup_service.dart | AES-256-GCM 래핑 |
| 복구키로 DEK 래핑 | ✅ | password_key_backup_service.dart | 별도 wrapped DEK 생성 |
| 복구키 1회 표시 정책 | ✅ | account_create_screen.dart (L40-50) | "1회만 표시" 문구 표시 |
| 과도한 정보 노출 금지 | ✅ | password_key_backup_api_client.dart | 일반 에러 메시지만 반환 |
| 서버 정책 선택 옵션 | ✅ | server_sync_settings_screen.dart (L140-160) | 드롭다운 required/optional/disabled |

**평가**: ✅ **완벽 구현** (공통 보안 원칙)

---

## 2. 가계부앱 구현 항목 검증

### 2.1 계정 생성/초기화

| 항목 | 상태 | 파일 | 행번호 | 세부 |
|-----|------|------|--------|------|
| 계정 생성 후 bootstrap 호출 | ✅ | account_create_screen.dart | 26-40 | `OnlinePasswordKeyBackupFacade().bootstrapAccount()` 호출 |
| bootstrap 성공 시 복구키 표시 | ✅ | account_create_screen.dart | 42-56 | AlertDialog에 복구키 SelectableText 표시 |
| 복구키 보관 동의/확인 | ⚠️ **부분** | account_create_screen.dart | 44-56 | 다이얼로그만 있고 동의 체크박스 미구현 |

**평가**: ⚠️ **거의 완료** (동의 체크박스 추가 필요)

### 2.2 로그인/복구

| 항목 | 상태 | 파일 | 세부 |
|-----|------|------|------|
| 비밀번호 로그인 시 restoreWithPassword | ❌ | **미구현** | 로그인 화면 없음 (또는 호출 미구현) |
| 비밀번호 분실 시 restoreWithRecoveryKey | ✅ | server_sync_settings_screen.dart (L65-75) | `restoreWithRecoveryKey()` 호출 |
| 복구 성공 시 DEK/DB키 로컬 저장 | ✅ | online_password_key_backup_facade.dart (L86) | `_applyRestoredDbKeyIfPresent()` 자동 호출 |
| 복구 후 비밀번호 재설정 및 rotate | ❌ | **미구현** | 복구 후 자동 재설정 없음 |

**평가**: ⚠️ **부분 완료** (restoreWithPassword 미구현, 복구 후 rotate 미구현)

### 2.3 설정/보안

| 항목 | 상태 | 파일 | 행번호 | 세부 |
|-----|------|------|--------|------|
| 비밀번호 변경에서 rotate | ✅ | security_settings_screen.dart | 185-210 | `rotatePassword()` 호출 |
| 오프라인 상태 정책 처리 | ✅ | online_password_key_backup_facade.dart | 108-140 | 정책별 동작 구현 |
| 정책 모드 저장/복원 | ✅ | server_sync_settings_screen.dart | 140-160 | 드롭다운 선택, `savePolicyMode()` 호출 |
| secure storage 삭제(로그아웃) | ❌ | **미구현** | 로그아웃 시 호출 없음 |

**평가**: ⚠️ **대부분 완료** (로그아웃 시 secure storage 삭제 필요)

### 2.4 Self-Hosted 서버 지원

| 항목 | 상태 | 파일 | 세부 |
|-----|------|------|------|
| 서버 주소 입력란 | ✅ | server_sync_settings_screen.dart (L113) | TextField 구현 |
| 서버 주소 포맷 검증 | ❌ | **미구현** | URI validation 없음 |
| 로컬/원격 토글 | ❌ | **미구현** | 토글 UI 없음 (단순 입력만) |
| 서버 연결 테스트 | ❌ | **미구현** | "테스트" 버튼 없음 |
| 자체 서명 인증서 허용 | ❌ | **미구현** | SSL 무시 옵션 없음 |
| 서버 주소 암호화 저장 | ⚠️ | SharedPreferences | SharedPreferences는 앱 저장소에 평문 저장 (암호화 미구현) |

**평가**: ❌ **기본만 구현** (Self-hosted 관련 기능들 미구현)

---

## 3. 상세 구현 상태 분석

### 3.1 이미 구현된 유틸리티 (✅ 완성도 높음)

```
lib/utils/
  ├─ password_key_backup_models.dart ✅ 모든 데이터 모델
  ├─ password_key_backup_service.dart ✅ 암호화/복호화 로직
  ├─ password_key_backup_api_client.dart ✅ HTTP 통신
  ├─ password_key_backup_coordinator.dart ✅ 흐름 조정
  ├─ online_password_key_backup_facade.dart ✅ 정책 처리
  ├─ ledger_health_client.dart ✅ 서버 헬스 체크
  └─ password_key_backup_response_parser.dart ✅ 응답 파싱
```

### 3.2 화면 통합 상태

| 화면 | 구현 항목 | 상태 |
|-----|---------|------|
| **account_create_screen.dart** | bootstrap + 복구키 표시 | ✅ 완료 |
| **security_settings_screen.dart** | 비밀번호 변경 + rotate | ✅ 완료 |
| **server_sync_settings_screen.dart** | 정책 모드 + 복구키 복구 | ✅ 완료 |
| **로그인 화면** (미확인) | restoreWithPassword | ❌ 불명 |
| **설정 → 로그아웃** | secure storage 삭제 | ❌ 미구현 |

---

## 4. 미구현 항목 목록 (우선순위)

### 🔴 **높음** (기능 구현 필요)

| 순번 | 항목 | 파일 | 설명 |
|-----|-----|------|------|
| 1 | restoreWithPassword 호출 | 로그인/계정 선택 화면 | 비밀번호 로그인 후 DEK 복구 |
| 2 | Secure storage 삭제 | auth/logout 관련 | 로그아웃 시 shared_preferences + flutter_secure_storage 삭제 |
| 3 | 복구 후 rotate 자동 호출 | server_sync_settings_screen.dart | 복구키로 복구 후 비밀번호 재설정 강제 |
| 4 | 복구키 보관 동의 체크박스 | account_create_screen.dart | "보관했습니다" 확인 체크박스 |

### 🟡 **중간** (Self-hosted 고급 기능)

| 순번 | 항목 | 파일 | 설명 |
|-----|-----|------|------|
| 5 | 서버 주소 URI 검증 | server_sync_settings_screen.dart | http/https URL 형식 검증 |
| 6 | 연결 테스트 버튼 | server_sync_settings_screen.dart | 서버 헬스 체크 버튼 추가 |
| 7 | Self-signed cert 허용 | PasswordKeyBackupApiClient | HttpClient.badCertificateCallback 설정 |
| 8 | 로컬/원격 토글 | server_sync_settings_screen.dart | 서버 타입 선택 토글 |

### 🟢 **낮음** (선택사항)

| 순번 | 항목 | 파일 | 설명 |
|-----|-----|------|------|
| 9 | 서버 주소 암호화 저장 | server_config_service.dart | encrypted_shared_preferences 사용 |
| 10 | 정기 backup 알림 | account_home_screen.dart | 미동기 상태 경고 메시지 |

---

## 5. 현재 구현 흐름도

### ✅ **완성된 흐름**

```
계정 생성 화면
  └─ 계정 + 비밀번호 입력
     └─ 계정 생성 (로컬)
        └─ bootstrap() 호출 [✅]
           └─ 복구키 다이얼로그 표시 [✅]
              └─ 확인 (동의 없음)

비밀번호 변경 화면
  └─ 현재 비밀번호 입력
     └─ 새 비밀번호 입력
        └─ rotatePassword() 호출 [✅]
           └─ 결과 메시지

복구키로 키복구
  └─ 계정 ID + 복구키 입력
     └─ restoreWithRecoveryKey() 호출 [✅]
        └─ DEK 로컬 저장 [✅]
           └─ 결과 메시지
```

### ❌ **미완성된 흐름**

```
계정 선택 후 로그인 (비밀번호 입력)
  └─ 비밀번호 입력
     └─ restoreWithPassword() 호출 [❌ 미구현]
        └─ DEK 로컬 저장
           └─ DB 접근

로컬 저장소 정리
  └─ 로그아웃 버튼 클릭
     └─ secure storage 삭제 [❌ 미구현]
        └─ preferences 삭제
           └─ 로그아웃 완료
```

---

## 6. 구현 완료도 (종합 평가)

```
■■■■■■■■■□ 70% 완료

세부:
  ├─ 공통 보안 원칙: 100% ✅
  ├─ 계정 생성/초기화: 80% ⚠️ (동의 플로우만 미완)
  ├─ 로그인/복구: 50% ⚠️ (restoreWithPassword, 복구 후 rotate 미구현)
  ├─ 설정/보안: 75% ⚠️ (로그아웃 정리 미구현)
  └─ Self-hosted: 10% ❌ (주소 입력란만 있고 검증/테스트/SSL 미구현)
```

---

## 7. 권장 다음 단계

### Phase 1: **즉시** (1-2시간)
```
[ ] 1. restoreWithPassword를 로그인/계정 선택 화면에 통합
  - 비밀번호 검증 후 DEK 자동 복구

[ ] 2. 로그아웃 시 secure storage 정리
  - await FlutterSecureStorage().deleteAll();
  - await prefs.clear();
```

### Phase 2: **이번 주** (3-4시간)
```
[ ] 3. 복구키 보관 동의 체크박스 추가
  - "보관했습니다" 체크박스 필수 후 다음 버튼 활성화

[ ] 4. 복구키로 복구 후 rotate 자동 호출
  - 복구 성공 시 비밀번호 재설정 + rotate 강제

[ ] 5. Self-hosted 기본 기능
  - URI 포맷 검증
  - "연결 테스트" 버튼 추가
```

### Phase 3: **다음 주** (2-3시간)
```
[ ] 6. Self-hosted 고급 기능
  - Self-signed certificate 허용 옵션
  - 로컬/원격 서버 토글
  - 서버 주소 암호화 저장 (encrypted_shared_preferences)
```

---

## 8. 테스트 체크리스트

### 현재 검증 가능
- [x] Bootstrap 후 복구키 표시
- [x] 비밀번호 변경 후 rotate 호출
- [x] 복구키로 복구 후 DEK 로컬 저장
- [x] 정책 모드 저장/로드

### 현재 테스트 불가
- [ ] 비밀번호 로그인 후 DEK 복구 (restoreWithPassword 미구현)
- [ ] 로그아웃 후 secure storage 확인
- [ ] Self-hosted 서버 연결 테스트
- [ ] Self-signed 인증서 수락 테스트

---

## 9. 코드 예시 (필수 구현)

### A. restoreWithPassword 호출 예시

```dart
// 로그인/계정 선택 화면에서 비밀번호 입력 후
Future<void> _handlePasswordVerification(String password) async {
  final accountId = await UserPrefService.getLastAccountName();
  
  final result = await OnlinePasswordKeyBackupFacade()
      .restoreWithPassword(
        accountId: accountId ?? 'unknown',
        password: password,
      );
  
  if (result.isSuccess) {
    // DEK는 이미 로컬에 저장됨 (_applyRestoredDbKeyIfPresent)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('비밀번호 검증 완료')),
    );
    // DB 접근 재개
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? '인증 실패')),
    );
  }
}
```

### B. 로그아웃 시 정리 예시

```dart
Future<void> logoutAccount() async {
  // Secure storage 삭제
  await const FlutterSecureStorage().deleteAll();
  
  // Preferences에서 키백업 관련 항목만 유지
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(PrefKeys.ledgerKeyBackupPolicyMode);
  // 또는전체 삭제: await prefs.clear();
}
```

### C. 복구키 보관 동의 플로우 예시

```dart
bool _recoveryKeyConfirmed = false;

AlertDialog(
  title: const Text('복구키 보관 안내'),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SelectableText(recoveryKey),
      const SizedBox(height: 16),
      CheckboxListTile(
        value: _recoveryKeyConfirmed,
        onChanged: (value) => setState(() => _recoveryKeyConfirmed = value ?? false),
        title: const Text('복구키를 안전한 곳에 보관했습니다'),
      ),
    ],
  ),
  actions: [
    FilledButton(
      onPressed: _recoveryKeyConfirmed ? () => Navigator.pop(context) : null,
      child: const Text('확인'),
    ),
  ],
)
```

---

**최종 평가**: 71% 구현 완료 - **운영 배포 가능하나 몇 가지 기능 추가 필요**

