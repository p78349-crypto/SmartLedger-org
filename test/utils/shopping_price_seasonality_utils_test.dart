import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/shopping_price_seasonality_utils.dart';

void main() {
  group('ShoppingPriceSeasonalityUtils', () {
    Transaction tx({
      required String id,
      required DateTime date,
      required String description,
      required double unitPrice,
      String mainCategory = '식비',
    }) {
      return Transaction(
        id: id,
        type: TransactionType.expense,
        description: description,
        amount: -1000,
        date: date,
        unitPrice: unitPrice,
        mainCategory: mainCategory,
      );
    }

    test('monthLabelKo formats correctly', () {
      expect(ShoppingPriceSeasonalityUtils.monthLabelKo(0), '1월');
      expect(ShoppingPriceSeasonalityUtils.monthLabelKo(11), '12월');
    });

    test('cheapestMonthLastYear returns null when insufficient data', () {
      final now = DateTime(2026, 1, 15);
      final result = ShoppingPriceSeasonalityUtils.cheapestMonthLastYear(
        transactions: [
          tx(id: '1', date: DateTime(2026, 1, 1), description: '사과', unitPrice: 1000),
        ],
        itemName: '사과',
        now: now,
      );
      expect(result, isNull);
    });

    test('cheapestMonthLastYear chooses month with lowest median', () {
      final now = DateTime(2026, 12, 31);

      // Ensure >= 6 samples total and >=2 per candidate month.
      final transactions = <Transaction>[
        // March (median 900)
        tx(id: 'm1', date: DateTime(2026, 3, 1), description: '사과', unitPrice: 800),
        tx(id: 'm2', date: DateTime(2026, 3, 2), description: '사과', unitPrice: 1000),
        // May (median 1200)
        tx(id: 'y1', date: DateTime(2026, 5, 1), description: '사과', unitPrice: 1100),
        tx(id: 'y2', date: DateTime(2026, 5, 2), description: '사과', unitPrice: 1300),
        // November (median 1500)
        tx(id: 'n1', date: DateTime(2026, 11, 1), description: '사과', unitPrice: 1400),
        tx(id: 'n2', date: DateTime(2026, 11, 2), description: '사과', unitPrice: 1600),
        // Noise: other item / wrong category
        tx(id: 'o1', date: DateTime(2026, 3, 3), description: '바나나', unitPrice: 100),
        tx(
          id: 'o2',
          date: DateTime(2026, 3, 4),
          description: '사과',
          unitPrice: 1,
          mainCategory: '식품·음료비',
        ),
      ];

      final result = ShoppingPriceSeasonalityUtils.cheapestMonthLastYear(
        transactions: transactions,
        itemName: '사과',
        now: now,
      );

      expect(result, isNotNull);
      expect(result!.best.monthIndex0, 2); // March
      expect(result.best.samples, greaterThanOrEqualTo(2));

      final hint = result.hintKo(formatWon: (won) => won.round().toString());
      expect(hint, contains('3월'));
      expect(hint, contains('중앙값'));
      expect(hint, contains('n='));
    });
  });
}
