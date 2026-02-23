# 미사용 파일 18개 - 상세 기능 설명

## 1️⃣ Services (3개)

### 1. search_service.dart (147줄)
**목적**: 거래 검색 및 필터링 로직

**주요 기능**:
- `searchTransactions()`: 검색 조건으로 거래 필터링
  - 상품명 검색
  - 결제수단 검색
  - 메모 검색
  - 금액 범위 검색
  - 날짜 범위 검색
- `calculateStats()`: 검색 결과 통계 계산
- `_matchText()`, `_matchAmount()`, `_matchDate()`: 매칭 헬퍼 함수

**사용 목적**: 고급 거래 검색 기능 지원
**상태**: **정의만 됨, 화면에서 미사용**

---

### 2. chart_data_service.dart (240줄)
**목적**: 차트 데이터 생성 및 처리

**주요 기능**:
- `ChartAggregation` enum: 일별/주별/월별 집계
- `ChartDataPoint` class: 차트 데이터 포인트 (x축, y축, 거래 건수, 날짜)
- `ChartData` class: 차트 데이터 + 통계
- `getChartData()`: 기간별 차트 데이터 생성
  - 일별/주별/월별 집계
  - 거래 유형별 분류 (수입/지출/예금)
  - 누적 합계, 평균 계산
- `compareChartData()`: 기간 비교 차트

**사용 목적**: 차트/그래프 렌더링용 데이터 준비
**상태**: **정의만 됨, 화면에서 미사용**

---

### 3. income_split_service.dart (106줄)
**목적**: 수입 배분 설정 관리 (예금/예산/비상금)

**주요 기능**:
- `IncomeSplit` class: 수입 배분 데이터
  - 총 수입
  - 예금액
  - 예산액
  - 비상금액
- `IncomeSplitService` singleton:
  - `setSplit()`: 배분 설정 저장
  - `getSplit()`: 배분 설정 조회
  - `loadSplits()`, `saveSplits()`: 파일 I/O

**사용 목적**: 수입 자동 배분 기능
**상태**: **정의만 됨, 화면에서 미사용**

---

## 2️⃣ Utils (10개)

### 1. validators.dart (182줄)
**목적**: 입력 검증 헬퍼 함수

**검증 종류**:
- `required()`: 필수 입력 검증
- `positiveNumber()`: 양수 검증 (0 초과)
- `nonNegativeNumber()`: 음이 아닌 수 검증 (0 이상)
- `integer()`: 정수 검증
- `positiveInteger()`: 양의 정수 검증
- `accountName()`: 계정명 (2-20자)
- `amount()`: 금액 검증
- `date()`: 날짜 형식 검증
- `email()`: 이메일 검증
- `phone()`: 전화번호 검증 (한국)
- `range()`: 범위 검증

**사용 목적**: 폼 입력 검증
**상태**: **정의만 됨, 실제 폼에서 미사용**

---

### 2. dialog_utils.dart (263줄)
**목적**: 다이얼로그 표시 헬퍼

**제공 다이얼로그**:
- `showConfirmDialog()`: 확인/취소 다이얼로그
- `showDeleteConfirmDialog()`: 삭제 확인 (위험 표시)
- `showErrorDialog()`: 에러 다이얼로그
- `showSuccessDialog()`: 성공 다이얼로그
- `showInfoDialog()`: 정보 다이얼로그
- `showInputDialog()`: 텍스트 입력 다이얼로그
- `showLoadingDialog()`: 로딩 다이얼로그
- `showCustomDialog()`: 커스텀 다이얼로그

**사용 목적**: 일관된 다이얼로그 스타일 제공
**상태**: **정의만 됨, 화면에서 미사용**

---

### 3. snackbar_utils.dart (130줄)
**목적**: 스낵바 표시 헬퍼

**제공 메서드**:
- `show()`: 기본 스낵바
- `showSuccess()`: 성공 스낵바 (초록색 + ✓)
- `showError()`: 에러 스낵바 (빨간색 + ✕)
- `showWarning()`: 경고 스낵바 (주황색 + ⚠)
- `showInfo()`: 정보 스낵바 (파란색)
- `showLoading()`: 로딩 스낵바 (진행 바 포함)

