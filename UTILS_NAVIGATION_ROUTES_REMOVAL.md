# UTILS: 하단 탭 / 라우트 개념 + 기능 제거 체크리스트

## 1) 하단 탭(Bottom Tab)이란?
- Flutter의 `BottomNavigationBar`(또는 `NavigationBar`)로 제공되는 앱 하단 탭 UI.
- 탭을 누르면 보통 `currentIndex`가 바뀌고, 화면(body)은 **라우트 이동이 아니라** 같은 화면 안에서 “서브 페이지(Widget) 교체”로 바뀌는 경우가 많음.
- 즉, 하단 탭에 특정 기능(예: 달력)이 들어가 있으면, 라우트를 지우더라도 하단 탭이 남아있으면 기능이 계속 노출될 수 있음.

### 현재 코드에서의 예
- `lib/screens/home_tab_screen.dart`에 ‘달력’ 탭이 들어있고 `CalendarScreen(...)`을 직접 연결하는 구조.

## 2) 라우트(Route)란?
- `Navigator.pushNamed(context, routeName, arguments: ...)`로 화면을 이동할 때 쓰는 문자열 주소.
- 보통 아래 2단계로 구성됨.
  1) `AppRoutes`(상수 모음)에서 문자열을 정의
  2) `app_router.dart`에서 해당 문자열을 받아 실제 Screen Widget을 만들어 반환

### 현재 코드에서의 예
- `lib/navigation/app_routes.dart`
  - `AppRoutes.calendar`
  - `AppRoutes.emergencyFund`
  - `AppRoutes.savingsPlanList`
- `lib/navigation/app_router.dart`
  - 위 라우트들을 `case`로 받아 `CalendarScreen`, `EmergencyFundScreen`, `SavingsPlanListScreen` 생성

## 3) “기능 자체 완전 제거”의 의미(코드 수준)
아래 중 하나라도 남아있으면, 사용자는 여전히 해당 기능에 도달 가능.

- (A) 하단 탭/메뉴/버튼에서 화면을 직접 띄움
  - 예: `onTap: () => Navigator.push(...)` 또는 `builder: (_) => CalendarScreen(...)`
- (B) 라우트 상수가 남아있고, 라우터가 그 라우트를 처리함
  - 예: `AppRoutes.calendar` + `case AppRoutes.calendar:`
- (C) 유틸 액션이 라우트로 이동함
  - 예: `UserMainActions.openSavingsPlanList()` → `Navigator.pushNamed(AppRoutes.savingsPlanList)`

따라서 “완전 제거”는 일반적으로 다음 순서로 진행.

### 권장 제거 순서
1) 진입점 제거
   - 하단 탭 항목 제거
   - 메뉴/버튼/액션 제거
2) 라우트 제거
   - `app_routes.dart` 상수 제거
   - `app_router.dart` case 제거
3) 스크린/서비스/모델 제거
   - 더 이상 참조가 없으면 파일 삭제(또는 코드 제거)
4) 테스트 실행
   - `flutter test`

## 4) 달력/비상금/저축계획: 현재 발견된 주요 진입점(2025-12-19 기준)
> 이 목록은 “아이콘 그리드(메인 9페이지)”에서 제거된 것과 별개로,
> 앱 전체(하단탭/라우트/메뉴/직접 Screen push)에 남아있는 연결을 의미.

### 달력
- 하단 탭
  - `lib/screens/home_tab_screen.dart` (탭 라벨 ‘달력’, `CalendarScreen(...)` 직접 연결)
- 라우트
  - `AppRoutes.calendar` / `app_router.dart`의 `case AppRoutes.calendar`
- 스크린 파일
  - `lib/screens/calendar_screen.dart`

### 비상금(비상금 관리 화면)
- 메뉴/버튼
  - `lib/screens/home_tab_screen.dart`에서 ‘비상금 관리’가 `AppRoutes.emergencyFund`로 이동
  - `lib/screens/asset_tab_screen.dart` / `lib/screens/asset_management_screen.dart`에서 `EmergencyFundScreen` 직접 push
- 라우트
  - `AppRoutes.emergencyFund` / `app_router.dart`의 `case AppRoutes.emergencyFund`
- 스크린 파일
  - `lib/screens/emergency_fund_screen.dart`

### 저축계획(플랜)
- 유틸 액션
  - `lib/utils/user_main_actions.dart`의 `openSavingsPlanList()` → `AppRoutes.savingsPlanList`
- 스크린 직접 push
  - `lib/screens/savings_entry_choice_screen.dart`에서 `SavingsPlanListScreen` 직접 push
- 라우트
  - `AppRoutes.savingsPlanList` / `app_router.dart`의 `case AppRoutes.savingsPlanList`
- 스크린 파일
  - `lib/screens/savings_plan_list_screen.dart`

## 5) 범위 결정 메모(중요)
- ‘비상금’이라는 단어는 앱 내에서 **거래 분류/정산 로직(SavingsAllocation 등)**에서도 사용될 수 있음.
- “비상금 관리 화면/라우트 제거”와 “거래 분류의 비상금 개념 제거”는 난이도/영향 범위가 크게 다름.
- 일반적으로 안전한 최소 범위는:
  - 달력 탭/라우트/화면 제거
  - 비상금 ‘관리 화면’(EmergencyFundScreen)과 그 진입점/라우트 제거 (거래 분류 개념은 유지)
  - 저축계획(플랜 리스트/폼) 화면과 진입점/라우트 제거
