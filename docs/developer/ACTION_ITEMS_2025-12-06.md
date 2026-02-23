# ⚡ 즉시 실행 액션 아이템 (Action Items)

**작성일**: 2025-12-06  
**우선순위**: 단계별 정렬  
**예상 완료**: 2025-12-13 (1주일)

---

## 🔴 PRIORITY 1: 미완성 기능 완료 (High)

### Task 1.1: emergency_fund_screen.dart 완성
**파일**: `lib/screens/emergency_fund_screen.dart`  
**담당**: 개발자  
**예상 시간**: 2일  
**완료 기준**: 4개 TODO 모두 해결  

#### 체크리스트
- [x] Line 34: `_loadTransactions()` 구현
  ```dart
  void _loadTransactions() {
    // IncomeSplitService에서 비상금 거래 로드
    final service = IncomeSplitService();
    final split = service.getSplit(widget.accountName);
    // TransactionService에서 필터링
    // setState 호출
  }
  ```

- [x] Line 260: `_addTransaction()` 구현
  ```dart
  void _addTransaction() {
    // 금액 입력 다이얼로그 표시
    // TransactionService에 추가
    // _loadTransactions() 재호출
  }
  ```

- [x] Line 276: `_saveTransaction()` 구현
  ```dart
  Future<void> _saveTransaction(...) async {
    // TransactionService.addTransaction() 호출
    // SharedPreferences 저장
  }
  ```

- [x] Line 376: `_deleteTransaction()` 구현
  ```dart
  Future<void> _deleteTransaction(String id) async {
    // 삭제 확인 다이얼로그
    // TrashService에 추가
    // _loadTransactions() 재호출
  }
  ```

#### 검증 체크
- [ ] 앱 실행 가능
- [ ] 비상금 화면 표시됨
- [ ] 거래 추가/삭제 가능
- [ ] 유효성 검사 작동

---

### Task 1.2: income_input_screen.dart 완성
**파일**: `lib/screens/income_input_screen.dart`  
**담당**: 개발자  
**예상 시간**: 2일  
**완료 기준**: `_saveIncome()` 완전 구현  

#### 체크리스트
- [x] Line 116: `_saveIncome()` 구현
  ```dart
  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 1. 데이터 검증
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 금액을 입력하세요')),
      );
      return;
    }
    
    // 2. 거래 생성
    final transaction = Transaction(
      id: const Uuid().v4(),
      accountName: widget.accountName,
      type: TransactionType.income,
      amount: amount,
      date: _incomeDate ?? DateTime.now(),
      description: _nameController.text,
      memo: _memoController.text,
    );
    
    // 3. 저장
    await TransactionService().addTransaction(
      widget.accountName,
      transaction,
    );
    
    // 4. 최근 입력값 저장
    await RecentInputService.saveValue(_paymentPrefsKey, _paymentMethod);
    if (_memoController.text.isNotEmpty) {
      await RecentInputService.saveValue(
        _memoPrefsKey,
        _memoController.text,
      );
    }
    
    // 5. 화면 종료
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수입이 저장되었습니다')),
      );
      Navigator.of(context).pop();
    }
  }
  ```

- [ ] 필드 검증 로직 추가
- [ ] TransactionService 호출
- [ ] 최근 입력값 저장
- [ ] 성공 피드백 표시

#### 검증 체크
- [ ] 앱 실행 가능
- [ ] 수입 입력 화면 표시됨
- [ ] 데이터 저장됨
- [ ] 거래 목록에 표시됨

---

### Task 1.3: savings_plan_search_screen.dart - 수정 기능 추가
**파일**: `lib/screens/savings_plan_search_screen.dart`  
**담당**: 개발자  
**예상 시간**: 1일  
**완료 기준**: Line 97 수정 화면 연결  

#### 체크리스트
- [ ] Line 97: `_editSelected()` 구현
  ```dart
  Future<void> _editSelected() async {
    if (_selectedIds.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정할 항목을 1개만 선택하세요')),
      );
      return;
    }
    
    final plans = SavingsPlanService().getPlans(widget.accountName);
    final plan = plans.firstWhere((p) => p.id == _selectedIds.first);
    
    // 수정 화면으로 이동
    final result = await Navigator.of(context).push<SavingsPlan?>(
      MaterialPageRoute(
        builder: (context) => SavingsPlanFormScreen(
          accountName: widget.accountName,
          initialPlan: plan,  // 수정 모드
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('예금계획이 수정되었습니다')),
        );
      }
    }
  }
  ```

