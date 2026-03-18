import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';

/// 멱등성(Idempotency) 키 서비스.
///
/// 동일한 operationKey로 24시간 내 재요청이 들어오면
/// 실제 처리를 건너뛰고 캐시된 결과를 반환한다.
/// 1000 TPS 환경에서 네트워크 재시도/중복 전송 방지의 핵심.
class IdempotencyService {
  IdempotencyService._();
  static final instance = IdempotencyService._();

  AppDatabase get _db => DatabaseProvider.instance.database;

  static const _defaultTtl = Duration(hours: 24);

  /// 키가 이미 존재하고 만료 전이면 캐시된 result 반환.
  /// 존재하지 않으면 null → 호출자가 실제 처리를 진행해야 함.
  Future<String?> tryGet(String operationKey) async {
    await _purgeExpired();
    final rows = await _db
        .customSelect(
          'SELECT result FROM db_idempotency_keys '
          'WHERE operation_key = ? AND expires_at > ?',
          variables: [
            Variable<String>(operationKey),
            Variable<DateTime>(DateTime.now()),
          ],
        )
        .get();
    if (rows.isEmpty) return null;
    return rows.first.read<String?>('result');
  }

  /// 처리 완료 후 결과를 기록한다. TTL 기본 24시간.
  Future<void> record(
    String operationKey, {
    String? result,
    Duration ttl = _defaultTtl,
  }) async {
    final now = DateTime.now();
    final companion = DbIdempotencyKeysCompanion.insert(
      operationKey: operationKey,
      result: Value(result),
      expiresAt: now.add(ttl),
    );
    await _db.into(_db.dbIdempotencyKeys).insertOnConflictUpdate(companion);
  }

  /// operationKey 존재 여부만 확인 (bool).
  Future<bool> exists(String operationKey) async {
    return (await tryGet(operationKey)) != null ||
        await _existsRaw(operationKey);
  }

  Future<bool> _existsRaw(String operationKey) async {
    final rows = await _db
        .customSelect(
          'SELECT 1 FROM db_idempotency_keys '
          'WHERE operation_key = ? AND expires_at > ?',
          variables: [
            Variable<String>(operationKey),
            Variable<DateTime>(DateTime.now()),
          ],
        )
        .get();
    return rows.isNotEmpty;
  }

  /// [operationKey] 기반 멱등 실행 래퍼.
  ///
  /// ```dart
  /// final result = await IdempotencyService.instance.executeOnce(
  ///   'tx_add_${tx.id}',
  ///   () async {
  ///     await dbStore.upsertTransaction(account, tx);
  ///     return 'ok';
  ///   },
  /// );
  /// ```
  Future<String> executeOnce(
    String operationKey,
    Future<String> Function() action, {
    Duration ttl = _defaultTtl,
  }) async {
    final cached = await tryGet(operationKey);
    if (cached != null) return cached;

    final result = await action();
    await record(operationKey, result: result, ttl: ttl);
    return result;
  }

  /// 만료된 키를 제거한다. 자동 호출됨.
  Future<int> _purgeExpired() async {
    return await _db.customUpdate(
      'DELETE FROM db_idempotency_keys WHERE expires_at <= ?',
      variables: [Variable<DateTime>(DateTime.now())],
      updates: {_db.dbIdempotencyKeys},
    );
  }

  /// 수동 퍼지 (관리/디버깅 용).
  Future<int> purgeExpired() => _purgeExpired();

  /// 전체 키 카운트 (모니터링).
  Future<int> activeKeyCount() async {
    final rows = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM db_idempotency_keys '
          'WHERE expires_at > ?',
          variables: [Variable<DateTime>(DateTime.now())],
        )
        .get();
    return rows.first.read<int>('c');
  }
}
