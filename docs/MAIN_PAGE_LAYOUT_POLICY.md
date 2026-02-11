# Main Page Layout Policy (2026-02-03)

## Overview
This document defines the page identity and icon distribution for the main Smart Ledger icon grid pages.
**All references use index-based notation (0-based) to match code implementation.**

## Quick Reference: Pages Identity (인덱스 기준)

| 인덱스 | UI 페이지 | Identity (한글) | Identity (EN) | Item Count | Status |
|---------|----------|----------|----------|-----------|--------|
| 0 | 1 | 대시보드 | Dashboard | 0 (dynamic) | Reserved |
| 1 | 2 | 지출입력 | Expense Input | 5 | Active |
| 2 | 3 | 수입 | Income | 4 | Active |
| 3 | 4 | 통계 | Statistics | 12 | Active |
| 4 | 5 | 자산 | Assets | 5 | Active |
| 5 | 6 | ROOT | Root Management | 6 | Active |
| 6 | 7 | 설정 | Settings | 8 | Active |
| 7 | 8 | 예비 | Spare | 0 | Reserved |
| 8 | 9 | 예비 | Spare | 0 | Reserved |
| 9 | 10 | 예비 | Spare | 0 | Reserved |
| 10 | 11 | 예비 | Spare | 0 | Reserved |
| 11 | 12 | 예비 | Spare | 0 | Reserved |
| 12 | 13 | 예비 | Spare | 0 | Reserved |
| 13 | 14 | 예비 | Spare | 0 | Reserved |
| 14 | 15 | 예비 | Spare | 0 | Reserved |

## Page Layout Structure

### Index 0 (UI: 페이지 1): Home / Screen Saver (홈/보호기)
- **Purpose**: Home page and screen saver launcher
- **Item Count**: 0 (dynamic)
- **Status**: Reserved for home page

### Index 1 (UI: 페이지 2): Expense Input (지출입력)
- **Purpose**: Expense entry and management
- **Items**:
  - `transactionAdd` - 지출 입력 (Add Expense)
  - `quick_simple_expense_input` - 간편 지출(1줄) (Quick Expense)
  - `shopping_prep` - 쇼핑준비 (Shopping Prep)
  - `shopping_cart` - 장바구니 (Cart)
  - `daily_transactions` - 오늘의 지출 (Today)
- **Item Count**: 5
- **Status**: Active

### Index 2 (UI: 페이지 3): Income (수입)
- **Purpose**: Income entry and distribution
- **Items**:
  - `income_add` - 수입 입력 (Add Income)
  - `income_detail` - 수입 상세 (Income Detail)
  - `income_split` - 수입배분 (Income Split)
  - `refund_menu` - 반품 (Refunds)
- **Item Count**: 4
- **Status**: Active

### Index 3 (UI: 페이지 4): Statistics (통계)
- **Purpose**: Financial statistics and reporting
- **Items**:
  - `accountStats` - 통계 (Stats)
  - `fixed_cost_stats` - 고정비 통계 (Fixed Costs)
  - `period_stats_7d` - 주간 리포트 (Weekly Report)
  - `period_stats_1m` - 월간 리포트 (Monthly Report)
  - `period_stats_3m` - 분기 리포트 (Quarterly Report)
  - `period_stats_6m` - 반기 리포트 (Half-year Report)
  - `period_stats_1y` - 연간 리포트 (Annual Report)
  - `period_stats_10y` - 10년 (10 Years)
  - `accountStatsSearch` - 검색 (Search)
  - `shopping_cheapest_month` - 최저가 달 (Cheapest Month)
  - `card_discount_stats` - 카드 할인 (Card Discounts)
  - `points_motivation_stats` - 포인트 (Points)
- **Item Count**: 12
- **Status**: Active

