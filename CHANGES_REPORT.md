# 코드 변경 리포트 (Git diff 기반)

**생성일**: 2025-12-06  
**총 변경 파일**: 50개  
**전체 변경**: +1859 줄, -965 줄

---

## 🆕 추가 변경 (2025-12-19)

### 메인 페이지 저장 구조 pageId 기반으로 전환
**대상**: AccountMainScreen / UserPrefService

**내용**:
- 메인 페이지 구성을 index 중심에서 pageId/moduleKey 중심으로 전환하여, 페이지 인덱스 변경/예약 페이지 확장 시 충돌 위험을 낮춤
- `main_page_configs_v1`(JSON) + `main_page_last_id` + `pageId_<id>_*` 키 체계 도입
- 레거시 index 기반 키는 fallback/sync로 호환 유지

**변경 파일**:
- lib/screens/account_main_screen.dart
- lib/services/user_pref_service.dart
- lib/models/main_page_config.dart

### Drift DB: MigrationStrategy 뼈대 추가(스키마 변경 없음)
**대상**: AppDatabase (Drift)

**내용**:
- `MigrationStrategy(onCreate/onUpgrade/beforeOpen)`를 명시해 향후 schemaVersion 증가 시 업그레이드 경로를 고정
- `PRAGMA foreign_keys = ON` 활성화

**변경 파일**:
- lib/database/app_database.dart

---

## 🆕 추가 변경 (2025-12-18)

### 메인 가로 PageView 인덱스 저장/복원
**대상**: AccountMainScreen (Smart Ledger 메인 1~6)

**내용**:
- 가로 스와이프(PageView) 현재 페이지 인덱스를 계정별로 SharedPreferences에 저장
- 앱 재실행 시 마지막으로 보던 페이지 인덱스로 자동 복원

**변경 파일**:
- lib/screens/account_main_screen.dart
- lib/services/user_pref_service.dart
- lib/utils/pref_keys.dart

---

## 📊 주요 변경 사항

### 1. 거래 추가 화면 (transaction_add_screen.dart)
**변경**: +18, -12 줄

**추가 기능**:
- `_isEditing` getter: 편집 모드 판별
- `_typeOptions` getter: 신규 입력에서 예금 타입 제외
- 드롭다운에서 TransactionType.savings 필터링 (신규 입력 시)
- 기존 예금 거래 편집 시에만 예금 타입 표시

**영향**: ✅ 사용자 정의 기능 유지, 기존 거래 편집 기능 보존

---

### 2. 달력 화면 (calendar_screen.dart)
**변경**: +479, -81 줄 (크게 확장됨)

**추가 기능**:
- 검색 기능 (상품명, 결제수단, 메모 검색)
- 거래 유형 필터링 버튼 (수입, 지출, 예금)
- 월별 합계 표시 (선택된 유형만)
- 현재 월의 거래만 필터링
- 검색 상태 표시 UI

**구조 변경**:
- 기존: AppBar + TableCalendar만
- 현재: SafeArea로 고정된 상단 영역 + 스크롤 가능한 캘린더/거래 목록

**영향**: ⚠️ 화면 동작 변경 (UI 확장됨)

---

### 3. 계정 홈 화면 (account_home_screen.dart)
**변경**: +380, -266 줄 (큰 리팩토링)

**추가/변경**:
- utils import 추가 (date_formats, CurrencyFormatter)
- DateFormatter 사용으로 통일
- 레이아웃 및 스타일 개선

**영향**: ✅ 포맷팅 일관성 향상

---

### 4. 자산 화면 (asset_tab_screen.dart)
**변경**: +494, -251 줄

**추가 기능**:
- state_placeholders 위젯 추가 (EmptyState, LoadingCardListSkeleton)
- 로딩, 에러, 빈 상태 처리 개선
- 자산 타입별 필터링 및 정렬

**영향**: ✅ UX 개선 (상태별 피드백 추가)

---

### 5. 백업 화면 (backup_screen.dart)
**변경**: +369, -142 줄

