import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/database/app_database.dart';
import 'package:smart_ledger/database/database_provider.dart';
import 'package:smart_ledger/services/idempotency_service.dart';
import 'package:smart_ledger/services/integrity_hash_chain_service.dart';
import 'package:smart_ledger/services/batch_integrity_verifier.dart';

/// 1000 TPS 부하 시뮬레이션 — SQLCipher 없는 인메모리 DB로 측정.
///
/// 목적: Drift batch insert 성능, 해시 체인 오버헤드,
///       멱등성 키 처리량, 배치 검증 쿼리 속도를 벤치마크.
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
  // 벤치마크 1: Raw batch insert throughput
  // ──────────────────────────────────────────────────
  test('[TPS-1] Batch insert 1000 rows — raw throughput', () async {
    // 계정 생성
    await db.insertAccount(DbAccountsCompanion.insert(name: 'bench_account'));
    final acct = await db.getAccountByName('bench_account');
    final accountId = acct!.id;

    final rng = Random(42);
    final companions = List.generate(1000, (i) {
      return DbTransactionsCompanion.insert(
        id: 'tx_batch_$i',
        accountId: accountId,
        type: i.isEven ? 'expense' : 'income',
        description: Value('Bench item $i'),
        amount: (rng.nextDouble() * 100000).roundToDouble(),
        date: DateTime(2026).add(Duration(minutes: i)),
      );
    });

    final sw = Stopwatch()..start();
    await db.batch((b) {
      b.insertAllOnConflictUpdate(db.dbTransactions, companions);
    });
    sw.stop();

    final tps = (1000 / (sw.elapsedMilliseconds / 1000)).round();
    // ignore: avoid_print
    print(
      '[TPS-1] 1000 rows batch insert: '
      '${sw.elapsedMilliseconds} ms → $tps TPS',
    );

    // 검증: 1000건 존재
    final count = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM db_transactions '
          'WHERE account_id = ?',
          variables: [Variable<int>(accountId)],
        )
        .getSingle();
    expect(count.read<int>('c'), 1000);
  });

  // ──────────────────────────────────────────────────
  // 벤치마크 2: 개별 upsert (worst-case)
  // ──────────────────────────────────────────────────
  test('[TPS-2] Individual upsert 500 rows — worst case', () async {
    await db.insertAccount(
      DbAccountsCompanion.insert(name: 'bench_individual'),
    );
    final acct = await db.getAccountByName('bench_individual');
    final accountId = acct!.id;

    final rng = Random(7);
    final sw = Stopwatch()..start();

    for (int i = 0; i < 500; i++) {
      final companion = DbTransactionsCompanion.insert(
        id: 'tx_ind_$i',
        accountId: accountId,
        type: 'expense',
        description: Value('Individual $i'),
        amount: (rng.nextDouble() * 50000).roundToDouble(),
        date: DateTime(2026, 2).add(Duration(minutes: i)),
      );
      await db.into(db.dbTransactions).insertOnConflictUpdate(companion);
    }

    sw.stop();
    final tps = (500 / (sw.elapsedMilliseconds / 1000)).round();
    // ignore: avoid_print
    print(
      '[TPS-2] 500 individual upserts: '
      '${sw.elapsedMilliseconds} ms → $tps TPS',
    );
  });

  // ──────────────────────────────────────────────────
  // 벤치마크 3: 해시 체인 계산 오버헤드
  // ──────────────────────────────────────────────────
  test('[TPS-3] Hash chain compute — 1000 hashes', () async {
    final svc = IntegrityHashChainService.instance;
    String? prev;

    final sw = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      prev = await svc.computeHash(
        transactionId: 'tx_hash_$i',
        accountId: 1,
        type: 'expense',
        amount: 12345.67,
        date: DateTime(2026, 3),
        description: 'Hash bench $i',
        prevHash: prev,
      );
    }
    sw.stop();

    final hps = (1000 / (sw.elapsedMilliseconds / 1000)).round();
    // ignore: avoid_print
    print(
      '[TPS-3] 1000 SHA-256 chain hashes: '
      '${sw.elapsedMilliseconds} ms → $hps H/s',
    );
    expect(prev, isNotNull);
    expect(prev!.length, 64); // SHA-256 hex
  });

  // ──────────────────────────────────────────────────
  // 벤치마크 4: 멱등성 키 처리량
  // ──────────────────────────────────────────────────
  test('[TPS-4] Idempotency key record + lookup — 1000 ops', () async {
    final svc = IdempotencyService.instance;

    final sw = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      await svc.record('op_$i', result: 'ok_$i');
    }
    sw.stop();

    final writeTps = (1000 / (sw.elapsedMilliseconds / 1000)).round();
    // ignore: avoid_print
    print(
      '[TPS-4a] 1000 idempotency key writes: '
      '${sw.elapsedMilliseconds} ms → $writeTps TPS',
    );

    // 읽기 벤치마크
    final sw2 = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      final r = await svc.tryGet('op_$i');
      expect(r, 'ok_$i');
    }
    sw2.stop();

    final readTps = (1000 / (sw2.elapsedMilliseconds / 1000)).round();
    // ignore: avoid_print
    print(
      '[TPS-4b] 1000 idempotency key reads: '
      '${sw2.elapsedMilliseconds} ms → $readTps TPS',
    );
  });

  // ──────────────────────────────────────────────────
  // 벤치마크 5: 배치 검증 쿼리 (10,000건 이상)
  // ──────────────────────────────────────────────────
  test('[TPS-5] Batch integrity report — 10K rows', () async {
    await db.insertAccount(DbAccountsCompanion.insert(name: 'bench_report'));
    final acct = await db.getAccountByName('bench_report');
    final accountId = acct!.id;

    // 10,000건 삽입
    final rng = Random(99);
    const batchSize = 500;
    for (int offset = 0; offset < 10000; offset += batchSize) {
      final chunk = List.generate(batchSize, (i) {
        final idx = offset + i;
        return DbTransactionsCompanion.insert(
          id: 'tx_rpt_$idx',
          accountId: accountId,
          type: idx % 3 == 0 ? 'income' : 'expense',
          description: Value('Report item $idx'),
          amount: (rng.nextDouble() * 80000).roundToDouble(),
          date: DateTime(2025).add(Duration(minutes: idx)),
        );
      });
      await db.batch((b) {
        b.insertAllOnConflictUpdate(db.dbTransactions, chunk);
      });
    }

    // 정합성 리포트 실행
    final verifier = BatchIntegrityVerifier.instance;
    final sw = Stopwatch()..start();
    final report = await verifier.runFullReport();
    sw.stop();

    // ignore: avoid_print
    print(
      '[TPS-5] Full integrity report on 10K rows: '
      '${sw.elapsedMilliseconds} ms',
    );
    // ignore: avoid_print
    print(
      '  → clean=${report.isClean}, '
      'orphans=${report.orphanRecords.length}, '
      'missing_hashes=${report.totalMissingHashes}',
    );

    expect(report.orphanRecords, isEmpty);
    expect(report.balances.any((b) => b.accountName == 'bench_report'), isTrue);
  });

  // ──────────────────────────────────────────────────
  // 벤치마크 6: 해시 체인 검증 (500건)
  // ──────────────────────────────────────────────────
  test('[TPS-6] Hash chain verify — 500 rows with hashes', () async {
    await db.insertAccount(DbAccountsCompanion.insert(name: 'bench_verify'));
    final acct = await db.getAccountByName('bench_verify');
    final accountId = acct!.id;

    final svc = IntegrityHashChainService.instance;
    String? prevHash;

    // 500건 삽입 + 해시 기록
    for (int i = 0; i < 500; i++) {
      final hash = await svc.computeHash(
        transactionId: 'tx_vfy_$i',
        accountId: accountId,
        type: 'expense',
        amount: 1000.0 + i,
        date: DateTime(2026, 4).add(Duration(minutes: i)),
        description: 'Verify item $i',
        prevHash: prevHash,
      );
      prevHash = hash;

      await db
          .into(db.dbTransactions)
          .insertOnConflictUpdate(
            DbTransactionsCompanion.insert(
              id: 'tx_vfy_$i',
              accountId: accountId,
              type: 'expense',
              description: Value('Verify item $i'),
              amount: 1000.0 + i,
              date: DateTime(2026, 4).add(Duration(minutes: i)),
              integrityHash: Value(hash),
            ),
          );
    }

    // 체인 검증
    final sw = Stopwatch()..start();
    final result = await svc.verifyChain(accountId);
    sw.stop();

    // ignore: avoid_print
    print(
      '[TPS-6] Hash chain verify 500 rows: '
      '${sw.elapsedMilliseconds} ms',
    );
    // ignore: avoid_print
    print(
      '  → verified=${result.verified}, '
      'broken=${result.broken}, '
      'clean=${result.isClean}',
    );

    expect(result.isClean, isTrue);
    expect(result.verified, 500);
  });

  // ──────────────────────────────────────────────────
  // 벤치마크 7: 동시 쓰기 시뮬레이션 (Future.wait)
  // ──────────────────────────────────────────────────
  test('[TPS-7] Concurrent batch writes — 10 × 100 rows', () async {
    await db.insertAccount(
      DbAccountsCompanion.insert(name: 'bench_concurrent'),
    );
    final acct = await db.getAccountByName('bench_concurrent');
    final accountId = acct!.id;

    final rng = Random(77);
    final sw = Stopwatch()..start();

    // 10개 배치를 동시에 실행
    await Future.wait(
      List.generate(10, (batchIdx) async {
        final companions = List.generate(100, (i) {
          final idx = batchIdx * 100 + i;
          return DbTransactionsCompanion.insert(
            id: 'tx_conc_$idx',
            accountId: accountId,
            type: 'expense',
            description: Value('Conc $idx'),
            amount: (rng.nextDouble() * 10000).roundToDouble(),
            date: DateTime(2026, 5).add(Duration(minutes: idx)),
          );
        });
        await db.batch((b) {
          b.insertAllOnConflictUpdate(db.dbTransactions, companions);
        });
      }),
    );

    sw.stop();
    final tps = (1000 / (sw.elapsedMilliseconds / 1000)).round();
    // ignore: avoid_print
    print(
      '[TPS-7] 10 concurrent batches × 100 rows: '
      '${sw.elapsedMilliseconds} ms → $tps TPS',
    );

    final count = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM db_transactions '
          'WHERE account_id = ?',
          variables: [Variable<int>(accountId)],
        )
        .getSingle();
    expect(count.read<int>('c'), 1000);
  });
}
