# 📝 AI Agent 작업 상세 기록 (2026-03-01)

### 📋 AI Agent 작업 상세 기록 (AI_WORK_LOG_RULES 준수)

#### 1. 🔄 작업 절차 (Procedure)
- `DUAL-APP-PASSWORD-RECOVERY-CHECKLIST.md` 기준으로 Self-Hosted 미구현 항목(인증서/암호화저장/토글)을 재확인.
- `ServerConfigService`, 서버 설정 UI, 키백업 HTTP 클라이언트 연동 경로를 점검하여 반영 지점을 확정.
- Self-hosted Phase 3 기능(자체서명 인증서 허용, 서버 유형 토글, 민감정보 secure storage 저장)을 구현.
- `flutter analyze`를 2회 실행하여 경고 포함 정적검증 완료(최종 No issues).
- 작업 상세기록 요청에 따라 금일 변경 핵심과 검증 결과를 문서화하고 로컬 백업 실행.

#### 2. 🎯 문제 발견 위치 (Problem Location)
- **파일**: `lib/screens/server_sync_settings_screen.dart`
- **위치**: `_showServerConfigDialog()` 내부
- **원인**: Self-hosted 고급 설정(공용/자체호스팅 선택, self-signed cert 허용 옵션) UI/상태 저장 로직 부재.

- **파일**: `lib/services/server_config_service.dart`
- **위치**: 서버 설정 저장/조회 로직
- **원인**: Admin Key가 SharedPreferences(평문 저장) 기반이어서 민감정보 보호 강화 필요.

- **파일**: `lib/utils/ledger_health_client.dart`, `lib/utils/password_key_backup_api_client.dart`
- **위치**: HTTP 호출 클라이언트 생성/사용 부분
- **원인**: 자체서명 인증서 허용 설정을 반영하는 네트워크 클라이언트 경로 부재.

#### 3. 🛠️ 수정 파일 및 내용 (Modified Files & Changes)
- **`lib/services/server_config_service.dart`**
  - [변경 전] Admin Key를 SharedPreferences에서 직접 읽기/쓰기.
  - [변경 후] Admin Key를 `FlutterSecureStorage`에 저장, 레거시 SharedPreferences 값 자동 마이그레이션 추가.
  - [추가] `allowSelfSignedCert`, `serverType` 저장/조회 메서드 추가.
  - [추가] `createHttpClient()`에서 self-signed 허용 시 `HttpClient.badCertificateCallback` 적용.

- **`lib/screens/server_sync_settings_screen.dart`**
  - [추가] 서버 유형 `SegmentedButton`(공용 서버 / 자체 호스팅).
  - [추가] 자체 호스팅 모드에서 `자체 서명 인증서 허용` 스위치 + 보안 경고 UI.
  - [개선] 주소 입력 힌트/도움말을 서버 유형에 따라 동적 변경.
  - [저장] 서버 유형/인증서 허용 설정/정책 모드를 함께 저장.

- **`lib/utils/ledger_health_client.dart`**
  - [변경] 기본 HTTP client 경로에서 `ServerConfigService().createHttpClient()`를 사용하도록 확장.

- **`lib/utils/password_key_backup_api_client.dart`**
  - [변경] 키백업 API 호출 시 self-signed 허용 설정이 반영된 HTTP client 사용.

- **`lib/utils/pref_keys.dart`**
  - [추가] `allowSelfSignedCert`, `serverType` 키 상수 추가.

- **`DUAL-APP-PASSWORD-RECOVERY-CHECKLIST.md`**
  - [변경] 2.4 Self-Hosted 서버 지원 6개 항목을 구현 완료(`- [x]`)로 반영.

#### 4. ✅ 현재 상태 (Current Status)
- `flutter analyze` 최종 결과: **No issues found**.
- Self-hosted Phase 3 범위(인증서 허용/암호화 저장/로컬-원격 토글) 구현 완료.
- 체크리스트 2.4(가계부앱 Self-Hosted 지원) 6/6 항목 완료 반영.
- 요청사항인 작업상세기록 문서화 완료.
- 로컬 백업 실행 완료: `C:\Users\plain\SmartLedger_backups\SmartLedger_backup_2026-03-01_002651`
- 백업 크기: `8.24 MB`, 스크립트 결과: **Backup script completed successfully**.
- 압축 백업 추가 완료: `C:\Users\plain\SmartLedger_backups\SmartLedger_backup_2026-03-01_002849.zip`
- 압축 결과: 원본 `8.24 MB` → 압축 `2.63 MB` (압축률 `31.9%`).

#### 5. ⚠️ 잔여 이슈 및 권장 사항 (Recommendations)
- Self-signed cert 허용은 보안상 예외 경로이므로, 운영 가이드에서 “신뢰된 내부망 전용”으로 명시 유지 권장.
- 실제 기기에서 공용 서버↔자체호스팅 전환 후 `연결 테스트` 및 `recover/rotate` 연동 스모크 테스트 1회 권장.
- 서버 주소 자체 암호화 저장까지 요구된다면(현재는 Admin Key만 secure storage), 주소도 secure storage로 이관할지 정책 확정 권장.
