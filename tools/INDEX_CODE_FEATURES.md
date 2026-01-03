# INDEX — Code & Feature Map / 코드·기능 인덱스

- 작성일: 2025-12-18
- 목적: “지금 앱이 어떻게 연결돼 있는지”를 **문서만 보고 바로 추적** 가능하게 만들기

---

## TL;DR (빠른 요약)

- 지금 앱의 “첫 화면/메인 고정” 경로: `(/)` → `LaunchScreen` → `accountMain` → `AccountMainScreen`
- (Legacy / REMOVED) 과거 경로: ~~`(/)` → `LaunchScreen` → `quickActions` → `QuickActionsScreen` → `SmartQuickActionsView`~~
- 다른 메인이 끼어드는 것을 막기 위해 루트 라우트 `(/)`는 **항상 LaunchScreen으로 진입**하도록 라우터에서 고정
- 오늘 작업/변경 이력은 별도 로그: tools/WORK_LOG.md

## 읽는 순서(요약→위치→내용)

1) 위 TL;DR로 전체 맥락 확인
2) 아래 Quick Jump로 “어느 섹션”인지 결정
3) “몇 줄인지(라인)”가 필요하면 PowerShell로 헤더 라인번호를 즉시 조회

- 헤더 라인번호 조회(권장): `pwsh -File tools/locate_md_headings.ps1 tools/INDEX_CODE_FEATURES.md`
- VS Code 이동: `Ctrl+G` → 라인번호 입력

## Quick Jump (바로가기)

- STEP 1: 파일 목록(10초 지도) → [STEP 1) 파일명 목록(기능 간략) — Quick File List](#step-1-파일명-목록기능-간략--quick-file-list)
- STEP 2: 파일별 상세/라우트/Args → [STEP 2) 파일별 자세한 기능 — Per-File Deep Details](#step-2-파일별-자세한-기능--per-file-deep-details)
- STEP 3: 기능→저장소까지(END) → [STEP 3) 가장 깊이 있는 경로 표시(끝) — Deepest Paths (END)](#step-3-가장-깊이-있는-경로-표시끝--deepest-paths-end)
- 변경 기록(필수) → [Change Log — INDEX 변경 기록(필수)](#change-log--index-변경-기록필수)

---

## INDEX POLICY (EN/KR) — 반드시 지킬 것

**EN:** If you change code behavior, move files, rename files, or change routes/args, you MUST update this INDEX and add an entry in the Change Log.

**KR:** 코드 동작 변경, 코드 위치 이동, 파일명 변경, 라우트/Args 변경이 발생하면 **반드시 이 INDEX를 수정하고 Change Log에 기록**한다.

### FIND-ONLY INDEX POLICY (찾기 전용 운영 규칙)

- 이 문서를 “설명서”가 아니라 **찾기/네비게이션 지도**로 사용한다.
- 각 엔트리는 1줄 요약 + “검색 단서(키워드)”를 우선한다.
- 키워드에는 아래 중 2~4개를 포함(가능한 것만):
  - 진입점: Screen/Service/Widget 클래스명
  - 라우트/Args: `AppRoutes.*`, `*Args`
  - 저장키/도메인 키: `PrefKeys.*`, 파일명/폴더명, icon id
  - 테스트/Widget Key: `ValueKey(...)`, finder 텍스트
- 작업 흐름(권장): INDEX에서 범위를 좁힌 뒤, 해당 폴더/파일만 검색(Select-String/VS Code Search).

### APPEND-ONLY POLICY (기록만 / 삭제 금지)

- 이 문서는 “정리(삭제)”가 아니라 “추적(기록)”이 목적이다.
- 따라서 원칙적으로 **기존 내용을 삭제하지 않는다.**
- 내용이 더 이상 유효하지 않으면 아래 규칙으로 “무효화 표시”만 한다.
  - `Legacy / REMOVED` 라벨을 붙이거나 ~~취소선~~ 처리
  - (가능하면) 이유/날짜를 Change Log에 1줄로 남김

#### 변경할 때의 표준 절차(권장)

1) **현재 상태 갱신(NOW)**: TL;DR / Routes / 핵심 흐름은 “현재” 기준으로 수정
2) **과거 보존(HISTORY)**: 바뀐 이전 정보는 삭제 대신 `Legacy / REMOVED`로 남김
3) **Change Log 추가**: Old/New/Note에 “무엇이 왜 바뀌었는지” 1줄 기록

#### 문제 발생 시 활용 순서(트러블슈팅용)

1) **증상 고정**: 에러 메시지/스크린샷/재현 단계(최소 3단계) 기록
2) **Change Log 확인**: 최근 날짜부터 보고, 관련 변경(라우트/Args/메인 흐름/저장소)을 찾기
3) **NOW 기준으로 추적**: TL;DR → Routes 표 → “라우트 호출 지점 인덱스” → 실제 호출 파일
4) **HISTORY 비교**: 예전 경로가 필요하면 `Legacy / REMOVED` 항목을 참고(삭제된 게 아니라 기록으로 남아있음)
5) **원인 범위 좁히기**: (a) 라우트/Args 캐스팅 (b) 저장소(prefs/DB/file) (c) 화면 state/provider 순으로 점검

권장 캡처(1줄씩)
- 실행 경로: 예) `(/) → LaunchScreen → accountMain`
- 실행한 명령: 예) `flutter analyze`, `flutter build apk --release`

#### 문구 템플릿(복붙용)

- (LEGACY) 이전: ~~`/` → LaunchScreen → quickActions~~
- (NOW) 현재: `(/)` → `LaunchScreen` → `accountMain`

---

# STEP 1) 파일명 목록(기능 간략) — Quick File List

> “어디부터 보면 되지?”를 10초 안에 해결하는 섹션

| 파일 | 한 줄 요약(기능) | 핵심 키워드 |
|---|---|---|
| tools/INDEX_CODE_FEATURES.md | Backup/Restore (Change Log 2025-12-20): 즐겨찾기(favorites) 백업/복원 + createdAt 보존 | BackupService, favorites, createdAt |
| tools/INDEX_CODE_FEATURES.md | Backup/Restore (Change Log 2025-12-20): snapshot 누락 항목 보강 | BackupService, snapshot |
| tools/INDEX_CODE_FEATURES.md | ~~Backup/Restore (DUPLICATE): snapshot 누락 항목 보강~~ | ~~(duplicate row; see above)~~ |
| lib/main.dart | 앱 시작 + Provider 구성 + LaunchScreen로 진입(고정) | LaunchScreen, AppRouter, accountMain |
| lib/screens/launch_screen.dart | 시작 화면(스플래시) → 마지막 계정 확인 후 accountMain으로 pushReplacement | goToAccountMain, UserPrefService |
| lib/navigation/app_routes.dart | 라우트 문자열 + Args 타입(강타입 네비게이션) | AppRoutes, *Args |
| lib/navigation/app_router.dart | onGenerateRoute 중앙 라우팅(Args 캐스팅 포함) | onGenerateRoute, MaterialPageRoute |
| lib/screens/account_main_screen.dart | 메인: 15페이지 PageView + 상단 배너 탭(번호) + 편집모드 드래그(페이지 스와이프 잠금) | PageController, PageBannerBar, LongPressDraggable, NeverScrollableScrollPhysics |
| lib/screens/icon_management_screen.dart | 아이콘 관리 허브(슬롯 편집/추가/숨김 + 파트별 카탈로그) | IconManagementScreen, icon_mgmt_slot_, _catalogOnlyUnplaced, MainFeatureIconCatalog.pageCount |
| test/screens/account_main_icon_picker_test.dart | 아이콘 선택(다중 선택/일괄 적용) 위젯 테스트 | icon_mgmt_slot_8, '하단에서 추가할 아이콘을 체크하세요', 적용, scrollUntilVisible |
| lib/screens/backup_screen.dart | 백업/복원 UI(Downloads 폴더/파일 목록) | BackupScreen, BackupService, Downloads, restore |
| lib/screens/privacy_policy_screen.dart | 개인정보 처리방침 화면(동의 저장) | PrivacyPolicy, PrefKeys.privacyPolicyConsentChoice |
| ~~lib/widgets/smart_quick_actions_view.dart~~ | (REMOVED) Smart Ledger 스타일 퀵액션 UI(페이지/섹션/점표시) | Smart, pager, dots |
| ~~lib/utils/quick_actions_catalog.dart~~ | (REMOVED) 퀵액션 아이콘/라우트 매핑(메뉴 정의) | QuickActionItem, AppRoutes.* |
| ~~lib/state/quick_actions_ui_state.dart~~ | (REMOVED) Smart Ledger 상태 저장(검색어/세로모드 등) | Provider, ChangeNotifier |
| lib/utils/asset_flow_stats.dart | (내 자산 흐름) 자산 이동 기록을 통계/지출(Outflow)로 분리 계산 | AssetMove, inflow/outflow |
| lib/utils/user_main_actions.dart | (레거시/보관 성격) 유저메인 상단 액션 네비게이션 유틸 | accountStatsSearch, trash |
| lib/screens/top_level_main_screen.dart | 계정 생성/선택/ROOT 대시보드, TopLevelStatsDetail 포함 | TopLevelStatsDetail |
| lib/services/transaction_service.dart | 거래 로드/저장/조회 핵심 서비스 | loadTransactions, getTransactions |
| lib/services/budget_service.dart | 예산 저장/조회 | getBudget |
| lib/services/income_split_service.dart | 수입 분리/예산 계획 값(대안 예산 소스) | getSplit |
| lib/services/asset_service.dart | 자산 로드/저장/조회 | loadAssets |
| lib/services/fixed_cost_service.dart | 고정비 로드/저장/조회 | loadFixedCosts |
| lib/services/savings_plan_service.dart | 저축 플랜(자동 납입 → 거래 생성) | syncDueDeposits |
| lib/services/account_service.dart | 계정 CRUD(Drift DB) + legacy prefs 마이그레이션 | AppDatabase, app_database.sqlite |
| lib/database/app_database.dart | Drift 테이블/DB 연결(app_database.sqlite) | DbAccounts, NativeDatabase |
| lib/services/trash_service.dart | 휴지통(삭제된 거래/자산/계정 스냅샷) 저장/조회 | PrefKeys.trash |
| lib/services/asset_move_service.dart | 자산 이동/전환 기록 저장/조회 | asset_moves |
| lib/services/backup_service.dart | 백업/복원(JSON 파일 저장/불러오기 + lastBackup) | Downloads, FilePicker |

## (Legacy / 숨김) 기존 유저 메인(HomeTab) 관련

| 파일 | 한 줄 요약(기능) | 핵심 키워드 |
|---|---|---|
| lib/screens/home_tab_screen.dart | 하단 탭 허브(과거 유저 메인) | HomeTabScreen, BottomNavigationBar |
| lib/screens/account_home_screen.dart | 거래 탭 메인(과거 유저 메인의 핵심 화면) | AccountHomeScreen |
| lib/screens/asset_entry_mode_screen.dart | 자산 탭으로 바로 보내던 레거시 래퍼 | entry mode |

---

# STEP 2) 파일별 자세한 기능 — Per-File Deep Details

> “이 파일이 정확히 뭘 하고, 어디로 연결되는가?”

## lib/main.dart

- 앱 진입점(MaterialApp) 설정
  - `home: LaunchScreen`
  - `onGenerateRoute: AppRouter.onGenerateRoute`
- 계정 선택/게스트 계정 등 상황에 따라 `AppRoutes.accountMain`으로 진입

## lib/navigation/app_routes.dart

- 라우트 문자열: `AppRoutes.*`
- Args 타입: `AccountArgs`, `AccountMainArgs`, `AccountSelectArgs`, `TransactionAddArgs`, ...
- 규칙: UI에서는 반드시 `Navigator.pushNamed(..., arguments: <Args>)` 형태만 사용

### Args 타입 상세(필드/타입/기본값/사용 라우트)

> 소스: `lib/navigation/app_routes.dart` (Args 정의), `lib/navigation/app_router.dart` (cast/사용)

#### Args 공통 규칙(중요)

- `AppRoutes.*` 호출 시 `arguments:`는 **아래 Args 타입만** 사용 (직접 Map/tuple 금지)
- 일부 필드가 `Object`로 선언되어 있습니다. 라우터에서 실제 타입으로 `as` 캐스팅합니다.
  - 즉, 잘못된 타입을 넣으면 **런타임 캐스팅 에러**가 납니다.
  - 예: `TransactionDetailArgs.initialType`은 라우터에서 `TransactionType`으로 캐스팅됨

#### Args 목록

| Args class | 정의 파일 | 필드(타입) | 기본값/옵션 | 사용 라우트(AppRoutes) | 라우터에서 기대 타입(cast) |
|---|---|---|---|---|---|
| AccountArgs | lib/navigation/app_routes.dart | accountName(String) | - | emergencyFund, backup, accountStats, accountStatsSearch, incomeSplit, calendar, assetTab, assetDashboard, assetAllocation, assetManagement, assetSimpleInput, assetDetailInput, fixedCostTab, fixedCostStats, savingsPlanList | - |
| ~~AccountArgs~~ | ~~lib/navigation/app_routes.dart~~ | ~~accountName(String)~~ | ~~(LEGACY)~~ | ~~quickActions~~ | ~~REMOVED~~ |
| AccountMainArgs | lib/navigation/app_routes.dart | accountName(String), initialIndex(int) | initialIndex=0 | accountMain | - |
| AccountSelectArgs | lib/navigation/app_routes.dart | accounts(List<String>) | - | accountSelect | - |
| TransactionAddArgs | lib/navigation/app_routes.dart | accountName(String), initialTransaction(Object?) | initialTransaction=null | transactionAdd | initialTransaction as Transaction? |
| TransactionDetailArgs | lib/navigation/app_routes.dart | accountName(String), initialType(Object) | - | transactionDetail | initialType as TransactionType |
| DailyTransactionsArgs | lib/navigation/app_routes.dart | accountName(String), initialDay(DateTime) | - | dailyTransactions | - |
| TopLevelStatsDetailArgs | lib/navigation/app_routes.dart | dashboard(Object) | - | topLevelStatsDetail | dashboard as RootDashboardContext |

#### 호출 예시(패턴)

- 계정 기반(가장 흔함)
  - `Navigator.of(context).pushNamed(AppRoutes.assetTab, arguments: AccountArgs(accountName: accountName));`
- 메인 진입(초기 탭 선택 포함)
  - `Navigator.of(context).pushNamed(AppRoutes.accountMain, arguments: AccountMainArgs(accountName: accountName, initialIndex: 0));`
- 거래 입력(편집 모드 포함)
  - `Navigator.of(context).pushNamed(AppRoutes.transactionAdd, arguments: TransactionAddArgs(accountName: accountName, initialTransaction: tx));`
- 상세내역(타입 선택)
  - `Navigator.of(context).pushNamed(AppRoutes.transactionDetail, arguments: TransactionDetailArgs(accountName: accountName, initialType: TransactionType.expense));`

## lib/navigation/app_router.dart

- 중앙 라우팅(Args 캐스팅 포함)
- `assetDashboard`는 화면 자체 AppBar가 없어, 라우터에서 `Scaffold + AppBar` 래핑

### AppRoutes → Screen 매핑(라우터 기준)

| AppRoutes | route string | Entry | Type | Required params(Entry 생성자) | Optional params(default) | Screen 파일 | Router notes |
|---|---|---|---|---|---|---|---|
| topLevelMain | / | LaunchScreen | StatefulWidget | - | - | lib/screens/launch_screen.dart | 앱 시작 고정 진입점 |
| topLevelStatsDetail | /top-level/stats-detail | TopLevelStatsDetailScreen | StatelessWidget | dashboard | - | lib/screens/top_level_main_screen.dart |  |
| ~~quickActions~~ | ~~/quick-actions~~ | ~~QuickActionsScreen~~ | ~~StatelessWidget~~ | ~~accountName~~ | ~~-~~ | ~~lib/screens/quick_actions_screen.dart~~ | ~~REMOVED~~ |
| accountMain | /account/main | AccountMainScreen | StatelessWidget | accountName | initialIndex(0) | lib/screens/account_main_screen.dart |  |
| accountCreate | /account/create | AccountCreateScreen | StatefulWidget | - | - | lib/screens/account_create_screen.dart |  |
| accountSelect | /account/select | AccountSelectScreen | StatelessWidget | accounts(List<String>) | - | lib/screens/account_select_screen.dart |  |
| transactionAdd | /transaction/add | TransactionAddScreen | StatelessWidget | accountName | initialTransaction(null) | lib/screens/transaction_add_screen.dart |  |
| transactionDetail | /transaction/detail | TransactionDetailScreen | StatefulWidget | accountName | initialType(null) | lib/screens/transaction_detail_screen.dart | 화면 initState에서 null이면 expense로 설정 |
| dailyTransactions | /transaction/daily | DailyTransactionsScreen | StatefulWidget | accountName, initialDay | - | lib/screens/daily_transactions_screen.dart |  |
| emergencyFund | /emergency-fund | EmergencyFundScreen | StatefulWidget | accountName | - | lib/screens/emergency_fund_screen.dart |  |
| trash | /trash | TrashScreen | StatefulWidget | - | - | lib/screens/trash_screen.dart |  |
| backup | /backup | BackupScreen | StatefulWidget | accountName | - | lib/screens/backup_screen.dart |  |
| settings | /settings | SettingsScreen | StatefulWidget | - | - | lib/screens/settings_screen.dart |  |
| accountStats | /stats/monthly | AccountStatsScreen | StatefulWidget | accountName | embed(false) | lib/screens/account_stats_screen.dart | 라우터에서 embed: false로 사용 |
| accountStatsSearch | /stats/search | AccountStatsSearchScreen | StatefulWidget | accountName | - | lib/screens/account_stats_screen.dart |  |
| incomeSplit | /income/split | IncomeSplitScreen | StatefulWidget | accountName | - | lib/screens/income_split_screen.dart |  |
| calendar | /calendar | CalendarScreen | StatefulWidget | accountName | - | lib/screens/calendar_screen.dart |  |
| assetTab | /asset/tab | AssetTabScreen | StatefulWidget | accountName | showAccountHeading(true) | lib/screens/asset_tab_screen.dart |  |
| assetDashboard | /asset/dashboard | AssetDashboardScreen | StatefulWidget | accountName | - | lib/screens/asset_dashboard_screen.dart | 라우터에서 Scaffold+AppBar로 감싸서 표시 |
| assetAllocation | /asset/allocation | AssetAllocationScreen | StatefulWidget | accountName | - | lib/screens/asset_allocation_screen.dart |  |
| assetManagement | /asset/management | AssetManagementScreen | StatelessWidget | accountName | - | lib/screens/asset_management_screen.dart | (참고) 화면 내부에서 일부 Navigator.push(MaterialPageRoute) 사용 |
| assetSimpleInput | /asset/input/simple | AssetSimpleInputScreen | StatefulWidget | accountName | - | lib/screens/asset_simple_input_screen.dart |  |
| assetDetailInput | /asset/input/detail | AssetInputScreen | StatefulWidget | accountName | initialAsset(null) | lib/screens/asset_input_screen.dart |  |
| fixedCostTab | /fixed-cost/tab | FixedCostTabScreen | StatefulWidget | accountName | - | lib/screens/fixed_cost_tab_screen.dart |  |
| fixedCostStats | /fixed-cost/stats | FixedCostStatsScreen | StatefulWidget | accountName | - | lib/screens/fixed_cost_stats_screen.dart |  |
| savingsPlanList | /savings/plan/list | SavingsPlanListScreen | StatefulWidget | accountName | - | lib/screens/savings_plan_list_screen.dart |  |

