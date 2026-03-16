# SmartLedger 앱 기능 요약 (운영 기준)

최종 갱신: 2026-03-03

## 1) 앱 한 줄 설명
SmartLedger는 가정/개인 자산·지출·식재료·쇼핑 흐름을 하나로 묶어,
입력 최소화와 실사용 반복성(장보기→지출기록→통계)을 중심으로 동작하는
다중 계정 금융·생활 통합 앱입니다.

## 2) 핵심 기능 영역

### A. 거래/가계부
- 지출·수입·환불 입력/수정/조회
- 거래 상세 이동 및 분류(카테고리/메모/결제수단)
- 빠른 입력/상세 입력 공존

### B. 통계/분석
- 월별·기간별·카테고리 통계
- 지출 패턴/카드 혜택/포인트 기반 분석
- 월별 집계 캐시 기반 성능 최적화

### C. 자산 관리
- 자산 등록/목록/분석/배분
- 자산 내보내기 및 보안 접근 제어
- ROOT/USER/ASSET 분리 보안 정책 반영

### D. 식료품/쇼핑/WMS 연동
- 식재료 재고·유통기한 관리
- 요리 준비/사용량 기록
- 장바구니와 지출 입력 연계(실사용 흐름)

### E. 백업/복원/운영
- 로컬 백업/복원
- 증분 백업 및 릴리즈 아티팩트 백업
- 운영 점검 스크립트 기반 지속 검증

### F. 설정/아이콘/페이지 구성
- 메인 아이콘 그리드 기반 기능 진입
- 페이지별 아이콘 관리(정책 문서 단일 기준)
- 설정/보안/라우팅 진입점 통합 관리

## 3) 보안·인증 핵심
- 인증 저장소 분리: ROOT / USER / ASSET
- PIN/비밀번호 정책 잠금(경고/쿨다운/장기잠금)
- 동시성 제어 적용:
  `verifyPinWithPolicy()` / `verifyPasswordWithPolicy()` 경로를
  서비스 내부 직렬화 큐로 보호하여 경쟁 조건 완화

## 4) 현재 운영 상태 (2026-03-03 기준)
- 정적 분석: `flutter analyze` 통과
- 전체 테스트: `flutter test` 통과
- 동시성 스모크 테스트:
  `test/services/auth_policy_concurrency_test.dart` 통과
- 오케스트레이션:
  `scripts/orchestrate_lifecycle.ps1`로 quality→release→ops 순차 실행 가능

## 5) 운영 시 주의사항
- release 단계는 Android 서명 환경변수 필요
  - `SLD_STORE_PASSWORD`
  - `SLD_KEY_PASSWORD`
- 환경변수 미설정 시 release 단계는 fail-fast로 즉시 중단됨

## 6) 1000 TPS 환경 데이터 무결성 기준
- DB 무결성 기본: `PRAGMA foreign_keys = ON`
- 동시성/내구성 프로파일:
  - `PRAGMA journal_mode = WAL`
  - `PRAGMA synchronous = FULL`
  - `PRAGMA busy_timeout = 5000`
  - `PRAGMA wal_autocheckpoint = 1000`
- 인증 Lock 무결성:
  - `verifyPinWithPolicy()` / `verifyPasswordWithPolicy()`는
    서비스 내부 직렬화 큐로 동시 호출 경쟁 조건을 완화
- 운영 검증 최소 세트:
  - `flutter analyze`
  - `flutter test`
  - `flutter test test/services/auth_policy_concurrency_test.dart`

## 7) 참고 문서
- 개발 핵심 연결 맵:
  `docs/developer/CORE_FEATURE_MAP_DEV_KO.md`
- 순차 오케스트레이션 런북:
  `docs/developer/INFRA_ORCHESTRATION_RUNBOOK_KO.md`
- 식단→지출 흐름 상세:
  `docs/MEAL_TO_EXPENSE_FLOW.md`

