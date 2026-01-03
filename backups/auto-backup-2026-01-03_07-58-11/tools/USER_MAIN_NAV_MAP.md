# 유저 메인 UI 연결 맵 (HomeTabScreen)

> UPDATE (2025-12-18): 현재 메인 진입은 `AppRoutes.accountMain` → `AccountMainScreen`이며, `AccountMainScreen`은 **빈 화면(모든 UI 제거)** 입니다. 따라서 이 문서에 정리된 **HomeTabScreen 기반 메인 UI 흐름은 현재 메인 진입에서 사용되지 않는 레거시 맵** 입니다(기록 보존 목적).

이 문서는 **유저 메인 UI 흐름(= AccountMainScreen → HomeTabScreen)**에서 실제로 연결된 화면/라우트들을 한 눈에 보기 위해 정리한 맵입니다.

- 기준 코드: 현재 워크스페이스(2025-12-18)
- 네비게이션 원칙: `Navigator.pushNamed(AppRoutes.*)` + 중앙 라우터(onGenerateRoute)
- 라우트 정의: `lib/navigation/app_routes.dart`
- 라우트 매핑: `lib/navigation/app_router.dart`

---

## 1) 진입 흐름

- 앱 시작(런치) → `AppRoutes.accountMain`
  - 인자: `AccountMainArgs(accountName, initialIndex)`

---

## 2) HomeTabScreen 하단 탭 구성

HomeTabScreen의 `_buildScreens()` 기준.

- 0 거래 탭: `AccountHomeScreen(accountName)`
- 1 통계 탭: `AccountStatsScreen(embed: true)`
- 2 달력 탭: `CalendarScreen(accountName)`
- 3 자산 탭: `AssetTabScreen(accountName, showAccountHeading: false)` + 자산 드로어
- 4 고정비 탭: `FixedCostTabScreen(accountName)`
- 5 ROOT 탭: `RootAccountManagerPage(embed: true, …)`

---

## 3) HomeTab 상단(AppBar)에서 열리는 화면들

### 공통 액션

- 검색: `AppRoutes.accountStatsSearch`
  - 인자: `AccountArgs(accountName)`

- 휴지통: `AppRoutes.trash`
  - 인자: 없음

### 메뉴(⋮) 항목

- 지출 상세: `AppRoutes.transactionDetail`
  - 인자: `TransactionDetailArgs(accountName, initialType: expense)`

- 수입 상세: `AppRoutes.transactionDetail`
  - 인자: `TransactionDetailArgs(accountName, initialType: income)`

- 수입 배분: `AppRoutes.incomeSplit`
  - 인자: `AccountArgs(accountName)`

- 예금(저축 플랜): `AppRoutes.savingsPlanList`
  - 인자: `AccountArgs(accountName)`

- 이월: `MonthEndCarryoverDialog`
  - 라우트 이동 아님(다이얼로그)

- 백업/복원: `AppRoutes.backup`
  - 인자: `AccountArgs(accountName)`

---

## 4) 자산 탭 드로어(Asset Drawer)에서 열리는 화면들

- 자산 대시보드: `AppRoutes.assetDashboard`
  - 인자: `AccountArgs(accountName)`
  - 표시: 라우터에서 `Scaffold + AppBar('자산 대시보드')`로 래핑

- 자산 배분 통계: `AppRoutes.assetAllocation`
  - 인자: `AccountArgs(accountName)`

- 간단 자산 입력: `AppRoutes.assetSimpleInput`
  - 인자: `AccountArgs(accountName)`

- 상세 자산 입력: `AppRoutes.assetDetailInput`
  - 인자: `AccountArgs(accountName)`

- 비상금 관리: `AppRoutes.emergencyFund`
  - 인자: `AccountArgs(accountName)`

---

## 5) 거래 탭(AccountHomeScreen)에서의 이동

- FAB(+) → 거래 입력: `AppRoutes.transactionAdd`
  - 인자: `TransactionAddArgs(accountName)`

---

## 6) 계정 전환(루트 리셋)

- HomeTabScreen 내부 `_switchAccount(...)`
  - `AppRoutes.accountMain`으로 `pushNamedAndRemoveUntil` 수행
  - 인자: `AccountMainArgs(accountName: selected, initialIndex: targetIndex)`

---

## 7) 참고: 중앙 라우터에서 요구하는 Args

- `AppRoutes.accountMain` → `AccountMainArgs`
- `AppRoutes.*` 대부분 accountName 필요 → `AccountArgs`

(Args 타입 불일치가 생기면 런타임 캐스팅 에러가 나므로, UI 쪽에서 `arguments:`를 반드시 맞춰야 합니다.)