**사용 목적**: 일관된 알림 스타일
**상태**: **정의만 됨, 화면에서 미사용**

---

### 4. color_utils.dart (146줄)
**목적**: 색상 처리 유틸리티

**기능**:
- `getAmountColor()`: 금액별 색상 (양수/음수/0)
- `getIncomeExpenseColor()`: 수입/지출 색상
- `getProgressColor()`: 진행률별 색상 (30%, 70%, 100%)
- `withOpacity()`: 투명도 조정
- `adjustBrightness()`: 밝기 조정
- `darken()`, `lighten()`: 색상 변경
- `fromHex()`, `toHex()`: 색상 변환
- `getCategoryColor()`: 카테고리별 색상
- `getLighterShade()`, `getDarkerShade()`: 색상 변형

**사용 목적**: 일관된 색상 관리
**상태**: **정의만 됨, 화면에서 미사용**

---

### 5. form_field_helpers.dart (90줄)
**목적**: 폼 필드 빌더 헬퍼

**제공 위젯**:
- `buildTextFormField()`: 텍스트 입력 필드
- `buildNumberFormField()`: 숫자 입력 필드 (천 단위 쉼표)
- `buildDatePickerField()`: 날짜 선택 필드
- `buildDropdownFormField()`: 드롭다운 필드
- `buildSwitchFormField()`: 토글 필드

**사용 목적**: 폼 필드 일관성
**상태**: **정의만 됨, 화면에서 미사용**

---

### 6. thousands_input_formatter.dart (50줄)
**목적**: 숫자 입력 시 천 단위 쉼표 자동 추가

**기능**:
- 입력 중 자동 쉼표 추가
- 백스페이스 처리
- 음수 지원

**사용 목적**: 금액 입력 필드 포맷팅
**상태**: **정의만 됨, 화면에서 미사용**

---

### 7. type_converters.dart (80줄)
**목적**: 열거형 <-> 문자열 변환

**변환**:
- `TransactionType` ↔ 문자열/한글
- `TimePeriod` ↔ 문자열
- `AccountType` ↔ 문자열/한글
- `AssetType` ↔ 문자열/한글

**사용 목적**: 데이터 직렬화/역직렬화
**상태**: **정의만 됨, 화면에서 미사용**

---

### 8. constants.dart (150줄)
**목적**: 앱 전역 상수 정의

**포함 상수**:
- API 엔드포인트
- 기본 값 (페이징, 타임아웃)
- 정규식 패턴
- 기본 통화 (KRW)
- 날짜 형식

**사용 목적**: 매직 넘버 제거
**상태**: **정의만 됨, 일부 중복된 상수**

---

### 9. account_utils.dart (120줄)
**목적**: 계정 관련 유틸리티

**기능**:
- `getAccountTypeColor()`: 계정 유형별 색상
- `getAccountTypeIcon()`: 계정 유형별 아이콘
- `getAccountTypeLabel()`: 계정 유형 레이블
- `calculateAccountHealth()`: 계정 건강도 계산

**사용 목적**: 계정 정보 표시
**상태**: **정의만 됨, 화면에서 미사용**

---

### 10. collapsible_section.dart (180줄)
**목적**: 접기/펼치기 가능한 섹션 위젯

**기능**:
- 헤더 클릭 시 토글
- 애니메이션 효과
- 자동 높이 조정
- 커스텀 스타일

**사용 목적**: 복잡한 폼 간소화
**상태**: **정의만 됨, 화면에서 미사용**

---

## 3️⃣ Widgets (3개)

### 1. search_bar_widget.dart (195줄)
**목적**: 재사용 가능한 검색바 위젯

**기능**:
- 카테고리 선택 드롭다운 (상품명/결제수단/메모/금액/날짜)
- 검색어 입력 필드
- 디바운싱 (500ms)
- 자동 완성 힌트
- 검색 초기화 버튼

**상태**: **정의만 됨, 화면에서 미사용** (달력화면에서는 직접 구현함)

---

### 2. filterable_chart_widget.dart (300줄+)
**목적**: 필터링 가능한 차트 위젯

