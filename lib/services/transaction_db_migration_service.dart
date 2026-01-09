import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import 'transaction_db_store.dart';
import '../utils/pref_keys.dart';

class TransactionDbMigrationResult {
  const TransactionDbMigrationResult({
    required this.performed,
    required this.totalImported,
  });

  final bool performed;
  final int totalImported;
}

class TransactionDbMigrationService {
  static final TransactionDbMigrationService _instance =
      TransactionDbMigrationService._internal();
  factory TransactionDbMigrationService() => _instance;
  TransactionDbMigrationService._internal();

  static const int _defaultBatchSize = 800;

  Future<TransactionDbMigrationResult> ensureMigratedFromPrefs({
    int batchSize = _defaultBatchSize,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool(PrefKeys.txDbMigratedV1) ?? false;
    if (already) {
      return const TransactionDbMigrationResult(
        performed: false,
        totalImported: 0,
      );
    }

    final raw = prefs.getString(PrefKeys.transactions);
    if (raw == null || raw.trim().isEmpty) {
      await _markMigrated(prefs);
      return const TransactionDbMigrationResult(
        performed: false,
        totalImported: 0,
      );
    }

    Map<String, dynamic> decoded;
    try {
      final d = jsonDecode(raw);
      if (d is! Map) {
        await _markMigrated(prefs);
        return const TransactionDbMigrationResult(
          performed: false,
          totalImported: 0,
        );
      }
      decoded = Map<String, dynamic>.from(d);
    } catch (_) {
      // If legacy JSON is corrupted, do not block app.
      // Mark migrated to avoid loops.
      await _markMigrated(prefs);
      return const TransactionDbMigrationResult(
        performed: false,
        totalImported: 0,
      );
    }

    final store = TransactionDbStore();
    var totalImported = 0;

    for (final entry in decoded.entries) {
      final accountName = entry.key;
      final value = entry.value;
      if (value is! List) continue;

      final txs = <Transaction>[];
      for (final item in value) {
        if (item is! Map) continue;
        try {
          txs.add(Transaction.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Skip malformed rows.
        }
      }

      for (var i = 0; i < txs.length; i += batchSize) {
        final chunk = txs.sublist(i, (i + batchSize).clamp(0, txs.length));
        await store.upsertMany(accountName, chunk);
      }

      // Basic verification: counts should be >= imported list count.
      // (If the app previously had DB transactions for this account, upsert
      //  keeps the count potentially larger. That's fine.)
      final countAfter = await store.countForAccount(accountName);
      if (countAfter < txs.length) {
        // Do not flip the migrated flag if verification fails.
        // Leave as not migrated so user/dev can retry.
        return TransactionDbMigrationResult(
          performed: true,
          totalImported: totalImported,
        );
      }

      totalImported += txs.length;
    }

    await _markMigrated(prefs);
    return TransactionDbMigrationResult(
      performed: true,
      totalImported: totalImported,
    );
  }

  static Future<void> _markMigrated(SharedPreferences prefs) async {
    await prefs.setBool(PrefKeys.txDbMigratedV1, true);
    await prefs.setInt(
      PrefKeys.txDbMigratedAtMsV1,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
