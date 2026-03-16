# SmartLedger 개발 핵심문서 (기능 요약 + 연결고리 맵)

- 개발 문서 인덱스: `docs/developer/README.md`
- 정책(아이콘/인덱스) 정본: `docs/policies/ICON_MANAGEMENT_SINGLE_SOURCE_KO.md`

목적: 기능 수정/추가 시 **처리시간을 줄이고 작업 요율(속도/정확도)**을 올리기 위한 “단 하나의 참고 문서”입니다.

- 최신 갱신: 2026-02-24
- 범위: 메인 페이지/라우팅/아이콘 진입점/핵심 서비스·저장소(Prefs/DB) 연결

---

## 0) TL;DR (수정할 때 여기부터)

- 라우트 추가/수정: `AppRoutes` + `app_router_*.dart` + (필요 시) 메인 아이콘 카탈로그
- 메인 아이콘/페이지 인덱스/아이콘관리(ENT): 단일 기준 문서 1개
  - `docs/policies/ICON_MANAGEMENT_SINGLE_SOURCE_KO.md`
- 데이터 저장 흐름(거래/자산/프리퍼런스): 서비스 파일(services) → `UserPrefService` / `transaction_db_store.dart`

### 작업 시작 3줄(권장)

- `flutter analyze`
- `flutter test`
- 변경 기능 스모크(아이콘 진입 → 저장/조회 → 재진입)

### 자주 여는 핵심 파일(점프)

- Routes 상수: `lib/navigation/app_routes_paths.dart`
- Router 엔트리: `lib/navigation/app_router.dart`
- Stats 라우팅: `lib/navigation/app_router_stats.dart`
- Settings 라우팅: `lib/navigation/app_router_settings.dart`
- 메인 아이콘 카탈로그(페이지 구성/모듈 매핑): `lib/utils/main_feature_icon_catalog.dart`
- 통계/자산/ROOT/설정 아이콘 목록: `lib/utils/main_feature_icon_catalog_stats_settings.dart`
- 지출입력 아이콘 목록: `lib/utils/main_feature_icon_catalog_purchase_income.dart`
- 메인 아이콘 탭 인자 구성: `lib/utils/icon_launch_utils.dart`

---

## 1) 메인 구조(요약)

### 1-1) 메인 페이지(0-based, pageCount=15)

기능 수정 시 “인덱스가 흔들리면 비용이 폭증”합니다. 페이지 인덱스/Reserved 정책은 아래 문서를 기준으로 합니다.

- 단일 기준: `docs/policies/ICON_MANAGEMENT_SINGLE_SOURCE_KO.md`

요약:
- Index 0: 대시보드
- Index 1: 요리/쇼핑/지출
- Index 2: 수입
- Index 3: 통계(Reserved)
- Index 4: 자산(Reserved)
- Index 5: ROOT(Reserved)
- Index 6: 설정(Reserved)
- Index 7~14: 미사용

### 1-2) “사용자 터치 → 화면”의 표준 연결 체인

1) 메인 그리드 아이콘(또는 메뉴) →
2) `routeName` (`AppRoutes.*`) →
3) `IconLaunchUtils.buildRequest()`가 arguments 구성 →
4) `AppRouter`(app_router_*.dart)가 화면 생성 →
5) Screen → Service → Prefs/DB

핵심 파일:
- Routes 상수: `lib/navigation/app_routes_paths.dart`
- Router: `lib/navigation/app_router.dart` + `lib/navigation/app_router_*.dart`
- 아이콘 진입점(메인 카탈로그): `lib/utils/main_feature_icon_catalog.dart`
- 아이콘 탭 인자 구성: `lib/utils/icon_launch_utils.dart`

---

## 2) 기능 요약 (한 줄)

- 거래(지출/수입/환불): 계정별 거래 저장/조회/수정
- 통계: 월별/기간별/카테고리/검색/지출분석 + (1억 모으기/보상 시스템)
- 자산: 자산 입력/목록/배분/분석/내보내기 + 1억 프로젝트
- ROOT: 계정 통합 관리(전체 거래/검색/계정관리/월말정산 등)
- 쇼핑/식료품(WMS): 유통기한/재고/사용량 기록/요리 추천
- 설정: 보안/테마/언어/백업/아이콘관리
- 음성/AI: 음성 입력/대시보드/투자/분석(옵션/플래그에 따라)

---

## 2.1) 기능별 “어디를 고치나” (초고속 맵)

기능 수정 시 아래 4개만 먼저 봐도 대부분 해결됩니다.