### 라우트 호출 지점 인덱스(“누가 pushNamed 하나?”)

| AppRoutes | 주 Args | 대표 호출 파일(발췌) |
|---|---|---|
| accountMain | AccountMainArgs | lib/main.dart, lib/screens/top_level_main_screen.dart, lib/screens/account_select_screen.dart, lib/screens/home_tab_screen.dart |
| topLevelStatsDetail | TopLevelStatsDetailArgs | lib/screens/top_level_main_screen.dart |
| ~~quickActions~~ | ~~AccountArgs~~ | ~~(REMOVED) lib/utils/user_main_actions.dart, lib/screens/account_home_screen.dart~~ |
| transactionAdd | TransactionAddArgs | lib/utils/account_home_actions.dart, lib/screens/account_home_screen.dart, lib/screens/root_transaction_manager_screen.dart |
| transactionDetail | TransactionDetailArgs | lib/utils/user_main_actions.dart |
| dailyTransactions | DailyTransactionsArgs | (현재 직접 호출 없음: 라우트만 존재) |
| emergencyFund | AccountArgs | lib/screens/home_tab_screen.dart |
| trash | - | lib/utils/user_main_actions.dart |
| backup | AccountArgs | lib/utils/user_main_actions.dart |
| settings | - | (현재 직접 호출 없음: legacy QuickActions에서만 링크) |
| accountStats | AccountArgs | (현재 직접 호출 없음: legacy QuickActions에서만 링크) |
| accountStatsSearch | AccountArgs | lib/utils/user_main_actions.dart |
| incomeSplit | AccountArgs | lib/utils/user_main_actions.dart |
| calendar | AccountArgs | (현재 직접 호출 없음: legacy QuickActions에서만 링크) |
| savingsPlanList | AccountArgs | lib/utils/user_main_actions.dart |
| fixedCostTab | AccountArgs | (현재 직접 호출 없음: legacy QuickActions에서만 링크) |
| fixedCostStats | AccountArgs | lib/screens/home_tab_screen.dart |
| assetTab | AccountArgs | (현재 직접 호출 없음: legacy QuickActions에서만 링크) |
| assetDashboard | AccountArgs | lib/screens/home_tab_screen.dart |
| assetAllocation | AccountArgs | lib/screens/home_tab_screen.dart |
| assetManagement | AccountArgs | (현재 직접 호출 없음: legacy QuickActions에서만 링크) |
| assetSimpleInput | AccountArgs | lib/screens/home_tab_screen.dart |
| assetDetailInput | AccountArgs | lib/screens/home_tab_screen.dart |

## lib/screens/account_main_screen.dart (현재 고정 메인)

- 화면 구성
  - PageView 기반 Smart Ledger 아이콘 그리드(최대 15페이지) + 페이지 인디케이터
  - 편집 모드, 고정 아이콘 정책, 사용자별 배경/테마 설정, 화면보호기(Idle Timer)
  - AppBar 미사용, 상단 여백 및 상태 안내는 아이콘 페이지 내부에서 처리

## (Legacy / REMOVED) lib/widgets/smart_quick_actions_view.dart

- (REMOVED) Smart Ledger 스타일 퀵액션 UI(검색/페이지/도트/드로어)
- 현재 앱의 메인 흐름/라우트에서 사용하지 않음
- NOTE: `lib/widgets/smart_quick_actions_view.dart` 파일은 2025-12-18에 실제 삭제됨(문서는 기록 보존 목적)
- 기록 정책상 과거 구현을 남기되, 기능은 제거된 상태로 유지

## (Legacy / REMOVED) lib/utils/quick_actions_catalog.dart

- (REMOVED) Smart Ledger 아이콘/동작을 한 곳에서 정의하던 카탈로그
- (기록) 과거 QuickActions에서 사용하던 “아이콘 → 라우트/Args” 매핑

### (Legacy / REMOVED) Smart Ledger 퀵 액션 상세(아이콘 → 라우트/Args)

| id | label | icon | route | arguments(Args) | 비고 |
|---|---|---|---|---|---|
| transaction_add | 거래 입력 | Icons.edit | AppRoutes.transactionAdd | TransactionAddArgs(accountName) |  |
| emergency_fund | 비상금 | Icons.health_and_safety_outlined | AppRoutes.emergencyFund | AccountArgs(accountName) |  |
| transaction_history | 거래 내역 | Icons.receipt_long_outlined | AppRoutes.dailyTransactions | DailyTransactionsArgs(accountName, initialDay: now) |  |
| search | 검색 | Icons.search | - | - | onInvoke: null (UI 내부 동작/미구현) |
| trash | 휴지통 | Icons.delete_outline | AppRoutes.trash | - |  |
| backup | 백업/복원 | Icons.backup_outlined | AppRoutes.backup | AccountArgs(accountName) |  |
| settings | 설정 | Icons.settings_outlined | AppRoutes.settings | - |  |
| monthly_stats | 월별 통계 | Icons.bar_chart | AppRoutes.accountStats | AccountArgs(accountName) |  |
| category_analysis | 카테고리\n분석 | Icons.pie_chart_outline | - | - | onInvoke: null (미구현) |
| transaction_details | 상세내역 | Icons.view_list_outlined | AppRoutes.transactionDetail | TransactionDetailArgs(accountName, initialType: expense) |  |
| income_split | 수입 분리 | Icons.account_tree_outlined | AppRoutes.incomeSplit | AccountArgs(accountName) |  |
| calendar | 달력 보기 | Icons.calendar_month | AppRoutes.calendar | AccountArgs(accountName) |  |
| alerts | 알림 | Icons.notifications_none | - | - | onInvoke: null (미구현) |
| event | 이벤트 | Icons.event_note | - | - | onInvoke: null (미구현) |
| checklist | 체크리스트 | Icons.fact_check_outlined | - | - | onInvoke: null (미구현) |
| asset_tab | 자산 현황 | Icons.account_balance_wallet_outlined | AppRoutes.assetTab | AccountArgs(accountName) |  |
| asset_dashboard | 대시보드 | Icons.dashboard_outlined | AppRoutes.assetDashboard | AccountArgs(accountName) | 라우터에서 Scaffold+AppBar로 래핑 |
| asset_allocation | 자산 배분 | Icons.pie_chart_outline | AppRoutes.assetAllocation | AccountArgs(accountName) |  |
| asset_input | 자산 입력 | Icons.edit_note | AppRoutes.assetManagement | AccountArgs(accountName) |  |
| fixed_cost_tab | 고정비 관리 | Icons.wallet_outlined | AppRoutes.fixedCostTab | AccountArgs(accountName) |  |
| fixed_cost_stats | 고정비 통계 | Icons.query_stats_outlined | AppRoutes.fixedCostStats | AccountArgs(accountName) |  |
| bill_schedule | 납부 일정 | Icons.edit_calendar_outlined | - | - | onInvoke: null (미구현) |
| urgent_items | 긴급 품목 | Icons.warning_amber_outlined | - | - | onInvoke: null (미구현) |

## lib/state/quick_actions_ui_state.dart

- (REMOVED) Smart Ledger 상태(검색어/세로모드 등) 유지/복원
- Provider(ChangeNotifier) 기반. 현재 기능 제거로 사용하지 않음

## lib/utils/user_main_actions.dart (레거시/보관 성격)

- HomeTab(레거시) 상단 액션을 한 곳에서 처리하던 유틸
- 현재 메인(AccountMainScreen)은 HomeTab을 사용하지 않으므로 “보관/참고용” 성격

## (Legacy / 숨김) 기존 유저 메인(HomeTab) — 상세

> 아래 내용은 기존 문서 2개를 **이 파일에 통합**한 것입니다.
> - tools/USER_MAIN_NAV_MAP.md
> - tools/LEGACY_USER_MAIN_LOCATION.md

### Legacy 위치 기록(요약)

- (NOW) 현재 메인 진입(고정)
  - 앱 시작 → `LaunchScreen` → `AppRoutes.accountMain` → `AccountMainScreen`
  - `AccountMainScreen`: Smart Ledger 아이콘 페이지 + 배경/화면보호기 조합
- (LEGACY / REMOVED) 과거 메인 진입
  - 앱 시작 → `LaunchScreen` → `AppRoutes.quickActions` → `QuickActionsScreen`
  - QuickActionsScreen: `SmartQuickActionsView` (Smart Ledger)
- 숨김 처리된(메인에서 분리된) 기존 유저 메인 UI
  - `lib/screens/home_tab_screen.dart`
  - `lib/screens/account_home_screen.dart`
  - `lib/screens/asset_entry_mode_screen.dart`

### Legacy HomeTab 연결 맵(요약)

- HomeTabScreen 하단 탭 구성(과거)
  - 0 거래 탭: `AccountHomeScreen(accountName)`
  - 1 통계 탭: `AccountStatsScreen(embed: true)`
  - 2 달력 탭: `CalendarScreen(accountName)`
  - 3 자산 탭: `AssetTabScreen(accountName, showAccountHeading: false)` + 자산 드로어
  - 4 고정비 탭: `FixedCostTabScreen(accountName)`
  - 5 ROOT 탭: `RootAccountManagerPage(embed: true, …)`

- 상단(AppBar) 공통 액션(과거)
  - 검색: `AppRoutes.accountStatsSearch` (AccountArgs)
  - 휴지통: `AppRoutes.trash` (인자 없음)
  - 퀵 액션: `AppRoutes.quickActions` (AccountArgs)

- 메뉴(⋮) 항목(과거)
  - 상세내역: `AppRoutes.transactionDetail` (TransactionDetailArgs)
  - 수입 배분: `AppRoutes.incomeSplit` (AccountArgs)
  - 저축 플랜: `AppRoutes.savingsPlanList` (AccountArgs)
  - 백업/복원: `AppRoutes.backup` (AccountArgs)

- 자산 드로어(과거)
  - 자산 대시보드: `AppRoutes.assetDashboard` (AccountArgs)
  - 자산 배분: `AppRoutes.assetAllocation` (AccountArgs)
  - 간단 입력: `AppRoutes.assetSimpleInput` (AccountArgs)
  - 상세 입력: `AppRoutes.assetDetailInput` (AccountArgs)
  - 비상금: `AppRoutes.emergencyFund` (AccountArgs)

- 다시 찾는 방법(검색 키워드)
  - `HomeTabScreen(` / `AccountHomeScreen(` / `BottomNavigationBarItem(`

---

# STEP 3) 가장 깊이 있는 경로 표시(끝) — Deepest Paths (END)

> “이 기능이 최종적으로 어디까지(서비스/저장/결과) 내려가는가?”
> 경로 끝에는 반드시 `(END)`를 붙입니다.

## 3-1) 앱 시작 → 메인 고정 진입 (END)

`lib/main.dart`
→ `LaunchScreen`
→ `Navigator.pushReplacementNamed(AppRoutes.accountMain, AccountMainArgs)`
→ `AppRouter.onGenerateRoute`
→ `AccountMainScreen(accountName, initialIndex)`
→ 선행 로드(대표): `AccountService.loadAccounts` / `TransactionService.loadTransactions` / `AssetService.loadAssets` / `FixedCostService.loadFixedCosts`
→ 계정 저장소(Drift): `AccountService` → `AppDatabase.getAllAccounts()` → `LazyDatabase(_openConnection)` → `getApplicationDocumentsDirectory()/app_database.sqlite` (END)
→ 거래/예산/자산/고정비 저장소(SharedPreferences)
  - 거래: `PrefKeys.transactions` (= "transactions")
  - 예산: `PrefKeys.budgets` (= "budgets")
  - 자산: "assets" (AssetService 내부 상수)
  - 고정비: `PrefKeys.fixedCosts` (= "fixed_costs")
→ 수입배분 저장소(File): `getApplicationDocumentsDirectory()/income_splits.json`
→ 화면 렌더: `AccountMainScreen` (빈 화면)
→ (END)

## 3-2) (LEGACY / REMOVED) 메인 → Smart Ledger 퀵액션 → 거래 입력 (END)

`QuickActionsScreen`
→ `SmartQuickActionsView`
→ `QuickActionsCatalog.build`
→ `Navigator.pushNamed(AppRoutes.transactionAdd, TransactionAddArgs)`
→ `TransactionAddScreen`
→ `TransactionService.addTransaction(accountName, transaction)`
→ `TransactionService._persist()` (persist-chain)
→ `SharedPreferences.getInstance()`
→ `prefs.setString(PrefKeys.transactions, jsonEncode(Map<accountName, List<Transaction.toJson>>))`
→ (END)

## 3-3) (LEGACY / REMOVED) 메인 → Smart Ledger 퀵액션 → 오늘/일별 거래 내역 (END)

`QuickActionsScreen`
→ `SmartQuickActionsView`
→ `QuickActionsCatalog.build`
→ `Navigator.pushNamed(AppRoutes.dailyTransactions, DailyTransactionsArgs)`
→ `DailyTransactionsScreen`
→ `TransactionService.loadTransactions()`
→ `TransactionService._doLoad()`
→ `SharedPreferences.getInstance()`
→ `prefs.getString(PrefKeys.transactions)` → `jsonDecode` → `Transaction.fromJson`
→ `TransactionService.getTransactions(accountName)`
→ (END)

## 3-4) 거래 삭제 → 휴지통 이동 → 저장 (END)

`(예: DailyTransactionsScreen / TransactionDetailScreen 등)`
→ `TransactionService.deleteTransaction(accountName, transactionId, moveToTrash: true)`
→ `TrashService.addTransaction(accountName, removedTransaction)`
→ `TrashService._persist()`
→ `SharedPreferences.getInstance()`
→ `prefs.setString(PrefKeys.trash, jsonEncode(List<TrashEntry.toJson>))`
→ `TransactionService._persist()`
→ `prefs.setString(PrefKeys.transactions, ...)`
→ (END)

## 3-5) 예산 설정/증감 → 저장 (END)

`(예: TransactionDetailScreen, IncomeSplitScreen 등)`
→ `BudgetService.setBudget(accountName, amount)`
→ `BudgetService._persist()`
→ `SharedPreferences.getInstance()`
→ `prefs.setString(PrefKeys.budgets, jsonEncode(Map<accountName, double>))`
→ (END)

## 3-6) 수입 분리 저장 → 파일 저장 + (옵션) 자산이동 기록 생성 (END)

`IncomeSplitScreen`
→ `IncomeSplitService.setSplit(..., persistToStorage: true, createAssetMoves: true)`
→ `IncomeSplitService.saveSplits()`
→ `getApplicationDocumentsDirectory()`
→ `File('<dir>/income_splits.json').writeAsString(jsonEncode(List<IncomeSplit.toJson>))` (END)
→ (옵션: createAssetMoves)
  - `AssetService.addAsset/UpdateAsset` → `SharedPreferences.setString('assets', ...)`
  - `AssetMoveService.addMove` → `SharedPreferences.setString('asset_moves', ...)`
→ (END)

## 3-7) 자산 추가/수정/삭제 → 저장(+휴지통) (END)

`AssetSimpleInputScreen / AssetInputScreen / AssetListScreen`
→ `AssetService.addAsset/updateAsset/deleteAsset`
→ (삭제 시) `TrashService.addAsset(...)` → `PrefKeys.trash`
→ `AssetService._persist()`
→ `SharedPreferences.getInstance()`
→ `prefs.setString('assets', jsonEncode(Map<accountName, List<Asset.toJson>>))`
→ (END)

## 3-8) 고정비 추가/편집 → 저장 (END)

`FixedCostTabScreen`
→ `FixedCostService.addFixedCost/replaceFixedCosts`
→ `FixedCostService._persist()` (persist-chain)
→ `SharedPreferences.getInstance()`
→ `prefs.setString(PrefKeys.fixedCosts, jsonEncode(Map<accountName, List<FixedCost.toJson>>))`
→ (END)

## 3-9) 저축 플랜 자동 납입 → 거래 생성 → 저장 (END)

`SavingsPlanListScreen (또는 플랜 동기화 트리거)`
→ `SavingsPlanService.syncDueDeposits(accountName)`
→ dueCount만큼 `TransactionService.addTransaction(accountName, Transaction(type: savings, ...))`
→ `SharedPreferences.setString(PrefKeys.transactions, ...)`
→ 플랜 상태 업데이트 후 `SavingsPlanService._persist()`
→ `SharedPreferences.setString(PrefKeys.savingsPlans, jsonEncode(Map<accountName, List<SavingsPlan.toJson>>))`
→ (END)

## 3-10) 백업 내보내기/복원 → 파일 I/O + prefs/DB 갱신 (END)