## 8) 제안사항 구현 장점
- 이상 징후를 조기에 탐지하여 사고 확산 전 대응 가능(사전 차단 강화)
- 기존 감사 로그/운영 대시보드 재사용으로 구현 비용 및 변경 리스크 최소화
- 임계치 기반 경고와 자동화 룰 연계 시 운영자 수동 점검 부담 감소
- 탐지 이력 누적으로 보안 감사/사후 분석 근거 확보
- 룰 기반 MVP로 빠르게 도입 후 점수화/패턴 분석으로 단계적 고도화 가능

## 9) 제안사항 최소 구현 범위(MVP 체크리스트)
- [x] 거래 이벤트 표준 로그 확정
  - 필수 필드: timestamp, userLevel, action, amount, accountId, success, metadata
- [x] 이상 징후 룰 1차 세트 적용
  - 단일 거래 고액 임계치 초과
  - 단시간 반복 실패(인증/권한/작업 실패)
  - 비정상 시간대 민감 작업 실행
- [x] 탐지 결과 기록 경로 통합
  - 감사 로그에 eventType=securityViolation 또는 policyEnforcement로 저장
  - 탐지 원인(ruleId, threshold, observedValue) 메타데이터 저장
- [x] 운영 대시보드 경고 표시 연결
  - 최근 N건 이상 탐지 시 warning/critical 표시
  - 최근 탐지 목록(시간/원인/심각도) 3건 표시
- [x] 자동화 대응 최소 세트 연결
  - 고위험 탐지 시 알림 생성
  - 동일 주체 반복 위반 시 계정 잠금 룰 트리거
- [x] 운영 검증 시나리오 3종 확보
  - 정상 거래(탐지 없음)
  - 경계 거래(경고만 발생)
  - 명백한 이상 거래(critical + 자동화 대응)

## 10) MVP 체크리스트 코드 매핑(착수용)
- 거래 이벤트 표준 로그 확정
  - 로그 스키마/저장: `lib/services/audit_log_service.dart`
  - 거래 입력 지점 연계: `lib/screens/transaction_detail_screen.dart`, `lib/services/transaction_service.dart`(존재 시)
- 이상 징후 룰 1차 세트 적용
  - 룰 정의/실행 엔진: `lib/services/workflow_automation_engine.dart`
  - 보조 임계치 계산/판정 유틸: `lib/services/financial_analytics_service.dart` 및 연관 utils
- 탐지 결과 기록 경로 통합
  - eventType/securityViolation 기록: `lib/services/audit_log_service.dart`
  - ruleId/threshold/observedValue 메타데이터 확장: 동일 파일 `metadata` payload
- 운영 대시보드 경고 표시 연결
  - KPI/경고 카드: `lib/widgets/operational_kpi_dashboard.dart`
  - 상태등 기준 연동: 동일 파일 `RealTimeStatusIndicator._updateStatus()`
- 자동화 대응 최소 세트 연결
  - alert/lockAccount 액션: `lib/services/workflow_automation_engine.dart`
  - 계정 잠금 정책 연계: `lib/services/user_pin_service.dart`, `lib/services/user_password_service.dart`, `lib/services/root_pin_service.dart`
- 운영 검증 시나리오 3종 확보
  - 단위/서비스 테스트 추가 위치: `test/services/`
  - 회귀 실행 기준: `flutter analyze`, `flutter test`, `flutter test test/services/auth_policy_concurrency_test.dart`

## 11) 운영 검증 시나리오(실행 예시)
- 시나리오 A: 정상 거래(탐지 없음)
  - 입력: 일반 금액 거래 1건, 최근 실패 로그 0~2건
  - 기대: `anomaly_signal_*` 미생성, 상태등 healthy 유지
- 시나리오 B: 경계 거래(경고만 발생)
  - 입력: 고액 거래 1건(임계치 초과), `violation_count` 합계 1~2
  - 기대: `policyEnforcement` 로그 생성, 대시보드 warning 표시, 잠금 미트리거
- 시나리오 C: 명백한 이상 거래(critical + 자동화 대응)
  - 입력: 반복 실패 3회 이상 이후 거래 입력(`violation_count >= 3`)
  - 기대: `securityViolation`/`policyEnforcement` 로그 생성, `automation_high_risk_alert` 기록,
    인증 잠금 키(`*_locked_until_ms`) 설정, 대시보드 critical 표시
