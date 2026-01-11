import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/market_analysis_utils.dart';

void main() {
  group('MarketAnalysisUtils', () {
    Transaction tx({
      required String id,
      required TransactionType type,
      required DateTime date,
      required String description,
      required double amount,
      required double unitPrice,
      String mainCategory = '식비',
    }) {
      return Transaction(
        id: id,
        type: type,
        description: description,
        amount: amount,
        date: date,
        unitPrice: unitPrice,
        mainCategory: mainCategory,
      );
    }

    test('analyzeItemPrice returns zeros when no matches', () {
      final stats = MarketAnalysisUtils.analyzeItemPrice('사과', const []);
      expect(stats.purchaseCount, 0);
      expect(stats.averagePrice, 0);
      expect(stats.minPrice, 0);
      expect(stats.maxPrice, 0);
      expect(stats.cheapestDate, isNull);
    });

    test('analyzeItemPrice computes min/max/avg and cheapestDate', () {
      final t1 = tx(
        id: '1',
        type: TransactionType.expense,
        date: DateTime(2026, 1, 1),
        description: '사과',
        amount: -3000,
        unitPrice: 1000,
      );
      final t2 = tx(
        id: '2',
        type: TransactionType.expense,
        date: DateTime(2026, 2, 1),
        description: '사과',
        amount: -2400,
        unitPrice: 800,
      );
      final stats = MarketAnalysisUtils.analyzeItemPrice('사과', [t1, t2]);
      expect(stats.purchaseCount, 2);
      expect(stats.minPrice, 800);
      expect(stats.maxPrice, 1000);
      expect(stats.averagePrice, 900);
      expect(stats.cheapestDate, DateTime(2026, 2, 1));
      expect(stats.priceRange, 200);
      expect(stats.volatilityPercent, closeTo((200 / 900) * 100, 0.0001));
    });

    test('getTopPurchasedItems ranks by frequency', () {
      final items = MarketAnalysisUtils.getTopPurchasedItems([
        tx(
          id: '1',
          type: TransactionType.expense,
          date: DateTime(2026, 1, 1),
          description: 'A',
          amount: -1,
          unitPrice: 1,
        ),
        tx(
          id: '2',
          type: TransactionType.expense,
          date: DateTime(2026, 1, 2),
          description: 'A',
          amount: -1,
          unitPrice: 1,
        ),
        tx(
          id: '3',
          type: TransactionType.expense,
          date: DateTime(2026, 1, 3),
          description: 'B',
          amount: -1,
          unitPrice: 1,
        ),
      ]);
      expect(items.first, 'A');
    });

    test('getCategorySpending and getMonthlySpending aggregate amounts', () {
      final txs = [
        tx(
          id: '1',
          type: TransactionType.expense,
          date: DateTime(2026, 1, 10),
          description: 'A',
          amount: -100,
          unitPrice: 1,
          mainCategory: '식비',
        ),
        tx(
          id: '2',
          type: TransactionType.income,
          date: DateTime(2026, 1, 11),
          description: 'Salary',
          amount: 1000,
          unitPrice: 0,
          mainCategory: '수입',
        ),
        tx(
          id: '3',
          type: TransactionType.savings,
          date: DateTime(2026, 2, 1),
          description: 'Save',
          amount: -200,
          unitPrice: 0,
          mainCategory: '저축/투자',
        ),
      ];

      final byCat = MarketAnalysisUtils.getCategorySpending(txs);
      expect(byCat['식비'], -100);
      expect(byCat['수입'], 1000);

      final byMonth = MarketAnalysisUtils.getMonthlySpending(txs);
      // Income is excluded.
      expect(byMonth['2026-01'], -100);
      expect(byMonth['2026-02'], -200);
    });

    test('recommendCheapestMonth picks lowest average month', () {
      final txs = [
        tx(
          id: '1',
          type: TransactionType.expense,
          date: DateTime(2026, 1, 1),
          description: '사과',
          amount: -1,
          unitPrice: 1000,
        ),
        tx(
          id: '2',
          type: TransactionType.expense,
          date: DateTime(2026, 1, 2),
          description: '사과',
          amount: -1,
          unitPrice: 1200,
        ),
        tx(
          id: '3',
          type: TransactionType.expense,
          date: DateTime(2026, 2, 1),
          description: '사과',
          amount: -1,
          unitPrice: 800,
        ),
      ];

      expect(MarketAnalysisUtils.recommendCheapestMonth('사과', txs), '2026-02');
    });

    test('generateAIReport returns friendly text for empty/non-empty', () {
      expect(
        MarketAnalysisUtils.generateAIReport(const []),
        contains('데이터가 쌓이면'),
      );

      final report = MarketAnalysisUtils.generateAIReport([
        tx(
          id: '1',
          type: TransactionType.expense,
          date: DateTime(2026, 1, 1),
          description: '사과',
          amount: -1000,
          unitPrice: 1000,
          mainCategory: '식비',
        ),
        tx(
          id: '2',
          type: TransactionType.expense,
          date: DateTime(2026, 1, 2),
          description: '사과',
          amount: -1000,
          unitPrice: 1000,
          mainCategory: '식비',
        ),
        tx(
          id: '3',
          type: TransactionType.expense,
          date: DateTime(2026, 1, 3),
          description: '우유',
          amount: -500,
          unitPrice: 500,
          mainCategory: '식비',
        ),
      ]);

      expect(report, contains('최근 구매 분석'));
      expect(report, contains('자주 구매한 품목'));
      expect(report, contains('최대 지출 카테고리'));
    });
  });
}
