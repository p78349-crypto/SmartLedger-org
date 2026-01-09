import '../models/transaction.dart';
import 'shopping_prep_utils.dart';

class ShoppingRepurchaseLearningUtils {
  ShoppingRepurchaseLearningUtils._();

  /// Returns learned min-days-between-purchases per normalized item name.
  ///
  /// Uses recent purchase gaps (in days) and takes the median to reduce noise.
  /// Clamps the learned value to [minClampDays, maxClampDays].
  static Map<String, int> learnMinDaysByNameKey(
    List<Transaction> groceryExpenseTransactions, {
    int minSamples = 2,
    int maxDatesPerItem = 5,
    int minClampDays = 2,
    int maxClampDays = 45,
  }) {
    final datesByKey = <String, List<DateTime>>{};

    for (final t in groceryExpenseTransactions) {
      final name = t.description.trim();
      final key = ShoppingPrepUtils.normalizeName(name);
      if (key.isEmpty) continue;

      final list = datesByKey.putIfAbsent(key, () => <DateTime>[]);
      if (list.length >= maxDatesPerItem) continue;
      list.add(t.date);
    }

    final out = <String, int>{};

    for (final e in datesByKey.entries) {
      final dates = e.value;
      if (dates.length < minSamples) continue;

      dates.sort((a, b) => b.compareTo(a));

      final gaps = <int>[];
      for (var i = 0; i < dates.length - 1; i++) {
        final a = dates[i];
        final b = dates[i + 1];
        final gap = a.difference(b).inDays;
        if (gap > 0) gaps.add(gap);
      }

      if (gaps.isEmpty) continue;
      gaps.sort();
      final median = gaps[gaps.length ~/ 2];

      var learned = median;
      if (learned < minClampDays) learned = minClampDays;
      if (learned > maxClampDays) learned = maxClampDays;

      out[e.key] = learned;
    }

    return out;
  }
}
