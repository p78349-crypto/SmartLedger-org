import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_provider.dart';
import '../models/transaction.dart';
import 'transaction_service.dart';

class TransactionFtsHit {
  const TransactionFtsHit({
    required this.accountName,
    required this.transactionId,
    this.rank,
  });

  final String accountName;
  final String transactionId;
  final double? rank;
}

class TransactionFtsIndexService {
  static final _instance = TransactionFtsIndexService._internal();
  factory TransactionFtsIndexService() => _instance;
  TransactionFtsIndexService._internal();

  static const _prefsTxPersistStampKey =
      'tx_persist_stamp_v1_transactions_json';
  static const _prefsFtsIndexedStampKey =
      'tx_fts_indexed_stamp_v1_transactions_json';

  Future<void> ensureIndexedFromPrefs() async {
    await TransactionService().loadTransactions();
    final prefs = await SharedPreferences.getInstance();
    final txStamp = prefs.getInt(_prefsTxPersistStampKey) ?? 0;
    final ftsStamp = prefs.getInt(_prefsFtsIndexedStampKey) ?? 0;
    if (txStamp != 0 && txStamp == ftsStamp) {
      return;
    }
    await rebuildFromCurrentMemory();
    final afterStamp = prefs.getInt(_prefsTxPersistStampKey) ?? txStamp;
    await prefs.setInt(_prefsFtsIndexedStampKey, afterStamp);
  }

  Future<void> rebuildFromCurrentMemory() async {
    final db = DatabaseProvider.instance.database;
    final service = TransactionService();
    await db.customStatement('DELETE FROM tx_fts');
    await db.batch((b) {
      for (final accountName in service.getAllAccountNames()) {
        final txs = service.getTransactions(accountName);
        for (final tx in txs) {
          final amountText = _amountText(tx.amount);
          final ymd = _dateYmd(tx.date);
          final ym = _dateYm(tx.date);
          b.customStatement(
            'INSERT INTO tx_fts('
            'transaction_id, account_name, description, memo, payment_method, '
            'store, main_category, sub_category, '
            'amount_text, date_ymd, date_ym, year_text, month_text'
            ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            <Object?>[
              tx.id,
              accountName,
              tx.description,
              tx.memo,
              tx.paymentMethod,
              tx.store,
              tx.mainCategory,
              tx.subCategory,
              amountText,
              ymd,
              ym,
              tx.date.year.toString(),
              tx.date.month.toString(),
            ],
          );
        }
      }
    });
  }