`BackupScreen`
→ `BackupService.exportAccountData(accountName)`
  - 계정: `AccountService.getAccountByName` (Drift: app_database.sqlite)
  - 거래: `TransactionService.getTransactions` (PrefKeys.transactions)
  - 자산: `AssetService.getAssets` ('assets')
  - 고정비: `FixedCostService.getFixedCosts` (PrefKeys.fixedCosts)
  - 예산: `BudgetService.getBudget` (PrefKeys.budgets)
→ `BackupService.saveBackupToDownloads` 또는 `saveBackupToFile`
→ `File.writeAsString(json)` (Downloads/VCCode1_Backup 또는 app documents)
→ `BackupService.setLastBackupDate` → `SharedPreferences.setInt(PrefKeys.accountKey(accountName,'lastBackup'), millis)`
→ (END)

`BackupService.restoreFromFile(newAccountName)`
→ `FilePicker.pickFiles` → `File.readAsString` → `importAccountDataAsNew`
→ `AccountService.addAccount` (Drift DB insert)
→ 거래: 반복 `TransactionService.addTransaction` → PrefKeys.transactions
→ 자산: `AssetService.replaceAssets` → 'assets'
→ 고정비: `FixedCostService.replaceFixedCosts` → PrefKeys.fixedCosts
→ 예산: `BudgetService.setBudget/removeBudget` → PrefKeys.budgets
→ (END)

## 3-11) ROOT/TopLevel → 통계 상세로 drill-down (END)

`TopLevelMainScreen`
→ `Navigator.pushNamed(AppRoutes.topLevelStatsDetail, TopLevelStatsDetailArgs)`
→ `TopLevelStatsDetailScreen(dashboard: RootDashboardContext)`
→ ROOT 집계 데이터 렌더
→ (END)

## 3-12) Legacy(숨김) 경로 — 참고용 (END)

`AccountMainScreen`이 과거에 `HomeTabScreen`을 반환하던 구조
→ `HomeTabScreen` (하단탭)
→ 각 탭 Screen(거래/통계/달력/자산/고정비/ROOT)
→ (END)

---

# Change Log — INDEX 변경 기록(필수)

> 파일 이동/파일명 변경/라우트 변경/Args 변경/메인 흐름 변경 시 여기에 1줄이라도 남기기

> 자동화 안내: 로컬에서 Git hooks를 활성화하려면
> 1) git config core.hooksPath .githooks
> 2) 이후부터 변경이 있을 때 `tools/INDEX_CODE_FEATURES.md`를 반드시 함께 수정해야 커밋이 통과합니다.

- 2025-12-27 요약: `차트 > 지출그래프(enhancedChart)` 기능을 UI/라우트/아이콘/코드/테스트/문서까지 “흔적 포함” 완전 제거. (추가로 Windows release 빌드에서 lint 캐시 file-lock로 실패하던 문제는 release lint 비활성으로 회피)
- 2025-12-27 요약: 지적재산권(IP)/오픈소스 라이선스 점검을 문서화하고, 로컬 Pub 캐시의 `LICENSE*` 파일을 스캔해 `docs/THIRD_PARTY_LICENSES_SUMMARY.md`를 자동 생성하는 스크립트를 추가.
- 2025-12-27 요약: IP 점검 근거 파일들의 무결성(SHA-256) 해시 로그를 생성하는 스크립트/산출물 추가.
- 2025-12-27 요약: 출시 전(또는 대량 수정 후) IP 재조사를 원클릭으로 실행하는 `tools/ip_recheck.ps1` 추가(라이선스 요약+해시+INDEX 검증/내보내기).