- **거래(입력/상세/환불)**: `AppRoutes./transaction/*`
  - Routes: `lib/navigation/app_routes_paths.dart`
  - Router: `lib/navigation/app_router_transactions.dart`
  - UI: `lib/screens/transaction_add_screen.dart`, `lib/screens/transaction_add_detailed_screen.dart`, `lib/screens/transaction_detail_screen.dart`
  - Data: `lib/services/transaction_service.dart` → `lib/services/transaction_db_store.dart`

- **통계(월별/기간/카테고리/검색/분석)**: `AppRoutes./stats/*`
  - Router: `lib/navigation/app_router_stats.dart`
  - UI: `lib/screens/account_stats_screen.dart`, `lib/screens/period_stats_screen.dart`, `lib/screens/category_stats_screen.dart`

- **자산**: `AppRoutes./asset/*`
  - Router: `lib/navigation/app_router_assets.dart`
  - Data: `lib/services/asset_service.dart`

- **유통기한/재고(WMS)**: `AppRoutes./food/*`, `AppRoutes./household/*`
  - UI: `lib/screens/food_expiry_items_screen.dart`, `lib/screens/consumable_inventory_screen.dart`
  - Data: `lib/services/food_expiry_service.dart`, `lib/services/consumable_inventory_service.dart`

- **아이콘 관리/페이지 인덱스**: 정책 문서가 정본
  - 정본: `docs/policies/ICON_MANAGEMENT_SINGLE_SOURCE_KO.md`
  - UI: `lib/screens/icon_management_screen.dart`

---

## 3) 기능별 상세 연결고리 (수정 포인트까지)

표기 규칙:
- **Entry**: 사용자 진입점
- **Route**: `AppRoutes.*`
- **UI**: 주요 Screen
- **Svc**: 핵심 Service
- **Data**: Prefs/DB 저장 지점

### 3-1) 거래(지출/수입/환불)

- Entry: 메인(지출입력) 아이콘, 빠른 입력, 상세 입력
- Route: `/transaction/*`
- UI:
  - `lib/screens/transaction_add_screen.dart`
  - `lib/screens/transaction_add_detailed_screen.dart`
  - `lib/screens/transaction_detail_screen.dart`
  - `lib/screens/refund_transactions_screen.dart`
- Svc:
  - `lib/services/transaction_service.dart`
  - `lib/services/transaction_db_store.dart` (DB 저장소)
- Data:
  - 거래 저장/조회: Transaction DB/스토어
  - 검색: `lib/services/transaction_fts_index_service.dart`

수정 시 체크:
- 라우트 인자(AccountArgs/TransactionAddArgs/TransactionDetailArgs) 파손 여부
- 저장/조회 후 UI 갱신(mounted 가드)

### 3-2) 통계(월별/기간/카테고리/검색/지출분석)

- Entry: 메인(통계) 아이콘
- Route: `/stats/*`
- UI:
  - `lib/screens/account_stats_screen.dart`
  - `lib/screens/period_stats_screen.dart`
  - `lib/screens/category_stats_screen.dart`
  - `lib/screens/account_stats_search_screen.dart`
  - `lib/screens/spending_analysis_screen.dart`
- Svc/Data:
  - 거래 기반 집계: `lib/services/transaction_service.dart`
  - 월별 집계 캐시(있을 경우): `lib/services/monthly_agg_cache_service.dart`

### 3-3) 1억 모으기(통계)

- Entry: 통계 페이지의 `card_discount_stats` 아이콘
- Route: `AppRoutes.cardDiscountStats` (`/stats/card-discount`)
- UI: `lib/screens/card_discount_stats_screen.dart`
- Svc/Data:
  - 거래에서 혜택/포인트 기록 판별: `lib/utils/benefit_aggregation_utils.dart`
  - 포인트/이자 가정: `lib/utils/pref_keys.dart` + SharedPreferences

수정 시 체크:
- “설정에서만 변경” 정책이면 입력 UI는 readOnly 유지

### 3-4) 보상 시스템(통계 전용)

- Entry: 통계 페이지의 `reward_system_stats` 아이콘
- Route: `AppRoutes.rewardSystemStats` (`/stats/reward-system`)
- UI: `lib/screens/reward_system_stats_screen.dart`
- Svc/Data:
  - 누적 카운트: `lib/services/reward_badge_service.dart`
  - 트리거(자동 적립):
    - 거래 저장 시: `lib/services/transaction_service.dart`
    - 식재료 사용 로그: `lib/services/savings_statistics_service.dart`

수정 시 체크:
- 보상 표시는 “통계 화면에서만” 노출(다른 화면에 Chip 재확산 금지)

### 3-5) 자산(입력/목록/배분/분석/내보내기)

- Entry: 메인(자산) 아이콘
- Route: `/asset/*`
- UI:
  - `lib/screens/asset_simple_input_screen.dart`
  - `lib/screens/asset_input_screen.dart` / `asset_detail_input` 흐름
  - `lib/screens/asset_list_screen.dart`
  - `lib/screens/asset_allocation_screen.dart`
  - `lib/screens/asset_portfolio_analysis_screen.dart`
  - `lib/screens/asset_export_screen.dart` / `lib/screens/data_flexible_export_screen.dart`
