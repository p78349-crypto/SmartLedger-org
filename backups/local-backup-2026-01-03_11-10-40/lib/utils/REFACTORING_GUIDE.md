# Utils 리팩토링 가이드

## ✅ 완료된 리팩토링

### 1. root_summary_card.dart
- ✅ `NumberFormat('#,##0')` → `CurrencyFormatter.format()`
- ✅ `formatSigned()` 로컬 함수 → `CurrencyFormatter.formatSigned()`
- ✅ `formatOutflow()` 로컬 함수 → `CurrencyFormatter.formatOutflow()`

### 2. account_home_screen.dart  
- ✅ `NumberFormat('#,##0')` → `CurrencyFormatter.format()`
- ✅ `DateFormat('yyyy-MM-dd')` → `DateFormatter.formatDate()`
- ✅ 모든 금액 포맷팅을 CurrencyFormatter로 통일

### 3. trash_screen.dart
- ✅ `DateFormat('yyyy-MM-dd HH:mm')` → `DateFormatter.formatDateTime()`
- ⚠️ ScaffoldMessenger 일부 변경 (전체 변경은 추가 작업 필요)

## 📋 남은 리팩토링 대상

### 우선순위 높음
1. **account_stats_screen.dart**
   - `NumberFormat('#,##0')` 제거 → `CurrencyFormatter`
   - `DateFormat('yyyy-MM-dd')` 제거 → `DateFormatter`

2. **top_level_main_screen.dart**
   - `NumberFormat('#,##0')` 제거 → `CurrencyFormatter`
   - `DateFormat('yyyy-MM-dd')` 제거 → `DateFormatter`

3. **root_account_screen.dart**
   - `NumberFormat('#,##0')` 제거 → `CurrencyFormatter`
   - `DateFormat('yyyy-MM-dd')` 제거 → `DateFormatter`

4. **transaction_add_screen.dart**
   - `DateFormat('yyyy-MM-dd')` 제거 → `DateFormatter`

5. **savings_plan_form_screen.dart**
   - `DateFormat('yyyy-MM-dd')` 제거 → `DateFormatter`

### 우선순위 중간
- **DialogUtils 활용**
  - 반복되는 `showDialog` 패턴을 `DialogUtils`로 교체
  - 삭제 확인 다이얼로그 → `DialogUtils.showDeleteConfirmDialog()`

- **SnackbarUtils 활용**
  - `ScaffoldMessenger.of(context).showSnackBar()` 패턴 교체

- **Validators 활용**
  - Form 검증 로직을 `Validators`로 통일

## 🔄 교체 패턴

### NumberFormat 교체
```dart
// Before
final formatter = NumberFormat('#,##0');
Text('${formatter.format(amount)}원')

// After
import '../utils/utils.dart';
Text(CurrencyFormatter.format(amount))
```

### DateFormat 교체
```dart
// Before
final dateFormat = DateFormat('yyyy-MM-dd');
Text(dateFormat.format(date))

// After
import '../utils/utils.dart';
Text(DateFormatter.formatDate(date))
```

### SnackBar 교체
```dart
// Before
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('저장되었습니다')),
);

// After
SnackbarUtils.showSuccess(context, '저장되었습니다');
```

### Dialog 교체
```dart
// Before
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('삭제 확인'),
    content: Text('삭제하시겠습니까?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소')),
      TextButton(onPressed: () => Navigator.pop(context, true), child: Text('삭제')),
    ],
  ),
);

// After
final confirmed = await DialogUtils.showDeleteConfirmDialog(
  context,
  itemName: '항목명',
);
```

## 🎯 기대 효과

1. **코드 중복 제거**: 9개 파일에서 NumberFormat 중복 제거
2. **일관성 향상**: 모든 화면에서 동일한 포맷 사용
3. **유지보수 용이**: 포맷 변경 시 한 곳만 수정
4. **가독성 향상**: 의도가 명확한 함수명 사용

## 📝 점진적 적용 방법

새로운 기능 개발 시:
1. 자동으로 `import '../utils/utils.dart';` 추가
2. NumberFormat 대신 `CurrencyFormatter` 사용
3. DateFormat 대신 `DateFormatter` 사용
4. ScaffoldMessenger 대신 `SnackbarUtils` 사용
5. 반복 다이얼로그는 `DialogUtils` 사용

기존 코드 수정 시:
- 해당 파일을 수정할 때 함께 리팩토링
- 전체 파일을 한 번에 수정하지 않아도 됨
- 점진적으로 Utils 적용