| Date | What changed | Old | New | Note |
|---|---|---|---|---|
| 2025-12-29 | Account name: locale suffix 강제(EN/JP/KR) + 복원은 새 계정만 | 계정 생성/복원 시 사용자가 입력한 이름 그대로 저장될 수 있고, 일부 복원 흐름은 덮어쓰기/혼합 위험이 존재 | 계정명 입력 UI 아래에 suffix 강제 삽입 안내/최종 계정명 프리뷰 표시 + 저장/복원 시 `AccountNameLanguageTag.applyForcedSuffix`로 계정명에 suffix 강제. 복원은 `importAccountDataAsNew`만 사용하도록 화면/호출 경로를 새 계정 복원으로 통일 | Why=언어/계정 경계를 명확히 하고 데이터 혼합(덮어쓰기) 위험 감소; Verify=flutter analyze --no-fatal-infos; Risk=계정명 suffix로 인해 동일 baseName의 계정이 분리됨(의도); Files=lib/utils/account_name_language_tag.dart, lib/screens/account_create_screen.dart, lib/screens/root_account_manager_page.dart, lib/screens/backup_screen.dart, lib/screens/trash_screen.dart, lib/services/backup_service.dart, DOCUMENTATION/WORK_LOG_2025-12-29_account_language_tag_and_new_account_only_restore.md, DOCUMENTATION/INDEX.md |
| 2025-12-29 | 2025-12-29 식구 구성 추 |  |  | Files=.analyze_output.txt, .vscode/tasks.json, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, SECURITY_GUIDE.md, android/app/build.gradle.kts, android/app/src/main/AndroidManifest.xml, android/app/src/main/kotlin/com/example/vccode1/MainActivity.kt, ios/Runner/Info.plist, lib/database/app_database.dart, lib/database/app_database.g.dart, lib/main.dart, lib/models/asset.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_home_screen.dart, lib/screens/account_main_screen.dart, lib/screens/account_select_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_allocation_screen.dart, lib/screens/asset_dashboard_screen.dart, lib/screens/asset_detail_screen.dart, lib/screens/asset_input_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_simple_input_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/backup_screen.dart, lib/screens/budget_status_screen.dart, lib/screens/calendar_screen.dart, lib/screens/category_stats_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/feature_icons_catalog_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/income_split_status_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/savings_plan_search_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/theme_settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/app_icon_service.dart, lib/services/backup_service.dart, lib/services/chart_data_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/theme/app_colors.dart, lib/theme/app_theme.dart, lib/utils/asset_dashboard_utils.dart, lib/utils/constants.dart, lib/utils/expense_graph_icons.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24.stats_reset, lib/utils/period_utils.dart, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/snackbar_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/comparison_widgets.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/filterable_chart_widget.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/investment_recommendation_dialog.dart, lib/widgets/month_end_carryover_dialog.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, macos/Flutter/GeneratedPluginRegistrant.swift, pubspec.lock, pubspec.yaml, test/feature_icons_page5_count_test.dart, test/models/transaction_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_menu_test.dart, test/screens/account_main_move_icon_test.dart, test/services/transaction_service_test.dart, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1, windows/flutter/generated_plugins.cmake, tools/INDEX_CODE_FEATURES.md |
| 2025-12-27 | 2025-12-27 라라이센스 초안작성 버전 |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, SECURITY_GUIDE.md, android/app/build.gradle.kts, lib/database/app_database.dart, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/feature_icons_catalog_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/theme_settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/chart_data_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/theme/app_colors.dart, lib/theme/app_theme.dart, lib/utils/constants.dart, lib/utils/expense_graph_icons.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24.stats_reset, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/comparison_widgets.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/filterable_chart_widget.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_move_icon_test.dart, tools/INDEX_CODE_FEATURES.md, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1 |
| 2025-12-27 | 2025-12.27 라이센스 문서의존성 추가버전 |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, SECURITY_GUIDE.md, android/app/build.gradle.kts, lib/database/app_database.dart, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/feature_icons_catalog_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/theme_settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/chart_data_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/theme/app_colors.dart, lib/theme/app_theme.dart, lib/utils/constants.dart, lib/utils/expense_graph_icons.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24.stats_reset, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/comparison_widgets.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/filterable_chart_widget.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_move_icon_test.dart, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1, tools/INDEX_CODE_FEATURES.md |
| 2025-12-27 | 2025-12-27지적재산권 조사 서명란추가 |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, SECURITY_GUIDE.md, android/app/build.gradle.kts, lib/database/app_database.dart, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/feature_icons_catalog_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/theme_settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/chart_data_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/theme/app_colors.dart, lib/theme/app_theme.dart, lib/utils/constants.dart, lib/utils/expense_graph_icons.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24.stats_reset, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/comparison_widgets.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/filterable_chart_widget.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_move_icon_test.dart, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1, tools/INDEX_CODE_FEATURES.md |
| 2025-12-27 | 2025-12-27지적재산권 권 조사 층 기 |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, SECURITY_GUIDE.md, android/app/build.gradle.kts, lib/database/app_database.dart, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/feature_icons_catalog_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/theme_settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/chart_data_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/theme/app_colors.dart, lib/theme/app_theme.dart, lib/utils/constants.dart, lib/utils/expense_graph_icons.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24.stats_reset, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/comparison_widgets.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/filterable_chart_widget.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_move_icon_test.dart, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1, tools/INDEX_CODE_FEATURES.md |
| 2025-12-27 | 2025-12-27License |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, SECURITY_GUIDE.md, android/app/build.gradle.kts, lib/database/app_database.dart, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/feature_icons_catalog_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/theme_settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/chart_data_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/theme/app_colors.dart, lib/theme/app_theme.dart, lib/utils/constants.dart, lib/utils/expense_graph_icons.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24.stats_reset, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/comparison_widgets.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/filterable_chart_widget.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_move_icon_test.dart, tools/INDEX_CODE_FEATURES.md, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1 |
| 2025-12-27 | 2025-12-27License Files |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, SECURITY_GUIDE.md, android/app/build.gradle.kts, lib/database/app_database.dart, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/feature_icons_catalog_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/theme_settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/chart_data_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/theme/app_colors.dart, lib/theme/app_theme.dart, lib/utils/constants.dart, lib/utils/expense_graph_icons.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24.stats_reset, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/comparison_widgets.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/filterable_chart_widget.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_move_icon_test.dart, tools/INDEX_CODE_FEATURES.md, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1 |
| 2025-12-27 | y |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, SECURITY_GUIDE.md, android/app/build.gradle.kts, lib/database/app_database.dart, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/feature_icons_catalog_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/theme_settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/chart_data_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/theme/app_colors.dart, lib/theme/app_theme.dart, lib/utils/constants.dart, lib/utils/expense_graph_icons.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24, lib/utils/main_feature_icon_catalog.dart.bak_2025-12-24.stats_reset, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/comparison_widgets.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/filterable_chart_widget.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_move_icon_test.dart, tools/INDEX_CODE_FEATURES.md, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1 |
| 2025-12-27 | 2025-12-27지출그래프 삭제 |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, lib/database/app_database.dart, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/feature_icons_catalog_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/theme_settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/theme/app_colors.dart, lib/theme/app_theme.dart, lib/utils/constants.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_move_icon_test.dart, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1, tools/INDEX_CODE_FEATURES.md |
| 2025-12-27 | 2025-12-27통계 -입력통계 삭제 |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, lib/database/app_database.dart, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/feature_icons_catalog_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/theme_settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/theme/app_colors.dart, lib/theme/app_theme.dart, lib/utils/constants.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_move_icon_test.dart, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1, tools/INDEX_CODE_FEATURES.md |
| 2025-12-27 | 2025-12-27테마 10 |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, lib/database/app_database.dart, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/feature_icons_catalog_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/theme_settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/theme/app_colors.dart, lib/theme/app_theme.dart, lib/utils/constants.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_move_icon_test.dart, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1, tools/INDEX_CODE_FEATURES.md |
| 2025-12-27 | 2025-12-27테마10개 |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, lib/database/app_database.dart, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/feature_icons_catalog_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/theme_settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/theme/app_colors.dart, lib/theme/app_theme.dart, lib/utils/constants.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_move_icon_test.dart, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1, tools/INDEX_CODE_FEATURES.md |
| 2025-12-27 | 2025.12.27 DB.FTS |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, lib/database/app_database.dart, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/utils/constants.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_move_icon_test.dart, tools/SSOT_QUALITY_GATE.md, tools/quality_gate.ps1, tools/INDEX_CODE_FEATURES.md |
| 2025-12-27 | 2025.12.27 |  |  | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/utils/constants.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_move_icon_test.dart, tools/INDEX_CODE_FEATURES.md |
| 2025-12-26 | 마트명 병합/정리(별칭→대표명 매핑) |  | 계정별 store alias→canonical 매핑 + 관리 화면 + 통계/쇼핑/메모 추천 대표명 resolve + 백업 포함 | Why=동일 마트의 여러 표기를 통합해 통계·추천 품질 개선; Verify=Quality Gate: flutter analyze + flutter test + INDEX validate/export; Risk=Low (prefs 매핑만 추가, resolve는 순환/깊이 제한으로 안전); Tests=flutter test; Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/backup_service.dart, lib/services/transaction_service.dart, lib/services/user_pref_service.dart, lib/utils/constants.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/pref_keys.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, test/models/transaction_test.dart, test/screens/account_main_move_icon_test.dart, tools/INDEX_CODE_FEATURES.md |
| 2025-12-26 | Daily transactions: 카드결제금액 칸 + 금액 비교 표시 / 1줄 간편지출 입력 → 거래추가 연결 / 카테고리 상세 표기 통일 / 헤더 글자 크기 조정 |  | 카드결제금액(선택) 저장 + 일일내역(가로) 카드금액 컬럼 및 mismatch 강조. “간편 지출 입력(1줄)” 별도 화면에서 파싱 후 거래추가 화면으로 seed 전달. 카테고리 상세 구분자 `·` 통일(간단 표기 유지). 일일 헤더 지출금액 글자 크기=날짜. | Files=.analyze_output.txt, ACTION_ITEMS_2025-12-06.md, APP_FEATURES_GUIDE.md, DOCUMENTATION/INDEX.md, DOCUMENTATION/SLOT_COUNT.md, REFACTORING_CHECKLIST.md, lib/main.dart, lib/models/transaction.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/account_main_screen.dart, lib/screens/account_stats_screen.dart, lib/screens/asset_list_screen.dart, lib/screens/asset_tab_screen.dart, lib/screens/calendar_screen.dart, lib/screens/chart_detail_screen.dart, lib/screens/daily_transactions_screen.dart, lib/screens/enhanced_chart_screen.dart, lib/screens/food_expiry_main_screen.dart, lib/screens/home_tab_screen.dart, lib/screens/icon_management_screen.dart, lib/screens/income_split_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_account_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/root_search_screen.dart, lib/screens/root_transaction_manager_screen.dart, lib/screens/settings_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/screens/shopping_cart_screen.dart, lib/screens/top_level_main_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/transaction_detail_screen.dart, lib/services/user_pref_service.dart, lib/utils/icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/stats_view_utils.dart, lib/utils/top_level_stats_utils.dart, lib/utils/weather_capture_utils.dart, lib/widgets/asset_move_dialog.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/in_app_screen_saver.dart, lib/widgets/root_summary_card.dart, lib/widgets/root_transaction_list.dart, lib/widgets/search_bar_widget.dart, lib/widgets/state_placeholders.dart, lib/widgets/user_account_auth_gate.dart, lib/widgets/user_pin_gate.dart, tools/INDEX_CODE_FEATURES.md |
| 2025-12-25 | ShoppingCart: 빠른 체크(탭) + 다음 항목 유지 + 상점별 기본값 | 장바구니에서 체크/해제 흐름이 “확인 팝업” 중심이면 현장 사용(마트)에서 느릴 수 있고, 카테고리 자동 추천 실패 시 매번 수동 선택이 필요 | 장바구니 품목 탭/체크로 즉시 체크/해제(빠른 UX) + 체크 항목은 아래로 정리 + 다음 미구매 항목이 보이도록 스크롤 포커스 유지. 빠른 거래 화면에서 카테고리 추천이 기본값이면 최근/상점별 마지막 카테고리를 자동 적용하고, 메모 `마트명 · ...` 입력 시 상점별 결제수단/카테고리 기본값을 불러옴. APP_FEATURES_GUIDE 쇼핑/반품 설명 업데이트 | Verify=flutter analyze --no-fatal-infos; Tests=flutter test test/widget_test.dart; Files=lib/screens/shopping_cart_screen.dart, lib/screens/shopping_cart_quick_transaction_screen.dart, lib/services/user_pref_service.dart, APP_FEATURES_GUIDE.md |
| 2025-12-25 | AccountStats restore + refund switches; analyze/test/build | `account_stats_screen.dart` corrupted(중복 코드/중간 import)로 format/analyze 실패, `TransactionType.refund` switch 누락, `directives_ordering` 발생 | `account_stats_screen.dart` 복원 + `refund` 케이스 처리 + import 정렬, Quality Gate OK, release APK 생성 | Verify=Quality Gate OK; Build=flutter build apk; Artifact=build/app/outputs/flutter-apk/app-release.apk; Files=lib/screens/account_stats_screen.dart, lib/screens/daily_transactions_screen.dart, DOCUMENTATION/WORK_LOG_2025-12-25_account_stats_restore_and_quality_gate.md, DOCUMENTATION/INDEX.md, TODO.md |
| 2025-12-23 | Icon management: 1페이지 하단 4칸 제한 제거(전체 12칸 배치) | 1페이지 편집이 “하단 4칸(8~11)” + allowlist 기반으로 동작하여, 2페이지/하단 포함 전체 영역 배치 요구를 충족하지 못함 | 아이콘 관리 화면에서 페이지별 슬롯 편집을 항상 12칸 전체 그리드로 통일(페이지 1/2 포함). page1 전용 하단-슬롯 모드/allowlist/정규화 강제 로직 제거. 단, 예약 페이지 정책(통계/자산/ROOT/설정)은 유지 | Playbook=AccountMainScreen; Why=페이지 하단 공간 낭비/배치 제약 해소(테스트 가능); Risk=Low(편집 UX/제약 로직 변경); Verify=flutter analyze --no-fatal-infos; Validate INDEX format; Export INDEX; Tests=flutter test test/screens/account_main_icon_picker_test.dart test/screens/account_main_move_icon_test.dart test/screens/account_main_screen_slots_test.dart; Files=lib/screens/icon_management_screen.dart; tools/INDEX_CHILD.md; tools/INDEX_CODE_FEATURES.md |
| 2025-12-23 | Reserved pages: 아이콘 소스/자동 채움 정합성 강화 | 예약 페이지(특히 ROOT/설정)에서 카탈로그 인덱스/정규화 불일치로 아이콘이 비어 보이거나 사라질 수 있었음 | 예약 페이지는 “페이지 인덱스”가 아니라 “모듈 아이콘 리스트(Stats/Asset/ROOT/Settings)”를 SSOT로 사용하도록 보정하고, 예약 페이지가 비면 best-effort 자동 채움(표시/테스트 가능). 정책도 강화: 자산은 6~7 고정, ROOT는 8~9 전용, 설정은 10 전용 | Playbook=AccountMainScreen; Why=예약 페이지 공백/아이콘 실종 방지 + 정책 고정; Risk=Low(초기 로드 시 슬롯 정규화/자동 채움); Verify=flutter analyze --no-fatal-infos; Validate INDEX format; Export INDEX; Tests=flutter test test/screens/account_main_icon_picker_test.dart test/screens/account_main_move_icon_test.dart test/screens/account_main_screen_slots_test.dart; Files=lib/screens/account_main_screen.dart; tools/INDEX_CHILD.md; tools/INDEX_CODE_FEATURES.md |
| 2025-12-23 | Stats screens: 가로화면 1줄 요약(텍스트) 확장 적용 | 통계/검색/상세 목록 화면에서 가로에서도 ListTile(2줄/세로 중심)이라 정보 밀도가 낮음 | landscape에서 목록 행을 `Row + Expanded + ellipsis` 기반 1줄 표 형태로 렌더(필요 시 헤더 1줄 추가), portrait는 기존 유지 | Why=가로에서 스캔/열람 속도 개선; Risk=Very Low(UI만); Verify=flutter analyze --no-fatal-infos; flutter test; Files=lib/screens/category_stats_screen.dart, lib/screens/monthly_stats_screen.dart, lib/screens/fixed_cost_stats_screen.dart, lib/screens/period_detail_stats_screen.dart, lib/screens/account_stats_screen.dart |
| 2025-12-23 | ZeroQuickButtons: append 커서 위치 안정화 | 천단위 포맷(formatThousands) 사용 시, 끝에 0을 추가해도 포맷 결과 길이가 달라져 커서가 끝에 남지 않을 수 있음. 또한 사용하지 않는 context 인자가 존재 | 끝에 붙이는 경우(insert at end) 커서를 항상 `nextText.length`로 유지하여 입력 흐름을 안정화, unused `BuildContext` 파라미터 제거 | Why=숫자 입력 UX 안정화; Risk=Very Low(위젯 내부만); Verify=flutter analyze --no-fatal-infos; flutter test; Files=lib/widgets/zero_quick_buttons.dart |
| 2025-12-23 | ZeroQuickButtons: 앱 전역 제거 | 숫자 입력 시 0/00/000 버튼이 여러 화면에서 노출되며, 특히 장바구니처럼 목록이 길 때 키보드/입력 UI와 겹쳐 스크롤/입력이 어려울 수 있음 | `ZeroQuickButtons` 사용을 적용된 곳 모두 제거(0/00/000 빠른 입력 UI 미노출). 장바구니는 인라인 입력 중에도 스크롤 가능 + 키보드 인셋을 고려해 하단 패딩 추가 | Why=목록이 길 때도 입력 가능(가림/조작 불가 방지); Risk=Low(UX 변경: 빠른 입력 버튼 제거); Verify=Quality Gate (analyze + test + INDEX); Files=lib/screens/shopping_cart_screen.dart, lib/widgets/root_auth_gate.dart, lib/screens/asset_tab_screen.dart, lib/screens/transaction_detail_screen.dart, lib/screens/transaction_add_screen.dart, lib/screens/account_stats_screen.dart, lib/widgets/month_end_carryover_dialog.dart, lib/widgets/emergency_fund_transfer_dialog.dart, lib/widgets/asset_move_dialog.dart, lib/screens/asset_input_screen.dart, lib/screens/asset_simple_input_screen.dart, lib/screens/emergency_fund_list_screen.dart, lib/screens/emergency_fund_screen.dart, lib/screens/fixed_cost_tab_screen.dart, lib/screens/income_add_form.dart, lib/screens/income_input_screen.dart, lib/screens/income_split_screen.dart, lib/screens/savings_plan_form_screen.dart |
| 2025-12-23 | TrashScreen: 가로화면 1줄 요약(헤더+Row) 적용 | 휴지통 리스트가 가로에서도 2줄(계정/삭제시각 줄바꿈)로 표시되어 스캔 효율이 낮음 | landscape에서 `항목/계정/삭제 시각`을 1줄 Row로 표시하고, 상단에 열 제목 1줄을 추가(세로 화면은 기존 유지) | Why=가로에서 빠른 스캔; Risk=Very Low(UI만); Verify=flutter analyze --no-fatal-infos; flutter test; Files=lib/screens/trash_screen.dart |
| 2025-12-23 | AssetListScreen: 가로화면 1줄 요약(헤더+Row) 적용 | 자산 목록이 가로에서도 2줄(메모/손익/금액) 중심이라 목록 스캔 효율이 낮음 | landscape에서 `자산/손익/금액/타입`을 1줄 Row로 표시하고, 상단에 열 제목 1줄을 추가(세로 화면은 기존 유지) | Why=가로에서 빠른 스캔; Risk=Very Low(UI만); Verify=flutter analyze --no-fatal-infos; flutter test; Files=lib/screens/asset_list_screen.dart |
| 2025-12-23 | EmergencyFundListScreen: 가로화면 1줄 요약(헤더+Row) 적용 | 비상금 거래 리스트가 가로에서도 ListTile 중심이라 항목 스캔 효율이 낮음 | landscape에서 `설명/날짜/금액`을 1줄 Row로 표시하고, 상단에 열 제목 1줄을 추가(세로 화면은 기존 유지) | Why=가로에서 빠른 스캔; Risk=Very Low(UI만); Verify=flutter analyze --no-fatal-infos; flutter test; Files=lib/screens/emergency_fund_list_screen.dart |
| 2025-12-23 | RootTransactionManagerScreen: 가로화면 1줄 표(헤더+Row) 적용 | ROOT 거래관리 리스트가 가로에서도 ListTile(2줄) 중심이라 전체 거래를 빠르게 스캔하기 어려움 | landscape에서 `계정·내용/날짜/유형·결제/금액`을 1줄 Row로 표시하고, 상단에 열 제목 1줄 추가(세로 화면은 기존 유지) | Why=가로에서 빠른 스캔; Risk=Very Low(UI만); Verify=flutter analyze --no-fatal-infos; flutter test; Files=lib/screens/root_transaction_manager_screen.dart |
| 2025-12-23 | RootAccountScreen: 가로화면 1줄 표(헤더+Row) 적용 | ROOT 계정 관리 화면이 카드형 상세 레이아웃 중심이라 가로에서 계정 간 비교/스캔이 느림 | landscape에서 `계정/자산/월 수입/월 지출/거래/최근 거래`를 1줄 Row로 표시하고, 행 우측에 이동/삭제(옵션) 액션을 배치(세로 화면은 기존 카드 유지) | Why=가로에서 빠른 스캔/비교; Risk=Very Low(UI만); Verify=flutter analyze --no-fatal-infos; flutter test; Files=lib/screens/root_account_screen.dart |
| 2025-12-23 | ROOT/TopLevelStatsDetail: 가로화면 1줄 표(헤더+Row) 적용 | ROOT 전체 통계 상세 화면에서도 가로 최적화가 덜 되어, 항목 열람 시 스캔 효율이 낮음 | `TopLevelStatsDetailScreen`에서 주요 리스트(계정/상위 거래/고정비)를 landscape에서는 1줄 Row로 표시(필요 시 헤더 1줄), portrait는 기존 유지 | Why=가로에서 빠른 스캔; Risk=Very Low(UI만); Verify=flutter analyze --no-fatal-infos; flutter test; Files=lib/screens/top_level_main_screen.dart |
| 2025-12-23 | Policy: 통계/텍스트 화면은 가로화면(landscape) 적극 활용 | 화면별로 가로 최적화 기준이 없어서, 통계/텍스트 출력 화면 개선이 일관되지 않을 수 있음 | `CONTRIBUTING.md`에 “Landscape-first for text/stat screens” 정책을 추가: 가로에서 1줄 요약 Row/ellipsis/헤더 허용(필요 시 제거)/portrait 안정 유지/테마 토큰 재사용/검증 루틴 | Why=가독성/열람 속도 향상 방향을 정책으로 고정; Risk=None(문서); Verify=문서 변경; Files=CONTRIBUTING.md |
| 2025-12-23 | DailyTransactions: 가로화면 1줄 요약 + 헤더(열 제목) | 가로화면에서도 ListTile(2줄 구조)라 정보 밀도가 낮고, 자료 열람 시 스캔이 느림 | landscape에서 `상품명/카테고리/결제/메모/금액`을 1줄 Row로 표시하고, 상단에 열 제목 1줄을 추가(세로 화면은 기존 유지) | Why=가로 화면 가독성/열람 편의; Risk=Very Low(UI만); Verify=flutter analyze --no-fatal-infos; flutter test; Files=lib/screens/daily_transactions_screen.dart |
| 2025-12-23 | ShoppingCart: 가격 입력 유지 + 하단 총액(중앙) + 상단 탭 UI | 스크롤/화면 이동(리빌드) 시 인라인 가격 입력이 컨트롤러 동기화로 덮여 초기화될 수 있음. 하단바에 체크 개수만 표시되어 금액 확인이 불편. 상단 쇼핑준비/장바구니 토글이 크고 좌측 정렬(라운드/정렬 미흡) | (1) 인라인 `TextField` 입력 중에는 `_syncInlineControllers()`가 `controller.text`를 덮지 않도록 item별 `FocusNode` 기반으로 보호. (2) 하단 체크 요약바 1줄을 `체크 항목(좌) / 총액(중앙) / 체크 개수(우)`로 재배치하고 체크 항목 `unitPrice×qty` 합계를 표시. (3) 상단 모드 스위치 바를 더 작게/중앙정렬/4모서리 라운드 + 세그먼트 끝 라운드 + 구분선으로 정리, AppBar `centerTitle` 적용 | Why=입력값 초기화(UX 버그) 제거 + 체크 항목 총액 가시성 개선 + 상단 토글 UI 정돈; Risk=Low(표시/동기화 로직 변경); Verify=flutter analyze --no-fatal-infos; flutter test; flutter build apk; Quality Gate (analyze + test + INDEX); Files=lib/screens/shopping_cart_screen.dart, tools/INDEX_CHILD.md, tools/INDEX_CODE_FEATURES.md |
| 2025-12-22 | UX: 2페이지 전용 “10페이지 이동(설정)” 바로가기 아이콘 | 설정(10페이지) 접근이 페이지 스와이프/배너 탭에 의존하여, 2페이지 중심 사용자에게 불편할 수 있음 | 2페이지(0-based index=1)에만 배치 가능한 `shortcut_settings_page10` 아이콘을 추가하고, 탭 시 메인 화면을 10페이지(index=9)로 점프. 아이콘 관리/배치 규칙에서도 2페이지 외 배치 불가로 제한 | Why=2페이지 사용 빈도 높음 가정에서 설정 접근 비용 최소화; Risk=Low(배치 제한으로 혼란 방지); Verify=flutter analyze --no-fatal-infos; flutter test; Validate INDEX format (PowerShell); Files=lib/utils/main_feature_icon_catalog.dart, lib/screens/account_main_screen.dart, lib/screens/icon_management_screen.dart, tools/INDEX_CHILD.md, tools/INDEX_CODE_FEATURES.md |
| 2025-12-22 | Docs: 자산/ROOT 보안 + 백업/복원 암호 동작 설명 추가 | 설정/동작 설명이 코드 및 인덱스 검색 단서에만 있고, 사용자 관점의 “암호 설정/복원 흐름” 문서가 분산되어 있음 | `SECURITY_GUIDE.md`에 (1) 자산 보안(기기 인증) 설정/자동잠금(1분) (2) ROOT 통합/별도 모드 동작 (3) 백업 암호화/2단계 옵션 및 백업/복원 시 암호 입력 규칙을 정리. BACKUP_INSTRUCTIONS에 링크 및 “암호화 ON 시 자동 백업 스킵” 안내 추가 | Why=요청사항(동작설명) 문서화 + 운영 혼란 감소; Risk=None(문서만); Verify=Validate INDEX format (PowerShell); Files=SECURITY_GUIDE.md, BACKUP_INSTRUCTIONS.md, tools/INDEX_CHILD.md, tools/INDEX_CODE_FEATURES.md |
| 2025-12-22 | ROOT 보안: 통합/별도(유저 선택) + ROOT 화면에서 인증 역할 분리 | (1) ROOT 접근 제어가 옵션으로 정의되어 있지 않거나, 라우팅 레벨에서 일괄로 처리되어 화면 책임이 불명확해질 수 있음 | (1) 자산 보안 ON일 때 ROOT 인증 모드를 `PrefKeys.rootAuthMode`로 선택: `integrated`(자산 인증 세션과 통합) vs `separate`(자산 인증 + ROOT 추가 인증). (2) 인증 적용은 라우터가 아닌 ROOT 화면 내부에서 `RootAuthGate`로 감싸 역할 분리(화면이 책임) | Why=유저 선택권(편의 vs 보안) 제공 + ROOT 인증 책임을 ROOT 화면으로 분리; Risk=Low(기본은 기존 흐름에 가깝게, 실패 시 재시도 UI); Verify=flutter analyze --no-fatal-infos; flutter test; Validate INDEX format (PowerShell); Files=lib/utils/pref_keys.dart, lib/screens/asset_tab_screen.dart, lib/widgets/root_auth_gate.dart, lib/screens/root_*.dart, lib/navigation/app_router.dart, tools/INDEX_CHILD.md, tools/INDEX_CODE_FEATURES.md |
| 2025-12-22 | Backup/Restore: 암호화 + 2단계(옵션) 백업 화면 내 설정 | 백업 보호 옵션이 단일 스위치(2중 인증) 중심으로 동작하며, “암호화”와 “기기 인증 추가(2단계)”를 분리해서 선택하기 어려움 | 백업 화면에서 (1) `backupEncryptionEnabled`(암호화)와 (2) `backupTwoFactorEnabled`(기기 인증 추가)을 분리. 2단계는 암호화 ON일 때만 선택 가능. 복원은 “암호화 파일”인 경우에만 암호 입력(필수) + 2단계 ON이면 기기 인증을 추가로 요구 | Why=유저 선택권(암호화만/암호화+기기인증) 제공 + 복원 흐름 직관화; Risk=Low(기본 OFF, 기존 2FA ON은 암호화 ON으로 자동 승격); Verify=flutter analyze --no-fatal-infos; Files=lib/screens/backup_screen.dart, lib/services/backup_service.dart, lib/utils/pref_keys.dart, tools/INDEX_CHILD.md |
| 2025-12-22 | Policy: 예약 모듈 아이콘 자동 재배치 | 예약(통계/자산/ROOT/설정) 아이콘이 다른 페이지 슬롯에 남아있을 수 있음 | AccountMainScreen 진입 시 예약 모듈 아이콘을 정책 페이지로 best-effort 이동. 단, 자산/수입 아이콘은 자산 잠금(암호/생체) ON + (허용 옵션/세션 unlock로 bypass 없음)일 때만 강제 이동(그 외에는 사용자 배치 유지). 빈 슬롯 우선, 가득 차면 드롭 없음 | Why=정책 위반 배치 자동 정리(사용자 혼란 감소) + 자산 잠금 조건 존중; Risk=Low(조건 충족 시에만 이동, full이면 유지); Verify=flutter analyze --no-fatal-infos; Files=lib/screens/account_main_screen.dart, tools/INDEX_CODE_FEATURES.md |
| 2025-12-22 | Docs: 예약 페이지(4~10) 정책 기록 | 정책이 코드에만 산재(account_main/icon_management) | tools/INDEX_CHILD.md에 4~10 페이지 예약 정책(통계/자산/ROOT/설정)과 0-based 인덱스 매핑을 명시 | Why=페이지 정책(4~10) 빠른 확인/검색; Verify=Validate INDEX format (PowerShell); Files=tools/INDEX_CHILD.md, tools/INDEX_CODE_FEATURES.md |
| 2025-12-21 | SCRATCHPAD 설계 기반 Smart Ledger 유틸리티 생성 | 없음 (설계만 존재) | 4가지 유틸리티 추가: WeatherCaptureUtils (날씨 수집), ShoppingWorkflowUtils (쇼핑 3단계), MarketAnalysisUtils (분석/통계), SmartLedgerIntegrationUtils (통합). lib/utils/에 저장 | Why=재사용 가능한 모듈화 + 향후 기능 확장 기반; Verify=flutter test (100 passed); Files=lib/utils/weather_capture_utils.dart, lib/utils/shopping_workflow_utils.dart, lib/utils/market_analysis_utils.dart, lib/utils/smart_ledger_integration_utils.dart |
| 2025-12-21 | 거래 입력: 날씨 기능 완전 제거 | 거래 추가 화면에 날씨 입력(자동/수동) + 저장 포함 | 날씨 관련 UI, 상태 변수, OpenWeather API 통합, 자동 날씨 버튼, 저장 시 weather 필드 등 모두 제거. 단순화 | Why=복잡도 감소 + 화면 단순화; Verify=flutter analyze; Tests=flutter test (100 passed); Files=lib/screens/transaction_add_screen.dart |
| 2025-12-21 | 거래 입력 UX: 날씨·저장 버튼 정리 + 쇼핑 화면 타이틀 간소화 | 날씨(선택) 텍스트 + 자동 날씨 버튼(상단). 저장 버튼 아이콘=영수증. 쇼핑 화면 AppBar에 계정명+모드 표시(2줄). 자동 날씨 아이콘 없음(또는 상단에만 있음) | 날씨(선택) 텍스트 제거. 자동 날씨 아이콘(위치 표시)을 카테고리 섹션 아래·저장 버튼 위로 이동(보기모드 아이콘만). 저장 버튼 아이콘="+" 기호(추가 의미 강화) + 색상 진하게(alpha=220). 쇼핑준비/장바구니 화면의 AppBar는 모드명만 표시(계정명 숨김, 기본 타이틀 크기). 쇼핑 준비 모드에서만 쇼핑 준비 버튼 노출(장바구니 모드에서는 숨김). 거래 추가 폼 ListView bottom padding 추가(SafeArea height 계산) | Why=화면 노이즈 감소(텍스트 제거) + 버튼 배치 명확화(하단으로 이동) + 아이콘 의도 강화(+ 기호) + 모드 표시 간소화(모드명만) + 오조작 방지(쇼핑준비 모드 경계); Verify=flutter analyze; Tests=flutter test; Files=lib/screens/transaction_add_screen.dart, lib/screens/shopping_cart_screen.dart |
| 2025-12-21 | 거래 입력: 자동 날씨 버튼(왼쪽) 추가 | 지출 입력 시 날씨는 수동 선택/기온 수동 입력만 가능 | 거래 추가 화면(지출)에 `자동 날씨` 버튼을 왼쪽에 추가하여 위치 권한 → OpenWeatherMap 조회 → 날씨/기온 자동 채움. `OPENWEATHER_API_KEY`는 `--dart-define`로 주입. Android 위치 권한 및 geolocator 의존성 추가 | Why=입력 편의/데이터 품질 향상; Risk=API 키/위치 권한 필요; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/transaction_add_screen.dart, android/app/src/main/AndroidManifest.xml, pubspec.yaml |
| 2025-12-21 | 거래: 날씨 스냅샷 확장(예측/알림 기반) | `weather`는 condition/tempC/source만 저장 | WeatherSnapshot에 capturedAt/대략 lat-lon/feelsLikeC/humidityPct/windSpeedMs/precipitation1hMm를 optional로 추가하고, 자동 날씨(OpenWeatherMap)에서 값 채워 저장 | Why=가격 변동폭/상승 감지 분석에 필요한 기상 변수 확보; Verify=flutter analyze; Tests=flutter test; Files=lib/models/weather_snapshot.dart, lib/screens/transaction_add_screen.dart |
| 2025-12-21 | (DUPLICATE) 거래: 날씨 스냅샷 확장(예측/알림 기반) | - | - | Duplicate row kept for history (see previous row). |
| 2025-12-21 | 거래: 가격 상승 감지 알림(+10%) | 저장 시 가격 상승 경고 없음 | 지출 저장 시 동일 품목(설명 기준) 최근 20건 단가 중앙값 대비 +10% AND +100원 이상 상승이면 저장 전 확인 다이얼로그 표시(취소/계속 저장) | Why=사용자에게 즉시 ‘가격 상승’ 정보 제공; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/transaction_add_screen.dart |
| 2025-12-21 | 메인: 편집모드 드래그는 현재 페이지에서만 + 배너 자동 추적 | 아이콘 이동(편집) 중 드래그/스와이프가 겹치면 옆 페이지로 넘어가 아이콘이 다른 페이지로 이동하는 듯한 오조작 발생. 상단 배너는 페이지 이동 시 현재 탭이 화면 밖에 있을 수 있음 | 편집모드 진입 시 현재 페이지의 `PageView` 스와이프를 잠금하여 아이콘 이동은 “해당 페이지 안에서만” 수행. 배너는 번호만 표시하며, 페이지 이동 시 현재 탭이 보이도록 자동 스크롤(ensureVisible) | Why=오조작(페이지 넘어감) 방지 + 현재 위치 가시성 개선; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart, lib/widgets/page_banner_bar.dart |
| 2025-12-21 | 메인: 15페이지까지 이동 가능(불일치 수정) | AccountMainScreen의 `_pageCount`가 8로 고정되어 9페이지 이상으로 이동 불가. (prefs/아이콘 카탈로그는 15페이지 기준) | AccountMainScreen의 페이지 수를 `MainFeatureIconCatalog.pageCount(15)`로 정렬하고, 저장된 pageNames 길이가 다르면 15개로 자동 보정(기존 이름 유지 + 부족분 기본값 채움) | Why=메인/아이콘관리/저장소(pageCount=15) 정합성 확보; Risk=Low(페이지 수 증가); Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-21 | 거래: 가격정보와 함께 날씨 스냅샷 저장(선택) | 거래 JSON에 날씨 필드 없음 | Transaction에 `weather`(condition/tempC/source) 옵션 필드 추가 + 거래 추가 화면(지출)에 날씨/기온 입력 추가 | Why=가격/소비 패턴과 날씨 상관 분석 기반 마련; Verify=Quality Gate (analyze + test + INDEX); Files=lib/models/weather_snapshot.dart, lib/models/transaction.dart, lib/screens/transaction_add_screen.dart |
| 2025-12-21 | 통계: 식비 최저월(최근 1년 가격 시즌성) 화면/라우트/아이콘 추가 | 없음(유틸만 있거나 기능이 노출되지 않음) | 품목명 입력 → 최근 1년 식비 거래(unitPrice) 기준으로 최저월(중앙값) 산출 화면 추가 + `/stats/shopping/cheapest-month` 라우트 및 통계 페이지 아이콘 등록 | Why=사용자가 체감 가능한 통계(시기) 제공; Verify=Quality Gate (analyze + test + INDEX); Files=lib/utils/shopping_price_seasonality_utils.dart, lib/screens/shopping_cheapest_month_screen.dart, lib/navigation/app_routes.dart, lib/navigation/app_router.dart, lib/utils/main_feature_icon_catalog.dart |
| 2025-12-21 | ShoppingCart: 리스트/상단 입력/하단 액션 단순화 + 쇼핑 준비 utils 분리 | 미리/현장 토글 및 문구가 존재, 행 UI가 복잡(부가 정보/정렬 포함), 쇼핑 준비(템플릿/복원/추천) 로직이 화면에 포함, 삭제는 즉시 수행 | 토글/문구 삭제(단일 모드), 행은 체크+물품명+거래추가+삭제(확인)만 유지, 상단 입력(AppBar.bottom) 고정, 하단 고정바(합계+체크 일괄 가계부 입력) 적용, 쇼핑 준비 흐름을 `ShoppingCartNextPrepUtils.run(...)`로 위임 | Why=화면/오조작(삭제) 리스크 감소 + 코드 책임 분리; Verify=flutter analyze --no-fatal-infos; Tests=flutter test; Files=lib/screens/shopping_cart_screen.dart, lib/utils/shopping_cart_next_prep_utils.dart, lib/utils/shopping_cart_next_prep_dialog_utils.dart, lib/utils/shopping_cart_bulk_ledger_utils.dart |
| 2025-12-21 | 쇼핑 준비: 전용 아이콘 + 2페이지(구매) 기본 표시 | 쇼핑 준비는 장바구니 화면 내부 버튼으로만 접근 | `AppRoutes.shoppingPrep` 추가(장바구니 진입 후 자동으로 쇼핑 준비 실행), 메인 2페이지(구매)에 `shoppingPrep` 아이콘을 카탈로그로 제공, 매뉴얼 문서 추가 | Why=원포인트 접근(아이콘 1개) + 기능 보관/재활용; Verify=flutter analyze --no-fatal-infos; Files=lib/navigation/app_routes.dart, lib/navigation/app_router.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/icon_launch_utils.dart, lib/screens/shopping_cart_screen.dart, UTILS_FEATURE_SHOPPING_PREP.md |
| 2025-12-21 | Dev tooling: 80자 초과 라인 체크 자동화 | long line 점검이 수동 검색(Select-String) 의존 | `tools/check_long_lines.ps1` 추가 + VS Code task(`Check long lines (lib dart >80)`)로 1클릭 검증 | Why=80자 규칙(ignored 불가)을 빠르게 보장; Verify=pwsh tools/check_long_lines.ps1 OK; Quality Gate OK; Files=tools/check_long_lines.ps1, .vscode/tasks.json, tools/README.md |
| 2025-12-21 | Find-only INDEX: Parent/Child + 즉시 오픈 동선 | 인덱스 접근이 단일 문서/수동 탐색에 의존 | `tools/INDEX_PARENT.md`(빠른 지도) + `tools/INDEX_CHILD.md`(검색 단서) 2단계로 분리, `tools/open_find_indexes.ps1` 및 VS Code task로 즉시 열기 | Why=검색 범위를 10초 내 결정; Verify=Quality Gate OK; Files=tools/INDEX_PARENT.md, tools/INDEX_CHILD.md, tools/open_find_indexes.ps1, .vscode/tasks.json, tools/README.md |
| 2025-12-21 | Icon management: 카탈로그를 파트(페이지)별로 모두 표시 | 하단 카탈로그가 단일 목록/그리드로만 표시되어 “어느 페이지(파트) 아이콘인지” 구분이 어려움 | 하단 카탈로그를 카탈로그 페이지(파트)별 섹션으로 나눠 전체 아이콘을 표시(페이지별 타이틀 포함) | Why=아이콘이 생성된 파트를 기준으로 빠르게 찾기; Verify=flutter analyze; (next) Quality Gate (analyze + test + INDEX); Files=lib/screens/icon_management_screen.dart |
| 2025-12-21 | Icon management: 기본 필터/표기 보수적 롤백 | 기본 필터가 ‘전체’로 시작 + 섹션명이 기능명(구매/수입/통계 등) 혼재 | 기본 필터는 ‘미배치만’(기존)으로 시작/리셋, 섹션 타이틀은 ‘1~15페이지’ 숫자형으로 통일 | Why=기존 UX 유지 + 용어 의존 제거(출시 안정성); Verify=flutter analyze; (next) Quality Gate (analyze + test + INDEX); Files=lib/screens/icon_management_screen.dart |
| 2025-12-21 | Reorder: Stats/Asset/Settings icon priority | Stats started with Calendar; Asset started with AssetTab; Settings started with language/currency | Stats starts with Stats/Decade/Search/Chart; Asset starts with Dashboard; Settings starts with IconMgmt/Backup/Privacy | Playbook=AccountMainScreen; Why=2단계(재배치): 자주 쓰는 기능을 페이지 상단 우선 배치; Verify=flutter analyze; flutter test; Risk=Low: only affects default prefill order when slots are empty; Tests=flutter analyze OK; flutter test OK; Files=lib/utils/main_feature_icon_catalog.dart |
| 2025-12-21 | Reorder: Page1 quick actions | Page1 had budget/detail + placeholders; add icons lived in purchase/income pages | Page1 shows TodaySpending + ExpenseAdd + IncomeAdd + ShoppingCart; duplicates removed from purchase/income | Playbook=AccountMainScreen; Why=2단계(재배치): 원포인트 핵심 기능을 1페이지 상단에 고정; Verify=flutter analyze; flutter test; Risk=Low: affects only default prefill when slots are empty; existing user slots stay; Tests=flutter analyze OK; flutter test OK; Files=lib/utils/main_feature_icon_catalog.dart, test/screens/account_main_move_icon_test.dart, test/screens/account_main_screen_slots_test.dart |
| 2025-12-21 | Smart Ledger 이식 완료: HomeTabScreen 완전 제거 확인 | HomeTabScreen(탭 기반 네비게이션) 및 5개 탭 화면(거래/통계/자산/고정비/ROOT) 사용 | AccountMainScreen(Smart Ledger 아이콘 그리드)로 완전 전환, 모든 기능이 페이지별 아이콘으로 접근 가능 | Why=탭 기반 → 아이콘 그리드 아키텍처 전환 완료, 기능 분산/모듈화; Verify=flutter analyze; Status=home_tab_screen.dart는 어디에서도 import되지 않음(이미 제거됨), home_tab_screen.dart.legacy, asset_entry_mode_screen.dart.legacy만 백업으로 남음; Files=lib/screens/account_main_screen.dart, lib/utils/main_feature_icon_catalog.dart |
| 2025-12-21 | AccountHomeScreen: 수입배분/예산 위젯 분리 및 개별 페이지 생성 | AccountHomeScreen에 통합되어 있던 수입 배분/예산 위젯(수입 배분 카드/예산 카드 + 관련 그래프/다이얼로그) | `lib/screens/income_split_status_screen.dart` 및 `lib/screens/budget_status_screen.dart` 신규 생성. `AccountHomeScreen`에서 해당 위젯을 제거하여 거래 내역 표시 중심으로 단순화(리팩토링). 인덱스에 Playbook/참조 추가 및 Change Log 기록 | Why=단일 책임 원칙 적용(화면 단순화) + Smart Ledger 아이콘 기반 접근성 개선; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/income_split_status_screen.dart, lib/screens/budget_status_screen.dart, lib/screens/account_home_screen.dart, tools/INDEX_CODE_FEATURES.md |
| 2025-12-21 | 통계 기능 분리: 월별/카테고리 화면 및 유틸 추가 | AccountStatsScreen(3688줄) 모놀리식 구조 | stats_calculator.dart 유틸 추가(MonthlyStats/CategoryStats/DailyStats 클래스 및 계산 메서드), monthly_stats_screen.dart / category_stats_screen.dart 신규 화면 생성, app_routes.dart에 monthlyStats/categoryStats 라우트 추가, app_router.dart에 케이스 추가, 9페이지에 아이콘 등록(아이콘 관리에서만 선택 가능), DateFormatter.formatYearMonth() 메서드 추가, page1_bottom_quick_icons.dart allowedIds에 monthlyStats/categoryStats/accountStatsSearch 추가 | Why=AccountStatsScreen 복잡도 감소 및 모듈화; Verify=flutter analyze; Tests=flutter test; Files=lib/utils/stats_calculator.dart, lib/screens/monthly_stats_screen.dart, lib/screens/category_stats_screen.dart, lib/navigation/app_routes.dart, lib/navigation/app_router.dart, lib/utils/main_feature_icon_catalog.dart, lib/utils/date_formatter.dart, lib/utils/page1_bottom_quick_icons.dart |
| 2025-12-20 | Fix: 메인 아이콘 그리드 Key/빈슬롯 숨김 정합성 | drag&drop 테스트가 `main_icon_slot_*` Key를 못 찾고 실패; hide_empty_slots 설정이 보기모드에 반영되지 않아 `+`가 노출 | 각 슬롯에 `main_icon_slot_{pageIndex}_{slotIndex}` Key를 부여하고, 보기모드+hideEmptySlots일 때 빈 슬롯은 `+` 없이 렌더(편집모드는 유지) | Playbook=AccountMainScreen; Verify=Quality Gate (analyze + test + INDEX); Tests=flutter test; Files=lib/screens/account_main_screen.dart, REAL_WORLD_TEST_PLAN.md |
| 2025-12-20 | Main pages: pageCount 15 고정 + 배너는 번호만 표시 | 페이지 수/배너 텍스트가 변경될 수 있고(출시 후 리스크), 배너에 라벨/텍스트가 혼재 | pageCount=15로 고정(출시 안정성), 상단 배너는 “번호만” 표시(텍스트/라벨 의존 제거) | Playbook=AccountMainScreen; Why=출시 후 구조 변경 금지/유지보수 안정성; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart, lib/widgets/page_banner_bar.dart, lib/utils/main_feature_icon_catalog.dart |
| 2025-12-20 | Prefs: 메인 페이지 기본값/정규화 SSOT 강화 | 기본 페이지 구성/이름/타입이 여러 위치에 흩어져 수정 리스크 | 기본값을 UserPrefService 중심으로 중앙화(폴백/정규화 포함), 1페이지 '가족' 라벨은 공백으로 정규화 | Why=문자열/기본값 변경을 1곳에서 안전하게; Verify=flutter analyze; Tests=flutter test; Files=lib/services/user_pref_service.dart |
| 2025-12-20 | Settings: 페이지/아이콘 초기화는 섹션 하단으로 정리 | 설정 내 기능들이 혼재되어 “위험 기능(초기화)”이 눈에 띄기 쉬움 | 설정을 아이콘/진입점 중심으로 정리하고, 페이지/아이콘 초기화는 해당 섹션 맨 아래로 배치 | Why=오조작 리스크 감소 + 동선 단순화; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/settings_screen.dart |
| 2025-12-20 | Language: 언어 설정 분리 + 저장값 앱 시작 시 반영 | 설정 화면 내 드롭다운 등으로 섞여 있고, 앱 시작 시 로케일 반영이 불명확 | 언어 설정 전용 화면/라우트 추가 + PrefKeys.language 저장 + 앱 시작 시 Intl locale 초기화에 반영 | Why=설정 단일 책임/개별 저장; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/language_settings_screen.dart, lib/navigation/app_routes.dart, lib/navigation/app_router.dart, lib/main.dart |
| 2025-12-20 | Icon management: 빈 슬롯 없으면 “다음 페이지 안내” 추가 | 아이콘 추가 시 빈 슬롯이 없으면 사용자 흐름이 막힘 | 다음 빈 슬롯이 있는 페이지를 자동 탐색하고 이동 버튼/스낵바 액션으로 안내 | Why=막힘 방지/가이드 강화; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/icon_management_screen.dart |
| 2025-12-20 | Page1: 전체 광고 오버레이 게이트(기본 비노출) | 출시 전/후 광고 삽입 시 매번 화면 구조를 뜯어야 함 | 1페이지에서만 전체 오버레이 광고 구조를 미리 제공(기본 OFF); 비정식 사용자만 노출 + 터치로 닫기(세션 1회) | Why=UX 단순/유지보수 안정 + 출시 전 토글로 조정; Verify=flutter analyze; Files=lib/screens/account_main_screen.dart, lib/widgets/page1_fullscreen_ad_overlay.dart, lib/services/user_pref_service.dart, lib/utils/pref_keys.dart |
| 2025-12-19 | 기본 pageTypes: 1페이지 family→icons | 기본/폴백에서 1페이지 타입이 family | 기본/폴백에서 1페이지 타입을 icons로 통일 | Playbook=AccountMainScreen; Why=family 타입 사용 중단(안정성/단순화); Verify=flutter test; Files=lib/services/user_pref_service.dart |
| 2025-12-19 | 메인 아이콘 카탈로그: 1페이지(0) 아이콘 연결 제거 | pages[0]에 달력/비상금/저축계획 아이콘(라우트 연결) 포함 | pages[0] items 비움(아이콘 그리드에서 진입/연결 제거) | Why=현재 사용 계획 없음(연결 제거); Tests=flutter test; Files=lib/utils/main_feature_icon_catalog.dart |
| 2025-12-19 | 위젯 테스트: page0 '달력' 가정 제거 | pageIndex 0에서 '달력' 및 calendar ID를 기대 | pageIndex 1(transactionAdd 등) 기반으로 이동/숨김 테스트 수행 | Why=page0 카탈로그 비움과 정합; Tests=flutter test; Files=test/screens/account_main_move_icon_test.dart; test/screens/account_main_screen_slots_test.dart |
| 2025-12-19 | UTILS: 달력/비상금/저축계획 기능 분리 문서화 | 설명/진입점 정보가 대화/코드에 분산 | 기능별 UTILS 문서 3종 + 하단탭/라우트 개념/제거 체크리스트 문서 추가 | Why=완전 제거 작업 준비(범위/진입점 명확화); Verify=Validate INDEX format; Files=UTILS_FEATURE_CALENDAR.md; UTILS_FEATURE_EMERGENCY_FUND.md; UTILS_FEATURE_SAVINGS_PLAN.md; UTILS_NAVIGATION_ROUTES_REMOVAL.md |
| 2025-12-19 | 가족 페이지: placeholder 텍스트 제거(아이콘만) | 가족 페이지에 안내 텍스트 노출 | 가족 페이지는 아이콘만 표시(텍스트 0) | Playbook=AccountMainScreen; Why=기본값/시각적 노이즈 제거; Verify=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | AccountMainScreen: 테스트 안정화(아이콘관리 UI 제거/슬롯/애니메이션) | 배너/페이지 내부에 편집·추가·복원 액션 노출; empty 슬롯에 항상 `+`; 드래그 슬롯 Key 부재; 편집 wiggle 무한 반복; pageCount 8로 9개 pageTypes 저장이 적용되지 않을 수 있음 | 메인 화면에서 아이콘 관리 액션 제거(설정에서만 관리); hide_empty_slots 반영(비편집시 empty 슬롯 숨김); `main_icon_slot_{pageIndex}_{slotIndex}` Key 추가; wiggle 1회 애니메이션(무한 repeat 제거); pageCount 9로 pageTypes 저장 적용 | Playbook=AccountMainScreen; Why=widget test/pumpAndSettle 타임아웃 및 UI 노출 이슈 해소; Verify=flutter test; Tests=flutter test; Files=lib/screens/account_main_screen.dart, test/screens/account_main_*_test.dart |
| 2025-12-19 | 기본 페이지명: '기능'→'수입' (보수적 마이그레이션) | 기본 3번째 탭 이름이 '기능' | 기본 3번째 탭 이름을 '수입'으로 변경; 저장된 이름이 “옛 기본값 그대로”인 경우에만 자동 갱신 | Playbook=AccountMainScreen; Why=요구사항(페이지 이름 표시) 반영; Verify=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-18 | 초기 인덱스 생성 및 3단계 구조로 통합 | tools/USER_MAIN_NAV_MAP.md + tools/LEGACY_USER_MAIN_LOCATION.md + tools/INDEX_CODE_FEATURES.md | tools/INDEX_CODE_FEATURES.md (단일 통합 문서) | 정책/Deepest Paths/Args/Routes 포함 |
| 2025-12-18 | STEP 3를 “저장소까지” 확장 | STEP 3: 화면→서비스까지만 | STEP 3: prefs/파일/DB(app_database.sqlite)까지 (END) | SharedPreferences 키/파일명/DB 경로 명시 |
| 2025-12-18 | 메인(Smart Ledger) 고정/정리 | 시작 시 / 라우트로 TopLevel/AccountMain 등이 끼어들 수 있음 | 시작: `/`→LaunchScreen→quickActions, QuickActions가 메인, 상단 `+` 제거 | (LEGACY) 이후 QuickActions는 완전 삭제됨 |
| 2025-12-18 | QuickActions 완전 삭제(기록) | 메인: `/`→LaunchScreen→quickActions | 메인: `/`→LaunchScreen→accountMain | 라우트/진입점/상태/PrefKeys/관련 파일·테스트 제거 |
| 2025-12-18 | AccountMainScreen 모든 UI 제거(빈 화면) | accountMain에 요약 UI/콘텐츠 표시 | accountMain은 빈 화면(배경만) | 사용자 캡처 기준으로 완전 제거 |
| 2025-12-18 | (REMOVED) smart_quick_actions_view.dart 파일 삭제 | lib/widgets/smart_quick_actions_view.dart 존재 | 파일 삭제됨 | 더 이상 import/사용되지 않아 잔재 정리 |
| 2025-12-18 | (내 자산 흐름) 통계/지출 분리 유틸 추가 | 자산 이동 기록은 화면에서만 부분 사용 | AssetMove 기반 inflow/outflow/net + outflow breakdown 계산 유틸 추가 | lib/utils/asset_flow_stats.dart |
| 2025-12-18 | Smart Ledger 상단 햄버거 메뉴 추가(설정 통합) | Smart Ledger 상단 액션 최소화 | 우측 상단 메뉴(섹션 이동 + 설정) 제공 | (LEGACY) lib/widgets/smart_quick_actions_view.dart |
| 2025-12-18 | AccountMainScreen 하단 도트 인디케이터 제거 | PageView 하단에 _MainDotsIndicator 오버레이 표시 | 하단 도트 완전 제거, PageView만 렌더 | lib/screens/account_main_screen.dart |
| 2025-12-18 | smart_quick_actions_view.dart의 _DotsIndicator 제거 | _DotsIndicator 위젯 정의 존재 (주석 블록 내) | _DotsIndicator 위젯 삭제 | lib/widgets/smart_quick_actions_view.dart |
| 2025-12-18 | AccountMainScreen 상단 6개 페이지 배너 추가 | 페이지 이동 도구 없음 | 상단 _PageBannerBar 추가: 6개 탭(가족,구매,기능,통계,자산,ROOT), 탭→페이지 이동, 롱프레스→이름 편집 | lib/screens/account_main_screen.dart |
| 2025-12-19 | 아이콘 숨김 복원 기능 추가 (원위치/빈슬롯 옵션) | 숨김 시 재노출 UI 없음 | 편집 모드에 '숨김 복원' 다이얼로그 추가, '원위치 우선'/'빈 슬롯 우선' 선택 가능, 숨김 시 원위치 인덱스 저장, 복원 로직(원위치→빈슬롯→스왑 확인), prefs에 동기 저장, 관련 위젯 테스트 추가 | lib/screens/account_main_screen.dart, lib/services/user_pref_service.dart, test/screens/account_main_restore_test.dart |
| 2025-12-19 | UI: 편집 및 숨김 복원 컨트롤 상단 배너로 이동 및 접근 제어 추가 | 편집 버튼이 상단 우측 버튼으로 고정 노출 | 편집/복원 아이콘을 배너 우측(툴팁)으로 이동, 각 페이지 제어용 GlobalKey 추가(부모에서 편집 토글/복원 다이얼로그 호출 가능), 테스트에서 툴팁 기반 셀렉터로 업데이트 | lib/screens/account_main_screen.dart, test/screens/account_main_restore_test.dart, test/screens/account_main_screen_slots_test.dart |
| 2025-12-19 | 사진 페이지(1페이지) 아이콘 위치 오버레이 추가 + 아이콘 일괄 설치 기능 | 숨김 아이콘 위치 미표시 / 빈 슬롯에 일괄 설치 불가 | 가족(사진) 페이지에 중앙 토글로 아이콘 위치 표시 기능 추가; 숨김 아이콘은 파란 마커로 강조 표시; 편집 모드에 '아이콘 추가' 대화상자(다중 선택→빈 슬롯 채움) 추가; 관련 테스트 추가 | lib/screens/account_main_screen.dart, test/screens/account_main_icon_picker_test.dart, test/screens/account_main_screen_slots_test.dart |
| 2025-12-19 | AccountMainScreen analyzer 에러 제거(복원 다이얼로그/async context/unused import) | `flutter analyze`에서 error 레벨 이슈 존재(Future<void> 반환 타입 불일치, async gap 후 context 사용, deprecated token/Radio 파라미터, unused import 등) | `_showRestoreHiddenDialog`를 `Future<void>`로 정리하고 void 결과 사용 코드 제거, await 이후 `mounted/context.mounted` 가드 추가, `surfaceVariant` → `surfaceContainerHighest` 교체, RadioListTile deprecation은 최소 영향으로 ignore 처리, `IconActionsMenu`/테스트의 unused import 제거 | lib/screens/account_main_screen.dart, lib/widgets/icon_actions_menu.dart, test/screens/account_main_restore_test.dart |
| 2025-12-19 | 사진 페이지 중앙 '아이콘 위치 표시' 토글 및 눈 아이콘 제거 | 중앙 토글(아이콘 눈 아이콘 + '탭해서 아이콘 위치 표시' 텍스트)로 오버레이 토글을 제공함 | 사용자 요청으로 해당 중앙 토글 제거: _FamilyPhotoMemoPage 내 content-hidden 상태에서 GestureDetector/아이콘/텍스트 제거. 관련 테스트(`test/screens/account_main_screen_slots_test.dart`)에서 텍스트 의존성 제거 및 prefs 기반 시뮬레이션으로 재작성하여 테스트 안정성 향상. 전체 위젯 테스트 실행 및 영향을 받은 테스트 수정 완료(일부 실패는 별도 조치 필요). | lib/screens/account_main_screen.dart, test/screens/account_main_screen_slots_test.dart |
| 2025-12-19 | 사진 페이지 아이콘 메뉴 위치 변경: 상단 우측 → 하단 좌측 점 3개 | 상단 우측의 '아이콘 메뉴' 버튼(`Icons.more_vert`)이 페이지 상단에 고정 노출됨 | 사용자 요청으로 상단 우측 버튼 삭제; 사진 스택 내부 하단 좌측의 가로 배치 점 3개(작은 원)로 메뉴 이동; `_FamilyPhotoMemoPage`에 `onOpenPageMenu` 콜백 추가 및 해당 콜백에서 `IconActionsMenu.showForPage`를 호출하도록 구현; 하단 점들은 `InkWell`으로 탭 가능하게 변경하여 동일한 메뉴 동작을 제공. 관련 UI/위젯 테스트(예: `test/screens/account_main_menu_test.dart`, `test/screens/account_main_screen_slots_test.dart`)에서 툴팁/위치 의존성 업데이트 필요. | lib/screens/account_main_screen.dart, test/screens/account_main_menu_test.dart, test/screens/account_main_screen_slots_test.dart |
| 2025-12-19 | 사진/메모 표시 토글 통합: 하단 좌측 메뉴 | 사진/메모는 기존에 하나의 숨김 토글(`family_content_hidden`)으로 관리되었음 | 사진/메모 각각의 표시 여부를 `family_photo_visible`/`family_memo_visible`로 분리하여 UserPrefService에 저장함. `_FamilyPhotoMemoPage`는 `_photoVisible`/`_memoVisible` 상태를 로드하고, 하단 점3개 메뉴(IconActionsMenu)에서 '사진 표시/숨기기' 및 '메모 표시/숨기기' 항목으로 제어 가능하도록 구현. 콘텐츠 숨김(`family_content_hidden`)은 기존대로 전체 토글로 유지되며, 개별 토글은 해당 메뉴에서 독립 제어됩니다. | lib/services/user_pref_service.dart, lib/screens/account_main_screen.dart, lib/widgets/icon_actions_menu.dart, test/screens/account_main_menu_test.dart |
| 2025-12-19 | 가족 페이지: 사진/메모 표시 토글이 UI에 실제 반영 | 사진/메모 토글은 prefs에 저장되지만 화면 렌더링에는 영향 없음(라벨만 변경) | `_photoVisible`/`_memoVisible` 값에 따라 사진 영역/메모 영역을 조건부 렌더링하여 숨김/표시가 즉시 UI에 반영되도록 수정 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | 설정: 아이콘 관리 허브로 관리 기능 통합 | 아이콘 노출/비노출 및 가족 페이지(사진/메모) 표시 설정이 메인 화면/페이지 내부에 분산되어 있고, 페이지 상단 액션이 페이지 이름을 가릴 수 있음 | Settings에 '아이콘 관리' 화면을 추가하여 1~6페이지 아이콘을 4x3 그리드로 미리보기하며 탭 1번으로 숨김/표시 토글(전체/숨김만 필터 포함) 가능하게 함. 가족 페이지의 사진/메모 표시 토글 및 가족 콘텐츠 숨김도 이 화면에서 관리하도록 통합. AccountMainScreen에서 페이지 상단 점3개 메뉴 및 가족 페이지 본문 내 숨김 관리 버튼을 제거하여 레이아웃 충돌을 해소 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/icon_management_screen.dart, lib/screens/settings_screen.dart, lib/navigation/app_routes.dart, lib/navigation/app_router.dart, lib/screens/account_main_screen.dart |
| 2025-12-19 | 메인 화면: 아이콘 관리 기능을 설정으로만 제한 | 메인 화면(상단/그리드)에서 아이콘 편집/추가/숨김/복원 UI가 1회 탭/롱프레스만으로 다이얼로그를 열 수 있어 사진 열람 흐름을 방해할 수 있음 | AccountMainScreen에서 아이콘 관리 상단 액션(편집/아이콘 추가/숨김 복원)을 제거하고, 아이콘 롱프레스 액션 메뉴를 비활성화하여 메인 화면에서는 아이콘 관리 창이 뜨지 않도록 변경. 아이콘 추가는 Settings > 아이콘 관리에서 빈 슬롯 탭으로만 수행하도록 통합 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart, lib/screens/icon_management_screen.dart, test/screens/account_main_menu_test.dart |
| 2025-12-19 | AccountMainScreen: 배너 탭 세로 패딩 반응형(작은 폰만) + invalid_constant 수정 | `const EdgeInsets`에 런타임 값(`isCompactPhone`)을 포함해 `flutter analyze` 실패 | 런타임 분기(`EdgeInsets.symmetric`)로 변경하고 작은 폰에서만 vertical padding을 늘려 터치 영역을 확장 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | AccountMainScreen: ROOT 바로가기 위치 변경 | 9페이지(설정) 아이콘 그리드 좌상단 슬롯에 ROOT 점프가 고정되어 있음 | 상단 배너에 고정 'ROOT' 버튼 추가(항상 노출), 설정 페이지의 강제 ROOT 슬롯 제거 | Why=위 스크롤/탭 조작으로 ROOT 접근; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | Icon navigation: pushNamed 실패 가드 추가 | 라우트 미등록/Args 불일치 시 런타임 크래시 가능 | pushNamed 예외를 catch해서 SnackBar 안내 + debug 로그(디버그 모드 rethrow)로 원인 추적 | Why=아이콘 확장 시 실수로 인한 크래시 방지; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | Settings: 가족 사진/메모 관리 화면 추가 | 1페이지(가족) 사진/메모는 메인 화면에서만 관리 가능 | Settings에 '가족 사진/메모 관리' 진입점 추가 + 사진 추가/삭제 및 메모 저장 전용 화면 제공(라우트 추가) | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/family_content_management_screen.dart, lib/screens/settings_screen.dart, lib/navigation/app_routes.dart, lib/navigation/app_router.dart |
| 2025-12-19 | Settings: 1페이지(가족) 아이콘 모드 토글 추가 | 1페이지를 아이콘 모드로 바꾸려면 배너 롱프레스에서 타입 변경 필요 | 설정에서 스위치로 1페이지를 family↔icons 전환, icons 전환 시 moduleKey를 custom으로 설정해 전체 아이콘 풀 배치 가능 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/settings_screen.dart |
| 2025-12-19 | 1페이지(가족): 사진 있으면 메모 숨김 | 사진 추가 후에도 사진/메모가 분할로 함께 노출되어 원래 설계와 다름 | 사진이 1장 이상이면 메모 영역을 숨기고 사진 영역이 화면 대부분을 사용(컨트롤은 하단 오버레이) | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | 1페이지(가족): 사진+메모 오버레이 병행 | 사진이 있을 때 메모를 완전히 숨기면 활용도가 떨어짐 | 사진이 있을 때 메모를 하단 오버레이(약 45% 높이)로 노출하고 사진 컨트롤과 패널을 통합해 동시에 사용 가능 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | 1페이지(가족): 드래그 가능한 메모 패널 추가 | 사용자가 메모 패널을 위아래로 끌어 더 많이/적게 보이게 할 수 있음 | `DraggableScrollableSheet`로 메모를 구현(초기 45%, 최소 10%, 최대 95%), 탭으로 편집 다이얼로그 호출 유지 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | 1페이지(가족): 사진 기능 제거 및 메모 전용화 | 사진 I/O가 불안정하여 시스템 리스크 요인으로 판단되어 family 페이지에서 사진 UI 제거 | 사진 관련 상태/메서드 제거, 가족 페이지는 메모 전용 카드로 단순화(편집은 기존 다이얼로그 사용) | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | 아이콘 선택 UX: 즉시 저장 → '적용' 버튼 커밋 | 빈 슬롯 탭 후 아이콘 타일 탭만으로 즉시 저장되어 사용자가 반영 여부를 확신하기 어려움 | 아이콘 선택 다이얼로그에서 타일 탭은 선택 상태만 표시하고, '적용' 버튼을 눌러야만 슬롯에 반영/저장되도록 변경(취소 시 미반영) | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/icon_management_screen.dart, test/screens/account_main_icon_picker_test.dart |
| 2025-12-19 | 아이콘 선택 UX: 다중 선택 + 일괄 적용(빈 슬롯 채움) | 아이콘 선택이 1개씩 선택/적용되어 여러 슬롯을 채우려면 반복 조작이 필요 | 아이콘 선택 다이얼로그에서 여러 아이콘을 선택한 뒤 '적용'을 누르면, 현재 슬롯부터 다음 빈 슬롯들에 순서대로 배치되도록 개선(취소 시 미반영) | Verify=tools/quality_gate.ps1; Files=lib/screens/icon_management_screen.dart, test/screens/account_main_icon_picker_test.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_menu_test.dart, test/screens/account_main_move_icon_test.dart |
| 2025-12-19 | 인덱스 작성 습관화: 훅 + CI + 가이드 추가 | 인덱스 업데이트는 수동/권장 수준이었음 | 로컬 pre-commit 훅(`.githooks/pre-commit`)으로 소스 변경 시 `tools/INDEX_CODE_FEATURES.md`가 스테이지되었는지 확인, PR 레벨에서 `.github/workflows/index-check.yml`로 누락 시 CI 실패하도록 구성. `CONTRIBUTING.md`에 인덱스 작성 체크리스트를 추가하여 로컬 습관화를 돕고, `tools/add-index-entry.ps1` 사용을 권장함. | .githooks/pre-commit, .github/workflows/index-check.yml, CONTRIBUTING.md, tools/add-index-entry.ps1 |
| 2025-12-19 | 인덱스: Screen Playbooks 도입 + Playbook 참조 검증 | Change Log/구조 위주(화면별 체크리스트/디버깅 절차는 분산/부재) | `Screen Playbooks` 섹션으로 화면별 체크리스트/디버깅 절차를 인덱스에서 바로 꺼낼 수 있게 하고, Change Log Note의 `Playbook=...`가 실제 `### Playbook: ...` 헤딩을 참조하는지 `validate_index.ps1/.sh`에서 검증하도록 강화. `add-index-entry.ps1`에 Playbook 입력 지원 추가 및 문서화. | Why=화면별 절차를 인덱스에서 즉시 꺼내기; Verify=Validate INDEX format (PowerShell); Risk=Playbook 오타/누락 시 검증 실패(의도된 보호); Files=tools/INDEX_CODE_FEATURES.md, tools/add-index-entry.ps1, tools/validate_index.ps1, tools/validate_index.sh, tools/README.md, CONTRIBUTING.md, tools/INDEX_ENTRY_TEMPLATE.md |
| 2025-12-19 | Playbooks: Root/Asset 화면 뼈대 추가 | Screen Playbooks는 AccountMainScreen만 존재 | RootAccountManageScreen / AssetTabScreen에 체크리스트+디버깅 루틴 뼈대 추가(변경 시 확인 포인트 표준화) | Playbook=RootAccountManageScreen; Playbook=AssetTabScreen; Verify=Validate INDEX format (PowerShell); Files=tools/INDEX_CODE_FEATURES.md |
| 2025-12-19 | Playbooks: 위젯 테스트 디버깅 루틴 추가 | 테스트 실패 유형별 대응이 구두/기억 의존 | WidgetTestDebugging Playbook 추가: 라우트 미등록, finder 모호성, pumpAndSettle 타임아웃의 확인 순서/해결 패턴을 표준화 | Playbook=WidgetTestDebugging; Verify=Validate INDEX format (PowerShell); Files=tools/INDEX_CODE_FEATURES.md |
| 2025-12-19 | Windows: INDEX 작업(Task) 및 릴리즈노트 생성 개선 | VS Code task가 `bash`에 의존(Windows에서 실패 가능), 릴리즈 노트 생성은 `.sh`만 제공 | VS Code task에 Windows 오버라이드 추가(Validate/Generate), `generate_release_notes.ps1` 추가, WidgetTestDebugging에 `flutter test` 와일드카드(`*`) 크래시 우회 노트 추가 | Playbook=WidgetTestDebugging; Verify=Validate INDEX format (PowerShell); Tests=flutter test; Files=.vscode/tasks.json, tools/generate_release_notes.ps1, tools/README.md, tools/INDEX_CODE_FEATURES.md |
| 2025-12-19 | AccountMainScreen: 아이콘 이동(스왑) 다이얼로그 async 안전성 보강 | 이동/스왑 흐름에서 첫 다이얼로그 이후 추가 다이얼로그를 띄울 때 analyzer에서 `use_build_context_synchronously` 오류 가능 | 첫 `showDialog` await 이후 `mounted` 가드 추가, 다이얼로그 builder context 변수명 분리(가독성/분석 안정성) | Verify=flutter analyze; Tests=flutter test test/screens/account_main_move_icon_test.dart; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | 빌드 스모크 체크: Android release APK 생성 확인 | (미확인) 테스트 통과만으로는 배포용 빌드 실패 가능 | `flutter build apk`로 `app-release.apk` 생성 성공 확인 | Verify=flutter build apk; Output=build/app/outputs/flutter-apk/app-release.apk |
| 2025-12-19 | 빌드 스모크 재확인: Android release APK 재생성 | (이전 스모크 체크만 존재) | 최근 포맷/리팩토링 이후에도 `flutter build apk` 재실행으로 `app-release.apk` 생성 성공 재확인 | Verify=flutter build apk; Output=build/app/outputs/flutter-apk/app-release.apk |
| 2025-12-19 | Dev task: `flutter analyze` info 비치명 실행 추가 | `flutter analyze`는 info lint만 있어도 exit code 1 | VS Code task로 `flutter analyze --no-fatal-infos` 실행 옵션 제공(로컬 편의) | Files=.vscode/tasks.json |
| 2025-12-19 | Lint 정리(무동작): analyzer info 감소 | 비-포맷(info) 린트가 섞여 있어 실제 이슈 확인이 어려움 | tear-off/Key/super-parameter/import ordering/avoid_print 등 저위험 린트 정리로 `flutter analyze --no-fatal-infos` 기준 176→155(잔여는 line length 위주). 전체 테스트 통과. | Verify=flutter analyze --no-fatal-infos; Tests=flutter test; Files=lib/screens/account_main_screen.dart, lib/navigation/app_router.dart, lib/navigation/app_routes.dart, lib/screens/settings_screen.dart, lib/screens/top_level_main_screen.dart, lib/utils/top_level_stats_utils.dart, lib/widgets/icon_actions_menu.dart, tools/export_index.dart, test/screens/account_main_screen_slots_test.dart, test/services/page_slot_groups_test.dart |
| 2025-12-19 | Lint: line-length 실제 수정 완료 (analyze 0) | `lines_longer_than_80_chars` 다수(특히 AccountMain 관련 파일/테스트) | 모든 long-line을 ignore 없이 실제 줄바꿈/리팩토링으로 제거하여 `flutter analyze` 0 issues 달성, 전체 테스트 104개 통과 확인 | Verify=flutter analyze; Tests=flutter test; Files=lib/services/user_pref_service.dart, lib/utils/top_level_stats_utils.dart, test/screens/account_main_hide_empty_slots_test.dart, test/screens/account_main_icon_picker_test.dart, test/screens/account_main_menu_test.dart, test/screens/account_main_move_icon_test.dart, test/screens/account_main_restore_test.dart, test/screens/account_main_screen_slots_test.dart, test/services/page_slot_groups_test.dart |
| 2025-12-19 | AccountSelectScreen: 소규모 리팩토링(무동작) | AccountService 생성/리스트 인덱스 접근이 itemBuilder 내에서 반복 | build에서 AccountService를 1회 생성하고 accountName 로컬 변수로 정리하여 가독성/불필요한 반복 감소 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_select_screen.dart |
| 2025-12-19 | AccountMainScreen: 가족 페이지에서 비기능 배너 버튼 숨김 | 가족(family) 페이지에서도 편집/아이콘 추가/숨김복원 버튼이 노출되지만 실제로는 `_pageKeys[0]`에 State가 없어 동작하지 않음 | 페이지 메뉴(점3개) 버튼은 유지하고, 편집/아이콘 추가/숨김 복원은 icons 페이지에서만 노출되도록 제한 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | AccountMainScreen: 저장된 페이지 복원 시 인덱스 저장 가드 강화 | `_isRestoringIndex`가 jump 직후 바로 false가 되어 `onPageChanged`에서 복원 중 저장을 안정적으로 막지 못할 수 있음 | 복원 플래그는 첫 `onPageChanged`에서만 해제하도록 변경하여 복원 중 저장을 확실히 스킵(이후 사용자 스와이프는 정상 저장) | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | AccountMainScreen: 라이프사이클/엣지 케이스 안정성 보강 | restore 시 PageController가 아직 attach되지 않았을 때 `jumpToPage`가 호출될 수 있고, 가족 페이지에서 마지막 사진 삭제 시 `clamp(0, -1)`로 크래시 가능, dialog TextEditingController dispose 누락 | restore 점프는 post-frame에서 controller attach 후 실행, 마지막 사진 삭제는 빈 리스트 케이스 안전 처리, dialog 컨트롤러는 finally에서 dispose, 콜백에 mounted 가드 추가 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | IconGridPage: async dialog 후 setState 안전성 강화 | `showDialog` await 이후 위젯 dispose 가능성에 대비한 `mounted` 가드가 부족해 setState-after-dispose 위험 | 이동/복원/아이콘추가 플로우에서 await 직후 `mounted` 체크 추가, 일괄 복원 루프도 dispose 시 조기 종료 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart |
| 2025-12-19 | IconActionsMenu: 메뉴 action 실행 전 context.mounted 가드 | 메뉴(dialog) 닫힘 이후 상위 위젯 dispose 가능 시, 콜백/GlobalKey state 호출이 setState-after-dispose로 이어질 수 있음 | showForPage/showForIcon에서 await showDialog 이후 `context.mounted`/action null 체크 후에만 액션 실행 | Verify=flutter analyze; Tests=flutter test; Files=lib/widgets/icon_actions_menu.dart |
| 2025-12-19 | InteractionBlockers: 중복 액션 실차단 + Root 거래관리 적용 | 일부 화면에서 `isBlocked`만 체크하고 실제로 busy 플래그를 세우지 않아 더블탭 시 중복 네비게이션/삭제 흐름이 가능 | InteractionBlockers.run 추가로 실행 구간을 busy로 묶고, RootTransactionManagerScreen의 편집/삭제를 run으로 래핑 | Verify=flutter analyze; Tests=flutter test; Files=lib/utils/interaction_blockers.dart, lib/screens/root_transaction_manager_screen.dart |
| 2025-12-19 | BackupScreen: dialog/컨트롤러 dispose 및 mounted 가드 보강 | `showDialog` await 이후 dispose 가능성과 dialog용 TextEditingController 미-dispose로 인한 리스크 | dialog 반환 후 `mounted` 체크 추가, 새 계정 복원 입력 컨트롤러 finally dispose, 복원/삭제 흐름에서 await 후 setState 보호 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/backup_screen.dart |
| 2025-12-19 | TransactionDetailScreen: dialog await 후 mounted/컨트롤러 dispose 보강 | dialog/bottomSheet await 이후 dispose 가능성과 반품 처리용 TextEditingController 미-dispose 리스크 | 이동/예산변경 흐름에서 dialog 후 `mounted` 체크 추가, 반품 bottomSheet 종료 시 컨트롤러 3종 finally dispose | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/transaction_detail_screen.dart |
| 2025-12-19 | Trash/SavingsPlan/FixedCost: dialog/controller 라이프사이클 안전성 보강 | Trash 계정복원 dialog의 TextEditingController 미-dispose, SavingsPlanListScreen에서 dispose 후 _loadPlans setState 가능, FixedCostTabScreen에서 _paymentController 미-dispose | Trash: controller try/finally dispose + dialog 후 mounted 가드; SavingsPlan: _loadPlans 시작 mounted 가드 + navigation/dialog 이후 mounted 가드; FixedCost: _paymentController.dispose 추가 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/trash_screen.dart, lib/screens/savings_plan_list_screen.dart, lib/screens/fixed_cost_tab_screen.dart |
| 2025-12-19 | RootAccountManagerPage: dialog/controller dispose 및 refresh mounted 가드 | 새 계정 생성 dialog의 TextEditingController 미-dispose, refresh 시작 setState가 dispose 후 호출될 수 있음 | controller try/finally dispose + dialog 이후 mounted 체크, _refreshAll 시작에 mounted 가드 추가 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/root_account_manager_page.dart |
| 2025-12-19 | TopLevelMainScreen: bottom sheet 계정삭제 async 레이스 가드 | 계정관리 bottom sheet에서 confirm/삭제 await 후 sheet가 이미 닫힌 경우에도 삭제/네비 pop이 진행될 수 있음 | confirm 이후 `sheetContext.mounted` 체크로 시트가 살아있을 때만 삭제 진행, pop도 `sheetContext.mounted` 조건으로 제한 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/top_level_main_screen.dart |
| 2025-12-19 | AccountStatsScreen: 반품 dialog 컨트롤러 dispose 보강 | 반품 처리 다이얼로그에서 입력값 오류로 early return 시 TextEditingController dispose가 실행되지 않아 누수 가능 | dialog 플로우를 try/finally로 감싸 controller를 항상 dispose, dialog 이후 mounted 가드 추가 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_stats_screen.dart |
| 2025-12-19 | PeriodDetailScreen: 날짜 선택 await 후 mounted 가드 | 날짜 선택 DatePicker await 중 화면이 dispose되면 setState-after-dispose 가능 | showDatePicker await 이후 `mounted` 체크 후에만 setState 실행 | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_stats_screen.dart |
| 2025-12-19 | Income UI: date/time picker await 후 mounted 가드 | picker await 이후 setState가 dispose 후 실행될 수 있음 | showDatePicker/showTimePicker await 이후 `mounted` 체크 후에만 setState 실행(값 null이면 no-op) | Verify=flutter analyze; Tests=flutter test; Files=lib/screens/income_add_form.dart, lib/screens/income_input_screen.dart |
| 2025-12-21 | PrefKey 문서: 아이콘 이동(슬롯) 저장 키를 계정 prefix 포함해 명시 | PrefKey가 `page_<N>_icon_slots`처럼 suffix만 보이면 실제 저장 키를 혼동할 수 있음 | 실제 저장은 `PrefKeys.accountKey(accountName, suffix)` 규칙으로 prefix가 붙음. 예: `${accountName}_page_${pageIndex}_icon_slots` (이동/드래그 결과 저장) | tools/INDEX_CODE_FEATURES.md, lib/services/user_pref_service.dart, lib/utils/pref_keys.dart |
| 2025-12-19 | Prefs: 메인 페이지를 pageId 기반으로 전환 | index 기반(mainPageIndex/page_<index>_*) 저장에 강결합 | main_page_configs_v1(JSON) + main_page_last_id + pageId_<id>_* 저장(legacy fallback/sync 유지) | Why=페이지 인덱스 변경/예약 페이지 채움 시 충돌 예방; Verify=flutter analyze; Tests=flutter test; Files=lib/services/user_pref_service.dart, lib/screens/account_main_screen.dart, lib/models/main_page_config.dart |
| 2025-12-19 | DB: Drift MigrationStrategy 뼈대 추가(무스키마) | schemaVersion=1만 존재(명시적 전략 부재) | onCreate/onUpgrade/beforeOpen(MigrationStrategy) 추가 + foreign_keys pragma 활성화 | Why=향후 v2+ 대비/업그레이드 경로 고정; Verify=flutter analyze; Tests=flutter test; Files=lib/database/app_database.dart |
| 2025-12-19 | Prefs: reserved 페이지 name/moduleKey 정규화 | reserved_1/2의 name이 공백이고, moduleKey 변형(reserved_1/2 등) 가능 | 기본 name을 예약1/예약2로 명확화, 로드시 reserved moduleKey를 'reserved'로 안전 정규화(사용자 재지정은 존중) | Why=미래 기능 확장 시 실수/충돌 예방; Verify=flutter analyze; Tests=flutter test; Files=lib/services/user_pref_service.dart |
| 2025-12-18 | UserPrefService 페이지 이름 저장/불러오기 추가 | 페이지 이름 저장 기능 없음 | setMainPageNames/getMainPageNames 추가, 기본값: ['가족','구매','기능','통계','자산','ROOT'] | lib/services/user_pref_service.dart, PrefKey: account_<name>_main_page_names |
| 2025-12-18 | AccountMainScreen 페이지 이름 편집 다이얼로그 | 페이지 이름 고정 | _showEditPageNameDialog: 배너 롱프레스→이름 변경→SharedPreferences 저장 | lib/screens/account_main_screen.dart |
| 2025-12-18 | UserPrefService 가족 사진/메모 저장 기능 추가 | 1페이지 사진/메모 기능 없음 | setFamilyPhoto/getFamilyPhoto/setFamilyMemo/getFamilyMemo 추가 | lib/services/user_pref_service.dart, PrefKeys: family_photo_path, family_memo |
| 2025-12-18 | AccountMainScreen 1페이지 가족 사진·메모 UI 구현 | 1페이지는 숫자만 표시 | _FamilyPhotoMemoPage: 사진 1장(탭→교체,롱프레스→삭제), 메모 카드(탭→편집), BoxFit.contain으로 원본 비율 유지 | lib/screens/account_main_screen.dart |
| 2025-12-18 | 1페이지 여러 사진 슬라이드쇼 기능 추가 | 사진 1장만 저장 | 여러 장 저장(List<String>), PageView로 좌우 스와이프, Timer로 자동 전환(기본 10분), 간격 설정(1/5/10/30/60분), 현재 위치 표시(3/5) | lib/screens/account_main_screen.dart, lib/services/user_pref_service.dart |
| 2025-12-18 | UserPrefService 사진 저장 방식 변경 | setFamilyPhoto(String?) 단일 경로 | setFamilyPhotos(List<String>) 리스트, setFamilyPhotoInterval(int minutes) 추가 | lib/services/user_pref_service.dart, PrefKeys: family_photo_paths, family_photo_interval_minutes |
| 2025-12-18 | 1페이지 콘텐츠 숨김 토글 기능 추가 | 콘텐츠 항상 표시 | 👁️ 버튼으로 사진/메모 숨김/표시 토글, setFamilyContentHidden/getFamilyContentHidden | lib/screens/account_main_screen.dart, lib/services/user_pref_service.dart, PrefKey: family_content_hidden |
| 2025-12-18 | 아이콘 관련 옵션화 (설정에 토글 추가) | 아이콘 기능 강제 활성화 | 설정 화면에 전역 숨김, 사진 오버레이, 편집 버튼 표시 토글 추가; 런타임에서 해당 토글을 반영하도록 수정 | lib/screens/settings_screen.dart, lib/screens/account_main_screen.dart, lib/services/user_pref_service.dart, tools/INDEX_CODE_FEATURES.md |
| 2025-12-19 | 스택형 슬롯 그룹(한 슬롯에 여러 아이콘) 추가 — prefs API | 슬롯 그룹 기능 없음 | `setPageSlotGroups` / `getPageSlotGroups` 추가: 각 슬롯은 쉼표로 연결된 아이콘 id를 저장, 누락/초과 정규화 | lib/services/user_pref_service.dart, test/services/page_slot_groups_test.dart |
| 2025-12-19 | 빈 슬롯 숨기기 옵션 추가 (보기모드) | 빈 슬롯 항상 보임 | Settings에 '빈 슬롯 숨기기' 토글 추가, `_IconGridPage`는 보기모드에서 빈 슬롯을 렌더하지 않음; 빈화면일때는 '아이콘 추가' 버튼 노출 | lib/screens/settings_screen.dart, lib/screens/account_main_screen.dart, lib/services/user_pref_service.dart, test/screens/account_main_hide_empty_slots_test.dart |
| 2025-12-19 | 아이콘 이동: 롱프레스 메뉴 + 슬롯 선택 다이얼로그 추가 | 아이콘 이동은 편집 모드 전용이거나 불편함 있음 | 아이콘 롱프레스에서 '이동' 메뉴 추가, 슬롯 선택 다이얼로그 도입, 빈 슬롯으로 이동 또는 점유 슬롯과의 스왑(교체 확인) 지원; 슬롯 변경 즉시 prefs에 저장 | lib/screens/account_main_screen.dart, test/screens/account_main_move_icon_test.dart |
| 2025-12-19 | 아이콘 메뉴 통합: 상단 배너 메뉴 + 롱프레스 컨텍스트 메뉴 통합 | 메뉴 분산(여러 버튼) | `IconActionsMenu` 위젯 추가, 배너의 아이콘 메뉴 버튼과 아이콘 롱프레스가 동일한 메뉴 호출: 아이콘 추가 / 편집 토글 / 숨김 복원 / 아이콘 전용 조치(열기/이동/숨김/삭제) | lib/widgets/icon_actions_menu.dart, lib/screens/account_main_screen.dart, test/screens/account_main_menu_test.dart |
| 2025-12-18 | 페이지 타입 선택 기능 추가 | 1페이지만 가족 모드 고정 | 각 페이지마다 타입 선택 가능: family(사진+메모) / icons(기능 아이콘), 배너 롱프레스→타입 변경 다이얼로그 | lib/screens/account_main_screen.dart, lib/services/user_pref_service.dart, PrefKey: page_types |
| 2025-12-18 | _IconGridPage 구현 (아이콘 모드) | 숫자만 표시 | main_feature_icon_catalog.dart 기반 아이콘 그리드, 편집 모드(탭→숨김/표시, 드래그→순서 변경), 페이지별 설정 저장 | lib/screens/account_main_screen.dart |
| 2025-12-18 | UserPrefService 페이지별 아이콘 설정 저장 추가 | 아이콘 설정 저장 없음 | setPageIconSettings/getPageIconSettings: 페이지별 숨긴 아이콘 ID, 아이콘 순서 저장 | lib/services/user_pref_service.dart, PrefKeys: page_<N>_hidden_icons, page_<N>_icon_order |
| 2025-12-18 | MainFeatureIconCatalog: 자산 및 ROOT 아이콘 추가 | 일부 아이콘이 누락되어 1터치 접근 불가 | assetManagement, assetSimpleInput, assetDetailInput (페이지2); rootTransactionManager, rootSearch, rootAccountManage, rootMonthEnd (페이지5) 추가 | lib/utils/main_feature_icon_catalog.dart |
| 2025-12-18 | 아이콘 슬롯 배치(4x3) 도입 | 자유형 아이콘 리스트(빈 슬롯 없음) | 슬롯 기반(12칸) 그리드, 드래그→빈 슬롯에 배치/스왑, SharedPreferences에 page_<N>_icon_slots로 저장 | lib/screens/account_main_screen.dart, lib/services/user_pref_service.dart, PrefKey: page_<N>_icon_slots |
| 2025-12-18 | TopLevel 전역 통계 로직: utils로 분리 및 코드 정리 | TopLevelMainScreen에 직접 구현되어 있었음 | `lib/utils/top_level_stats_utils.dart` 추가, `TopLevelMainScreen`은 `TopLevelStatsUtils.buildDashboardContext()`로 대체, 관련 타입 중복 제거 및 의존성 정리 | lib/utils/top_level_stats_utils.dart, lib/screens/top_level_main_screen.dart |
| 2025-12-18 | 아이콘 추가: TopLevel 통계 상세 바로가기 | 통계 상세로 가는 아이콘 없음 | `topLevelStatsDetail` 아이콘 추가 (page 5, ROOT 페이지) — `AppRoutes.topLevelStatsDetail`로 바로 네비게이트 가능 | lib/utils/main_feature_icon_catalog.dart |
| 2025-12-18 | 코드 품질 개선: deprecated 교체/const 적용/Matrix4 변경 | 일부 deprecated API 사용 및 const 미사용, Matrix4.scale 사용 | `Matrix4.scale` → `Matrix4.diagonal3Values`로 변경, 일부 `surfaceVariant`/color 토큰 정리, const 권장 위치 적용, analyzer 경고 정리 | lib/screens/account_main_screen.dart, lib/utils/top_level_stats_utils.dart |
| 2025-12-18 | 라우트 추가: ROOT 관련 라우트 | 라우트 없음 | `AppRoutes.rootSearch`, `AppRoutes.rootAccountManage`, `AppRoutes.rootMonthEnd` 추가 및 AppRouter에 케이스 등록 | lib/navigation/app_routes.dart, lib/navigation/app_router.dart |
| 2025-12-18 | ROOT 기능 분리: 검색/계정관리/월말정산 화면 생성 | TopLevelMainScreen 내부 통합 구현 | `RootSearchScreen`, `RootAccountManageScreen`, `RootMonthEndScreen` 분리 생성, TopLevelMainScreen은 각 화면으로 네비게이트 | lib/screens/root_search_screen.dart, lib/screens/root_account_manage_screen.dart, lib/screens/root_month_end_screen.dart, lib/screens/top_level_main_screen.dart |
| 2025-12-18 | TopLevelMainScreen: 계정관리 모달 → RootAccountManageScreen 분리 | 계정 관리 모달 내 직접 삭제 처리 | 계정 삭제 로직을 `RootAccountManageScreen`으로 이관, UI/UX 분리 | lib/screens/top_level_main_screen.dart, lib/screens/root_account_manage_screen.dart |
| 2025-12-18 | Build fix: smart_quick_actions_view.dart 완전 교체 및 빌드 성공 | 주석 블록 내 코드로 컴파일 에러 발생 | 파일을 1줄로 교체하여 컴파일 오류 제거(빌드 성공) | lib/widgets/smart_quick_actions_view.dart |
| 2025-12-18 | smart_quick_actions_view.dart 주석 블록 완전 제거 | 주석 블록 내 코드로 인한 컴파일 에러 162개 발생 | 파일을 "// QuickActions feature removed." 1줄로 완전 교체 | lib/widgets/smart_quick_actions_view.dart |
| 2025-12-18 | ROOT 통계 로직을 utils로 분리 | TopLevelMainScreen 내부에 통계 계산 로직 포함 | `lib/utils/top_level_stats_utils.dart` 추가, `TopLevelMainScreen`은 utils 호출로 변경 | lib/utils/top_level_stats_utils.dart, lib/screens/top_level_main_screen.dart |
| 2025-12-19 | CI: PR 레벨에서 INDEX 업데이트 강제 검사 추가 | 없음 | `.github/workflows/index-check.yml` 추가; `CONTRIBUTING.md`에 CI 안내 추가 | PR에서 소스 변경 시 `tools/INDEX_CODE_FEATURES.md` 갱신 필수 — 누락 시 PR 실패 (자동 보호) |
| 2025-12-19 | AccountMainScreen: 빈 페이지 2개 추가 (페이지 수 6→8) | 6 페이지(가족,구매,기능,통계,자산,ROOT) | 8 페이지(가족,구매,기능,통계,빈페이지,자산,ROOT,빈페이지2) | `lib/screens/account_main_screen.dart`, `lib/services/user_pref_service.dart` |
| 2025-12-19 | INDEX helper 및 템플릿 추가 | 없음 | `tools/add-index-entry.ps1`, `tools/INDEX_ENTRY_TEMPLATE.md` 추가 | 대화형 PowerShell 스크립트로 사용자 편리하게 INDEX 항목 추가 가능 |
| 2025-12-19 | INDEX 검증/내보내기/릴리스 스크립트 추가 | 없음 | `tools/validate_index.sh`, `tools/export_index.dart`, `tools/generate_release_notes.sh` 추가 | INDEX 포맷 검증, CSV/JSON 내보내기, 릴리스 노트 생성 도구 추가 |
| 2025-12-19 | 개발 편의성: VS Code tasks 및 docs 추가 | 없음 | `.vscode/tasks.json`, `tools/README.md` 추가 | Add/Export/Validate/Generate 작업을 VS Code 내에서 실행 가능 |
| 2025-12-18 | Root screens 분리 및 라우트 추가 | 통합된 모달/내부 로직 | `AppRoutes.rootSearch`, `AppRoutes.rootAccountManage`, `AppRoutes.rootMonthEnd` 추가, AppRouter에 케이스 등록 | lib/navigation/app_routes.dart, lib/navigation/app_router.dart |
## 변경 시 체크리스트(빠르게)

