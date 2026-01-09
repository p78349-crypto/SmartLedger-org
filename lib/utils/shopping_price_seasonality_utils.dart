import '../models/transaction.dart';
import 'shopping_prep_utils.dart';

class ShoppingPriceSeasonalityUtils {
  ShoppingPriceSeasonalityUtils._();

  /// Returns a 0-based month index (0=Jan..11=Dec) that appears cheapest
  /// for the given [itemName] within the last 365 days.
  ///
  /// - Uses `unitPrice` only (ignores rows with `unitPrice <= 0`).
  /// - Filters to `expense` + `mainCategory == '식비'`.
  /// - Groups by month-of-year.
  /// - Chooses the month with the lowest median unit price.
  /// - If there isn't enough data, returns null.
  static ShoppingCheapestMonthResult? cheapestMonthLastYear({
    required Iterable<Transaction> transactions,
    required String itemName,
    DateTime? now,
    int minSamplesPerMonth = 2,
    int minTotalSamples = 6,
  }) {
    final now0 = now ?? DateTime.now();
    final start = now0.subtract(const Duration(days: 365));

    final targetKey = ShoppingPrepUtils.normalizeName(itemName);
    if (targetKey.isEmpty) return null;

    final byMonth = <int, List<double>>{};

    for (final t in transactions) {
      if (t.type != TransactionType.expense) continue;
      if (t.mainCategory != '식비') continue;
      if (t.unitPrice <= 0) continue;
      if (t.date.isBefore(start) || t.date.isAfter(now0)) continue;

      final key = ShoppingPrepUtils.normalizeName(t.description);
      if (key != targetKey) continue;

      final monthIndex = t.date.month - 1;
      (byMonth[monthIndex] ??= <double>[]).add(t.unitPrice);
    }

    final all = byMonth.values.fold<int>(0, (sum, v) => sum + v.length);
    if (all < minTotalSamples) return null;

    final candidates = <ShoppingMonthPriceStat>[];
    for (final entry in byMonth.entries) {
      final prices = List<double>.from(entry.value)..sort();
      if (prices.length < minSamplesPerMonth) continue;
      candidates.add(
        ShoppingMonthPriceStat(
          monthIndex0: entry.key,
          samples: prices.length,
          medianUnitPrice: _medianOfSorted(prices),
          meanUnitPrice: _mean(prices),
          minUnitPrice: prices.first,
        ),
      );
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final byMedian = a.medianUnitPrice.compareTo(b.medianUnitPrice);
      if (byMedian != 0) return byMedian;
      final bySamples = b.samples.compareTo(a.samples);
      if (bySamples != 0) return bySamples;
      return a.monthIndex0.compareTo(b.monthIndex0);
    });

    return ShoppingCheapestMonthResult(
      itemName: itemName,
      normalizedKey: targetKey,
      now: now0,
      best: candidates.first,
      months: candidates,
      totalSamples: all,
    );
  }

  static String monthLabelKo(int monthIndex0) {
    final m = monthIndex0 + 1;
    return '$m월';
  }

  static double _mean(List<double> xs) {
    if (xs.isEmpty) return 0;
    var sum = 0.0;
    for (final x in xs) {
      sum += x;
    }
    return sum / xs.length;
  }

  static double _medianOfSorted(List<double> sorted) {
    if (sorted.isEmpty) return 0;
    final n = sorted.length;
    final mid = n ~/ 2;
    if (n.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }
}

class ShoppingMonthPriceStat {
  final int monthIndex0;
  final int samples;
  final double medianUnitPrice;
  final double meanUnitPrice;
  final double minUnitPrice;

  const ShoppingMonthPriceStat({
    required this.monthIndex0,
    required this.samples,
    required this.medianUnitPrice,
    required this.meanUnitPrice,
    required this.minUnitPrice,
  });
}

class ShoppingCheapestMonthResult {
  final String itemName;
  final String normalizedKey;
  final DateTime now;
  final ShoppingMonthPriceStat best;
  final List<ShoppingMonthPriceStat> months;
  final int totalSamples;

  const ShoppingCheapestMonthResult({
    required this.itemName,
    required this.normalizedKey,
    required this.now,
    required this.best,
    required this.months,
    required this.totalSamples,
  });

  /// One-line hint for UI, e.g. "3월이 가장 저렴(중앙값 2,300원, n=12)".
  String hintKo({String Function(double won)? formatWon}) {
    final fmt = formatWon ?? ((v) => v.round().toString());
    final month = ShoppingPriceSeasonalityUtils.monthLabelKo(best.monthIndex0);
    return '$month이 가장 저렴('
        '중앙값 ${fmt(best.medianUnitPrice)}원, '
        'n=${best.samples})';
  }
}
