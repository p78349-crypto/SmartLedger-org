# UTILS: 거래 추가 — 상세입력(Detail Input)

## 목적/역할
- 거래를 **정확하게 기록**하기 위한 전체 입력 모드.
- 카테고리(대/소), 수량/단가, 메모, 결제수단, 저축 배분 등 기존 기능을 모두 제공.

## 사용자 UX(최상위 카테고리)
- 거래 추가 화면 상단에 모드 선택 제공:
  - `간단 입력` / `상세입력`
- 상세입력 선택 시:
  - 기존 `TransactionAddForm`의 전체 필드/옵션을 그대로 노출
  - 기존 초기값 복원/즐겨찾기/자동 계산 동작 유지

## 주요 화면/파일(현재)
- Screen
  - `lib/screens/transaction_add_screen.dart`
    - `TransactionAddScreen`
    - `TransactionAddForm`

- 모델/서비스
  - `lib/models/transaction.dart`
  - `lib/services/transaction_service.dart`
  - (자산/이동 등 연계 시) `lib/services/asset_service.dart`

- 카테고리/포맷
  - `lib/utils/category_definitions.dart`
  - `lib/utils/income_category_definitions.dart`
  - `lib/utils/currency_formatter.dart`
  - `lib/utils/date_formatter.dart`

## 진입점(Entry points)
- 라우트
  - `AppRoutes.transactionAdd`
  - `AppRoutes.transactionAddIncome`

- 거래 상세 화면에서 수정 진입
  - `lib/screens/transaction_detail_screen.dart`에서 `TransactionAddScreen` 호출

## 상세입력 특징(유지해야 하는 동작)
- 즐겨찾기 입력값(설명/결제수단/메모) 관리
- 금액 자동 계산(수량×단가 ↔ 금액) 및 예외 처리
- 카테고리 옵션(수입/지출에 따른 분기)
- 초기 입력값 스냅샷 기반 “입력값 되돌리기”

## 체크리스트
- [ ] 상단 모드 선택을 추가해도 상세입력 UX/저장 로직 변경 없음
- [ ] 수정 모드(기존 거래 편집)에서도 동일하게 동작
- [ ] `transactionAddIncome`(수입 템플릿) 진입 시에도 정상
- [ ] `flutter analyze` 통과
