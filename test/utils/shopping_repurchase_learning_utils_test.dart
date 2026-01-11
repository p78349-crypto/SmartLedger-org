import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/shopping_repurchase_learning_utils.dart';

void main() {
  group('ShoppingRepurchaseLearningUtils', () {
    Transaction tx(String desc, DateTime date) => Transaction(
          id: 't_${desc}_${date.millisecondsSinceEpoch}',
          type: TransactionType.expense,
          description: desc,
          amount: 1000,
          date: date,
          mainCategory: Transaction.defaultMainCategory,
        );

    test('learnMinDaysByNameKey uses median of recent gaps and normalizes keys', () {
      final now = DateTime(2026, 1, 10);
      final list = [
        tx(' Apple ', now),
        tx('apple', now.subtract(const Duration(days: 3))),
        tx('APPLE', now.subtract(const Duration(days: 10))),
      ];

      final learned = ShoppingRepurchaseLearningUtils.learnMinDaysByNameKey(list);
      // gaps: 3 and 7 -> sorted [3,7] -> median index 1 => 7
      expect(learned['apple'], 7);
    });

    test('learnMinDaysByNameKey clamps learned values', () {
      final now = DateTime(2026, 1, 10);
      final list = [
        tx('milk', now),
        tx('milk', now.subtract(const Duration(days: 1))),
      ];

      final learned = ShoppingRepurchaseLearningUtils.learnMinDaysByNameKey(
        list,
        minClampDays: 2,
        maxClampDays: 45,
      );
      expect(learned['milk'], 2);

      final far = [
        tx('rice', now),
        tx('rice', now.subtract(const Duration(days: 200))),
      ];
      final learned2 = ShoppingRepurchaseLearningUtils.learnMinDaysByNameKey(
        far,
        minClampDays: 2,
        maxClampDays: 45,
      );
      expect(learned2['rice'], 45);
    });

    test('learnMinDaysByNameKey ignores items with insufficient samples', () {
      final learned = ShoppingRepurchaseLearningUtils.learnMinDaysByNameKey([
        tx('only-once', DateTime(2026, 1, 1)),
      ]);
      expect(learned, isEmpty);
    });
  });
}