- Svc/Data:
  - 자산 저장: `lib/services/asset_service.dart`
  - 보안/잠금: `lib/services/asset_security_service.dart` (관련 정책이 켜진 경우)

### 3-6) 1억 프로젝트(자산)

- Entry: 자산 페이지의 `assetProject100m` 아이콘
- Route: `AppRoutes.assetProject100m` (`/asset/project-100m`)
- UI:
  - `lib/screens/one_hundred_million_project_screen.dart`
  - 설정 파트: `one_hundred_million_project_screen_settings.dart`
- Svc/Data:
  - 자산/거래 로드: `asset_service.dart`, `transaction_service.dart`
  - 가정(연이율/포인트모드) 저장: `pref_keys.dart` + SharedPreferences

### 3-7) 식료품/유통기한/WMS(재고)

- Entry: 유통기한/재고 관련 아이콘
- Route: `AppRoutes.foodExpiry` (`/food/expiry`), `AppRoutes.consumableInventory` 등
- UI:
  - `lib/screens/food_expiry_items_screen.dart`
  - `lib/screens/consumable_inventory_screen.dart`
  - `lib/screens/quick_stock_use_screen.dart`
- Svc/Data:
  - 유통기한: `lib/services/food_expiry_service.dart`
  - 재고: `lib/services/consumable_inventory_service.dart`

### 3-8) 아이콘 관리(필수: 단일 기준 문서)

- 단일 기준 문서: `docs/policies/ICON_MANAGEMENT_SINGLE_SOURCE_KO.md`
- UI:
  - `lib/screens/icon_management_screen.dart`
  - `lib/screens/icon_management_root_screen.dart`
  - `lib/screens/icon_management_asset_screen.dart`
- Svc/Data:
  - 페이지 슬롯/순서/라벨: `lib/services/user_pref_service.icons.dart`
  - 메인 페이지 구성: `lib/services/user_pref_service.main_page.dart` + `MainPageConfig`

수정 시 체크(재발 방지):
- Reserved 인덱스 불일치(통계/자산/ROOT/설정)
- moduleKey → pages[index] 매핑 불일치

---

## 4) 기능 수정 ‘레시피’ (자주 하는 작업)

### A) 새 화면을 메인 아이콘으로 노출

1) Route 추가: `lib/navigation/app_routes_paths.dart`
2) Router 케이스 추가: `lib/navigation/app_router_*.dart`
3) 아이콘 카탈로그 추가:
   - 통계/자산/ROOT/설정 아이콘이면 `lib/utils/main_feature_icon_catalog_stats_settings.dart`
   - 지출입력(페이지1)이면 `lib/utils/main_feature_icon_catalog_purchase_income.dart`

### B) 설정(Prefs) 키 추가

- 키 정의: `lib/utils/pref_keys.dart`
- 저장/로드 위치를 한 화면/한 서비스로 ‘단일화’ (분산 저장 금지)

### C) Reserved 정책/인덱스 관련 변경(권장: 변경 금지)

정말 필요할 때만 수행:
- 반드시 `docs/policies/ICON_MANAGEMENT_SINGLE_SOURCE_KO.md`를 먼저 업데이트
- 그 다음 코드를 세트로 수정(문서 내 체크리스트 참고)

---

## 5) 변경 후 최소 검증

- `flutter analyze`
- `flutter test test/smoke` (스모크 전체 실행)
- `flutter test test/smoke/core_flows_smoke_test.dart` (핵심 플로우 스모크: 거래 저장→통계 반영 + 아이콘 ENT→메인 반영)
- `flutter test test/smoke/core_flows_smoke_db_backend_test.dart` (DB 백엔드 스모크: 거래 저장→통계 반영)
- `flutter test test/smoke/tx_db_migration_smoke_test.dart` (마이그레이션 스모크: legacy prefs→DB)
- `flutter test test/smoke/tx_db_caches_smoke_test.dart` (DB 캐시 스모크: FTS/월별집계/월별캐시)
- 기능 단위 스모크(해당 아이콘 진입 → 저장/조회 → 재진입)
- 아이콘/페이지 인덱스 관련 변경이 있다면:
  - ROOT/자산/통계 아이콘 관리 진입 시 Index 표시 확인

---

## 6) 이 문서 운용 규칙

- “정책/연결고리”가 바뀌면 이 문서를 먼저 고칩니다.
- 세부 사용법/UX 설명은 사용자 매뉴얼로 보내고, 이 문서는 **개발 연결고리만** 유지합니다.