- STEP 1 표에서 파일/요약 갱신
- STEP 2 해당 파일 섹션에서 연결/라우트/Args 갱신
- STEP 3 Deepest Paths에 (END) 포함한 경로 추가/수정
- (중요) 삭제 대신 `Legacy / REMOVED`로 보존
- Change Log에 1줄 기록

---

## Screen Playbooks (체크리스트/디버깅)

> 목적: "이 화면 바꿀 때 뭘 확인하지?" / "버그 재현되는데 어디부터 보지?"를
> Change Log 한 줄에서 `Playbook=...`로 바로 점프해서 꺼내 쓰는 용도.

### Playbook: AccountMainScreen

체크리스트(변경 시)

- 페이지 수/타입을 바꾸면 `UserPrefService.getPageTypes()` 기본값과 저장 키(`page_types`)까지 함께 확인
- 배너 탭 이름/페이지 이름 변경 시: `main_page_names` 저장/로드와 UI 표시가 일치하는지 확인
- 아이콘 슬롯/정렬/숨김/복원 관련 변경 시(중요): 실제 prefs 키는 계정 prefix가 붙는다.
  - 규칙: `PrefKeys.accountKey(accountName, suffix)` → `${accountName}_$suffix`
  - 이동/슬롯 저장: `${accountName}_page_${pageIndex}_icon_slots`
  - 숨김/정렬/복원: `${accountName}_page_${pageIndex}_hidden_icons`, `${accountName}_page_${pageIndex}_icon_order`, `${accountName}_page_${pageIndex}_hidden_origins`, `${accountName}_page_${pageIndex}_icon_restore_behavior`
  - (Legacy) pageId 기반: `${accountName}_pageId_${pageId}_icon_slots` 등 `pageId_${pageId}_*`
