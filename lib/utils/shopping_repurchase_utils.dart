import 'shopping_prep_utils.dart';
import 'shopping_repurchase_rules.dart';

class ShoppingRepurchaseUtils {
  ShoppingRepurchaseUtils._();

  static int minDaysFor({
    required String name,
    Map<String, int>? learnedMinDaysByKey,
  }) {
    final raw = name.trim();
    if (raw.isEmpty) return ShoppingRepurchaseRules.defaultMinDays;
    final key = ShoppingPrepUtils.normalizeName(raw);
    final learned = learnedMinDaysByKey?[key];
    if (learned != null && learned > 0) return learned;
    return minDaysForName(raw);
  }

  static int minDaysForName(String name) {
    final raw = name.trim();
    if (raw.isEmpty) return ShoppingRepurchaseRules.defaultMinDays;

    final normalized = ShoppingPrepUtils.normalizeName(raw);

    for (final e in ShoppingRepurchaseRules.keywordToMinDays.entries) {
      final key = ShoppingPrepUtils.normalizeName(e.key);
      if (key.isEmpty) continue;
      if (normalized.contains(key)) {
        return e.value;
      }
    }

    return ShoppingRepurchaseRules.defaultMinDays;
  }

  static bool isDue({
    required DateTime lastPurchasedAt,
    required String name,
    Map<String, int>? learnedMinDaysByKey,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final minDays = minDaysFor(
      name: name,
      learnedMinDaysByKey: learnedMinDaysByKey,
    );
    final daysSince = ref.difference(lastPurchasedAt).inDays;
    return daysSince >= minDays;
  }
}
