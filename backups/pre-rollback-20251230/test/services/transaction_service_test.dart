import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    // Keep unit tests on the legacy prefs backend (no platform plugins needed).
    PrefKeys.txStorageBackendV1: 'prefs',
  });
  group('TransactionService', () {
    late TransactionService service;

    setUp(() async {
      // Reset mock SharedPreferences for isolation across tests
      SharedPreferences.setMockInitialValues({
        PrefKeys.txStorageBackendV1: 'prefs',
      });
      service = TransactionService();
      await service.loadTransactions();
      // Ensure any leftover test account is removed
      if (service.getAllAccountNames().contains('test_account')) {
        await service.deleteAccount('test_account');
      }
      await service.createAccount('test_account');
    });

    test('should create account', () async {
      await service.createAccount('test_account_new');
      expect(service.getTransactions('test_account_new'), isEmpty);
    });

    test('should get all account names', () async {
      await service.createAccount('account_1');
      await service.createAccount('account_2');
      final names = service.getAllAccountNames();
      expect(names, isNotEmpty);
    });

    test('should add transaction to account', () async {
      final tx = Transaction(
        id: 'test-tx-001',
        type: TransactionType.expense,
        amount: 10000,
        date: DateTime.now(),
        description: '식비',
      );

      await service.addTransaction('test_account', tx);
      final transactions = service.getTransactions('test_account');

      expect(transactions, isNotEmpty);
      expect(transactions.length, equals(1));
      expect(transactions.first.id, equals('test-tx-001'));
      expect(transactions.first.description, equals('식비'));
    });

    test('should add multiple transactions', () async {
      final tx1 = Transaction(
        id: 'multi-001',
        type: TransactionType.expense,
        amount: 5000,
        date: DateTime.now(),
        description: '커피',
      );
      final tx2 = Transaction(
        id: 'multi-002',
        type: TransactionType.income,
        amount: 100000,
        date: DateTime.now(),
        description: '용돈',
      );

      await service.addTransaction('test_account', tx1);
      await service.addTransaction('test_account', tx2);

      final transactions = service.getTransactions('test_account');
      expect(transactions.length, equals(2));
    });

    test('should update transaction', () async {
      final originalTx = Transaction(
        id: 'update-001',
        type: TransactionType.expense,
        amount: 10000,
        date: DateTime.now(),
        description: '점심',
      );

      await service.addTransaction('test_account', originalTx);

      final updatedTx = Transaction(
        id: 'update-001',
        type: TransactionType.expense,
        amount: 15000, // 변경
        date: DateTime.now(),
        description: '점심',
      );

      final result = await service.updateTransaction('test_account', updatedTx);
      expect(result, isTrue);

      final transactions = service.getTransactions('test_account');
      expect(transactions.first.amount, equals(15000));
    });

    test(
      'should return false when updating non-existent transaction',
      () async {
        final tx = Transaction(
          id: 'non-existent-001',
          type: TransactionType.expense,
          amount: 5000,
          date: DateTime.now(),
          description: '테스트',
        );

        final result = await service.updateTransaction('test_account', tx);
        expect(result, isFalse);
      },
    );

    test('should delete transaction', () async {
      final tx = Transaction(
        id: 'delete-001',
        type: TransactionType.expense,
        amount: 3000,
        date: DateTime.now(),
        description: '버스비',
      );

      await service.addTransaction('test_account', tx);
      expect(service.getTransactions('test_account'), isNotEmpty);

      await service.deleteTransaction('test_account', 'delete-001');
      expect(service.getTransactions('test_account'), isEmpty);
    });

    test('should delete account', () async {
      await service.createAccount('temp_account');
      await service.deleteAccount('temp_account');
      final names = service.getAllAccountNames();
      expect(names.contains('temp_account'), isFalse);
    });

    test('should return empty list for non-existent account', () async {
      final transactions = service.getTransactions('non_existent_account');
      expect(transactions, isEmpty);
    });

    test('should get all transactions from all accounts', () async {
      await service.createAccount('acc1');
      await service.createAccount('acc2');

      final tx1 = Transaction(
        id: 'all-001',
        type: TransactionType.expense,
        amount: 1000,
        date: DateTime.now(),
        description: 'test1',
      );
      final tx2 = Transaction(
        id: 'all-002',
        type: TransactionType.income,
        amount: 50000,
        date: DateTime.now(),
        description: 'test2',
      );

      await service.addTransaction('acc1', tx1);
      await service.addTransaction('acc2', tx2);

      final allTransactions = service.getAllTransactions();
      expect(allTransactions.length, greaterThanOrEqualTo(2));
    });

    test('should handle transaction with memo', () async {
      final tx = Transaction(
        id: 'memo-001',
        type: TransactionType.expense,
        amount: 5000,
        date: DateTime.now(),
        description: '카페',
        memo: '중요한 미팅',
      );

      await service.addTransaction('test_account', tx);
      final transactions = service.getTransactions('test_account');

      expect(transactions.first.memo, equals('중요한 미팅'));
    });

    test('should handle different transaction types', () async {
      final expenseTx = Transaction(
        id: 'type-exp',
        type: TransactionType.expense,
        amount: 5000,
        date: DateTime.now(),
        description: '지출',
      );
      final incomeTx = Transaction(
        id: 'type-inc',
        type: TransactionType.income,
        amount: 100000,
        date: DateTime.now(),
        description: '수입',
      );
      final savingsTx = Transaction(
        id: 'type-sav',
        type: TransactionType.savings,
        amount: 50000,
        date: DateTime.now(),
        description: '예금',
      );

      await service.addTransaction('test_account', expenseTx);
      await service.addTransaction('test_account', incomeTx);
      await service.addTransaction('test_account', savingsTx);

      final transactions = service.getTransactions('test_account');
      expect(
        transactions.where((t) => t.type == TransactionType.expense).length,
        equals(1),
      );
      expect(
        transactions.where((t) => t.type == TransactionType.income).length,
        equals(1),
      );
      expect(
        transactions.where((t) => t.type == TransactionType.savings).length,
        equals(1),
      );
    });

    test('should return unmodifiable list', () async {
      final tx = Transaction(
        id: 'unmodi-001',
        type: TransactionType.expense,
        amount: 1000,
        date: DateTime.now(),
        description: 'test',
      );

      await service.addTransaction('test_account', tx);
      final transactions = service.getTransactions('test_account');

      expect(() => transactions.add(tx), throwsUnsupportedError);
    });
  });
}

