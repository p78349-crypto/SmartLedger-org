import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';

/// 배치 데이터 정합성 검증 쿼리 서비스.
///
/// 일일/주간 정합성 체크를 통해
/// 잔액 불일치, 고아 레코드, 해시 깨짐, 중복 syncId 등을 탐지.
class BatchIntegrityVerifier {
  BatchIntegrityVerifier._();
  static final instance = BatchIntegrityVerifier._();

  AppDatabase get _db => DatabaseProvider.instance.database;

  /// ─── 1. 잔액 정합성 (수입 - 지출 vs 기대값) ─────────

  /// 계정별 수입/지출 합계를 계산한다.
  Future<List<AccountBalanceCheck>> checkBalances() async {
    final rows = await _db.customSelect('''
      SELECT
        a.id          AS account_id,
        a.name        AS account_name,
        COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) AS total_income,
        COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0) AS total_expense,
        COALESCE(SUM(CASE WHEN t.type = 'savings' THEN t.amount ELSE 0 END), 0) AS total_savings,
        COUNT(t.id)   AS tx_count
      FROM db_accounts a
      LEFT JOIN db_transactions t
        ON t.account_id = a.id AND t.is_deleted = 0
      WHERE a.is_deleted = 0
      GROUP BY a.id
      ''').get();

    return rows
        .map(
          (r) => AccountBalanceCheck(
            accountId: r.read<int>('account_id'),
            accountName: r.read<String>('account_name'),
            totalIncome: r.read<double>('total_income'),
            totalExpense: r.read<double>('total_expense'),
            totalSavings: r.read<double>('total_savings'),
            txCount: r.read<int>('tx_count'),
          ),
        )
        .toList();
  }

  /// ─── 2. 고아 레코드 (없는 account_id 참조) ──────────

  Future<List<OrphanRecord>> findOrphanTransactions() async {
    final rows = await _db.customSelect('''
      SELECT t.id AS tx_id, t.account_id
      FROM db_transactions t
      LEFT JOIN db_accounts a ON a.id = t.account_id
      WHERE a.id IS NULL
      LIMIT 1000
      ''').get();

    return rows
        .map(
          (r) => OrphanRecord(
            transactionId: r.read<String>('tx_id'),
            accountId: r.read<int>('account_id'),
          ),
        )
        .toList();
  }

  /// ─── 3. 중복 syncId 탐지 ──────────────────────────

  Future<List<DuplicateSyncId>> findDuplicateSyncIds() async {
    final rows = await _db.customSelect('''
      SELECT sync_id, COUNT(*) AS cnt
      FROM db_transactions
      WHERE sync_id IS NOT NULL AND sync_id != ''
      GROUP BY sync_id
      HAVING cnt > 1
      LIMIT 500
      ''').get();

    return rows
        .map(
          (r) => DuplicateSyncId(
            syncId: r.read<String>('sync_id'),
            count: r.read<int>('cnt'),
          ),
        )
        .toList();
  }

  /// ─── 4. 해시 누락 레코드 카운트 ───────────────────

  Future<Map<int, int>> countMissingHashes() async {
    final rows = await _db.customSelect('''
      SELECT account_id, COUNT(*) AS missing
      FROM db_transactions
      WHERE (integrity_hash IS NULL OR integrity_hash = '')
        AND is_deleted = 0
      GROUP BY account_id
      ''').get();

    return {
      for (final r in rows) r.read<int>('account_id'): r.read<int>('missing'),
    };
  }

  /// ─── 5. 날짜 이상치 (미래 날짜 거래) ───────────────

  Future<List<String>> findFutureDateTransactions() async {
    final rows = await _db
        .customSelect(
          '''
      SELECT id FROM db_transactions
      WHERE date > ? AND is_deleted = 0
      LIMIT 500
      ''',
          variables: [
            Variable<DateTime>(DateTime.now().add(const Duration(days: 1))),
          ],
        )
        .get();

    return rows.map((r) => r.read<String>('id')).toList();
  }

  /// ─── 6. 금액 이상치 (음수, 극단값) ─────────────────