**추가 기능**:
- state_placeholders 위젯 적용
- 로딩 상태 관리 개선
- 에러 재시도 버튼
- 빈 상태 안내

**영향**: ✅ 사용자 경험 개선

---

### 6. 저장 계획 양식 (savings_plan_form_screen.dart)
**변경**: +89, -23 줄

**추가 기능**:
- utils import (CurrencyFormatter, DateFormatter)
- 포맷팅 통일
- 입력 검증 개선

**영향**: ✅ 일관성 향상

---

### 7. 설정 화면 (settings_screen.dart)
**변경**: 바이너리 파일 변경 (구조 변경)

**영향**: ⚠️ 바이너리 변경으로 인해 상세 내용 확인 필요

---

## 📁 신규 추가된 파일들 (사용 안 함)

### Utils 라이브러리 (lib/utils/)
- date_formats.dart
- date_formatter.dart
- number_formats.dart
- currency_formatter.dart
- validators.dart
- dialog_utils.dart
- snackbar_utils.dart
- color_utils.dart
- constants.dart
- form_field_helpers.dart
- thousands_input_formatter.dart
- type_converters.dart
- pref_keys.dart (서비스에서 사용 중)
- account_utils.dart
- collapsible_section.dart
- utils.dart (barrel file)
- utils_example.dart

### 서비스 (lib/services/)
- search_service.dart (미사용)
- chart_data_service.dart (미사용)
- income_split_service.dart (미사용)

### 위젯 (lib/widgets/)
- search_bar_widget.dart (미사용)
- filterable_chart_widget.dart (미사용)
- comparison_widgets.dart (미사용)
- state_placeholders.dart (일부 사용)

### 모델 (lib/models/)
- search_filter.dart (미사용)

### 테스트 & 문서
- test/utils/validators_test.dart
- test/services/transaction_service_test.dart
- test/models/transaction_test.dart
- lib/utils/README.md
- lib/utils/REFACTORING_GUIDE.md
- lib/utils/utils_example.dart

---

## 🔍 실제 적용된 변경사항 정리

### ✅ 실제 사용 중
1. **date_formats.dart / number_formats.dart**
   - root_transaction_list.dart
   - account_home_screen.dart
   - calendar_screen.dart (새로 추가)
   - emergency_fund_list_screen.dart
   - savings_plan_form_screen.dart

2. **state_placeholders.dart**
   - root_transaction_list.dart
   - asset_tab_screen.dart
   - backup_screen.dart

3. **pref_keys.dart**
   - 모든 서비스에서 SharedPreferences 키 관리

4. **utils.dart (barrel file)**
   - 다수의 화면에서 import

5. **예금 거래추가 숨김**
   - transaction_add_screen.dart (신규 입력에서만 숨김)

### ❌ 미사용 (단순 추가만 됨)
1. search_service.dart
2. chart_data_service.dart
3. income_split_service.dart
4. search_bar_widget.dart
5. filterable_chart_widget.dart
6. comparison_widgets.dart
7. validators.dart (정의만 됨)
8. dialog_utils.dart (정의만 됨)
9. snackbar_utils.dart (정의만 됨)
10. color_utils.dart (정의만 됨)

---

## 🎯 권장사항

### 유지해야 할 것
- ✅ date_formats, number_formats (좋은 추상화)
- ✅ state_placeholders (UX 개선)
- ✅ pref_keys (중앙화된 키 관리)
- ✅ 예금 타입 숨김 (요구사항 완료)
- ✅ calendar_screen 개선 (UX 향상)

### 검토/제거 고려
- ⚠️ search_service, chart_data_service (미사용)
- ⚠️ search_bar_widget, filterable_chart_widget (미연결)
- ⚠️ validators, dialog_utils, snackbar_utils (정의만 됨)
- ⚠️ income_split_service (미사용)

---

## 빌드 상태
✅ **성공**: flutter build apk --release (293.9MB)

---

## 정리 필요 작업
1. 미사용 파일 제거 여부 결정
2. calendar_screen 최종 검증
3. 새로운 utils들 실제 화면 연결 (또는 제거)
4. 테스트 파일 최종 정리
