## 메인 페이지 정책 (인덱스 기준)

목적: 앱의 메인 페이지(사용자 정의 가능한 아이콘 그리드) 기본 구성과 아이콘 동작에 대한 일관된 정책을 정의한다.

**표기법:**
- 코드에서는 **인덱스(0부터 시작)** 사용
- UI에서는 **페이지 번호(1부터 시작)** 표시
- 예: index 0 = UI의 페이지 1

기본 페이지 인덱스:

- index 0: 대시보드 (Dashboard)
  - 용도: 요약 통계, 빠른 요약 위젯, 외부 정보 연동, 도움말 센터
  - 권장 아이콘: 대시보드/요약 관련 아이콘, `weather_manual_input` (날씨 입력), 도움말 아이콘 (`help_center`, `help_quick_start`, `help_transactions`, `help_faq`) 등
- index 1: 지출입력 (Expense Input)
  - 용도: 지출 입력, 장바구니, 쇼핑 준비 등 지출 관련 진입점
  - 권장 아이콘: `transactionAdd`, `quick_simple_expense_input`, `shopping_cart` 등
- index 2: 통계 (Statistics)
  - 용도: 월간/주간/기간별 통계 진입
  - 권장 아이콘: `accountStats`, `period_stats_*` 등
- index 3: 자산 (Assets)
  - 용도: 자산 대시보드, 자산 입력/관리
  - 권장 아이콘: `assetDashboard`, `assetManagement`, `assetSimpleInput`
- index 4: ROOT (관리자)
  - 용도: 루트 권한이 필요한 전역 기능(계정 관리, 전체 거래 등)
  - 권장 아이콘: `root_*` 등
- index 5: 설정 (Settings)
  - 용도: 백업/테마/언어/보안 설정 등
  - 권장 아이콘: `backup`, `theme_settings`, `security_settings`, `database_encryption` 등
- index 6: (미사용)
  - 용도: 비워둠
  - 권장 아이콘: 없음

정책: 아이콘 → 페이지 매핑 및 네비게이션

- 모든 사용자 노출 기능은 `lib/utils/main_feature_icon_catalog.dart`의 `MainFeatureIconCatalog.pages`에 한 곳 이상 노출되어야 한다.
- 각 `MainFeatureIcon`의 `routeName`은 `lib/navigation/app_routes.dart`의 경로 상수(`AppRoutes`)를 사용해야 한다.
- 메인 그리드에서 아이콘을 탭하면 `lib/utils/icon_launch_utils.dart`의 `IconLaunchUtils.buildRequest(...)`를 통해 적절한 인수(`AccountArgs`, `QuickSimpleExpenseInputArgs` 등)를 포함하여 네비게이션해야 한다.
- 페이지 예약 정책(예시):
  - 통계 전용 인덱스(index 3)는 통계 관련 아이콘만 허용할 수 있다.
  - 자산/ROOT 등 민감 페이지는 전용 인덱스로 분리하고, 사용자 임의 배치 시 자동으로 적절한 위치로 이동시키는 정책을 유지한다 (`AccountMainScreen`의 보정 로직 참고).

운영 절차

- 새 기능을 추가할 때:
  1. `AppRoutes`에 경로 상수 추가(필요 시 Args 클래스 정의).
  2. 새 화면을 `lib/screens/`에 추가하고 `AppRouter.onGenerateRoute`에 핸들러를 등록.
  3. `MainFeatureIconCatalog.pages`의 적절한 인덱스에 `MainFeatureIcon(id, label, icon, routeName: AppRoutes.xxx)`로 아이콘 추가.
  4. `tools/check_feature_visibility.ps1` 스크립트를 실행해 메인 페이지 노출 규칙을 검증.

참고 파일

- `lib/utils/main_feature_icon_catalog.dart` — 메인 페이지 아이콘 SSOT
- `lib/navigation/app_routes.dart` — 라우트 상수 및 Args 타입
- `lib/utils/icon_launch_utils.dart` — 아이콘 탭 → 라우트/인자 생성
- `lib/screens/settings_screen.dart` — 설정 화면 항목
- `lib/screens/account_main_screen.dart` — 메인 페이지 그리드 및 예약 정책 로직

변경 기록

- 2026-02-27: 페이지 0에 도움말 아이콘 추가 — help_center, help_quick_start, help_transactions, help_faq (기능별 카테고리화)
- 2026-02-17: 날씨 입력(weather_manual_input) 아이콘 이동 — 수입(index 2) → 대시보드(index 0)
- 2026-02-23: 페이지 재배치 — 수입 페이지 아이콘 삭제, 통계(3)→2, 자산(4)→3, ROOT(5)→4, 설정(6)→5
- 2026-01-30: 페이지2 이름 변경 — 거래(Transactions) → 지출입력(Expense Input)
- 2025-12-30: 초기 작성 — 페이지 매핑(1:대시보드,2:거래,3:수입,4:통계,5:자산,6:ROOT,7:설정) 및 네비게이션 규칙 기록.