  Future<List<AmountAnomaly>> findAmountAnomalies({
    double threshold = 100000000,
  }) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT id, amount, type FROM db_transactions
      WHERE is_deleted = 0
        AND (amount < 0 OR amount > ?)
      LIMIT 500
      ''',
          variables: [Variable<double>(threshold)],
        )
        .get();

    return rows
        .map(
          (r) => AmountAnomaly(
            transactionId: r.read<String>('id'),
            amount: r.read<double>('amount'),
            type: r.read<String>('type'),
          ),
        )
        .toList();
  }

  /// ─── 7. 멱등성 키 통계 ─────────────────────────────

  Future<IdempotencyStats> idempotencyStats() async {
    final total = await _db
        .customSelect('SELECT COUNT(*) AS c FROM db_idempotency_keys')
        .getSingle();
    final active = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM db_idempotency_keys '
          'WHERE expires_at > ?',
          variables: [Variable<DateTime>(DateTime.now())],
        )
        .getSingle();

    return IdempotencyStats(
      totalKeys: total.read<int>('c'),
      activeKeys: active.read<int>('c'),
    );
  }

  /// ─── 통합 리포트 ──────────────────────────────────

  /// 전체 정합성 리포트를 한 번에 생성한다.
  Future<IntegrityReport> runFullReport({
    double amountThreshold = 100000000,
  }) async {
    final balances = await checkBalances();
    final orphans = await findOrphanTransactions();
    final dupSyncIds = await findDuplicateSyncIds();
    final missingHashes = await countMissingHashes();
    final futureDates = await findFutureDateTransactions();
    final amountAnomalies = await findAmountAnomalies(
      threshold: amountThreshold,
    );
    final idempotency = await idempotencyStats();

    return IntegrityReport(
      timestamp: DateTime.now(),
      balances: balances,
      orphanRecords: orphans,
      duplicateSyncIds: dupSyncIds,
      missingHashesByAccount: missingHashes,
      futureDateIds: futureDates,
      amountAnomalies: amountAnomalies,
      idempotencyStats: idempotency,
    );
  }
}

// ─── Result Models ────────────────────────────────────

class AccountBalanceCheck {
  final int accountId;
  final String accountName;
  final double totalIncome;
  final double totalExpense;
  final double totalSavings;
  final int txCount;

  const AccountBalanceCheck({
    required this.accountId,
    required this.accountName,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalSavings,
    required this.txCount,
  });

  double get netBalance => totalIncome - totalExpense;

  Map<String, dynamic> toJson() => {
    'accountId': accountId,
    'accountName': accountName,
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
    'totalSavings': totalSavings,
    'netBalance': netBalance,
    'txCount': txCount,
  };
}

class OrphanRecord {
  final String transactionId;
  final int accountId;

  const OrphanRecord({required this.transactionId, required this.accountId});
}

class DuplicateSyncId {
  final String syncId;
  final int count;

  const DuplicateSyncId({required this.syncId, required this.count});
}

class AmountAnomaly {
  final String transactionId;
  final double amount;
  final String type;

  const AmountAnomaly({
    required this.transactionId,
    required this.amount,
    required this.type,
  });
}

class IdempotencyStats {
  final int totalKeys;
  final int activeKeys;

  const IdempotencyStats({required this.totalKeys, required this.activeKeys});

  int get expiredKeys => totalKeys - activeKeys;
}

class IntegrityReport {
  final DateTime timestamp;
  final List<AccountBalanceCheck> balances;
  final List<OrphanRecord> orphanRecords;
  final List<DuplicateSyncId> duplicateSyncIds;
  final Map<int, int> missingHashesByAccount;
  final List<String> futureDateIds;
  final List<AmountAnomaly> amountAnomalies;
  final IdempotencyStats idempotencyStats;

  const IntegrityReport({
    required this.timestamp,
    required this.balances,
    required this.orphanRecords,
    required this.duplicateSyncIds,
    required this.missingHashesByAccount,
    required this.futureDateIds,
    required this.amountAnomalies,
    required this.idempotencyStats,
  });

  bool get isClean =>
      orphanRecords.isEmpty &&
      duplicateSyncIds.isEmpty &&
      futureDateIds.isEmpty &&
      amountAnomalies.isEmpty;

  int get totalMissingHashes =>
      missingHashesByAccount.values.fold(0, (a, b) => a + b);

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'isClean': isClean,
    'accounts': balances.length,
    'orphanRecords': orphanRecords.length,
    'duplicateSyncIds': duplicateSyncIds.length,
    'totalMissingHashes': totalMissingHashes,
    'futureDateTransactions': futureDateIds.length,
    'amountAnomalies': amountAnomalies.length,
    'idempotency': {
      'active': idempotencyStats.activeKeys,
      'expired': idempotencyStats.expiredKeys,
    },
    'balances': balances.map((b) => b.toJson()).toList(),
  };

  @override
  String toString() {
    final buf = StringBuffer()
      ..writeln('=== Integrity Report (${timestamp.toIso8601String()}) ===')
      ..writeln('Clean: $isClean')
      ..writeln('Accounts: ${balances.length}')
      ..writeln('Orphan records: ${orphanRecords.length}')
      ..writeln('Duplicate syncIds: ${duplicateSyncIds.length}')
      ..writeln('Missing hashes: $totalMissingHashes')
      ..writeln('Future-date tx: ${futureDateIds.length}')
      ..writeln('Amount anomalies: ${amountAnomalies.length}')
      ..writeln(
        'Idempotency keys: '
        '${idempotencyStats.activeKeys} active / '
        '${idempotencyStats.expiredKeys} expired',
      );
    for (final b in balances) {
      buf.writeln(
        '  [${b.accountName}] income=${b.totalIncome}, '
        'expense=${b.totalExpense}, net=${b.netBalance}, '
        'tx=${b.txCount}',
      );
    }
    return buf.toString();
  }
}
