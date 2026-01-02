# Utils 라이브러리 사용 가이드

## 📚 개요
`lib/utils/` 폴더에는 프로젝트 전반에서 사용할 수 있는 유틸리티 클래스들이 포함되어 있습니다.

## 📦 포함된 유틸리티

### 1. **DateFormatter** - 날짜 포맷팅
날짜와 시간을 다양한 형식으로 변환합니다.

```dart
import 'package:vccode1/utils/utils.dart';

// 기본 날짜 포맷
DateFormatter.formatDate(DateTime.now()); // "2025-12-05"

// 날짜 + 시간
DateFormatter.formatDateTime(DateTime.now()); // "2025-12-05 14:30"

// 월 라벨
DateFormatter.formatMonthLabel(DateTime.now()); // "2025년 12월"

// 파일명용 (시간 포함)
DateFormatter.formatForFileName(DateTime.now(), includeTime: true); // "20251205_143000"

// 월 시작일/마지막일
DateFormatter.getMonthStart(DateTime.now());
DateFormatter.getMonthEnd(DateTime.now());

// 같은 날짜인지 확인
DateFormatter.isSameDay(date1, date2);
```

### 2. **CurrencyFormatter** - 통화 포맷팅
금액을 다양한 형식으로 표시합니다.

```dart
// 기본 포맷
CurrencyFormatter.format(1234567); // "1,234,567원"

// 부호 포함
CurrencyFormatter.formatSigned(50000);  // "+50,000원"
CurrencyFormatter.formatSigned(-30000); // "-30,000원"

// 지출/수입 포맷
CurrencyFormatter.formatOutflow(15000);  // "-15,000원"
CurrencyFormatter.formatInflow(100000);  // "+100,000원"

// 간단한 포맷
CurrencyFormatter.formatCompact(1234567); // "1.2M원"

// 퍼센트
CurrencyFormatter.formatPercent(75.5); // "75.5%"

// 비율 계산
CurrencyFormatter.formatRatio(3, 4); // "75.0%"

// 문자열 파싱
CurrencyFormatter.parse("1,234,567원"); // 1234567.0
```

### 3. **Validators** - 입력 검증
Form 입력값을 검증합니다.

```dart
// Form에서 사용
TextFormField(
  decoration: const InputDecoration(labelText: '금액'),
  validator: (value) => Validators.positiveNumber(value, fieldName: '금액'),
)

TextFormField(
  decoration: const InputDecoration(labelText: '계정명'),
  validator: Validators.accountName,
)

// 개별 검증 함수들
Validators.required(value, fieldName: '이름');
Validators.positiveNumber(value, fieldName: '금액');
Validators.positiveInteger(value, fieldName: '수량');
Validators.accountName(value);
Validators.email(value);
Validators.phoneNumber(value);

// 여러 검증 조합
Validators.compose(value, [
  Validators.required,
  (v) => Validators.length(v, min: 2, max: 20),
]);
```

### 4. **DialogUtils** - 다이얼로그 표시
다양한 종류의 다이얼로그를 쉽게 표시합니다.

```dart
// 확인 다이얼로그
final confirmed = await DialogUtils.showConfirmDialog(
  context,
  title: '확인',
  message: '계속하시겠습니까?',
);

// 삭제 확인 (위험한 작업)
final deleted = await DialogUtils.showDeleteConfirmDialog(
  context,
  itemName: '거래 내역',
);

// 정보 다이얼로그
await DialogUtils.showInfoDialog(
  context,
  title: '알림',
  message: '저장되었습니다',
);

// 에러 다이얼로그
await DialogUtils.showErrorDialog(
  context,
  message: '오류가 발생했습니다',
);

// 성공 다이얼로그
await DialogUtils.showSuccessDialog(
  context,
  message: '백업이 완료되었습니다',
);

// 텍스트 입력 다이얼로그
final input = await DialogUtils.showTextInputDialog(
  context,
  title: '이름 입력',
  hint: '이름을 입력하세요',
  validator: Validators.required,
);

// 선택 다이얼로그
final choice = await DialogUtils.showChoiceDialog<String>(
  context,
  title: '카테고리 선택',
  items: ['식비', '교통비', '쇼핑'],
  itemLabel: (item) => item,
);

// 로딩 다이얼로그
DialogUtils.showLoadingDialog(context, message: '처리 중...');
// ... 작업 수행
DialogUtils.dismissLoadingDialog(context);
```

