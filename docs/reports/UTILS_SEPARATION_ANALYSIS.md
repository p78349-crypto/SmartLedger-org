# Utils 분리 상태 분석 (account_stats_screen.dart)

## ✅ 이미 Utils에 분리된 기능

### 1. 날짜 포맷팅 (date_formatter.dart)
- ✅ `DateFormat('yyyy-MM-dd')` → `DateFormatter.defaultDate`
- ✅ `DateFormat('yyyy년 M월')` → `DateFormatter.monthLabel`
- ✅ `DateFormat('yyyy.MM')` → `DateFormatter.rangeMonth`
- ✅ `DateFormat('M월')` → `DateFormatter.shortMonth`
- ✅ `DateFormat('M월 d일')` → `DateFormatter.monthDay`

### 2. 통화 포맷팅 (currency_formatter.dart)
- ✅ `_formatCurrency()` → `CurrencyFormatter.format()`
- ✅ `_formatAmountByType()` → `CurrencyFormatter.formatSigned()`
- ✅ `_formatSignedAmount()` → `CurrencyFormatter.formatSigned()`

### 3. 색상 유틸 (color_utils.dart)
- ✅ `_colorWithOpacity()` → `ColorUtils.withOpacity()`
- ✅ 색상 밝기 조정 → `ColorUtils.adjustBrightness()`

### 4. 차트 유틸 (chart_utils.dart)
- ✅ `_ChartDisplay` enum → `ChartDisplayType` enum
- ✅ 차트 타입별 아이콘 → `ChartDisplayType.icon`
- ✅ 차트 타입별 레이블 → `ChartDisplayType.label`

### 5. 다이얼로그 (dialog_utils.dart)
- ✅ 확인 다이얼로그
- ✅ 에러 다이얼로그
- ✅ 로딩 다이얼로그

### 6. 스낵바 (snackbar_utils.dart)
- ✅ 성공 메시지
- ✅ 에러 메시지
- ✅ 정보 메시지

### 7. 검증 (validators.dart)
- ✅ 양수 검증
- ✅ 필수 입력 검증
- ✅ 계정명 검증

---

## ❌ 아직 분리되지 않은 기능 (account_stats_screen.dart에 존재)

### 1. 차트 관련 헬퍼 함수
```dart
Line 387: String _formatAxisLabel(double value)  // 축 라벨 포맷 (1000 → 1k)
Line 401: Color _sliceColor(Color base, int index, int totalSlices)  // 파이 차트 색상
```
**제안:** `chart_utils.dart`에 추가
- `ChartUtils.formatAxisLabel(double value)`
- `ChartUtils.generateSliceColor(Color base, int index, int total)`

### 2. 거래 타입 관련
```dart
Line 420: String _typeLabel([TransactionType? type])  // "지출", "수입", "저축"
Line 425: Color _typeColor(ThemeData theme)  // 현재 타입의 색상
Line 428: Color _typeColorFor(TransactionType type, ThemeData theme)  // 타입별 색상
```
**제안:** 새 파일 `lib/utils/transaction_type_utils.dart` 생성
- `TransactionTypeUtils.getLabel(TransactionType type)`
- `TransactionTypeUtils.getColor(TransactionType type, ThemeData theme)`

### 3. 금액 계산/집계
```dart
Line 497: double _sumAmounts(Iterable<Transaction> transactions)  // 거래 합계
```
**제안:** `lib/utils/transaction_utils.dart` 생성
- `TransactionUtils.sumAmounts(Iterable<Transaction> transactions)`
- `TransactionUtils.filterByDate(List<Transaction>, DateTime date)`
- `TransactionUtils.filterByType(List<Transaction>, TransactionType type)`
- `TransactionUtils.groupByDate(List<Transaction>)`

### 4. 날짜 범위 포맷팅
```dart
Line 1493: String _formatRangeLabel(DateTime start, DateTime end)  // "2025.01 ~ 2025.12"
Line 1499: int _monthsInYearWithinRange(DateTime year, DateTime start, DateTime end)
```
**제안:** `date_formatter.dart`에 추가
- `DateFormatter.formatRangeLabel(DateTime start, DateTime end)`
- `DateFormatter.getMonthsInYearWithinRange(DateTime year, DateTime start, DateTime end)`

### 5. 고정비 관련
```dart
Line 1517: String _fixedCostTitleForMonths(int months)  // "고정비 (1개월)", "고정비 (3개월)"
Line 2390: double _fixedCostTotalForMonth(DateTime _)
Line 2448: String _fixedCostSubtitle(FixedCost cost)  // "매월 15일 · 주거"
```
**제안:** 새 파일 `lib/utils/fixed_cost_utils.dart` 생성
- `FixedCostUtils.getTitleForMonths(int months)`
- `FixedCostUtils.calculateTotalForMonth(List<FixedCost>, DateTime)`
- `FixedCostUtils.formatSubtitle(FixedCost cost)`

### 6. 거래 상세 다이얼로그
```dart
Line 527: _showTransactionActionDialog()  // 수정/반품/삭제 메뉴
Line 713: _showRefundDialog()  // 반품 다이얼로그
```
**제안:** 새 파일 `lib/widgets/transaction_action_dialog.dart` 생성
- `showTransactionActionDialog(BuildContext, Transaction, callbacks)`
- `showRefundDialog(BuildContext, Transaction, callback)`

### 7. 차트 데이터 변환
```dart
_ChartPoint 클래스 정의 및 변환 로직
```
**제안:** `chart_utils.dart`에 추가
- `class ChartPoint` (month, total 포함)
- `ChartUtils.convertToChartPoints(List<Transaction>)`

---

## 📊 분리 우선순위

### 🔴 높음 (즉시 분리 권장)
1. **거래 타입 유틸** - 여러 화면에서 재사용 가능
2. **거래 계산/필터 유틸** - 핵심 비즈니스 로직
3. **차트 헬퍼 함수** - 다른 통계 화면에서도 사용 가능

### 🟡 중간 (점진적 분리)
4. **날짜 범위 포맷팅** - date_formatter.dart 확장
5. **고정비 유틸** - fixed_cost 관련 화면에서 재사용

### 🟢 낮음 (필요시 분리)
6. **거래 다이얼로그 위젯** - 특정 화면에서만 사용
7. **차트 데이터 변환** - 통계 화면 전용

---

## 📝 다음 단계

1. ✅ **분리된 기능 확인** - README.md에 문서화 완료
2. ❌ **미분리 기능 식별** - 이 문서로 완료
3. ⏭️ **우선순위별 분리 작업** 시작
   - transaction_type_utils.dart 생성
   - transaction_utils.dart 생성
   - chart_utils.dart 확장
   - date_formatter.dart 확장
   - fixed_cost_utils.dart 생성

---

## 🎯 기대 효과

- **코드 재사용성** ↑ (다른 화면에서도 동일 로직 사용)
- **테스트 용이성** ↑ (독립적인 유닛 테스트 가능)
- **파일 크기** ↓ (account_stats_screen.dart 3197줄 → 약 2500줄)
- **유지보수성** ↑ (수정 시 한 곳만 변경)
- **가독성** ↑ (화면 로직과 유틸리티 분리)