- [ ] 수정 화면 연결
- [ ] 데이터 전달 로직
- [ ] 성공 피드백

#### 검증 체크
- [ ] 항목 선택 가능
- [ ] 수정 화면 열림
- [ ] 데이터 저장됨

---

## 🟡 PRIORITY 2: 기본 테스트 추가 (High)

### Task 2.1: 트랜잭션 모델 테스트
**파일**: `test/models/transaction_test.dart` (생성)  
**담당**: 개발자  
**예상 시간**: 1일  
**커버리지**: 15-20개 테스트 케이스  

```dart
// test/models/transaction_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vccode1/models/transaction.dart';

void main() {
  group('Transaction Model', () {
    test('TransactionType parsing - income', () {
      final type = _parseTransactionType('income');
      expect(type, equals(TransactionType.income));
    });

    test('TransactionType parsing - expense', () {
      final type = _parseTransactionType('expense');
      expect(type, equals(TransactionType.expense));
    });

    test('TransactionType parsing - savings', () {
      final type = _parseTransactionType('savings');
      expect(type, equals(TransactionType.savings));
    });

    test('TransactionType sign - expense', () {
      expect(TransactionType.expense.sign, equals('-'));
    });

    test('TransactionType sign - income', () {
      expect(TransactionType.income.sign, equals('+'));
    });

    test('TransactionType isInflow - income', () {
      expect(TransactionType.income.isInflow, isTrue);
    });

    test('TransactionType isOutflow - expense', () {
      expect(TransactionType.expense.isOutflow, isTrue);
    });

    test('Transaction JSON serialization', () {
      final tx = Transaction(
        id: 'test-123',
        type: TransactionType.expense,
        amount: 10000,
        date: DateTime(2025, 12, 6),
        description: '식비',
        memo: '점심',
      );

      final json = tx.toJson();
      final restored = Transaction.fromJson(json);

      expect(restored.id, equals(tx.id));
      expect(restored.type, equals(tx.type));
      expect(restored.amount, equals(tx.amount));
    });
  });
}
```

#### 체크리스트
- [ ] test/models/transaction_test.dart 생성
- [ ] 10개+ 테스트 케이스 작성
- [ ] 모든 테스트 통과

---

### Task 2.2: 거래 서비스 테스트
**파일**: `test/services/transaction_service_test.dart` (생성)  
**담당**: 개발자  
**예상 시간**: 1일  
**커버리지**: 15-20개 테스트 케이스  

```dart
// test/services/transaction_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vccode1/models/transaction.dart';
import 'package:vccode1/services/transaction_service.dart';

void main() {
  group('TransactionService', () {
    late TransactionService service;

    setUp(() async {
      service = TransactionService();
      await service.loadTransactions();
      await service.createAccount('test_account');
    });

    test('should create account', () async {
      await service.createAccount('test_account2');
      expect(
        service.getTransactions('test_account2'),
        isEmpty,
      );
    });

    test('should add transaction', () async {
      final tx = Transaction(
        id: 'test-123',
        type: TransactionType.expense,
        amount: 10000,
        date: DateTime.now(),
        description: '식비',
      );

      await service.addTransaction('test_account', tx);
      final transactions = service.getTransactions('test_account');

      expect(transactions, isNotEmpty);
      expect(transactions.first.id, equals('test-123'));
    });

    test('should update transaction', () async {
      final tx = Transaction(
        id: 'test-123',
        type: TransactionType.expense,
        amount: 10000,
        date: DateTime.now(),
        description: '식비',
      );

      await service.addTransaction('test_account', tx);

      final updated = Transaction(
        id: 'test-123',
        type: TransactionType.expense,
        amount: 15000,  // 변경
        date: DateTime.now(),
        description: '식비',
      );

      final result = await service.updateTransaction(
        'test_account',
        updated,
      );

      expect(result, isTrue);
      expect(
        service.getTransactions('test_account').first.amount,
        equals(15000),
      );
    });

    test('should delete transaction', () async {
      final tx = Transaction(
        id: 'test-123',
        type: TransactionType.expense,
        amount: 10000,
        date: DateTime.now(),
        description: '식비',
      );

      await service.addTransaction('test_account', tx);
      await service.deleteTransaction('test_account', 'test-123');

      expect(
        service.getTransactions('test_account'),
        isEmpty,
      );
    });
  });
}
```