  Future<void> upsertTransaction(String accountName, Transaction tx) async {
    final db = DatabaseProvider.instance.database;
    final amountText = _amountText(tx.amount);
    final ymd = _dateYmd(tx.date);
    final ym = _dateYm(tx.date);
    await db.transaction(() async {
      await db.customStatement(
        'DELETE FROM tx_fts WHERE transaction_id = ? AND account_name = ?',
        <Object?>[tx.id, accountName],
      );
      await db.customStatement(
        'INSERT INTO tx_fts('
        'transaction_id, account_name, description, memo, payment_method, '
        'store, main_category, sub_category, '
        'amount_text, date_ymd, date_ym, year_text, month_text'
        ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          tx.id,
          accountName,
          tx.description,
          tx.memo,
          tx.paymentMethod,
          tx.store,
          tx.mainCategory,
          tx.subCategory,
          amountText,
          ymd,
          ym,
          tx.date.year.toString(),
          tx.date.month.toString(),
        ],
      );
    });
    await _syncIndexedStampToPersistStamp();
  }

  Future<void> deleteTransaction(
    String accountName,
    String transactionId,
  ) async {
    final db = DatabaseProvider.instance.database;
    await db.customStatement(
      'DELETE FROM tx_fts WHERE transaction_id = ? AND account_name = ?',
      <Object?>[transactionId, accountName],
    );
    await _syncIndexedStampToPersistStamp();
  }

  Future<List<TransactionFtsHit>> search({
    String? accountName,
    required String query,
    bool memoOnly = false,
    int limit = 500,
  }) async {
    final db = DatabaseProvider.instance.database;
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <TransactionFtsHit>[];
    final matchExpr = _buildMatchExpression(trimmed, memoOnly: memoOnly);
    final sql = StringBuffer()
      ..write('SELECT transaction_id, account_name, bm25(tx_fts) AS rank ')
      ..write('FROM tx_fts ')
      ..write('WHERE tx_fts MATCH ? ');

    final args = <Variable<Object>>[Variable<String>(matchExpr)];

    if (accountName != null && accountName.trim().isNotEmpty) {
      sql.write('AND account_name = ? ');
      args.add(Variable<String>(accountName.trim()));
    }

    sql.write('ORDER BY rank LIMIT ?');
    args.add(Variable<int>(limit));

    final rows = await db.customSelect(sql.toString(), variables: args).get();
    return rows.map((row) {
      return TransactionFtsHit(
        transactionId: row.read<String>('transaction_id'),
        accountName: row.read<String>('account_name'),
        rank: row.readNullable<double>('rank'),
      );
    }).toList();
  }

  String _buildMatchExpression(String input, {required bool memoOnly}) {
    var normalized = input;
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\d),(?=\d)'),
      (m) => m.group(1) ?? '',
    );

    String pad2(String s) => s.padLeft(2, '0');
    String esc(String token) => '$token*';
    final scoped = <String>[];
    final ignoreNumericTokens = <String>{};
    if (!memoOnly) {
      for (final m in RegExp(
        r'(\d[\d,]*)\s*원',
        unicode: true,
      ).allMatches(input)) {
        final raw = (m.group(1) ?? '').replaceAll(',', '').trim();
        if (raw.isEmpty) continue;
        scoped.add('amount_text:${esc(raw)}');
        ignoreNumericTokens.add(raw);
      }

      for (final m in RegExp(
        r'(\d{4})[./-](\d{1,2})[./-](\d{1,2})',
      ).allMatches(input)) {
        final y = m.group(1) ?? '';
        final mo = m.group(2) ?? '';
        final d = m.group(3) ?? '';
        if (y.isEmpty || mo.isEmpty || d.isEmpty) continue;
        scoped.add('date_ymd:${esc(y)}');
        scoped.add('date_ymd:${esc(pad2(mo))}');
        scoped.add('date_ymd:${esc(pad2(d))}');
        ignoreNumericTokens.add(y);
        ignoreNumericTokens.add(pad2(mo));
        ignoreNumericTokens.add(pad2(d));
      }

      for (final m in RegExp(r'(\d{4})[./-](\d{1,2})').allMatches(input)) {
        final after = input.substring(m.end);
        if (after.startsWith('-') ||
            after.startsWith('/') ||
            after.startsWith('.')) {
          continue;
        }
        final y = m.group(1) ?? '';
        final mo = m.group(2) ?? '';
        if (y.isEmpty || mo.isEmpty) continue;
        scoped.add('date_ym:${esc(y)}');
        scoped.add('date_ym:${esc(pad2(mo))}');
        ignoreNumericTokens.add(y);
        ignoreNumericTokens.add(pad2(mo));
      }

      for (final m in RegExp(r'(\d{4})\s*년', unicode: true).allMatches(input)) {
        final y = (m.group(1) ?? '').trim();
        if (y.isEmpty) continue;
        scoped.add('year_text:${esc(y)}');
        ignoreNumericTokens.add(y);
      }

      for (final m in RegExp(
        r'(\d{1,2})\s*월',
        unicode: true,
      ).allMatches(input)) {
        final mo = (m.group(1) ?? '').trim();
        if (mo.isEmpty) continue;
        scoped.add('month_text:${esc(mo)}');
        ignoreNumericTokens.add(mo);
        ignoreNumericTokens.add(pad2(mo));
      }
    }
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\d+)\s*(원|월|년|일|개월|분기|반기)', unicode: true),
      (m) => m.group(1) ?? '',
    );

    final tokens = <String>[];
    for (final part in normalized.split(RegExp(r'\s+'))) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final sub = trimmed
          .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty);
      tokens.addAll(sub);
    }

    if (tokens.isEmpty) return '';

    if (memoOnly) {
      return tokens.map((t) => 'memo:${esc(t)}').join(' AND ');
    }

    final unscoped = <String>[];
    for (final t in tokens) {
      final isDigits = RegExp(r'^\d+$').hasMatch(t);
      if (isDigits && ignoreNumericTokens.contains(t)) continue;
      unscoped.add(esc(t));
    }

    final allTerms = <String>[...scoped, ...unscoped];
    return allTerms.join(' AND ');
  }

  static String _amountText(double amount) {
    final isInt = amount % 1 == 0;
    return isInt ? amount.toInt().toString() : amount.toString();
  }

  static String _dateYmd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _dateYm(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  static Future<void> _syncIndexedStampToPersistStamp() async {
    final prefs = await SharedPreferences.getInstance();
    final txStamp = prefs.getInt(_prefsTxPersistStampKey) ?? 0;
    if (txStamp == 0) return;
    await prefs.setInt(_prefsFtsIndexedStampKey, txStamp);
  }

  /// Called by TransactionService persistence to keep stamps consistent.
  static Future<void> bumpTransactionsPersistStamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefsTxPersistStampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
