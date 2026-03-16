# 📝 AI Agent 작업 상세 기록 (2026-03-17)

### 📋 AI Agent 작업 상세 기록 (AI_WORK_LOG_RULES 준수)

#### 1. 🔄 작업 절차 (Procedure)
1. 동시성 Lock 메커니즘 점검 결과를 기준으로, 인증 서비스 5종의 직렬화 범위를 재점검.
2. 인스턴스별 큐로 인한 경합 가능성을 해소하기 위해 클래스 전역(static) 직렬화 큐로 통일.
3. verify 계열만 직렬화되던 구조를 set/clear 경로까지 확장해 인증 상태 변경 경합을 차단.
4. 동시성 테스트를 다중 인스턴스 시나리오까지 확장.
5. `flutter test test/services/auth_policy_concurrency_test.dart`와 `flutter analyze`로 최종 검증.

#### 2. 🎯 문제 발견 위치 (Problem Location)
- 파일: `lib/services/user_pin_service.dart`
- 위치: `_policyQueue` 필드 및 `setPin()`, `verifyPinWithPolicy()`, `clearPin()`
- 원인: 서비스 인스턴스별 큐 사용으로, 서로 다른 인스턴스 동시 호출 시 전역 직렬화 보장 부족.

- 파일: `lib/services/user_password_service.dart`
- 위치: `_policyQueue` 필드 및 `setPassword()`, `verifyPasswordWithPolicy()`, `clearPassword()`
- 원인: verify 중심 직렬화, 상태 변경(set/clear) 경합 가능.

- 파일: `lib/services/root_pin_service.dart`
- 위치: PIN/Password 양쪽 정책 메서드와 set/clear 메서드
- 원인: 루트 인증도 동일한 인스턴스 스코프 락 한계 존재.

- 파일: `lib/services/asset_pin_service.dart`, `lib/services/asset_password_service.dart`
- 위치: 자산 인증 정책 및 set/clear 메서드
- 원인: 자산 경로도 동일 패턴으로 동시성 보호 범위 제한.

- 파일: `test/services/auth_policy_concurrency_test.dart`
- 위치: 기존 2개 테스트(User Pin/Password 단일 시나리오)
- 원인: Root/Asset 및 다중 인스턴스 경쟁 시나리오 검증 누락.

#### 3. 🛠️ 수정 파일 및 내용 (Modified Files & Changes)
- `lib/services/user_pin_service.dart`
  - [변경 전] 인스턴스 필드 `Future<void> _policyQueue`
  - [변경 후] 클래스 전역 `static Future<void> _policyQueue`
  - [추가] `setPin()`, `clearPin()`을 `_runPolicySerialized()`로 감싸 직렬화

- `lib/services/user_password_service.dart`
  - [변경 전] verify 경로만 실질 직렬화
  - [변경 후] `setPassword()`, `clearPassword()`까지 동일 큐 직렬화
  - [추가] `_policyQueue`를 static으로 전환

- `lib/services/root_pin_service.dart`
  - [변경 전] PIN/Password verify 중심 직렬화
  - [변경 후] PIN/Password set/clear 전부 직렬화 큐로 통합
  - [추가] `_policyQueue` static 전환

- `lib/services/asset_pin_service.dart`
  - [변경 전] 인스턴스 단위 큐 + verify 중심
  - [변경 후] static 큐 + set/clear 포함 직렬화

- `lib/services/asset_password_service.dart`
  - [변경 전] 인스턴스 단위 큐 + verify 중심
  - [변경 후] static 큐 + set/clear 포함 직렬화

- `test/services/auth_policy_concurrency_test.dart`
  - [변경 전] 2개 테스트
  - [변경 후] 8개 테스트로 확장
  - [추가 항목] User/Root/Asset의 PIN/Password 다중 인스턴스 동시 실패 카운트 검증

#### 4. ✅ 현재 상태 (Current Status)
- 테스트 실행: `flutter test test/services/auth_policy_concurrency_test.dart`
  - 결과: **8개 테스트 모두 통과**
- 정적 분석: `flutter analyze`
  - 결과: **No issues found**
- 결론: 인증 정책 동시성 제어가 단일 인스턴스 범위를 넘어 클래스 범위로 강화되었고,
  상태 변경(set/clear) 경합 가능성까지 완화됨.

#### 5. ⚠️ 잔여 이슈 및 권장 사항 (Recommendations)
- 현재 개선은 서비스 "클래스 단위" 직렬화입니다. 향후 isolate 분리/멀티프로세스 저장소 접근 구조로 확장 시, 저장소 레벨 락 전략(예: DB 트랜잭션) 병행 검토 권장.
- 동일 패턴이 반복되므로 공통 직렬화 유틸(예: `PolicySerializationGuard`) 추출 시 유지보수성이 향상됩니다.
- 회귀 안정성을 위해 CI에 본 테스트 파일을 필수 게이트로 포함 권장.
