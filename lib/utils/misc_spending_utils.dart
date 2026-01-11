import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'category_icon_map.dart';

/// Misc spending analysis utilities.
/// - Based on a lookback period (months), aggregates per category.
/// - Flags categories considered '잡다한 지출' using simple heuristics
///   (low average per transaction OR high frequency of small transactions).
/// - Computes monthly total and projects to 12 months (연 환산) for awareness.

class MiscCategoryStat {
  final String mainCategory;
  final String subCategory;
  final int count;
  final double totalAmount; // absolute value (positive)
  final double avgPerTx;
  final double monthlyAmount; // per lookback month
  final double annualProjection; // monthlyAmount * 12

  MiscCategoryStat({
    required this.mainCategory,
    required this.subCategory,
    required this.count,
    required this.totalAmount,
    required this.avgPerTx,
    required this.monthlyAmount,
    required this.annualProjection,
  });

  IconData get icon => CategoryIcon.getIcon(mainCategory);
}

class MiscSpendingUtils {
  /// Identify misc categories from [txs].
  /// [lookbackMonths] default 1: compute stats for last N months (from now).
  /// Heuristics:
  /// - avgPerTx < 10000 KRW OR
  /// - count >= 5 (many small transactions)
  /// These can be tuned later.
  static List<MiscCategoryStat> analyze(
    List<Transaction> txs, {
    int lookbackMonths = 1,
    DateTime? anchor,
  }) {
    final now = anchor ?? DateTime.now();
    final start = DateTime(now.year, now.month - (lookbackMonths - 1));

    // Filter expense txs in range
    final filtered = txs.where((t) {
      if (t.type != TransactionType.expense) return false;
      final d = t.date;
      final day = DateTime(d.year, d.month, d.day);
      return !day.isBefore(start) && !day.isAfter(now);
    }).toList();

    final Map<String, List<Transaction>> groups = {};
    for (final t in filtered) {
      final main = t.mainCategory.isEmpty
          ? Transaction.defaultMainCategory
          : t.mainCategory;
      final sub = t.subCategory ?? '';
      final key = sub.isEmpty ? main : '$main·$sub';
      groups.putIfAbsent(key, () => []).add(t);
    }

    final List<MiscCategoryStat> results = [];
    for (final entry in groups.entries) {
      final key = entry.key;
      final parts = key.split('·');
      final main = parts[0];
      final sub = parts.length > 1 ? parts[1] : '';
      final list = entry.value;
      final count = list.length;
      final total = list.fold<double>(0, (s, e) => s + e.amount.abs());
      final avg = count > 0 ? total / count : 0.0;

      // heuristic: misc if avg < 10000 or count >=5
      final bool isMisc = (avg < 10000) || (count >= 5);
      if (!isMisc) continue;

      final monthly = total / (lookbackMonths > 0 ? lookbackMonths : 1);
      final annualProj = monthly * 12;

      results.add(
        MiscCategoryStat(
          mainCategory: main,
          subCategory: sub,
          count: count,
          totalAmount: total,
          avgPerTx: avg,
          monthlyAmount: monthly,
          annualProjection: annualProj,
        ),
      );
    }

    // sort by monthlyAmount desc
    results.sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));
    return results;
  }
}