- 사진/메모 UX 변경 시: `family_photo_paths`, `family_memo`, `family_content_hidden`, `family_photo_visible`, `family_memo_visible` 저장/로드 확인
- 관련 테스트/검증을 최소 1개 이상 갱신하거나 새로 추가(아래 디버깅 절차 참고)

디버깅 절차(빠른 루틴)

- 상태 초기화가 필요하면 앱 데이터 초기화(또는 prefs key 변경 시 마이그레이션 고려) 후 재현
- 표시 문제(아이콘/페이지)가 있으면 먼저 `page_types`와 해당 페이지의 `page_<N>_*` 키 값이 기대 형태인지 확인
- 숨김 복원 이슈면: `page_<N>_hidden_icons`(숨김 목록)과 `page_<N>_hidden_origins`(원위치 인덱스) 불일치 여부부터 확인
- 복원 동작이 이상하면: `page_<N>_icon_restore_behavior` 값('original'/'first_empty')이 UI 선택과 일치하는지 확인
- 최소 검증: `flutter analyze` + 관련 위젯 테스트(예: restore/slots/menu 계열) 1회 실행

### Playbook: RootAccountManageScreen

체크리스트(변경 시)

- 라우트/Args: `AppRoutes.rootAccountManage` 및 라우터(AppRouter) 등록/Args 타입 변경 여부 확인
- 데이터/삭제: 계정 삭제/수정 흐름이 DB/서비스(예: 계정 목록 소스)와 일치하는지 확인
- 네비게이션: 삭제 후 back stack / 현재 화면 pop 처리 / lastAccountName 처리(있다면) 일관성 확인
- 예외/빈 상태: 계정 0개/삭제 실패/권한(잠금)/확인 다이얼로그 취소 시 UI가 안전한지 확인
- 테스트: 계정 삭제/리스트 갱신 관련 위젯/서비스 테스트가 있다면 최소 1개 업데이트