#### 체크리스트
- [ ] test/services/transaction_service_test.dart 생성
- [ ] 10개+ 테스트 케이스 작성
- [ ] 모든 테스트 통과

---

### Task 2.3: 유효성 검사 테스트
**파일**: `test/utils/validators_test.dart` (생성)  
**담당**: 개발자  
**예상 시간**: 0.5일  

```dart
// test/utils/validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vccode1/utils/validators.dart';

void main() {
  group('Validators', () {
    test('required - should fail with empty string', () {
      final result = Validators.required('', fieldName: 'Name');
      expect(result, isNotNull);
      expect(result, contains('입력'));
    });

    test('required - should pass with valid string', () {
      final result = Validators.required('John');
      expect(result, isNull);
    });

    test('positiveNumber - should fail with non-numeric', () {
      final result = Validators.positiveNumber('abc');
      expect(result, isNotNull);
    });

    test('positiveNumber - should fail with negative', () {
      final result = Validators.positiveNumber('-100');
      expect(result, isNotNull);
    });

    test('positiveNumber - should pass with positive', () {
      final result = Validators.positiveNumber('100');
      expect(result, isNull);
    });
  });
}
```

#### 체크리스트
- [ ] test/utils/validators_test.dart 생성
- [ ] 10개+ 테스트 케이스 작성
- [ ] 모든 테스트 통과

---

## 🟠 PRIORITY 3: 코드 정리 (Medium)

### Task 3.1: 타입 변환 헬퍼 클래스 추가
**파일**: `lib/utils/type_converters.dart` (생성)  
**담당**: 개발자  
**예상 시간**: 1day  
**변경 파일**: 5개  

#### 새 파일 생성
```dart
// lib/utils/type_converters.dart
class TypeConverters {
  TypeConverters._();  // Private constructor

  /// 동적 값을 double로 변환합니다.
  static double parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// 동적 값을 int로 변환합니다.
  static int parseInt(dynamic value, [int defaultValue = 0]) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// 동적 값을 String으로 변환합니다.
  static String parseString(dynamic value, [String defaultValue = '']) {
    if (value is String) return value;
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// 동적 값을 bool로 변환합니다.
  static bool parseBool(dynamic value, [bool defaultValue = false]) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return defaultValue;
  }
}
```

#### 변경할 파일 목록
- [ ] `lib/services/backup_service.dart` (Line 119)
  ```dart
  // Before
  final budgetValue = (data['budget'] as num?)?.toDouble() ?? 0;
  
  // After
  final budgetValue = TypeConverters.parseDouble(data['budget']);
  ```

- [ ] `lib/services/income_split_service.dart` (Line 35-38)
  ```dart
  // Before
  totalIncome: (json['totalIncome'] as num).toDouble(),
  
  // After
  totalIncome: TypeConverters.parseDouble(json['totalIncome']),
  ```

- [ ] `lib/services/budget_service.dart` (Line 51)
- [ ] `lib/models/fixed_cost.dart` (Line 21)
- [ ] `lib/models/transaction.dart` (Line 157)

#### 체크리스트
- [ ] lib/utils/type_converters.dart 생성
- [ ] 5개 파일 수정
- [ ] utils.dart export 추가
- [ ] 모든 테스트 통과

---

### Task 3.2: SharedPreferences 키 상수화
**파일**: `lib/utils/pref_keys.dart` (생성)  
**담당**: 개발자  
**예상 시간**: 0.5일  
**변경 파일**: 10개+  

```dart
// lib/utils/pref_keys.dart
/// SharedPreferences 키 모음
class PrefKeys {
  PrefKeys._();  // Private constructor

  // Transaction 관련
  static const String transactions = 'transactions';

  // Account 관련
  static const String accounts = 'accounts';
  static const String lastAccountName = 'last_account_name';

  // Asset 관련
  static const String assets = 'assets';

  // Budget 관련
  static const String budgets = 'budgets';

  // Fixed Cost 관련
  static const String fixedCosts = 'fixed_costs';

  // Savings Plan 관련
  static const String savingsPlans = 'savings_plans';

  // Trash 관련
  static const String trash = 'trash';

  // Income Split 관련
  static const String incomeSplits = 'income_splits';

  // User Preferences
  static const String currencyUnit = 'currency_unit';
  static const String theme = 'theme_mode';

  // Recent Inputs (동적 키 생성)
  static String recentPayments(String accountName) =>
      'recent_payments_$accountName';

  static String recentMemos(String accountName) =>
      'recent_memos_$accountName';
}
```

