# UTILS: 기능 분리 - 비상금(비상금 관리 화면)

## 목적/역할
- 별도의 ‘비상금 지갑’ UI로 입출금 내역/잔액을 보여주는 관리 화면.
- 현재 구현은 데모/스캐폴딩 성격이 강함(주석에 TODO 다수):
  - 실제 저장/동기화 로직은 아직 연결되지 않음.

## 주요 화면/파일
- Screen
  - `lib/screens/emergency_fund_screen.dart` (`EmergencyFundScreen`)
- UI 의존
  - `lib/widgets/state_placeholders.dart` (Loading/Empty/Error)
  - `lib/utils/utils.dart` (CurrencyFormatter, DateFormatter, SnackbarUtils, DialogUtils 등)

## 진입점(Entry points)
### 1) 라우트(Route)
- `lib/navigation/app_routes.dart`
  - `AppRoutes.emergencyFund = '/emergency-fund'`
- `lib/navigation/app_router.dart`
  - `case AppRoutes.emergencyFund:` → `EmergencyFundScreen(accountName: ...)`

### 2) 메뉴/드로어
- `lib/screens/home_tab_screen.dart`
  - 자산 Drawer에 ‘비상금 관리’ ListTile이 있고 `AppRoutes.emergencyFund`로 pushNamed
- `lib/screens/asset_management_screen.dart`
  - PopupMenu에서 ‘비상금’ 선택 시 `EmergencyFundScreen(...)`를 직접 push(MaterialPageRoute)

### 3) 자산 탭 내부 버튼
- `lib/screens/asset_tab_screen.dart`
  - ‘🆘 비상금 관리’ 버튼이 `EmergencyFundScreen(...)` 직접 push
  - `_openEmergencyFund()` 메서드

### 4) (과거/참고) 메인 아이콘 그리드
- 과거에는 `MainFeatureIconCatalog.pages[0]`에 `emergencyFund` 아이콘이 있었으나, 현재는 페이지 0 아이콘 카탈로그가 비어있도록 정리됨.

## 기능 제거(완전 삭제) 체크리스트
### A. UX에서 비상금 관리 진입점 제거
- `home_tab_screen.dart`
  - 자산 Drawer의 ‘비상금 관리’ ListTile 제거
- `asset_tab_screen.dart`
  - ‘🆘 비상금 관리’ 버튼 제거 + `_openEmergencyFund()` 제거
- `asset_management_screen.dart`
  - PopupMenu의 ‘비상금’ 항목 제거 + `_openEmergencyFund()` 제거

### B. 라우트 제거
- `app_routes.dart`에서 `AppRoutes.emergencyFund` 제거
- `app_router.dart`에서 `case AppRoutes.emergencyFund` 제거 + import 제거

### C. 스크린/의존 코드 제거
- 다른 참조가 모두 끊기면 `lib/screens/emergency_fund_screen.dart` 삭제 가능
- 삭제 후 `flutter test`로 컴파일/테스트 확인

## 범위 주의(중요)
- 앱 전체에서 ‘비상금’이라는 용어/개념은 **거래 분류/정산 로직(SavingsAllocation 등)**에서도 사용될 수 있음.
- “비상금 관리 화면 제거”는 위 화면/라우트/메뉴 진입점만 제거하는 작업.
- “거래 분류의 비상금 개념 제거”는 데이터 모델/통계/입력폼 전반에 영향이 커서 별도 과제로 분리하는 것을 권장.
