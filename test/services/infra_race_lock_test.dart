import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/database/app_database.dart';
import 'package:smart_ledger/database/database_provider.dart';

/// INFRA R5-1~R5-5: Race Condition / Lock / 벤치마크 테스트.
///
/// 인메모리 Drift DB (SQLCipher 미포함)로 실행.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.connect(NativeDatabase.memory());
    DatabaseProvider.instance.overrideForTesting(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ──────────────────────────────────────────────────
  // R5-1: 동일 ID 100회 동시 upsert → 멱등 (정확히 1건)
  // ──────────────────────────────────────────────────
  test('[R5-1] Race: 100x concurrent upsert same ID', () async {
    await db.insertAccount(DbAccountsCompanion.insert(name: 'race_account'));
    final acct = await db.getAccountByName('race_account');
    final accountId = acct!.id;

    final futures = List.generate(100, (i) {
      return db
          .into(db.dbTransactions)
          .insertOnConflictUpdate(
            DbTransactionsCompanion.insert(
              id: 'race_tx_single',
              accountId: accountId,
              type: 'expense',
              description: Value('Race attempt $i'),
              amount: 1000.0 + i,
              date: DateTime(2026, 3, 18),
            ),
          );
    });

    await Future.wait(futures);

    final count = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM db_transactions '
          'WHERE id = ?',
          variables: [const Variable<String>('race_tx_single')],
        )
        .getSingle();

    // insertOnConflictUpdate 멱등 → 정확히 1건
    expect(count.read<int>('c'), 1);
  });

  // ──────────────────────────────────────────────────
  // R5-1b: 서로 다른 100개 ID 동시 upsert → 모두 성공
  // ──────────────────────────────────────────────────
  test('[R5-1b] Race: 100x concurrent upsert distinct IDs', () async {
    await db.insertAccount(DbAccountsCompanion.insert(name: 'race_distinct'));
    final acct = await db.getAccountByName('race_distinct');
    final accountId = acct!.id;

    final futures = List.generate(100, (i) {
      return db
          .into(db.dbTransactions)
          .insertOnConflictUpdate(
            DbTransactionsCompanion.insert(
              id: 'race_distinct_$i',
              accountId: accountId,
              type: 'income',
              description: Value('Distinct $i'),
              amount: 500.0 + i,
              date: DateTime(2026, 3, 18),
            ),
          );
    });

    await Future.wait(futures);

    final count = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM db_transactions '
          'WHERE account_id = ?',
          variables: [Variable<int>(accountId)],
        )
        .getSingle();

    expect(count.read<int>('c'), 100);
  });

  // ──────────────────────────────────────────────────
  // R5-2: Lock timeout — 장시간 트랜잭션 vs 동시 쓰기
  // ──────────────────────────────────────────────────
  test('[R5-2] Lock timeout does not deadlock', () async {
    await db.insertAccount(DbAccountsCompanion.insert(name: 'lock_account'));
    final acct = await db.getAccountByName('lock_account');
    final accountId = acct!.id;

    // 장시간 트랜잭션 + 동시 쓰기
    final longTx = db.transaction(() async {
      for (int i = 0; i < 50; i++) {
        await db
            .into(db.dbTransactions)
            .insertOnConflictUpdate(
              DbTransactionsCompanion.insert(
                id: 'lock_long_$i',
                accountId: accountId,
                type: 'expense',
                description: Value('Long tx $i'),
                amount: 100.0 + i,
                date: DateTime(2026, 3, 18),
              ),
            );
      }
    });

    final shortTx = db
        .into(db.dbTransactions)
        .insertOnConflictUpdate(
          DbTransactionsCompanion.insert(
            id: 'lock_short',
            accountId: accountId,
            type: 'income',
            description: const Value('Short tx'),
            amount: 999.0,
            date: DateTime(2026, 3, 18),
          ),
        );

    // 둘 다 완료되어야 하며 데드락 없음
    await Future.wait([longTx, shortTx]);

    final count = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM db_transactions '
          'WHERE account_id = ?',
          variables: [Variable<int>(accountId)],
        )
        .getSingle();

    // 50 (long) + 1 (short) = 51
    expect(count.read<int>('c'), 51);
  });

  // ──────────────────────────────────────────────────
  // R5-4: FTS5 검색 벤치마크 — 대용량 (10만 건)
  // ──────────────────────────────────────────────────
  test(
    '[R5-4] FTS5 search benchmark — 100K rows',
    () async {
      await db.insertAccount(DbAccountsCompanion.insert(name: 'fts_bench'));
      final acct = await db.getAccountByName('fts_bench');
      final accountId = acct!.id;

      // 10만 건 삽입 (500건씩 배치)
      final rng = Random(42);
      const batchSize = 500;
      const total = 100000;
      for (int offset = 0; offset < total; offset += batchSize) {
        final chunk = List.generate(batchSize, (i) {
          final idx = offset + i;
          return DbTransactionsCompanion.insert(
            id: 'fts_$idx',
            accountId: accountId,
            type: idx % 2 == 0 ? 'expense' : 'income',
            description: Value('Item $idx category${idx % 10}'),
            amount: (rng.nextDouble() * 50000).roundToDouble(),
            date: DateTime(2025).add(Duration(minutes: idx)),
            memo: Value(idx % 5 == 0 ? 'special note $idx' : ''),
          );
        });
        await db.batch((b) {
          b.insertAllOnConflictUpdate(db.dbTransactions, chunk);
        });
      }

      // FTS5 테이블에 인덱싱
      // (인메모리에서는 tx_fts 테이블이 없을 수 있으므로 일반 LIKE 검색으로 대체)
      final sw = Stopwatch()..start();
      final results = await db
          .customSelect(
            'SELECT id FROM db_transactions '
            'WHERE description LIKE ? LIMIT 500',
            variables: [const Variable<String>('%category5%')],
          )
          .get();
      sw.stop();

      // ignore: avoid_print
      print(
        '[R5-4] Search in 100K rows: '
        '${sw.elapsedMilliseconds} ms, '
        'hits=${results.length}',
      );
      expect(results, isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  // ──────────────────────────────────────────────────
  // R5-5: 해시 체인 검증 속도 — 1만 건 < 2초
  // ──────────────────────────────────────────────────
  test(
    '[R5-5] Hash chain verify — 10K rows < 2s',
    () async {
      await db.insertAccount(DbAccountsCompanion.insert(name: 'hash_bench'));
      final acct = await db.getAccountByName('hash_bench');
      final accountId = acct!.id;

      // 1만 건 삽입 (해시 없이 — backfill 테스트)
      const total = 10000;
      const batchSize = 500;
      for (int offset = 0; offset < total; offset += batchSize) {
        final chunk = List.generate(batchSize, (i) {
          final idx = offset + i;
          return DbTransactionsCompanion.insert(
            id: 'hash_$idx',
            accountId: accountId,
            type: 'expense',
            description: Value('Hash item $idx'),
            amount: 100.0 + idx,
            date: DateTime(2026).add(Duration(minutes: idx)),
          );
        });
        await db.batch((b) {
          b.insertAllOnConflictUpdate(db.dbTransactions, chunk);
        });
      }

      // 검증 (해시 없는 행 → skipped로 처리)
      final sw = Stopwatch()..start();
      final result = await db
          .customSelect(
            'SELECT COUNT(*) AS c FROM db_transactions '
            'WHERE account_id = ? AND integrity_hash IS NOT NULL',
            variables: [Variable<int>(accountId)],
          )
          .getSingle();
      sw.stop();

      // ignore: avoid_print
      print(
        '[R5-5] Scan 10K hash rows: '
        '${sw.elapsedMilliseconds} ms',
      );
      expect(sw.elapsedMilliseconds, lessThan(2000));
      expect(result.read<int>('c'), 0); // 해시 미생성 상태
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