#### 변경할 파일 목록
- [ ] `lib/services/transaction_service.dart` - 모든 _prefsKey 교체
- [ ] `lib/services/account_service.dart` - 모든 상수 교체
- [ ] `lib/services/asset_service.dart` - 모든 상수 교체
- [ ] `lib/services/budget_service.dart` - 모든 상수 교체
- [ ] `lib/services/fixed_cost_service.dart` - 모든 상수 교체
- [ ] `lib/services/savings_plan_service.dart` - 모든 상수 교체
- [ ] `lib/services/trash_service.dart` - 모든 상수 교체
- [ ] `lib/services/income_split_service.dart` - 모든 상수 교체
- [ ] `lib/services/user_pref_service.dart` - 모든 상수 교체

#### 체크리스트
- [ ] lib/utils/pref_keys.dart 생성
- [ ] 9개+ 파일 수정
- [ ] utils.dart export 추가
- [ ] 모든 테스트 통과
- [ ] 앱 정상 작동 확인

---

## 📋 완료 체크리스트

### Phase 1: 미완성 기능 (예상 완료: 2025-12-09)
```
Task 1.1: emergency_fund_screen.dart
  □ _loadTransactions() 구현
  □ _addTransaction() 구현
  □ _saveTransaction() 구현
  □ _deleteTransaction() 구현
  □ 테스트 통과

Task 1.2: income_input_screen.dart
  □ _saveIncome() 구현
  □ 유효성 검사 추가
  □ 최근 입력값 저장
  □ 성공 피드백
  □ 테스트 통과

Task 1.3: savings_plan_search_screen.dart
  □ _editSelected() 구현
  □ 수정 화면 연결
  □ 데이터 전달 로직
  □ 테스트 통과
```

### Phase 2: 테스트 추가 (예상 완료: 2025-12-10)
```
Task 2.1: Transaction 모델 테스트
  □ test/models/transaction_test.dart 생성
  □ 15-20개 테스트 케이스
  □ 커버리지 80%+
  □ 모든 테스트 통과

Task 2.2: TransactionService 테스트
  □ test/services/transaction_service_test.dart 생성
  □ 15-20개 테스트 케이스
  □ CRUD 모두 테스트
  □ 모든 테스트 통과

Task 2.3: Validators 테스트
  □ test/utils/validators_test.dart 생성
  □ 10개+ 테스트 케이스
  □ 모든 검증 로직 테스트
  □ 모든 테스트 통과
```

### Phase 3: 코드 정리 (예상 완료: 2025-12-11)
```
Task 3.1: 타입 변환 헬퍼
  □ lib/utils/type_converters.dart 생성
  □ 5개 파일 수정
  □ utils.dart export 추가
  □ 모든 테스트 통과

Task 3.2: SharedPreferences 키 상수화
  □ lib/utils/pref_keys.dart 생성
  □ 9개+ 파일 수정
  □ utils.dart export 추가
  □ 모든 테스트 통과
```

---

## 📊 진행률 추적

### Weekly Progress Template
```markdown
# 주간 진행 현황 (2025-12-06 ~ 2025-12-13)

## ✅ 완료
- [ ] Task 1.1: emergency_fund_screen.dart
- [ ] Task 1.2: income_input_screen.dart
- [ ] Task 1.3: savings_plan_search_screen.dart

## 🔄 진행 중
- [ ] Task 2.1: Transaction 모델 테스트
- [ ] Task 2.2: TransactionService 테스트

## ⏳ 대기
- [ ] Task 2.3: Validators 테스트
- [ ] Task 3.1: 타입 변환 헬퍼
- [ ] Task 3.2: 키 상수화

## 이슈
- [ ] (있으면 기록)

## 다음 주 계획
- [ ] (다음 주 계획 작성)
```

---

## 🎯 완료 기준

각 Task가 완료되려면:
1. ✅ 모든 코드 변경 적용
2. ✅ 모든 테스트 통과 (flutter test)
3. ✅ 앱 빌드 성공 (flutter build apk 등)
4. ✅ 수동 테스트 완료
5. ✅ 이 체크리스트에 ✓ 표시

---

**생성일**: 2025-12-06  
**예상 완료**: 2025-12-13  
**상태**: 🟡 준비 대기 중

