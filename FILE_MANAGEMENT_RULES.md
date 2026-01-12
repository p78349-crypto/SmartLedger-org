# Flutter 프로젝트 파일 관리 규칙 (제안서)

## 1. 하드 룰 (Hard Rules)
- 라인 길이: 모든 Dart 코드 라인은 80자 이하
- 파일 크기: Dart 파일은 300줄 이하 (자동 생성 파일 제외)
  - 250줄 이상 → 분리 준비
  - 280줄 이상 → 신규 기능 추가 금지, 반드시 먼저 분리

---

## 2. 폴더 책임 (Folder Responsibilities)
- models/ → 순수 데이터 클래스, 직렬화/역직렬화
- services/ → I/O, DB, SharedPreferences, API 호출
- utils/ → 순수 함수, 무상태 헬퍼
- screens/ → UI 화면 단위
- widgets/ → 재사용 가능한 UI 컴포넌트
- navigation/ → 라우팅, 네비게이션 관리

원칙: 한 파일은 한 책임만 가진다.

---

## 3. 파일명 규칙 (Naming Convention)
- snake_case.dart 사용
- 역할 suffix 고정
  - *_service.dart
  - *_controller.dart
  - *_utils.dart
  - *_screen.dart
  - *_widget.dart

---

## 4. 분리 규칙 (Separation Rules)
- 타입/enum/extension/상수 → 별도 파일로 분리
  - *_types.dart
  - *_constants.dart
- 기존 import 호환 필요 시 → 기존 파일에서 export로 연결
  - 목적: 대규모 수정 방지, 사용처 변경 최소화

---

## 5. 예시/데모 코드 관리
- 실제 앱 코드(lib/)에 두지 않는다
- docs/, tools/, lib/examples/ 등 별도 경로에 격리
- 유지 필요 시 → 최소한 UI/헬퍼 분리로 300줄 준수

---

## 6. 테스트 미러링 (Test Mirroring)
- test/는 lib/ 경로를 그대로 따라간다
  - 예: lib/utils/x.dart → test/utils/x_test.dart
- 파일 분리 시 테스트도 함께 분리/추가

---

## 7. 정리/폐기 프로세스
- 미사용 파일은 바로 삭제하지 않는다
  1. 사용처 검색
  2. UNUSED_FILES_DETAILED.md에 기록
  3. 한 릴리즈/주기 후 삭제 (승인 필요)

---

## 8. 규칙 집행 (Enforcement)
- PR/작업 완료 전 반드시 자동 스캔 통과
  - 300줄 초과 파일 목록
  - 80자 초과 라인 목록
- 스크립트/CI로 고정 검사

---

## 9. 규칙 문서화 규칙 (Documentation Rules)
### 9.1 문서 위치/권위(SSOT)
- 파일 관리 규칙의 단일 기준 문서는 이 파일(FILE_MANAGEMENT_RULES.md)로 한다.
- AI가 준수해야 하는 실행 규칙(예: 80자/300줄)은 AI_CODE_RULES.md가 최상위다.
  - 충돌 시 우선순위: 사용자 지시 > AI_CODE_RULES.md > 본 문서

### 9.2 변경 절차
- 규칙 변경은 “제안 → 합의(승인) → 적용” 순서로 진행한다.
- 규칙 변경 시 함께 업데이트할 항목
  - 관련 스캔 스크립트/CI(있다면)
  - 관련 가이드 문서(README, CONTRIBUTING 등) 중 영향 범위

### 9.3 버전/기록
- 규칙 변경 시 하단의 변경 이력(Changelog)을 갱신한다.
- 변경 이력에는 최소 다음을 포함한다
  - 날짜
  - 변경 요약
  - 변경 이유

### 9.4 예외 처리
- 예외는 임시가 원칙이며, 기간/대상/이유를 명시한다.
- 예외 적용 시 해당 파일 상단에 “예외 사유/만료일”을 기록한다.

### 9.5 문서 스타일
- 섹션 번호는 고정(추가 시 9.x 형식으로 확장)한다.
- 규칙은 “명령형 문장”으로 작성한다.
- 예시는 최소화하되, 필요한 경우 예시는 별도 블록으로 분리한다.

---

## 변경 이력 (Changelog)
- 2026-01-12: 초안 작성
