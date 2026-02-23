# UTILS: 기능 분리 - 달력(Calendar)

## 목적/역할
- 계정별 거래 데이터를 날짜별로 묶어 달력 UI로 표시.
- `TransactionService`를 로드한 뒤, `table_calendar` 위젯으로 월/주/2주 뷰를 제공.

## 주요 화면/파일
- Screen
  - `lib/screens/calendar_screen.dart` (`CalendarScreen`)
- 데이터/서비스
  - `lib/services/transaction_service.dart` (거래 로드/조회)
  - `lib/models/transaction.dart` (거래 모델)
- 외부 패키지
  - `table_calendar`
  - `intl`

## 진입점(Entry points)
> “기능 완전 제거”를 하려면 아래 진입점이 모두 없어져야 함.

### 1) 하단 탭(가장 큰 진입점)
- `lib/screens/home_tab_screen.dart`
  - `_tabTitles`에 '달력' 포함
  - `_buildScreens()`에서 `CalendarScreen(accountName: ...)` 포함
  - `BottomNavigationBarItem(label: '달력')` 포함
  - 또한 팝업 메뉴 처리 후 `_screens`를 재구성할 때도 `CalendarScreen(...)`를 넣는 코드가 있음

### 2) 라우트(Route)
- `lib/navigation/app_routes.dart`
  - `AppRoutes.calendar = '/calendar'`
- `lib/navigation/app_router.dart`
  - `case AppRoutes.calendar:` → `CalendarScreen(accountName: ...)`

### 3) (과거/참고) 메인 아이콘 그리드
- 과거에는 `MainFeatureIconCatalog.pages[0]`에 `calendar` 아이콘이 있었으나, 현재는 페이지 0 아이콘 카탈로그가 비어있도록 정리됨.
  - 즉, ‘메인 9페이지 아이콘’ 쪽 진입점은 이미 제거된 상태(다만 하단탭/라우트는 별개).

## 기능 제거(완전 삭제) 체크리스트
### A. UX에서 달력 노출 제거
- `home_tab_screen.dart`에서:
  - '달력' 탭 제거
  - 탭 인덱스(예: `_currentIndex == 2` 달력 탭 처리) 및 타이틀/스크린 리스트 재정렬
  - 팝업 메뉴 후 `_screens` 재구성 코드에서 `CalendarScreen` 제거

### B. 라우트 제거
- `app_routes.dart`에서 `AppRoutes.calendar` 제거
- `app_router.dart`에서 `case AppRoutes.calendar` 제거 + `calendar_screen.dart` import 제거

### C. 스크린/의존 코드 제거
- 다른 참조가 모두 끊기면 `lib/screens/calendar_screen.dart` 삭제 가능
- 삭제 후 `flutter test`로 컴파일/테스트 확인

## 영향/주의
- 달력 탭 제거 시, 사용자 탭 수가 줄어 인덱스가 바뀌므로:
  - `HomeTabScreen(initialIndex: ...)`를 호출하는 곳에서 기존 인덱스 의미가 변할 수 있음.
  - 특히 `AccountMainArgs(initialIndex: targetIndex)`로 넘어오는 인덱스 매핑을 점검 필요.
