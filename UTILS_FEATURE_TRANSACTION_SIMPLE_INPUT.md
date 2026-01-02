# UTILS: 거래 추가 — 간단 입력(Simple Input)

## 목적/역할
- 거래 추가에서 **최소 입력만으로 빠르게 저장**할 수 있는 모드.
- 기존 `Transaction` 저장 로직(`TransactionService`)은 그대로 재사용하고, UI만 간소화한다.

## 사용자 UX(최상위 카테고리)
- 거래 추가 화면 진입 시 상단에 모드 선택을 제공:
  - `간단 입력`
  - `상세입력`
- 간단 입력 선택 시:
  - 불필요한 필드/고급 옵션을 숨기고, 필수 입력만 노출
  - 저장 후 이전 화면으로 복귀(기존 흐름 유지)

## 최소 입력 범위(MVP)
> 정확한 필드 구성은 기존 모델/검증 규칙을 우선하며, 아래는 기본 목표.

- 공통
  - 날짜(`date`)
  - 종류(`type`: 지출/수입/저축 등 앱 정책에 따름)
  - 금액(`amount`) 또는 (수량×단가) 중 하나
  - 설명(`description`) 또는 메모(`memo`) 중 앱이 요구하는 최소

- 지출(Expense) 기준 권장 최소
  - 금액
  - 설명(가맹점/항목)
  - 결제수단(앱이 필수로 강제하는 경우)

## 주요 화면/파일(예정)
- Screen
  - `lib/screens/transaction_add_screen.dart` (`TransactionAddScreen`, `TransactionAddForm`)

- 데이터/서비스
  - `lib/models/transaction.dart`
  - `lib/services/transaction_service.dart`

- 공통 유틸
  - `lib/utils/snackbar_utils.dart`
  - `lib/utils/currency_formatter.dart`
  - `lib/utils/date_formatter.dart`

## 진입점(Entry points)
- 라우트
  - `AppRoutes.transactionAdd`
  - `AppRoutes.transactionAddIncome` (수입 템플릿 기반 진입)

- 아이콘/런처
  - `lib/utils/main_feature_icon_catalog.dart`의 거래 추가 아이콘들
  - `lib/utils/icon_launch_utils.dart`의 route → args 매핑

## 구현 메모(권장 구조)
- `TransactionAddScreen`는 그대로 두고, 내부 폼(`TransactionAddForm`) 상단에 모드 선택을 추가한다.
- 상세 입력 UI는 기존 폼을 유지하고,
  - 간단 입력은 기존 컨트롤러/저장 함수를 **공유**하면서
  - 화면에 표시되는 입력 필드만 줄이는 방식이 가장 안전하다.

## 체크리스트
- [ ] 상단 모드 선택(간단/상세) 추가
- [ ] 간단 입력에서 필수 검증/에러 메시지 일관성 유지
- [ ] 저장 로직/데이터 구조(`Transaction`) 변경 없음
- [ ] 기존 상세 입력 기능 회귀 없음
- [ ] `flutter analyze` 통과
