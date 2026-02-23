# UTILS: 기능 분리 - 저축계획/예금 플랜(Savings Plan)

## 목적/역할
- 예금(저축) 플랜을 생성/수정/삭제하고, 자동 납입을 거래(`TransactionType.savings`)로 동기화하는 기능.
- 플랜은 SharedPreferences에 계정별 리스트로 저장됨.

## 주요 화면/파일
### Screens
- `lib/screens/savings_plan_list_screen.dart` (`SavingsPlanListScreen`)
  - 플랜 목록/진행률 표시, 추가/수정/삭제
- `lib/screens/savings_plan_form_screen.dart` (`SavingsPlanFormScreen`)
  - 플랜 생성/수정 폼
- `lib/screens/savings_plan_search_screen.dart` (`SavingsPlanSearchScreen`)
  - 검색/선택 모드 UI + 진입 시 신규 플랜 폼 자동 오픈
- `lib/screens/savings_entry_choice_screen.dart` (`SavingsEntryChoiceScreen`)
  - 진입 즉시 목록 화면으로 이동(자동 오픈)

### 데이터/서비스
- `lib/models/savings_plan.dart` (`SavingsPlan`)
- `lib/services/savings_plan_service.dart` (`SavingsPlanService`)
  - SharedPreferences 저장
  - `syncDueDeposits()`에서 납입 예정분을 거래로 생성
- `lib/services/transaction_service.dart` + `lib/models/transaction.dart`
  - 자동 납입이 거래로 기록됨

## 진입점(Entry points)
### 1) 라우트(Route)
- `lib/navigation/app_routes.dart`
  - `AppRoutes.savingsPlanList = '/savings/plan/list'`
- `lib/navigation/app_router.dart`
  - `case AppRoutes.savingsPlanList:` → `SavingsPlanListScreen(accountName: ...)`

### 2) 상단 메뉴(팝업)
- `lib/screens/home_tab_screen.dart`
  - PopupMenu의 value `'savings'` 선택 시 `UserMainActions.openSavingsPlanList()` 호출

### 3) 유틸 액션
- `lib/utils/user_main_actions.dart`
  - `openSavingsPlanList()`가 `Navigator.pushNamed(AppRoutes.savingsPlanList)` 실행

### 4) 스크린 직접 push
- `lib/screens/savings_entry_choice_screen.dart`
  - `SavingsPlanListScreen`을 `MaterialPageRoute`로 직접 push (자동 오픈)

### 5) (과거/참고) 메인 아이콘 그리드
- 과거에는 `MainFeatureIconCatalog.pages[0]`에 `savingsPlanList` 아이콘이 있었으나, 현재는 페이지 0 아이콘 카탈로그가 비어있도록 정리됨.

## 기능 제거(완전 삭제) 체크리스트
### A. UX에서 진입점 제거
- `home_tab_screen.dart`
  - PopupMenu에서 ‘예금/저축계획’ 항목(value: 'savings') 제거
  - 선택 핸들러에서 `openSavingsPlanList()` 분기 제거
- `savings_entry_choice_screen.dart`
  - 이 화면 자체를 쓰지 않는다면 라우트/진입점도 함께 정리(또는 파일 삭제)

### B. 라우트/액션 제거
- `user_main_actions.dart`에서 `openSavingsPlanList()` 제거(또는 더 이상 호출되지 않게 정리)
- `app_routes.dart`에서 `AppRoutes.savingsPlanList` 제거
- `app_router.dart`에서 `case AppRoutes.savingsPlanList` 제거 + import 제거

### C. 스크린/서비스/모델 제거
- 더 이상 참조가 없으면 다음 파일 삭제 가능
  - screens: `savings_plan_list_screen.dart`, `savings_plan_form_screen.dart`, `savings_plan_search_screen.dart`, `savings_entry_choice_screen.dart`
  - services/models: `savings_plan_service.dart`, `savings_plan.dart`

## 영향/주의(데이터/정산)
- `SavingsPlanService.syncDueDeposits()`는 거래(`TransactionType.savings`)를 생성함.
  - 저축계획 기능을 제거하면 이 자동 생성 경로가 사라짐.
- 단, 앱 전반에서 `TransactionType.savings` 자체는 통계/정산/입력에 쓰일 수 있으므로,
  - “플랜 기능 제거”와 “savings 거래 타입 제거”는 별도 범위로 분리하는 것을 권장.
