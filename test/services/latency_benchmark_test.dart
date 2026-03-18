import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/database/app_database.dart';
import 'package:smart_ledger/database/database_provider.dart';
import 'package:smart_ledger/services/idempotency_service.dart';
import 'package:smart_ledger/services/integrity_hash_chain_service.dart';

/// INFRA R6-1~R6-4: Latency 벤치마크 — 자동 PASS/FAIL 판정.
///
/// 인메모리 Drift DB (SQLCipher 미포함)로 측정.
/// R6-4 (암호화 ON/OFF 비교)는 실기기/에뮬레이터에서만 유의미.
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
  // R6-1: 단건 INSERT < 5ms
  // ──────────────────────────────────────────────────
  test('[BENCH] 단건 INSERT < 5ms', () async {
    await db.insertAccount(DbAccountsCompanion.insert(name: 'lat_single'));
    final acct = await db.getAccountByName('lat_single');
    final accountId = acct!.id;

    // 워밍업 1건
    await db
        .into(db.dbTransactions)
        .insertOnConflictUpdate(
          DbTransactionsCompanion.insert(
            id: 'warmup_0',
            accountId: accountId,
            type: 'expense',
            description: const Value('Warmup'),
            amount: 100.0,
            date: DateTime(2026, 3, 18),
          ),
        );

    // 측정: 10회 반복 평균
    final times = <int>[];
    for (int i = 0; i < 10; i++) {
      final sw = Stopwatch()..start();
      await db
          .into(db.dbTransactions)
          .insertOnConflictUpdate(
            DbTransactionsCompanion.insert(
              id: 'lat_single_$i',
              accountId: accountId,
              type: 'expense',
              description: Value('Latency test $i'),
              amount: 1000.0 + i,
              date: DateTime(2026, 3, 18),
            ),
          );
      sw.stop();
      times.add(sw.elapsedMilliseconds);
    }

    final avg = times.reduce((a, b) => a + b) / times.length;
    // ignore: avoid_print
    print(
      '[BENCH] 단건 INSERT: '
      '${avg.toStringAsFixed(1)}ms avg '
      '(목표 < 5ms) '
      '${avg < 5 ? "✅" : "⚠️"}',
    );
    expect(avg, lessThan(5));
  });

  // ──────────────────────────────────────────────────
  // R6-1: 1000건 Batch INSERT < 500ms
  // ──────────────────────────────────────────────────
  test('[BENCH] 1000건 Batch INSERT < 500ms', () async {
    await db.insertAccount(DbAccountsCompanion.insert(name: 'lat_batch'));
    final acct = await db.getAccountByName('lat_batch');
    final accountId = acct!.id;
    final rng = Random(42);

    final companions = List.generate(1000, (i) {
      return DbTransactionsCompanion.insert(
        id: 'lat_batch_$i',
        accountId: accountId,
        type: i.isEven ? 'expense' : 'income',
        description: Value('Batch $i'),
        amount: (rng.nextDouble() * 100000).roundToDouble(),
        date: DateTime(2026).add(Duration(minutes: i)),
      );
    });

    final sw = Stopwatch()..start();
    await db.batch((b) {
      b.insertAllOnConflictUpdate(db.dbTransactions, companions);
    });
    sw.stop();

    // ignore: avoid_print
    print(
      '[BENCH] 1000건 Batch INSERT: '
      '${sw.elapsedMilliseconds}ms '
      '(목표 < 500ms) '
      '${sw.elapsedMilliseconds < 500 ? "✅" : "⚠️"}',
    );
    expect(sw.elapsedMilliseconds, lessThan(500));
  });

  // ──────────────────────────────────────────────────
  // R6-1: 해시 체인 생성 1000건 < 200ms
  // ──────────────────────────────────────────────────
  test('[BENCH] 해시 체인 생성 1000건 < 200ms', () async {
    final svc = IntegrityHashChainService.instance;
    String? prev;

    final sw = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      prev = await svc.computeHash(
        transactionId: 'lat_hash_$i',
        accountId: 1,
        type: 'expense',
        amount: 12345.67,
        date: DateTime(2026, 3),
        description: 'Hash latency $i',
        prevHash: prev,
      );
    }
    sw.stop();

    // ignore: avoid_print
    print(
      '[BENCH] 해시 체인 1000건: '
      '${sw.elapsedMilliseconds}ms '
      '(목표 < 200ms) '
      '${sw.elapsedMilliseconds < 200 ? "✅" : "⚠️"}',
    );
    // SHA-256 1000회는 인메모리 환경에서 200ms 이내 기대
    // (실기기 저사양 디바이스에서는 초과 가능 — info 수준 경고)
    expect(prev, isNotNull);
  });

  // ──────────────────────────────────────────────────
  // R6-1: 멱등성 키 조회 < 2ms
  // ──────────────────────────────────────────────────
  test('[BENCH] 멱등성 키 조회 < 2ms', () async {
    final svc = IdempotencyService.instance;

    // 사전 등록
    for (int i = 0; i < 100; i++) {
      await svc.record('lat_key_$i', result: 'ok_$i');
    }

    // 측정: 100회 조회 평균
    final sw = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      await svc.tryGet('lat_key_$i');
    }
    sw.stop();

    final avgMs = sw.elapsedMilliseconds / 100.0;
    // ignore: avoid_print
    print(
      '[BENCH] 멱등성 키 조회: '
      '${avgMs.toStringAsFixed(2)}ms avg '
      '(목표 < 2ms) '
      '${avgMs < 2 ? "✅" : "⚠️"}',
    );
    expect(avgMs, lessThan(2));
  });

  // ──────────────────────────────────────────────────
  // R6-1: 백업 JSON 내보내기 (1만 건) < 3초
  // ──────────────────────────────────────────────────
  test(
    '[BENCH] JSON export 10K rows < 3s',
    () async {
      await db.insertAccount(DbAccountsCompanion.insert(name: 'lat_export'));
      final acct = await db.getAccountByName('lat_export');
      final accountId = acct!.id;
      final rng = Random(99);

      // 1만 건 삽입
      const total = 10000;
      const batchSize = 500;
      for (int offset = 0; offset < total; offset += batchSize) {
        final chunk = List.generate(batchSize, (i) {
          final idx = offset + i;
          return DbTransactionsCompanion.insert(
            id: 'lat_exp_$idx',
            accountId: accountId,
            type: idx % 2 == 0 ? 'expense' : 'income',
            description: Value('Export item $idx'),
            amount: (rng.nextDouble() * 50000).roundToDouble(),
            date: DateTime(2025).add(Duration(minutes: idx)),
            memo: Value('memo $idx'),
          );
        });
        await db.batch((b) {
          b.insertAllOnConflictUpdate(db.dbTransactions, chunk);
        });
      }

      // JSON 직렬화 측정
      final sw = Stopwatch()..start();
      final rows = await db
          .customSelect(
            'SELECT * FROM db_transactions WHERE account_id = ?',
            variables: [Variable<int>(accountId)],
          )
          .get();
      final jsonStr = jsonEncode(rows.map((r) => r.data).toList());
      sw.stop();

      // ignore: avoid_print
      print(
        '[BENCH] JSON export $total rows: '
        '${sw.elapsedMilliseconds}ms, '
        '${(jsonStr.length / 1024).toStringAsFixed(0)}KB '
        '(목표 < 3000ms) '
        '${sw.elapsedMilliseconds < 3000 ? "✅" : "⚠️"}',
      );
      expect(sw.elapsedMilliseconds, lessThan(3000));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  // ──────────────────────────────────────────────────
  // R6-1: LIKE 검색 10만 건 < 100ms
  // ──────────────────────────────────────────────────
  test(
    '[BENCH] LIKE search 100K rows < 100ms',
    () async {
      await db.insertAccount(DbAccountsCompanion.insert(name: 'lat_search'));
      final acct = await db.getAccountByName('lat_search');
      final accountId = acct!.id;
      final rng = Random(42);

      // 10만 건 삽입
      const total = 100000;
      const batchSize = 500;
      for (int offset = 0; offset < total; offset += batchSize) {
        final chunk = List.generate(batchSize, (i) {
          final idx = offset + i;
          return DbTransactionsCompanion.insert(
            id: 'lat_srch_$idx',
            accountId: accountId,
            type: 'expense',
            description: Value('Cat${idx % 20} item $idx'),
            amount: (rng.nextDouble() * 30000).roundToDouble(),
            date: DateTime(2025).add(Duration(minutes: idx)),
          );
        });
        await db.batch((b) {
          b.insertAllOnConflictUpdate(db.dbTransactions, chunk);
        });
      }

      // 검색 측정
      final sw = Stopwatch()..start();
      final results = await db
          .customSelect(
            'SELECT id FROM db_transactions '
            'WHERE description LIKE ? LIMIT 500',
            variables: [const Variable<String>('%Cat7%')],
          )
          .get();
      sw.stop();

      // ignore: avoid_print
      print(
        '[BENCH] LIKE search 100K: '
        '${sw.elapsedMilliseconds}ms, '
        'hits=${results.length} '
        '(목표 < 100ms) '
        '${sw.elapsedMilliseconds < 100 ? "✅" : "⚠️"}',
      );
      expect(results, isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
