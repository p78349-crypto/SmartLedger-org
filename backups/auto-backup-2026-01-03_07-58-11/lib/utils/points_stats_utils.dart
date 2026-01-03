import 'package:flutter/foundation.dart';

import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/benefit_aggregation_utils.dart';
import 'package:smart_ledger/utils/benefit_memo_utils.dart';

/// Utilities for "points/discount saved" motivation stats.
///
/// Goal: aggregate "saved money" driven by benefits/points without hardcoding
/// UI colors or requiring per-screen custom logic.
@immutable
class PointsStatsUtils {
  const PointsStatsUtils._();

  static const String catCard = '카드';
  static const String catMart = '마트';
  static const String catOnline = '온라인 쇼핑';
  static const String catConvenience = '편의점';
  static const String catOther = '기타';

  static const List<String> categories = <String>[
    catCard,
    catMart,
    catOnline,
    catConvenience,
    catOther,
  ];

  /// Normalizes a raw benefit key to one of the 5 display categories.
  static String normalizeCategoryKey(String rawKey) {
    final key = rawKey.trim();
    if (key.isEmpty) return catOther;

    final lowered = key.toLowerCase();

    // Korean keywords.
    if (lowered.contains('카드')) return catCard;
    if (lowered.contains('마트')) return catMart;
    if (lowered.contains('편의점')) return catConvenience;
    if (lowered.contains('온라인') || lowered.contains('쇼핑')) return catOnline;

    return catOther;
  }

  /// Extracts per-category "saved amount" from a single transaction.
  ///
  /// Priority (no double counting), aligned with [BenefitAggregationUtils]:
  /// 1) cardChargedAmount => treat as 카드 discount
  /// 2) benefitJson       => sum by benefit keys
  /// 3) memo "혜택:"      => sum by benefit keys
  ///
  /// Additionally, manual "saved points" records (#포인트모으기) are counted
  /// as 기타 unless they include structured benefit info.
  static Map<String, double> savedByCategory(Transaction t) {
    // Manual points records: treat as saved money (assetIncrease).
    if (BenefitAggregationUtils.isSavedPointsRecord(t)) {
      final structured = t.benefitByType;
      if (structured.isNotEmpty) {
        return _bucketize(structured);
      }

      final memoMap = BenefitMemoUtils.parseBenefitByType(t.memo);
      if (memoMap.isNotEmpty) {
        return _bucketize(memoMap);
      }

      final amount = t.amount;
      if (amount <= 0) return const <String, double>{};
      return <String, double>{catOther: amount};
    }

    if (t.type != TransactionType.expense) return const <String, double>{};
    if (t.isRefund) return const <String, double>{};

    final charged = t.cardChargedAmount;
    if (charged != null && charged > 0) {
      final diff = t.amount - charged;
      if (diff > 0) {
        return <String, double>{catCard: diff};
      }
      return const <String, double>{};
    }

    final structured = t.benefitByType;
    if (structured.isNotEmpty) {
      return _bucketize(structured);
    }

    final memoMap = BenefitMemoUtils.parseBenefitByType(t.memo);
    if (memoMap.isNotEmpty) {
      return _bucketize(memoMap);
    }

    return const <String, double>{};
  }

  static Map<String, double> _bucketize(Map<String, double> raw) {
    final out = <String, double>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v.isNaN || v.isInfinite || v <= 0) continue;
      final cat = normalizeCategoryKey(e.key);
      out[cat] = (out[cat] ?? 0) + v;
    }

    // Ensure stable keys for UI ordering if needed.
    for (final c in categories) {
      out[c] = out[c] ?? 0;
    }

    return out;
  }

  /// Aggregates saved amounts by category within a date range.
  ///
  /// Both endpoints are inclusive.
  static Map<String, double> sumByCategory(
    Iterable<Transaction> transactions, {
    required DateTime start,
    required DateTime end,
  }) {
    final totals = <String, double>{for (final c in categories) c: 0};

    for (final t in transactions) {
      if (t.date.isBefore(start)) continue;
      if (t.date.isAfter(end)) continue;

      final bucket = savedByCategory(t);
      if (bucket.isEmpty) continue;

      for (final e in bucket.entries) {
        totals[e.key] = (totals[e.key] ?? 0) + e.value;
      }
    }

    return totals;
  }

  static double sumTotal(Map<String, double> byCategory) =>
      byCategory.values.fold<double>(0, (s, v) => s + v);

  /// Computes category ratios from a lookback window.
  /// Returns empty map when total is 0.
  static Map<String, double> ratios(Map<String, double> byCategory) {
    final total = sumTotal(byCategory);
    if (total <= 0) return const <String, double>{};

    final out = <String, double>{};
    for (final c in categories) {
      final v = byCategory[c] ?? 0;
      out[c] = (v <= 0) ? 0 : (v / total);
    }
    return out;
  }

  /// Projects totals into the future assuming the same average daily saved
  /// amount continues.
  static Map<String, double> projectByCategory(
    Map<String, double> recentByCategory, {
    required int lookbackDays,
    required int horizonDays,
  }) {
    if (lookbackDays <= 0 || horizonDays <= 0) {
      return <String, double>{for (final c in categories) c: 0};
    }

    final dailyTotal = sumTotal(recentByCategory) / lookbackDays;
    if (dailyTotal <= 0) {
      return <String, double>{for (final c in categories) c: 0};
    }

    final r = ratios(recentByCategory);
    if (r.isEmpty) {
      return <String, double>{for (final c in categories) c: 0};
    }

    final projectedTotal = dailyTotal * horizonDays;
    final out = <String, double>{};
    for (final c in categories) {
      out[c] = projectedTotal * (r[c] ?? 0);
    }
    return out;
  }
}

