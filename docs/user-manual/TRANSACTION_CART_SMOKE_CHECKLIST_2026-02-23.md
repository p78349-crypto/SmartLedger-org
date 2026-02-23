# 거래/장바구니 연동 스모크 체크리스트 (2026-02-23)

## 목적
- 수입/지출 입력과 장바구니 연동이 실제 사용자 흐름에서 정상 동작하는지 빠르게 확인한다.
- 계산 로직(금액, 분류, 합계)과 화면/기능 연결(입력→저장→조회)을 동시에 검증한다.

## 사전 조건
- 브랜치: `chore/style-lints-2026-01-12`
- 최신 코드 동기화 및 실행 가능 상태
- `flutter analyze` 통과 상태
- 테스트용 계정 1개 준비

---

## 시나리오 A: 지출 기본 입력
1. 거래 입력 화면에서 지출 1건 입력
   - 예: `커피`, `5000`, 카테고리 `식비`
2. 저장 직후 거래 목록에서 해당 항목 확인
3. 통계/합계에서 지출 합계 증가 확인

### 기대 결과
- 저장 성공 토스트/피드백 표시
- 거래 목록에 즉시 반영
- 지출 합계가 정확히 `+5000` 반영

---

## 시나리오 B: 수입 입력 + 합계 반영
1. 수입 1건 입력
   - 예: `급여`, `1000000`
2. 저장 후 목록 및 요약 카드 확인
3. 순계산(수입-지출)에 반영 여부 확인

### 기대 결과
- 수입 합계 `+1000000`
- 순계산 값이 수입 증가만큼 반영

---

## 시나리오 C: 장바구니 추가 → 지출 전환
1. 장바구니에서 품목 2개 추가
   - 예: `우유`, `계란`
2. 장바구니 품목을 지출 입력으로 전송/연결
3. 거래 입력 화면에서 품목/금액 파싱 상태 확인
4. 저장 후 거래 목록 반영 확인

### 기대 결과
- 품목명이 누락 없이 전달
- 금액/수량 파싱 오류 없음
- 저장 시 거래 내역과 합계가 정확히 증가

---

## 시나리오 D: Enter 네비게이션/입력 연결
1. 입력 필드에서 Enter로 다음 필드 이동
2. 최종 Enter 또는 저장 액션으로 저장 수행
3. 저장 후 입력창 초기화/포커스 복귀 확인

### 기대 결과
- 포커스 이동이 끊기지 않음
- 저장 액션이 중복 실행되지 않음
- 입력 상태가 꼬이지 않음

---

## 시나리오 E: 경계값 계산 점검
1. 소수/큰 금액 입력
   - 예: `0`, `1`, `999999999`
2. 환불/저축 분류가 있는 케이스 1건씩 입력
3. 통계 화면에서 집계 기준 확인

### 기대 결과
- 0/소액/대액 저장 및 계산 오류 없음
- 환불/저축 분류가 집계 규칙대로 반영

---

## 자동 검증 명령 (권장)
```powershell
flutter test test/utils/transaction_aggregation_utils_test.dart \
  test/utils/stats_calculator_test.dart \
  test/utils/asset_flow_stats_test.dart \
  test/utils/top_level_stats_utils_test.dart \
  test/utils/root_account_summary_aggregation_utils_test.dart

flutter test test/screens/shopping_cart_enter_navigation_test.dart \
  test/screens/transaction_add_enter_navigation_test.dart \
  test/screens/transaction_add_amount_parsing_test.dart \
  test/screens/transaction_add_detailed_amount_parsing_test.dart \
  test/utils/shopping_cart_bulk_ledger_utils_test.dart \
  test/utils/shopping_cart_next_prep_utils_test.dart \
  test/utils/shopping_cart_next_prep_dialog_utils_test.dart

flutter analyze
```

---

## 실패 시 우선 점검 포인트
- 장바구니 → 거래 전송 키 매핑 누락 여부
- 분류(enum) 변경 후 집계 유틸 동기화 누락 여부
- 화면 분리(part 파일) 후 import/part 연결 누락 여부
- 입력 포커스/Enter 핸들러 중복 실행 여부

## 기록 포맷 (간단)
- 실행일시:
- 실행자:
- 통과 시나리오: A/B/C/D/E
- 실패 시나리오:
- 재현 단계:
- 수정 커밋:
