import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';

void main() {
  group('TransactionType Enum', () {
    test('expense has correct properties', () {
      expect(TransactionType.expense.label, equals('지출'));
      expect(TransactionType.expense.sign, equals('-'));
      expect(TransactionType.expense.isOutflow, isTrue);
      expect(TransactionType.expense.isInflow, isFalse);
    });

    test('income has correct properties', () {
      expect(TransactionType.income.label, equals('수입'));
      expect(TransactionType.income.sign, equals('+'));
      expect(TransactionType.income.isInflow, isTrue);
      expect(TransactionType.income.isOutflow, isFalse);
    });

    test('savings has correct properties', () {
      expect(TransactionType.savings.label, equals('예금'));
      expect(TransactionType.savings.sign, equals('-'));
      expect(TransactionType.savings.isOutflow, isTrue);
      expect(TransactionType.savings.isInflow, isFalse);
    });

    test('longLabel - expense', () {
      expect(TransactionType.expense.longLabel, equals('지출'));
    });

    test('longLabel - income', () {
      expect(TransactionType.income.longLabel, equals('수입'));
    });

    test('longLabel - savings', () {
      expect(TransactionType.savings.longLabel, equals('예금(저금통)'));
    });
  });

  group('Transaction Model', () {
    test('Transaction creation with all fields', () {
      final tx = Transaction(
        id: 'test-123',
        type: TransactionType.expense,
        amount: 10000,
        date: DateTime(2025, 12, 6),
        description: '식비',
        memo: '점심',
      );

      expect(tx.id, equals('test-123'));
      expect(tx.type, equals(TransactionType.expense));
      expect(tx.amount, equals(10000));
      expect(tx.description, equals('식비'));
      expect(tx.memo, equals('점심'));
    });

    test('Transaction with empty memo', () {
      final tx = Transaction(
        id: 'test-789',
        type: TransactionType.expense,
        amount: 3000,
        date: DateTime.now(),
        description: '커피',
        memo: '',
      );

      expect(tx.memo, isEmpty);
    });

    test('Transaction JSON serialization - expense', () {
      final tx = Transaction(
        id: 'test-123',
        type: TransactionType.expense,
        amount: 10000,
        date: DateTime(2025, 12, 6),
        description: '식비',
        memo: '점심',
      );

      final json = tx.toJson();
      expect(json['id'], equals('test-123'));
      expect(json['description'], equals('식비'));
      expect(json['memo'], equals('점심'));
    });

    test('Transaction JSON deserialization', () {
      final json = {
        'id': 'test-456',
        'type': 'income',
        'amount': 5000000,
        'date': '2025-12-06T00:00:00.000Z',
        'description': '월급',
        'memo': '12월 봉급',
      };

      final tx = Transaction.fromJson(json);
      expect(tx.id, equals('test-456'));
      expect(tx.type, equals(TransactionType.income));
      expect(tx.amount, equals(5000000));
      expect(tx.description, equals('월급'));
      expect(tx.memo, equals('12월 봉급'));
    });

    test('Income transaction amount should be positive', () {
      final tx = Transaction(
        id: 'income-1',
        type: TransactionType.income,
        amount: 5000000,
        date: DateTime.now(),
        description: '월급',
      );

      expect(tx.amount, isPositive);
      expect(tx.type.sign, equals('+'));
    });

    test('Expense transaction amount should be positive', () {
      final tx = Transaction(
        id: 'expense-1',
        type: TransactionType.expense,
        amount: 50000,
        date: DateTime.now(),
        description: '식비',
      );

      expect(tx.amount, isPositive);
      expect(tx.type.sign, equals('-'));
    });

    test('Savings transaction amount should be positive', () {
      final tx = Transaction(
        id: 'savings-1',
        type: TransactionType.savings,
        amount: 100000,
        date: DateTime.now(),
        description: '예금',
      );

      expect(tx.amount, isPositive);
      expect(tx.type.sign, equals('-'));
    });

    test('Transaction date is preserved', () {
      final date = DateTime(2025, 12, 25, 10, 30, 45);
      final tx = Transaction(
        id: 'test-date',
        type: TransactionType.expense,
        amount: 1000,
        date: date,
        description: '테스트',
      );

      expect(tx.date, equals(date));
      expect(tx.date.year, equals(2025));
      expect(tx.date.month, equals(12));
      expect(tx.date.day, equals(25));
    });

    test('Transaction roundtrip JSON serialization', () {
      final originalTx = Transaction(
        id: 'roundtrip-1',
        type: TransactionType.savings,
        amount: 250000,
        date: DateTime(2025, 12, 6),
        description: '예금 적립',
        memo: '12월 예금',
      );

      final json = originalTx.toJson();
      final restoredTx = Transaction.fromJson(json);

      expect(restoredTx.id, equals(originalTx.id));
      expect(restoredTx.type, equals(originalTx.type));
      expect(restoredTx.amount, equals(originalTx.amount));
      expect(restoredTx.description, equals(originalTx.description));
      expect(restoredTx.memo, equals(originalTx.memo));
    });

    test('Transaction JSON serialization includes store when provided', () {
      final originalTx = Transaction(
        id: 'store-1',
        type: TransactionType.expense,
        amount: 12000,
        date: DateTime(2025, 12, 26),
        description: '장보기',
        memo: '이마트\n우유',
        store: '이마트',
      );

      final json = originalTx.toJson();
      expect(json['store'], equals('이마트'));

      final restoredTx = Transaction.fromJson(json);
      expect(restoredTx.store, equals('이마트'));
    });
  });

  group('SavingsAllocation Enum', () {
    test('SavingsAllocation.assetIncrease exists', () {
      expect(SavingsAllocation.assetIncrease, isNotNull);
    });

    test('SavingsAllocation.expense exists', () {
      expect(SavingsAllocation.expense, isNotNull);
    });

    test('SavingsAllocation values are distinct', () {
      expect(
        SavingsAllocation.assetIncrease,
        isNot(equals(SavingsAllocation.expense)),
      );
    });
  });
}
