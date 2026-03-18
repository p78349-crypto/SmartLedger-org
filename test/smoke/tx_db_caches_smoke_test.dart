import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/database/app_database.dart';
import 'package:smart_ledger/database/database_provider.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/monthly_agg_cache_service.dart';
import 'package:smart_ledger/services/transaction_benefit_monthly_agg_service.dart';
import 'package:smart_ledger/services/transaction_fts_index_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final testDb = AppDatabase.connect(NativeDatabase.memory());

  setUp(() {
    DatabaseProvider.instance.overrideForTesting(testDb);
    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefKeys.txStorageBackendV1: 'db',
    });
    TransactionService().resetForTesting();
  });

  testWidgets('SMOKE(DB-CACHES): FTS + benefit agg + monthly cache build', (
    tester,
  ) async {
    final service = TransactionService()..resetForTesting();
    await service.loadTransactions();

    final accountName = 'cache_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    final tx = Transaction(
      id: 'c1',
      type: TransactionType.expense,
      description: 'milk',
      amount: 2600,
      date: now,
      unitPrice: 1300,
      quantity: 2,
      paymentMethod: '카드',
      benefitJson: '{"카드":100}',
    );

    await service.addTransaction(accountName, tx);

    // 1) FTS incremental upsert should make the transaction searchable.
    await TransactionFtsIndexService().ensureIndexedFromPrefs();
    final hits = await TransactionFtsIndexService().search(
      accountName: accountName,
      query: 'milk',
      limit: 20,
    );
    expect(hits.any((h) => h.transactionId == 'c1'), isTrue);

    // 2) Benefit monthly aggregation should include the benefitJson amount.
    await TransactionBenefitMonthlyAggService().ensureAggregatedFromPrefs();
    final ym = MonthlyAggCacheService.yearMonthOf(now);
    final benefitTotal = await TransactionBenefitMonthlyAggService().sumTotal(
      accountName: accountName,
      startYm: ym,
      endYm: ym,
    );
    expect(benefitTotal, greaterThanOrEqualTo(100));

    // 3) Monthly agg cache should build and contain this month's expense agg.
    final cache = await MonthlyAggCacheService().ensureBuilt(
      accountName: accountName,
      transactions: service.getTransactions(accountName),
    );
    expect(cache.months.containsKey(ym), isTrue);
    final bucket = cache.months[ym]!;
    expect(bucket.expenseAggAmount, 2600);
    expect(bucket.expenseAggCount, 1);
  });

  testWidgets(
    'SMOKE(DB-CACHES): precision stable after add/update/delete cycle',
    (tester) async {
      final service = TransactionService()..resetForTesting();
      await service.loadTransactions();

      final accountName = 'precision_${DateTime.now().microsecondsSinceEpoch}';
      final now = DateTime.now();
      final ym = MonthlyAggCacheService.yearMonthOf(now);

      final tx = Transaction(
        id: 'p1',
        type: TransactionType.expense,
        description: 'precision-case',
        amount: 0.1,
        date: now,
        paymentMethod: '카드',
        benefitJson: '{"카드":0.1}',
      );

      await service.addTransaction(accountName, tx);

      var cache = await MonthlyAggCacheService().ensureBuilt(
        accountName: accountName,
        transactions: service.getTransactions(accountName),
      );
      expect(cache.months[ym]?.expenseAggAmount ?? 0.0, 0.1);

      var benefitTotal = await TransactionBenefitMonthlyAggService().sumTotal(
        accountName: accountName,
        startYm: ym,
        endYm: ym,
      );
      expect(benefitTotal, 0.1);

      final updated = tx.copyWith(amount: 0.2, benefitJson: '{"카드":0.2}');
      final updatedOk = await service.updateTransaction(accountName, updated);
      expect(updatedOk, isTrue);

      cache = await MonthlyAggCacheService().ensureBuilt(
        accountName: accountName,
        transactions: service.getTransactions(accountName),
      );
      expect(cache.months[ym]?.expenseAggAmount ?? 0.0, 0.2);

      benefitTotal = await TransactionBenefitMonthlyAggService().sumTotal(
        accountName: accountName,
        startYm: ym,
        endYm: ym,
      );
      expect(benefitTotal, 0.2);

      await service.deleteTransaction(
        accountName,
        updated.id,
        moveToTrash: false,
      );

      cache = await MonthlyAggCacheService().ensureBuilt(
        accountName: accountName,
        transactions: service.getTransactions(accountName),
      );
      expect(cache.months[ym]?.expenseAggAmount ?? 0.0, 0.0);

      benefitTotal = await TransactionBenefitMonthlyAggService().sumTotal(
        accountName: accountName,
        startYm: ym,
        endYm: ym,
      );
      expect(benefitTotal, 0.0);
    },
  );
}
