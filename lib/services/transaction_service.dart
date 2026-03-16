library transaction_service;

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/widgets/user_permission_badge.dart';

import '../database/database_provider.dart';
import '../models/transaction.dart';
import '../services/reward_badge_service.dart';
import '../utils/benefit_aggregation_utils.dart';
import '../utils/pref_keys.dart';
import '../utils/store_memo_utils.dart';
import 'audit_log_service.dart';
import 'monthly_agg_cache_service.dart';
import 'transaction_benefit_monthly_agg_service.dart';
import 'transaction_db_migration_service.dart';
import 'transaction_db_store.dart';
import 'transaction_fts_index_service.dart';
import 'trash_service.dart';
import 'workflow_automation_engine.dart';

part 'transaction_service_storage.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  static String get _prefsKey => PrefKeys.transactions;
  static const String _storeMigrationFlagKey = 'tx_store_migration_done_v1';

  final Map<String, List<Transaction>> _accountTransactions = {};
  bool _initialized = false;
  Future<void>? _loading;
  Future<void> _persistChain = Future.value();

  final TransactionDbStore _dbStore = TransactionDbStore();

  static const String _backendDb = 'db';
  static const double _largeTransactionThreshold = 1000000;

  /// Test-only: reset the singleton state so a test can re-run initialization
  /// (e.g. after changing storage backend prefs).
  void resetForTesting() {
    _accountTransactions.clear();
    _initialized = false;
    _loading = null;
    _persistChain = Future.value();
  }

  List<String> getAllAccountNames() =>
      List.unmodifiable(_accountTransactions.keys.toList());

  List<Transaction> getTransactions(String accountName) {
    final list = _accountTransactions[accountName];
    if (list == null) {
      return const <Transaction>[];
    }
    return List.unmodifiable(list);
  }

  /// ROOT 계정 전용: 모든 계정의 거래 내역 조회
  List<Transaction> getAllTransactions() {
    final allTransactions = <Transaction>[];
    for (final transactions in _accountTransactions.values) {
      allTransactions.addAll(transactions);
    }
    return List.unmodifiable(allTransactions);
  }

  /// Returns all transactions across all accounts within [start]..[end]
  /// (inclusive).
  ///
  /// This is a convenience API for analytics modules.
  Future<List<Transaction>> getTransactionsBetween(
    DateTime start,
    DateTime end,
  ) async {
    await loadTransactions();
    final startUtc = DateTime.utc(start.year, start.month, start.day);
    final endUtc = DateTime.utc(end.year, end.month, end.day, 23, 59, 59, 999);

    final result = <Transaction>[];
    for (final list in _accountTransactions.values) {
      for (final tx in list) {
        final d = tx.date.toUtc();
        if (d.isBefore(startUtc) || d.isAfter(endUtc)) continue;
        result.add(tx);
      }
    }
    result.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(result);
  }

  Future<void> loadTransactions() {
    if (_initialized) {
      return Future.value();
    }
    _loading ??= _doLoad();
    return _loading!;
  }

  Future<void> createAccount(String name) async {
    await loadTransactions();
    if (_accountTransactions.containsKey(name)) {
      return;
    }
    _accountTransactions[name] = [];
    await _persist(
      dbUpsert: (backend) async {
        if (backend != _backendDb) return;
        await _dbStore.ensureAccountId(name);
      },
    );
  }

  Future<void> deleteAccount(String name) async {
    await loadTransactions();
    final removed = _accountTransactions.remove(name);
    if (removed != null) {
      await _persist();
    }
  }

  Future<void> addTransaction(
    String accountName,
    Transaction transaction,
  ) async {
    await loadTransactions();
    final transactions = _accountTransactions.putIfAbsent(
      accountName,
      () => [],
    );
    final normalized = _normalizeForPersist(transaction);
    transactions.add(normalized);
    await _persist(
      dbUpsert: (backend) async {
        if (backend != _backendDb) return;
        await _dbStore.upsertTransaction(accountName, normalized);
      },
    );

    final ym = MonthlyAggCacheService.yearMonthOf(normalized.date);
    await MonthlyAggCacheService().markDirty(accountName, <String>{ym});

    try {
      await TransactionFtsIndexService().upsertTransaction(
        accountName,
        normalized,
      );
    } catch (_) {
      // Index is a cache; ignore failures and allow rebuild via stamps.
    }

    try {
      await TransactionBenefitMonthlyAggService().upsertTransaction(
        accountName,
        normalized,
      );
    } catch (_) {
      // Aggregation is a cache; can be rebuilt via stamps.
    }

    // Reward medals (best-effort; ignore failures).
    try {
      if (BenefitAggregationUtils.isSkippedSpendRecord(normalized)) {
        await RewardBadgeService.instance.awardOnce(
          accountName: accountName,
          type: RewardBadgeService.typeSkippedSpend,
          dedupeKey: normalized.id,
        );
      }
      if (BenefitAggregationUtils.isSavedPointsRecord(normalized)) {
        await RewardBadgeService.instance.awardOnce(
          accountName: accountName,
          type: RewardBadgeService.typeProject100m,
          dedupeKey: normalized.id,
        );
      }
    } catch (_) {
      // Ignore reward failures.
    }

    await _logTransactionAudit(
      action: 'transaction_added',
      accountName: accountName,
      transaction: normalized,
    );

    await _evaluateAnomalySignals(
      accountName: accountName,
      transaction: normalized,
    );
  }

  Future<bool> updateTransaction(
    String accountName,
    Transaction updated,
  ) async {
    await loadTransactions();
    final transactions = _accountTransactions[accountName];
    if (transactions == null) {
      return false;
    }
    final index = transactions.indexWhere((t) => t.id == updated.id);
    if (index == -1) {
      return false;
    }
    final before = transactions[index];
    final normalized = _normalizeForPersist(updated);
    transactions[index] = normalized;
    await _persist(
      dbUpsert: (backend) async {
        if (backend != _backendDb) return;
        await _dbStore.upsertTransaction(accountName, normalized);
      },
    );

    final ymBefore = MonthlyAggCacheService.yearMonthOf(before.date);
    final ymAfter = MonthlyAggCacheService.yearMonthOf(normalized.date);
    await MonthlyAggCacheService().markDirty(accountName, <String>{
      ymBefore,
      ymAfter,
    });

    try {
      await TransactionFtsIndexService().upsertTransaction(
        accountName,
        normalized,
      );
    } catch (_) {
      // Ignore index failures (rebuild on next ensure).
    }

    try {
      await TransactionBenefitMonthlyAggService().applyUpdate(
        accountName,
        before: before,
        after: normalized,
      );
    } catch (_) {
      // Ignore aggregation failures (rebuild on next ensure).
    }

    await _logTransactionAudit(
      action: 'transaction_updated',
      accountName: accountName,
      transaction: normalized,
      metadata: {
        'beforeAmount': before.amount,
        'afterAmount': normalized.amount,
      },
    );
    return true;
  }

  Transaction _normalizeForPersist(Transaction tx) {
    final existingStore = tx.store?.trim() ?? '';
    if (existingStore.isNotEmpty) {
      return tx;
    }

    final extracted = StoreMemoUtils.extractStoreKey(tx.memo);
    if (extracted == null || extracted.trim().isEmpty) {
      return tx;
    }
    return tx.copyWith(store: extracted.trim());
  }

  Future<void> deleteTransaction(
    String accountName,
    String transactionId, {
    bool moveToTrash = true,
  }) async {
    await loadTransactions();
    final transactions = _accountTransactions[accountName];
    if (transactions == null) {
      return;
    }
    final index = transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) {
      return;
    }
    final removed = transactions.removeAt(index);
    if (moveToTrash) {
      await TrashService().addTransaction(accountName, removed);
    }
    await _persist(
      dbUpsert: (backend) async {
        if (backend != _backendDb) return;
        await _dbStore.deleteTransaction(accountName, transactionId);
      },
    );

    final ym = MonthlyAggCacheService.yearMonthOf(removed.date);
    await MonthlyAggCacheService().markDirty(accountName, <String>{ym});

    try {
      await TransactionFtsIndexService().deleteTransaction(
        accountName,
        transactionId,
      );
    } catch (_) {
      // Ignore index failures (rebuild on next ensure).
    }

    try {
      await TransactionBenefitMonthlyAggService().deleteTransaction(
        accountName,
        removed,
      );
    } catch (_) {
      // Ignore aggregation failures (rebuild on next ensure).
    }

    await _logTransactionAudit(
      action: 'transaction_deleted',
      accountName: accountName,
      transaction: removed,
      metadata: {
        'moveToTrash': moveToTrash,
      },
    );
  }

  /// 반품 처리: 원본 거래의 환불 거래를 생성
  Future<void> createRefundTransaction(
    String accountName,
    Transaction originalTransaction, {
    DateTime? refundDate,
    double? refundAmount,
  }) async {
    await loadTransactions();

    // 반품 거래 생성 (마이너스 지출로 기록)
    final refund = originalTransaction.createRefund(
      refundId: 'refund_${DateTime.now().millisecondsSinceEpoch}',
      refundDate: refundDate ?? DateTime.now(),
      refundAmount: refundAmount,
    );

    // 반품 거래 추가
    await addTransaction(accountName, refund);

    final ym = MonthlyAggCacheService.yearMonthOf(refund.date);
    await MonthlyAggCacheService().markDirty(accountName, <String>{ym});
  }

  /// 특정 거래의 반품 내역 조회
  List<Transaction> getRefundsForTransaction(
    String accountName,
    String originalTransactionId,
  ) {
    final transactions = _accountTransactions[accountName];
    if (transactions == null) {
      return const <Transaction>[];
    }

    return transactions
        .where(
          (t) => t.isRefund && t.originalTransactionId == originalTransactionId,
        )
        .toList();
  }

  Future<void> _logTransactionAudit({
    required String action,
    required String accountName,
    required Transaction transaction,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await AuditLogService.logTransactionEvent(
        action: action,
        accountId: accountName,
        amount: transaction.amount,
        transactionId: transaction.id,
        transactionType: transaction.type.name,
        metadata: {
          'isRefund': transaction.isRefund,
          ...?metadata,
        },
      );
    } catch (_) {
      // Audit logging is best-effort and should not break transaction flow.
    }
  }

  Future<void> _evaluateAnomalySignals({
    required String accountName,
    required Transaction transaction,
  }) async {
    try {
      final engine = WorkflowAutomationEngine();
      await engine.initialize();

      var violationCount = 0;

      final recentFailures = await AuditLogService.getFailedActions(limit: 5);
      if (recentFailures.length >= 3) {
        violationCount += 1;
        await AuditLogService.log(
          eventType: AuditEventType.policyEnforcement,
          action: 'anomaly_signal_repeated_failures',
          userLevel: UserPermissionLevel.operator,
          targetResource: accountName,
          metadata: {
            'transactionId': transaction.id,
            'ruleId': 'rule_repeated_failures_v1',
            'failedActions': recentFailures.length,
            'window': 'recent_5',
            'threshold': 3,
            'observedValue': recentFailures.length,
          },
        );
      }

      if (transaction.amount.abs() >= _largeTransactionThreshold) {
        violationCount += 1;
        await AuditLogService.log(
          eventType: AuditEventType.policyEnforcement,
          action: 'anomaly_signal_large_transaction',
          userLevel: UserPermissionLevel.operator,
          targetResource: accountName,
          metadata: {
            'transactionId': transaction.id,
            'ruleId': 'rule_large_transaction_v1',
            'amount': transaction.amount,
            'threshold': _largeTransactionThreshold,
            'observedValue': transaction.amount.abs(),
          },
          riskLevel: ActionRiskLevel.warning,
        );
      }

      final hour = transaction.date.toLocal().hour;
      final isOffHours = hour < 5;
      if (isOffHours) {
        violationCount += 1;
        await AuditLogService.log(
          eventType: AuditEventType.policyEnforcement,
          action: 'anomaly_signal_off_hours_sensitive_action',
          userLevel: UserPermissionLevel.operator,
          targetResource: accountName,
          metadata: {
            'transactionId': transaction.id,
            'ruleId': 'rule_off_hours_sensitive_action_v1',
            'hour': hour,
            'offHours': true,
            'window': '00:00-04:59',
            'threshold': 5,
            'observedValue': hour,
          },
          riskLevel: ActionRiskLevel.warning,
        );
      }

      if (violationCount <= 0) {
        return;
      }

      await AuditLogService.log(
        eventType: AuditEventType.securityViolation,
        action: 'anomaly_detection_summary',
        userLevel: UserPermissionLevel.operator,
        targetResource: accountName,
        metadata: {
          'transactionId': transaction.id,
          'ruleId': 'rule_security_alert',
          'threshold': 3,
          'observedValue': violationCount,
          'violation_count': violationCount,
        },
      );

      await engine.evaluateRules(
        eventType: 'security_violation',
        eventData: {
          'violation_count': violationCount,
          'accountId': accountName,
          'transactionId': transaction.id,
          'amount': transaction.amount,
        },
      );
    } catch (_) {
      // Best-effort anomaly detection should not break transaction flow.
    }
  }
}