디버깅 절차(빠른 루틴)

- "삭제했는데 다시 나타남" → DB 반영 여부/리스트 리로드 타이밍/캐시 여부부터 확인
- "삭제 후 화면이 꼬임" → `Navigator` pop 순서/현재 route 스택을 먼저 확인
- 최소 검증: `flutter analyze` + 관련 테스트(또는 화면 진입→삭제→목록 갱신 수동 시나리오 1회)

### Playbook: AssetTabScreen

체크리스트(변경 시)

- 데이터 소스: 자산 목록/요약이 어떤 서비스/DB 쿼리 결과를 쓰는지(집계 기준) 변경 시 함께 반영
- 라우트 연결: 자산 상세/입력/관리/대시보드 등으로의 이동(`AppRoutes.asset*`)이 깨지지 않았는지 확인
- 금액/합계: 표시 합계(총자산/현금/투자 등) 계산 로직 변경 시 단위/반올림/부호 규칙 확인
- 빈 상태: 자산 0개일 때 CTA(추가 버튼)/설명 문구가 의도대로인지 확인
- 성능: 리스트/집계가 무거워졌다면 초기 로딩/스크롤 시 프레임 드랍 여부 확인

디버깅 절차(빠른 루틴)

- 값이 "틀림" → 먼저 DB 원본 데이터(해당 자산 항목)와 집계 함수/쿼리 필터(기간/계정)부터 확인
- 화면 전환이 "안됨" → `AppRoutes`/AppRouter 케이스 누락, Args 타입 불일치 여부 확인
- 최소 검증: `flutter analyze` + 자산 관련 핵심 플로우 1회(목록→상세→수정/추가→목록 반영)

