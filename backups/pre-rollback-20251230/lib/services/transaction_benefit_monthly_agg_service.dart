import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_ledger/database/database_provider.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/transaction_db_store.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/benefit_memo_utils.dart';

class TransactionBenefitMonthlyAggService {
  static final TransactionBenefitMonthlyAggService _instance =
      TransactionBenefitMonthlyAggService._internal();
  factory TransactionBenefitMonthlyAggService() => _instance;
  TransactionBenefitMonthlyAggService._internal();

  static const String _prefsTxPersistStampKey =
      'tx_persist_stamp_v1_transactions_json';
  static const String _prefsBenefitAggStampKey =
      'tx_benefit_monthly_agg_stamp_v1_transactions_json';

  final TransactionDbStore _dbStore = TransactionDbStore();

  String _ym(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  Map<String, double> _benefitByType(Transaction tx) {
    final fromJson = tx.benefitByType;
    if (fromJson.isNotEmpty) return fromJson;
    return BenefitMemoUtils.parseBenefitByType(tx.memo);
  }

  Future<void> ensureAggregatedFromPrefs() async {
    await TransactionService().loadTransactions();

    final prefs = await SharedPreferences.getInstance();
    final txStamp = prefs.getInt(_prefsTxPersistStampKey) ?? 0;
    final aggStamp = prefs.getInt(_prefsBenefitAggStampKey) ?? 0;

    if (txStamp != 0 && txStamp == aggStamp) {
      return;
    }

    await rebuildFromCurrentMemory();

    final afterStamp = prefs.getInt(_prefsTxPersistStampKey) ?? txStamp;
    await prefs.setInt(_prefsBenefitAggStampKey, afterStamp);
  }

  Future<void> rebuildFromCurrentMemory() async {
    final db = DatabaseProvider.instance.database;
    final service = TransactionService();

    await db.customStatement('DELETE FROM tx_benefit_monthly');

    final acc = <String, _MonthlyAgg>{};

    for (final accountName in service.getAllAccountNames()) {
      final accountId = await _dbStore.ensureAccountId(accountName);
      if (accountId == null) continue;

      final txs = service.getTransactions(accountName);
      for (final tx in txs) {
        final byType = _benefitByType(tx);
        if (byType.isEmpty) continue;

        final ym = _ym(tx.date);
        for (final e in byType.entries) {
          final key = e.key.trim();
          final amount = e.value;
          if (key.isEmpty) continue;
          if (amount.isNaN || amount.isInfinite) continue;
          if (amount <= 0) continue;

          final k = '$accountId|$ym|$key';
          final item = acc.putIfAbsent(
            k,
            () => _MonthlyAgg(
              accountId: accountId,
              ym: ym,
              benefitType: key,
            ),
          );
          item.total += amount;
          item.count += 1;
        }
      }
    }

    if (acc.isEmpty) {
      return;
    }

    await db.batch((b) {
      for (final item in acc.values) {
        b.customStatement(
          'INSERT INTO tx_benefit_monthly('
          'account_id, ym, benefit_type, total_amount, tx_count'
          ') VALUES (?, ?, ?, ?, ?)',
          <Object?>[
            item.accountId,
            item.ym,
            item.benefitType,
            item.total,
            item.count,
          ],
        );
      }
    });
  }

  Future<void> upsertTransaction(String accountName, Transaction tx) async {
    final byType = _benefitByType(tx);
    if (byType.isEmpty) {
      await _syncAggStampToPersistStamp();
      return;
    }

    final accountId = await _dbStore.ensureAccountId(accountName);
    if (accountId == null) return;

    final db = DatabaseProvider.instance.database;
    final ym = _ym(tx.date);

    await db.batch((b) {
      for (final e in byType.entries) {
        final key = e.key.trim();
        final amount = e.value;
        if (key.isEmpty) continue;
        if (amount.isNaN || amount.isInfinite) continue;
        if (amount <= 0) continue;

        b.customStatement(
          'INSERT INTO tx_benefit_monthly('
          'account_id, ym, benefit_type, total_amount, tx_count'
          ') VALUES (?, ?, ?, ?, ?) '
          'ON CONFLICT(account_id, ym, benefit_type) DO UPDATE SET '
          'total_amount = total_amount + excluded.total_amount, '
          'tx_count = tx_count + excluded.tx_count',
          <Object?>[accountId, ym, key, amount, 1],
        );
      }
    });

    await _syncAggStampToPersistStamp();
  }

  Future<void> deleteTransaction(String accountName, Transaction tx) async {
    final byType = _benefitByType(tx);
    if (byType.isEmpty) {
      await _syncAggStampToPersistStamp();
      return;
    }

    final accountId = await _dbStore.ensureAccountId(accountName);
    if (accountId == null) return;

    final db = DatabaseProvider.instance.database;
    final ym = _ym(tx.date);

    await db.batch((b) {
      for (final e in byType.entries) {
        final key = e.key.trim();
        final amount = e.value;
        if (key.isEmpty) continue;
        if (amount.isNaN || amount.isInfinite) continue;
        if (amount <= 0) continue;

        b.customStatement(
          'UPDATE tx_benefit_monthly '
          'SET total_amount = total_amount - ?, tx_count = tx_count - 1 '
          'WHERE account_id = ? AND ym = ? AND benefit_type = ?',
          <Object?>[amount, accountId, ym, key],
        );
        b.customStatement(
          'DELETE FROM tx_benefit_monthly '
          'WHERE account_id = ? AND ym = ? AND benefit_type = ? '
          'AND (tx_count <= 0 OR total_amount <= 0)',
          <Object?>[accountId, ym, key],
        );
      }
    });

    await _syncAggStampToPersistStamp();
  }

  Future<void> applyUpdate(
    String accountName, {
    required Transaction before,
    required Transaction after,
  }) async {
    // Remove before, then add after.
    await deleteTransaction(accountName, before);
    await upsertTransaction(accountName, after);
  }

  Future<double> sumTotal({
    required String accountName,
    String? benefitTypeContains,
    required String startYm,
    required String endYm,
  }) async {
    final accountId = await _dbStore.ensureAccountId(accountName);
    if (accountId == null) return 0;

    final db = DatabaseProvider.instance.database;

    final where = StringBuffer()
      ..write('account_id = ? AND ym >= ? AND ym <= ?');
    final vars = <Variable<Object>>[
      Variable<int>(accountId),
      Variable<String>(startYm),
      Variable<String>(endYm),
    ];

    if (benefitTypeContains != null && benefitTypeContains.trim().isNotEmpty) {
      where.write(' AND LOWER(benefit_type) LIKE ?');
      vars.add(Variable<String>('%${benefitTypeContains.trim().toLowerCase()}%'));
    }

    final row = await db.customSelect(
      'SELECT COALESCE(SUM(total_amount), 0) AS s '
      'FROM tx_benefit_monthly '
      'WHERE ${where.toString()}',
      variables: vars,
    ).getSingle();

    final v = row.read<num>('s').toDouble();
    return v;
  }

  static Future<void> _syncAggStampToPersistStamp() async {
    final prefs = await SharedPreferences.getInstance();
    final txStamp = prefs.getInt(_prefsTxPersistStampKey) ?? 0;
    if (txStamp == 0) return;
    await prefs.setInt(_prefsBenefitAggStampKey, txStamp);
  }
}

class _MonthlyAgg {
  final int accountId;
  final String ym;
  final String benefitType;

  double total = 0;
  int count = 0;

  _MonthlyAgg({
    required this.accountId,
    required this.ym,
    required this.benefitType,
  });
}

