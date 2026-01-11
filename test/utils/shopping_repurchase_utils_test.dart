import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/shopping_repurchase_rules.dart';
import 'package:smart_ledger/utils/shopping_repurchase_utils.dart';

void main() {
  group('ShoppingRepurchaseUtils', () {
    test('minDaysFor returns default for empty name', () {
      expect(
        ShoppingRepurchaseUtils.minDaysFor(name: ''),
        ShoppingRepurchaseRules.defaultMinDays,
      );
    });

    test('minDaysFor prefers learned value when available', () {
      final learned = {'apple': 9};
      expect(
        ShoppingRepurchaseUtils.minDaysFor(name: ' Apple ', learnedMinDaysByKey: learned),
        9,
      );
    });

    test('minDaysForName matches keyword rules (normalized contains)', () {
      // Use the real rules map so the test stays aligned.
      final entry = ShoppingRepurchaseRules.keywordToMinDays.entries.first;
      final keyword = entry.key;
      final expected = entry.value;

      expect(ShoppingRepurchaseUtils.minDaysForName('xx $keyword yy'), expected);
    });

    test('isDue compares day difference against minDays', () {
      final now = DateTime(2026, 1, 10);
      final last = now.subtract(const Duration(days: 10));
      final learned = {'apple': 9};

      expect(
        ShoppingRepurchaseUtils.isDue(
          lastPurchasedAt: last,
          name: 'apple',
          learnedMinDaysByKey: learned,
          now: now,
        ),
        isTrue,
      );

      expect(
        ShoppingRepurchaseUtils.isDue(
          lastPurchasedAt: now.subtract(const Duration(days: 3)),
          name: 'apple',
          learnedMinDaysByKey: learned,
          now: now,
        ),
        isFalse,
      );
    });
  });
}