### 5. **SnackbarUtils** - 스낵바 표시
다양한 종류의 스낵바를 표시합니다.

```dart
// 기본 스낵바
SnackbarUtils.show(context, '저장되었습니다');

// 성공 스낵바 (초록색)
SnackbarUtils.showSuccess(context, '백업 완료!');

// 에러 스낵바 (빨간색)
SnackbarUtils.showError(context, '오류가 발생했습니다');

// 경고 스낵바 (주황색)
SnackbarUtils.showWarning(context, '주의가 필요합니다');

// 정보 스낵바 (파란색)
SnackbarUtils.showInfo(context, '새로운 업데이트가 있습니다');

// 실행 취소 가능한 스낵바
SnackbarUtils.showWithUndo(
  context,
  '항목이 삭제되었습니다',
  onUndo: () {
    // 삭제 취소 로직
  },
);
```

### 6. **ColorUtils** - 색상 유틸리티
색상 관련 헬퍼 함수들입니다.

```dart
// 금액에 따른 색상
final color = ColorUtils.getAmountColor(1000, context); // 양수면 파란색

// 수입/지출 색상
final color = ColorUtils.getIncomeExpenseColor(true, context);

// 진행률에 따른 색상
final color = ColorUtils.getProgressColor(75, context);

// 색상 밝기 조정
final darker = ColorUtils.darken(Colors.blue);
final lighter = ColorUtils.lighten(Colors.blue);

// 16진수 변환
final hex = ColorUtils.toHex(Colors.blue); // "#2196F3"
final color = ColorUtils.fromHex("#2196F3");

// 차트용 색상 팔레트
final colors = ColorUtils.generateChartColors(5);

// 대비되는 텍스트 색상
final textColor = ColorUtils.getContrastingTextColor(backgroundColor);
```

### 7. **Constants** - 상수 정의
앱 전체에서 사용하는 상수들입니다.

```dart
// SharedPreferences 키
AppConstants.lastAccountNameKey
AppConstants.accountsKey

// 제한값
AppConstants.maxFavoritesCount
AppConstants.maxTrashSizeBytes
AppConstants.autoBackupIntervalDays

// 기본값
AppConstants.defaultCurrency
AppConstants.defaultAccountName

// UI 상수
AppConstants.defaultPadding
AppConstants.defaultBorderRadius

// 에러 메시지
ErrorMessages.networkError
ErrorMessages.accountNotFound
ErrorMessages.backupFailed

// 성공 메시지
SuccessMessages.saved
SuccessMessages.backupCompleted
```

## 🚀 사용 방법

### 전체 import (권장)
```dart
import 'package:vccode1/utils/utils.dart';
```

### 개별 import
```dart
import 'package:vccode1/utils/date_formatter.dart';
import 'package:vccode1/utils/currency_formatter.dart';
```

## 📝 실전 예시

### 거래 내역 화면에서 활용
```dart
import 'package:vccode1/utils/utils.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(transaction.description),
      subtitle: Text(DateFormatter.formatDate(transaction.date)),
      trailing: Text(
        CurrencyFormatter.format(transaction.amount),
        style: TextStyle(
          color: ColorUtils.getAmountColor(transaction.amount, context),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

### Form 검증
```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        decoration: const InputDecoration(labelText: '계정명'),
        validator: Validators.accountName,
      ),
      TextFormField(
        decoration: const InputDecoration(labelText: '금액'),
        validator: (value) => Validators.positiveNumber(value, fieldName: '금액'),
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            SnackbarUtils.showSuccess(context, SuccessMessages.saved);
          }
        },
        child: const Text('저장'),
      ),
    ],
  ),
)
```

### 삭제 확인
```dart
Future<void> _deleteTransaction(Transaction transaction) async {
  final confirmed = await DialogUtils.showDeleteConfirmDialog(
    context,
    itemName: transaction.description,
  );
  
  if (confirmed) {
    await transactionService.delete(transaction.id);
    if (mounted) {
      SnackbarUtils.showSuccess(context, SuccessMessages.deleted);
    }
  }
}
```

## 🎨 데모 화면
`utils_example.dart` 파일에서 모든 유틸리티의 사용 예시를 확인할 수 있습니다.

```dart
// main.dart에서 데모 화면 추가
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const UtilsExampleScreen()),
);
```