**기능**:
- 기간 선택 (일/주/월)
- 거래 유형 필터
- 차트 렌더링 (FlChart)
- 상세 통계 표시
- 비교 기능

**상태**: **정의만 됨, 화면에서 미사용**

---

### 3. comparison_widgets.dart (200줄+)
**목적**: 기간 비교 위젯 모음

**포함 위젯**:
- `ExpenseComparisonWidget`: 지출 비교
- `IncomeComparisonWidget`: 수입 비교
- `SavingsComparisonWidget`: 예금 비교
- `ComparisonChartWidget`: 비교 차트

**상태**: **정의만 됨, 화면에서 미사용**

---

## 4️⃣ Models (1개)

### 1. search_filter.dart (80줄)
**목적**: 검색 필터 데이터 모델

**포함**:
- `SearchFilter` class: 검색 쿼리 + 카테고리
- `SearchCategory` enum: 검색 대상 (상품명/결제수단/메모/금액/날짜)
- `SearchStats` class: 검색 통계

**상태**: **정의만 됨, 화면에서 미사용**

---

## 📊 요약표

| 파일명 | 줄수 | 목적 | 상태 |
|--------|------|------|------|
| search_service.dart | 147 | 검색/필터링 | ❌ |
| chart_data_service.dart | 240 | 차트 데이터 | ❌ |
| income_split_service.dart | 106 | 수입 배분 | ❌ |
| validators.dart | 182 | 입력 검증 | ❌ |
| dialog_utils.dart | 263 | 다이얼로그 | ❌ |
| snackbar_utils.dart | 130 | 스낵바 | ❌ |
| color_utils.dart | 146 | 색상 관리 | ❌ |
| form_field_helpers.dart | 90 | 폼 필드 | ❌ |
| thousands_input_formatter.dart | 50 | 숫자 포맷팅 | ❌ |
| type_converters.dart | 80 | 타입 변환 | ❌ |
| constants.dart | 150 | 전역 상수 | ❌ |
| account_utils.dart | 120 | 계정 유틸 | ❌ |
| collapsible_section.dart | 180 | 접기 섹션 | ❌ |
| search_bar_widget.dart | 195 | 검색바 | ❌ |
| filterable_chart_widget.dart | 300+ | 차트 위젯 | ❌ |
| comparison_widgets.dart | 200+ | 비교 위젯 | ❌ |
| search_filter.dart | 80 | 검색 모델 | ❌ |
| - | - | - | - |
| **합계** | **~2800** | **18개 파일** | **모두 미사용** |

---

## 💡 평가

### 🟢 유용한 파일들 (나중에 사용 가능)
1. **validators.dart** - 폼 검증에 필요 (계정/예금목표 추가 시)
2. **dialog_utils.dart** - 일관된 다이얼로그 스타일
3. **snackbar_utils.dart** - 알림 통일
4. **search_service.dart** - 고급 검색 기능 필요 시
5. **chart_data_service.dart** - 대시보드/통계 화면 필요 시

### 🟡 선택적 사용
1. **color_utils.dart** - 색상 일관성 필요 시
2. **form_field_helpers.dart** - 폼 일관성 필요 시
3. **type_converters.dart** - 데이터 변환 필요 시
4. **account_utils.dart** - 계정 상세 정보 필요 시

### 🔴 즉시 제거 고려
1. **comparison_widgets.dart** - 대시보드 없음
2. **filterable_chart_widget.dart** - 대시보드 없음
3. **income_split_service.dart** - 자동 배분 미구현
4. **search_bar_widget.dart** - 달력에서 직접 구현함
5. **thousands_input_formatter.dart** - 기존 코드에서 처리

---

## 🎯 추천 조치

**현재 상태**: 
- ✅ 기본 기능 정상 작동
- ⚠️ 불필요한 코드 누적으로 유지보수 부담 증가

**권장안**:
1. **즉시 제거** (3-5개): comparison_widgets, filterable_chart_widget, income_split_service, search_bar_widget, thousands_input_formatter
2. **아카이브** (5-8개): 백업 후 주석 처리 (나중에 필요할 수 있음)
3. **선택적 통합** (5-10개): validators, dialog_utils 등을 기존 화면에 점진적으로 연결
