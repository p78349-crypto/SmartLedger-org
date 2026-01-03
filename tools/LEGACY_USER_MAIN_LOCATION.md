# Legacy 유저 메인(HomeTab) 코드 위치 기록

> UPDATE (2026-01-03): 현재 `AccountMainScreen`은 **Smart Ledger 아이콘 그리드 + 페이지 인디케이터 + 화면 보호기** 조합으로 고정되어 있습니다. 과거 Smart Ledger QuickActions 전용 위젯은 삭제되었으며, 이 문서는 숨김 처리된 HomeTab 경로와 레거시 QuickActions 구조를 찾아볼 때 참고용으로만 유지합니다.

- 작성일: 2025-12-18
- 목적: Smart Ledger 메인을 고정 사용하기 위해 기존 유저 메인(HomeTab) UI는 **앱 시작/메인 진입에서 분리(숨김 처리)** 하고, 코드만 보관합니다.

## 현재 메인 진입(고정)

- 앱 시작 → `LaunchScreen` → `AppRoutes.accountMain`
- `AppRoutes.accountMain` → `AccountMainScreen`
- `AccountMainScreen`은 **Smart Ledger 스타일 아이콘 페이지(최대 15페이지) + 배경/화면보호기 설정 + 사용자 편집 모드**로 구성되어 계정별 대시보드를 대체합니다.

관련 파일:
- `lib/main.dart`
- `lib/screens/account_main_screen.dart`

## 숨김 처리된(메인에서 분리된) 기존 유저 메인 UI

아래 파일들이 기존 유저 메인(HomeTab) 구성 요소입니다. 현재는 메인 진입에서 사용하지 않습니다.

- HomeTab(하단 탭 허브): `lib/screens/home_tab_screen.dart`
- 거래 탭(기존 유저 메인의 핵심 화면): `lib/screens/account_home_screen.dart`
- (레거시 래퍼) 자산 탭으로 바로 보내던 화면: `lib/screens/asset_entry_mode_screen.dart`

참고: 과거 유저 메인에서 사용하던 네비게이션 wiring은 utils로 분리되어 있으나, 현재 메인(AccountMainScreen)에서는 HomeTab을 사용하지 않으므로 사실상 "보관/참고용" 성격입니다.
- `lib/utils/user_main_actions.dart`

## 다시 찾는 방법(검색 키워드)

- `HomeTabScreen(`
- `AccountHomeScreen(`
- `BottomNavigationBarItem(`

## 재활성화(복구) 힌트 (참고)

필요 시 아래 한 줄 변경으로 과거 구조로 되돌릴 수 있습니다.
- `lib/screens/account_main_screen.dart`에서 Smart Ledger 아이콘 그리드 대신 `HomeTabScreen(...)` 반환

(단, 현재 설계는 Smart Ledger 메인 고정이 목표이므로 기본은 비활성 유지)