### Index 4 (UI: 페이지 5): Assets (자산)
- **Purpose**: Asset management and tracking
- **Items**:
  - `asset_dashboard` - 자산 대시보드 (Asset Dashboard)
  - `asset_input` - 자산 입력 (Add Asset)
  - `asset_trending_up` - 상승 자산 (Allocation)
  - `asset_assessment` - 자산 평가 (Assessment)
  - `icon_management_asset_entry` - 아이콘 관리 (Icon Manager)
- **Item Count**: 5
- **Status**: Active (moved to index 4 on 2026-02-03)

### Index 5 (UI: 페이지 6): ROOT (루트 관리)
- **Purpose**: Root-level account and system management
- **Items**:
  - `root_transactions` - 전체 거래 (All Transactions)
  - `root_search` - 검색 (Search)
  - `root_account_manage` - 계정 관리 (Account Manager)
  - `root_month_end` - 월말 정산 (Month-end Close)
  - `root_screen_saver_settings` - 보호기 설정 (Screen Protection)
  - `icon_management_root_entry` - 아이콘 관리 (Icon Manager)
- **Item Count**: 6
- **Status**: Active

### Index 6 (UI: 페이지 7): Settings (설정)
- **Purpose**: App-wide settings and preferences
- **Items**:
  - `settings` - 설정 (Settings)
  - `settings_screen_saver_settings` - 보호기 설정 (Screen Protection)
  - `theme_settings` - 테마 (Theme)
  - `display_settings` - 표시/폰트 (Display/Font)
  - `language_settings` - 언어 설정 (Language)
  - `currency_settings` - 통화 설정 (Currency)
  - `backup` - 백업 (Backup)
  - `trash` - 휴지통 (Trash)
- **Item Count**: 8
- **Status**: Active

### Index 7-14 (UI: 페이지 8-15): Spare (예비)
- **Purpose**: Reserved for future expansion
- **Item Count**: 0 (empty)
- **Status**: Reserved

## Localization Rules

All icon labels support bilingual display:
- **Korean Locale**: Shows Korean label with English in parentheses (if available)
  - Example: `통계 (Stats)`, `자산 입력 (Add Asset)`
- **English Locale**: Shows English label only
  - Example: `Stats`, `Add Asset`

## Icon Management

### Reserved Pages by Feature
- **Assets**: Index 4 (UI: 페이지 5) - 자산 관련 아이콘
- **Root**: Index 5 (UI: 페이지 6) - ROOT 관리 아이콘
- **Settings**: Index 6 (UI: 페이지 7) - 설정 관련 아이콘

### Icon Placement Rules
- **Reserved Module Icons**: Cannot be placed on non-policy pages
- **Asset Icons**: Restricted to Index 4 (UI: 페이지 5) for security/UX consistency
- **Root Icons**: Restricted to Index 5 (UI: 페이지 6) for administrative separation
- **Settings Icons**: Restricted to Index 6 (UI: 페이지 7) for organization

## Recent Changes (2026-02-03)

| Change | Description |
|--------|-------------|
| Index notation unified | All references use index-based (0-based) with UI page numbers in parentheses |
| Asset page confirmed | Index 4 (UI: 페이지 5) - 자산 기능 고정 |

## Module Key Mapping

The app uses logical module keys for icon access (preferred over hard-coded page indices):

```
'page1'     → pages[0]  (대시보드/Dashboard)
'purchase'  → pages[1]  (거래/Transactions)
'income'    → pages[2]  (수입/Income)
'stats'     → pages[3]  (통계/Statistics)
'asset'     → pages[4]  (자산/Assets)
'root'      → pages[5]  (ROOT/Root Management)
'settings'  → pages[6]  (설정/Settings)
```

## Notes

- Dynamic page recreation is supported via `MainFeatureIconCatalog.recreatePages()`
- Per-account icon ordering is persisted in SharedPreferences
- Empty slots can be hidden per-account via `UserPrefService.setHideEmptySlots()`
- The first page (index 0) has special behavior for screen saver shortcut placement
