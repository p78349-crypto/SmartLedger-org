import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/audit_log_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/widgets/user_permission_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    // Keep unit tests on the legacy prefs backend (no platform plugins needed).
    PrefKeys.txStorageBackendV1: 'prefs',
  });
  group('TransactionService', () {
    late TransactionService service;
    late Directory tempDir;
    late String auditLogPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sl_tx_audit_');
      auditLogPath = '${tempDir.path}${Platform.pathSeparator}audit_log.jsonl';
      AuditLogService.setLogFilePathForTesting(auditLogPath);

      // Reset mock SharedPreferences for isolation across tests
      SharedPreferences.setMockInitialValues({
        PrefKeys.txStorageBackendV1: 'prefs',
      });
      service = TransactionService();
      service.resetForTesting();
      await service.loadTransactions();
      final auditFile = File(auditLogPath);
      if (auditFile.existsSync()) {
        await auditFile.delete();
      }
      // Ensure any leftover test account is removed
      if (service.getAllAccountNames().contains('test_account')) {
        await service.deleteAccount('test_account');
      }
      await service.createAccount('test_account');
    });

    tearDown(() async {
      AuditLogService.setLogFilePathForTesting(null);
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
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

    test('should write standardized transaction audit fields on add', () async {
      final tx = Transaction(
        id: 'audit-tx-001',
        type: TransactionType.expense,
        amount: 32100,
        date: DateTime.now(),
        description: '감사 로그 필드 테스트',
      );

      await service.addTransaction('test_account', tx);
      final logs = await AuditLogService.getRecentLogs(limit: 20);
      final entry = logs.firstWhere((e) => e.action == 'transaction_added');

      expect(entry.success, isTrue);
      expect(entry.targetResource, equals('test_account'));
      expect(entry.metadata?['accountId'], equals('test_account'));
      expect(entry.metadata?['amount'], equals(32100));
      expect(entry.metadata?['transactionId'], equals('audit-tx-001'));
      expect(entry.metadata?['schemaVersion'], equals('transaction_event_v1'));
    });

    test('should emit anomaly signal for large transaction', () async {
      final tx = Transaction(
        id: 'anomaly-large-001',
        type: TransactionType.expense,
        amount: 1500000,
        date: DateTime.now(),
        description: '고액 거래',
      );

      await service.addTransaction('test_account', tx);
      final logs = await AuditLogService.getRecentLogs(limit: 30);
      final signal = logs.firstWhere(
        (e) => e.action == 'anomaly_signal_large_transaction',
      );

      expect(signal.eventType, equals(AuditEventType.policyEnforcement));
      expect(signal.metadata?['transactionId'], equals('anomaly-large-001'));
      expect(signal.metadata?['ruleId'], equals('rule_large_transaction_v1'));
      expect(signal.metadata?['threshold'], equals(1000000.0));
      expect(signal.metadata?['observedValue'], equals(1500000.0));
    });

    test('should emit anomaly signal for repeated failed actions', () async {
      for (var i = 0; i < 3; i++) {
        await AuditLogService.logFailure(
          eventType: AuditEventType.authentication,
          action: 'seed_failed_auth_$i',
          userLevel: UserPermissionLevel.operator,
          errorMessage: 'seed',
        );
      }

      final tx = Transaction(
        id: 'anomaly-repeat-001',
        type: TransactionType.expense,
        amount: 2000,
        date: DateTime.now(),
        description: '반복 실패 이후 거래',
      );

      await service.addTransaction('test_account', tx);
      final logs = await AuditLogService.getRecentLogs(limit: 40);
      final signal = logs.firstWhere(
        (e) => e.action == 'anomaly_signal_repeated_failures',
      );

      expect(signal.eventType, equals(AuditEventType.policyEnforcement));
      expect(signal.metadata?['transactionId'], equals('anomaly-repeat-001'));
      expect(signal.metadata?['ruleId'], equals('rule_repeated_failures_v1'));
      expect(signal.metadata?['threshold'], equals(3));
      expect(signal.metadata?['observedValue'], equals(3));

      final summary = logs.firstWhere(
        (e) => e.action == 'anomaly_detection_summary',
      );
      expect(summary.eventType, equals(AuditEventType.securityViolation));
      expect(summary.metadata?['ruleId'], equals('rule_security_alert'));
      expect(summary.metadata?['threshold'], equals(3));
    });

    test(
      'scenario A: normal transaction should not emit anomaly signals',
      () async {
        final tx = Transaction(
          id: 'scenario-a-001',
          type: TransactionType.expense,
          amount: 12000,
          date: DateTime.now().copyWith(hour: 14, minute: 20),
          description: '정상 거래',
        );

        await service.addTransaction('test_account', tx);
        final logs = await AuditLogService.getRecentLogs(limit: 30);

        final hasAnomalySignal = logs.any(
          (e) =>
              e.action.startsWith('anomaly_signal_') ||
              e.action == 'anomaly_detection_summary',
        );

        expect(hasAnomalySignal, isFalse);
      },
    );

    test('scenario B: boundary anomaly should warn without lock', () async {
      final prefs = await SharedPreferences.getInstance();
      final tx = Transaction(
        id: 'scenario-b-001',
        type: TransactionType.expense,
        amount: 1200000,
        date: DateTime.now().copyWith(hour: 13, minute: 10),
        description: '경계 거래',
      );

      await service.addTransaction('test_account', tx);
      final logs = await AuditLogService.getRecentLogs(limit: 40);

      expect(
        logs.any((e) => e.action == 'anomaly_signal_large_transaction'),
        isTrue,
      );
      expect(
        logs.any((e) => e.action == 'automation_account_lock_applied'),
        isFalse,
      );
      expect(prefs.getInt(PrefKeys.userPinLockedUntilMs), isNull);
      expect(prefs.getInt(PrefKeys.rootPinLockedUntilMs), isNull);
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

    test('should persist and reload exact amount values', () async {
      final tx = Transaction(
        id: 'persist-001',
        type: TransactionType.expense,
        amount: 12345.67,
        date: DateTime.now(),
        description: '정밀 금액 테스트',
      );

      await service.addTransaction('test_account', tx);

      // Reload service to verify persistence
      final newService = TransactionService();
      await newService.loadTransactions();

      final reloadedTx = newService.getTransactions('test_account').first;
      expect(reloadedTx.amount, equals(12345.67));
      expect(reloadedTx.description, equals('정밀 금액 테스트'));
    });

    test('should persist transaction with card charged amount', () async {
      final tx = Transaction(
        id: 'card-persist-001',
        type: TransactionType.expense,
        amount: 50000,
        date: DateTime.now(),
        description: '카드 구매',
        cardChargedAmount: 48000, // 할인 적용
      );

      await service.addTransaction('test_account', tx);

      // Reload and verify card amount
      final newService = TransactionService();
      await newService.loadTransactions();

      final reloadedTx = newService.getTransactions('test_account').first;
      expect(reloadedTx.amount, equals(50000));
      expect(reloadedTx.cardChargedAmount, equals(48000));
    });

    test('should reload multiple transactions with precise values', () async {
      final txList = [
        Transaction(
          id: 'multi-persist-001',
          type: TransactionType.expense,
          amount: 1200,
          unitPrice: 400,
          quantity: 3,
          date: DateTime.now(),
          description: '상품1',
        ),
        Transaction(
          id: 'multi-persist-002',
          type: TransactionType.expense,
          amount: 3600,
          unitPrice: 1200,
          quantity: 3,
          date: DateTime.now(),
          description: '상품2',
          cardChargedAmount: 3600,
        ),
        Transaction(
          id: 'multi-persist-003',
          type: TransactionType.income,
          amount: 100000,
          date: DateTime.now(),
          description: '급여',
        ),
      ];

      for (final tx in txList) {
        await service.addTransaction('test_account', tx);
      }

      // Reload and verify all transactions
      final newService = TransactionService();
      await newService.loadTransactions();

      final reloadedTxs = newService.getTransactions('test_account');
      expect(reloadedTxs.length, equals(3));

      expect(reloadedTxs[0].amount, equals(1200));
      expect(reloadedTxs[0].unitPrice, equals(400));
      expect(reloadedTxs[0].quantity, equals(3));

      expect(reloadedTxs[1].amount, equals(3600));
      expect(reloadedTxs[1].unitPrice, equals(1200));
      expect(reloadedTxs[1].quantity, equals(3));
      expect(reloadedTxs[1].cardChargedAmount, equals(3600));

      expect(reloadedTxs[2].amount, equals(100000));
      expect(reloadedTxs[2].type, equals(TransactionType.income));
    });
  });
}
