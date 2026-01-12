library transaction_service;

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_provider.dart';
import '../models/transaction.dart';
import '../utils/pref_keys.dart';
import '../utils/store_memo_utils.dart';
import 'monthly_agg_cache_service.dart';
import 'transaction_benefit_monthly_agg_service.dart';
import 'transaction_db_migration_service.dart';
import 'transaction_db_store.dart';
import 'transaction_fts_index_service.dart';
import 'trash_service.dart';

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
}
