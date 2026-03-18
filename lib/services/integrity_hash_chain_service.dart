import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';

/// SHA-256 해시 체인 기반 트랜잭션 무결성 검증 서비스.
///
/// 모든 거래 레코드는 이전 해시(prevHash)를 포함한 SHA-256 체인으로
/// 연결되어, 단 하나의 레코드라도 변조되면 체인이 즉시 끊어짐.
class IntegrityHashChainService {
  IntegrityHashChainService._();
  static final instance = IntegrityHashChainService._();

  AppDatabase get _db => DatabaseProvider.instance.database;

  // ─── 해시 생성 ──────────────────────────────────────

  /// 단일 트랜잭션의 payload 해시를 계산한다.
  /// [prevHash]가 null이면 체인의 첫 번째 블록(genesis)으로 간주.
  Future<String> computeHash({
    required String transactionId,
    required int accountId,
    required String type,
    required double amount,
    required DateTime date,
    required String description,
    String? prevHash,
  }) async {
    final payload = StringBuffer()
      ..write(prevHash ?? 'GENESIS')
      ..write('|')
      ..write(transactionId)
      ..write('|')
      ..write(accountId)
      ..write('|')
      ..write(type)
      ..write('|')
      ..write(amount.toStringAsFixed(2))
      ..write('|')
      ..write(date.toUtc().toIso8601String())
      ..write('|')
      ..write(description);

    final algo = Sha256();
    final hash = await algo.hash(utf8.encode(payload.toString()));
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // ─── DB 연동: 체인 기록 / 갱신 ────────────────────

  /// 계정의 마지막 해시를 가져온다 (체인 연결점).
  Future<String?> getLastHash(int accountId) async {
    final rows = await _db
        .customSelect(
          'SELECT integrity_hash FROM db_transactions '
          'WHERE account_id = ? AND is_deleted = 0 '
          'ORDER BY date DESC, rowid DESC LIMIT 1',
          variables: [Variable<int>(accountId)],
        )
        .get();
    if (rows.isEmpty) return null;
    return rows.first.read<String?>('integrity_hash');
  }

  /// 새 트랜잭션 삽입 시 호출 — 해시를 계산하여 반환한다.
  /// 호출자가 이 값을 companion의 integrityHash에 넣어줘야 함.
  Future<String> computeNextHash({
    required int accountId,
    required String transactionId,
    required String type,
    required double amount,
    required DateTime date,
    required String description,
  }) async {
    final prevHash = await getLastHash(accountId);
    return await computeHash(
      transactionId: transactionId,
      accountId: accountId,
      type: type,
      amount: amount,
      date: date,
      description: description,
      prevHash: prevHash,
    );
  }

  // ─── 체인 검증 ─────────────────────────────────────

  /// 특정 계정의 전체 해시 체인을 검증한다.
  /// 반환: 분기점이 없으면 null, 있으면 깨진 첫 번째 트랜잭션 ID.
  Future<IntegrityVerifyResult> verifyChain(int accountId) async {
    final rows = await _db
        .customSelect(
          'SELECT id, account_id, type, amount, date, description, '
          'integrity_hash FROM db_transactions '
          'WHERE account_id = ? AND is_deleted = 0 '
          'ORDER BY date ASC, rowid ASC',
          variables: [Variable<int>(accountId)],
        )
        .get();

    if (rows.isEmpty) {
      return IntegrityVerifyResult(
        accountId: accountId,
        totalRows: 0,
        verified: 0,
        broken: 0,
      );
    }

    int verified = 0;
    int broken = 0;
    int skipped = 0;
    String? firstBrokenId;
    String? prevHash;

    for (final row in rows) {
      final storedHash = row.read<String?>('integrity_hash');
      if (storedHash == null || storedHash.isEmpty) {
        // 해시 미등록(레거시 데이터) → 건너뜀
        skipped++;
        continue;
      }

      final expected = await computeHash(
        transactionId: row.read<String>('id'),
        accountId: row.read<int>('account_id'),
        type: row.read<String>('type'),
        amount: row.read<double>('amount'),
        date: DateTime.fromMillisecondsSinceEpoch(row.read<int>('date') * 1000),
        description: row.read<String>('description'),
        prevHash: prevHash,
      );

      if (expected == storedHash) {
        verified++;
        prevHash = storedHash;
      } else {
        broken++;
        firstBrokenId ??= row.read<String>('id');
        // 체인 끊어졌으므로 이후 모든 해시는 불일치 — 계속 세기만 함
        prevHash = storedHash; // stored 기준으로 이어감
      }
    }

    return IntegrityVerifyResult(
      accountId: accountId,
      totalRows: rows.length,
      verified: verified,
      broken: broken,
      skipped: skipped,
      firstBrokenTransactionId: firstBrokenId,
    );
  }

  /// 모든 계정의 체인을 한꺼번에 검증한다.
  Future<List<IntegrityVerifyResult>> verifyAll() async {
    final accounts = await _db.getAllAccounts();
    final results = <IntegrityVerifyResult>[];
    for (final acct in accounts) {
      results.add(await verifyChain(acct.id));
    }
    return results;
  }

  // R4-4: 앱 시작 시 비동기 검증 + 결과 캐싱
  static const String _prefKeyLastVerify = 'integrity_last_verify';

  /// verifyAll()을 실행하고 결과를 SharedPreferences에 JSON 캐싱.
  Future<void> runStartupVerification() async {
    try {
      final results = await verifyAll();
      final prefs = await SharedPreferences.getInstance();
      final payload = {
        'timestamp': DateTime.now().toIso8601String(),
        'accounts': results.map((r) => r.toJson()).toList(),
        'allClean': results.every((r) => r.isClean),
      };
      await prefs.setString(_prefKeyLastVerify, jsonEncode(payload));
    } catch (_) {
      // 검증 실패는 앱 시작을 차단하지 않음
    }
  }

  // ─── 배치 재계산(Rehash) ────────────────────────────

  /// 레거시 데이터(integrityHash == NULL) 전체에 해시를 소급 적용한다.
  /// 이미 해시가 있는 행은 건드리지 않는다.
  Future<int> backfillHashes(int accountId) async {
    final rows = await _db
        .customSelect(
          'SELECT id, account_id, type, amount, date, description, '
          'integrity_hash FROM db_transactions '
          'WHERE account_id = ? AND is_deleted = 0 '
          'ORDER BY date ASC, rowid ASC',
          variables: [Variable<int>(accountId)],
        )
        .get();

    int updated = 0;
    String? prevHash;

    for (final row in rows) {
      final existing = row.read<String?>('integrity_hash');
      if (existing != null && existing.isNotEmpty) {
        prevHash = existing;
        continue;
      }

      final hash = await computeHash(
        transactionId: row.read<String>('id'),
        accountId: row.read<int>('account_id'),
        type: row.read<String>('type'),
        amount: row.read<double>('amount'),
        date: DateTime.fromMillisecondsSinceEpoch(row.read<int>('date') * 1000),
        description: row.read<String>('description'),
        prevHash: prevHash,
      );

      await _db.customUpdate(
        'UPDATE db_transactions SET integrity_hash = ? WHERE id = ?',
        variables: [Variable<String>(hash), Variable<String>(row.read('id'))],
        updates: {_db.dbTransactions},
      );

      prevHash = hash;
      updated++;
    }

    return updated;
  }
}

/// 해시 체인 검증 결과
class IntegrityVerifyResult {
  final int accountId;
  final int totalRows;
  final int verified;
  final int broken;
  final int skipped;
  final String? firstBrokenTransactionId;

  const IntegrityVerifyResult({
    required this.accountId,
    required this.totalRows,
    required this.verified,
    required this.broken,
    this.skipped = 0,
    this.firstBrokenTransactionId,
  });

  bool get isClean => broken == 0;
  double get integrityRate =>
      totalRows == 0 ? 1.0 : verified / (verified + broken);

  Map<String, dynamic> toJson() => {
    'accountId': accountId,
    'totalRows': totalRows,
    'verified': verified,
    'broken': broken,
    'skipped': skipped,
    'isClean': isClean,
    'integrityRate': '${(integrityRate * 100).toStringAsFixed(2)}%',
    'firstBrokenTransactionId': firstBrokenTransactionId,
  };

  @override
  String toString() =>
      'IntegrityVerifyResult(account=$accountId, '
      'total=$totalRows, ok=$verified, broken=$broken, '
      'skipped=$skipped, clean=$isClean)';
}