### Playbook: WidgetTestDebugging

체크리스트(테스트가 깨졌을 때 공통)

- 실패 메시지에서 1) 어떤 위젯/라우트/키를 못 찾는지 2) 타임아웃인지 3) 예외 스택이 무엇인지 먼저 분류
- 테스트는 가능한 한 `pumpAndSettle` 남발 대신 “기대 상태까지 필요한 최소 pump”로 맞추기
- Finder는 텍스트 의존을 줄이고 `Key`/`Tooltip`/타입+조건 조합으로 유일하게 만들기
- (Windows) `flutter test test/screens/account_main_*_test.dart`처럼 `*`가 포함된 경로를 그대로 넘기면 Flutter 툴이 `Invalid argument(s): Illegal character in path`로 크래시할 수 있음 → PowerShell에서 파일 목록을 먼저 확장해서 실행: `pwsh -NoProfile -Command "$tests = Get-ChildItem -Path 'test/screens' -Filter 'account_main_*_test.dart' | ForEach-Object { $_.FullName }; flutter test @tests"`

디버깅 절차: 라우트 미등록 / Unknown route

- 증상: `Navigator.pushNamed` 또는 `onGenerateRoute`에서 라우트 미등록 예외
- 확인 순서:
  - `AppRoutes.*` 상수 존재 여부
  - 라우터(AppRouter)에서 해당 라우트 케이스 등록 여부
  - 테스트에서 사용하는 `MaterialApp(routes/onGenerateRoute)`가 실제 앱 라우터를 쓰는지(또는 테스트 전용 라우트 주입이 필요한지)
- 해결 패턴: 테스트에서 `onGenerateRoute: AppRouter.onGenerateRoute` 같은 실제 라우터를 주입하거나, 해당 테스트에 필요한 최소 라우트만 더미로 등록

디버깅 절차: Finder 모호성(여러 개 매칭)

- 증상: `find.text`/`find.byType`가 2개 이상 매칭되어 실패
- 확인 순서:
  - 동일 텍스트/아이콘이 여러 위치에 있는지(툴바/리스트/다이얼로그)
  - 테스트가 의도한 위치(특정 subtree)인지
- 해결 패턴:
  - 위젯에 `Key('...')` 추가(가능하면 화면 코드에) 또는 `Tooltip` 기반으로 선택
  - `find.descendant(of: ..., matching: ...)` / `find.ancestor`로 범위를 좁히기

디버깅 절차: pumpAndSettle 타임아웃

- 증상: 애니메이션/Timer/Stream 등으로 settle이 끝나지 않아 타임아웃
- 확인 순서:
  - 화면에 `Timer.periodic`/무한 애니메이션/Stream 구독이 있는지
  - 테스트가 실제로 기다려야 하는 이벤트가 무엇인지(단순 rebuild인지, 네트워크/DB mock인지)
- 해결 패턴:
  - `pumpAndSettle` 대신 `pump(const Duration(...))` + 기대 위젯 `expect`로 종료 조건 명확화
  - 타이머/애니메이션이 테스트에서 꺼질 수 있도록 플래그/의존성 주입(가능하면)
