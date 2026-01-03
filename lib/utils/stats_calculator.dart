/// 통계 계산 공통 유틸리티
///
/// AccountStatsScreen에서 추출한 통계 계산 로직
library;

import 'package:smart_ledger/models/transaction.dart';

/// 월별 집계 결과
class MonthlyStats {
  final DateTime month;
  final double total;
  final int count;
  final List<Transaction> transactions;

  const MonthlyStats({
    required this.month,
    required this.total,
    required this.count,
    required this.transactions,
  });
}

/// 카테고리별 집계 결과
class CategoryStats {
  final String category;
  final double total;
  final int count;
  final double percentage;
  final List<Transaction> transactions;

  const CategoryStats({
    required this.category,
    required this.total,
    required this.count,
    required this.percentage,
    required this.transactions,
  });
}

/// 일별 집계 결과
class DailyStats {
  final DateTime date;
  final double total;
  final List<Transaction> transactions;

  const DailyStats({
    required this.date,
    required this.total,
    required this.transactions,
  });
}

/// 통계 계산 헬퍼 클래스
class StatsCalculator {
  /// 특정 타입의 거래만 필터링
  static List<Transaction> filterByType(
    List<Transaction> transactions,
    TransactionType type,
  ) {
    return transactions.where((tx) => tx.type == type).toList();
  }

  /// 특정 월의 거래만 필터링
  static List<Transaction> filterByMonth(
    List<Transaction> transactions,
    DateTime month,
  ) {
    return transactions.where((tx) {
      return tx.date.year == month.year && tx.date.month == month.month;
    }).toList();
  }

  /// 특정 카테고리의 거래만 필터링
  static List<Transaction> filterByCategory(
    List<Transaction> transactions,
    String category,
    TransactionType type,
  ) {
    return transactions.where((tx) {
      if (tx.type != type) return false;
      final txCategory = tx.mainCategory.isEmpty
          ? Transaction.defaultMainCategory
          : tx.mainCategory;
      return txCategory == category;
    }).toList();
  }

  /// 거래 리스트의 총합 계산
  static double calculateTotal(List<Transaction> transactions) {
    return transactions.fold<double>(0, (sum, tx) => sum + tx.amount);
  }

  /// 월별로 그룹화하여 집계
  static List<MonthlyStats> calculateMonthlyStats(
    List<Transaction> transactions,
    TransactionType type,
  ) {
    final filtered = filterByType(transactions, type);
    final grouped = <DateTime, List<Transaction>>{};

    for (final tx in filtered) {
      final month = DateTime(tx.date.year, tx.date.month);
      grouped.putIfAbsent(month, () => []).add(tx);
    }

    final stats = grouped.entries.map((entry) {
      final total = calculateTotal(entry.value);
      return MonthlyStats(
        month: entry.key,
        total: total,
        count: entry.value.length,
        transactions: entry.value,
      );
    }).toList();

    // 월 순서대로 정렬
    stats.sort((a, b) => a.month.compareTo(b.month));
    return stats;
  }

  /// 카테고리별로 그룹화하여 집계
  static List<CategoryStats> calculateCategoryStats(
    List<Transaction> transactions,
    TransactionType type,
  ) {
    final filtered = filterByType(transactions, type);
    final grouped = <String, List<Transaction>>{};

    for (final tx in filtered) {
      final category = tx.mainCategory.isEmpty
          ? Transaction.defaultMainCategory
          : tx.mainCategory;
      grouped.putIfAbsent(category, () => []).add(tx);
    }

    final totalAmount = calculateTotal(filtered);
    final stats = grouped.entries.map((entry) {
      final categoryTotal = calculateTotal(entry.value);
      final percentage = totalAmount > 0
          ? (categoryTotal / totalAmount * 100)
          : 0.0;
      return CategoryStats(
        category: entry.key,
        total: categoryTotal,
        count: entry.value.length,
        percentage: percentage,
        transactions: entry.value,
      );
    }).toList();

    // 금액 내림차순 정렬
    stats.sort((a, b) => b.total.compareTo(a.total));
    return stats;
  }

  /// 소분류 카테고리별로 그룹화하여 집계
  static List<CategoryStats> calculateSubCategoryStats(
    List<Transaction> transactions,
    TransactionType type,
  ) {
    final filtered = filterByType(transactions, type);
    final grouped = <String, List<Transaction>>{};

    for (final tx in filtered) {
      final category = (tx.subCategory == null || tx.subCategory!.trim().isEmpty)
          ? Transaction.defaultMainCategory
          : tx.subCategory!;
      grouped.putIfAbsent(category, () => []).add(tx);
    }

    final totalAmount = calculateTotal(filtered);
    final stats = grouped.entries.map((entry) {
      final categoryTotal = calculateTotal(entry.value);
      final percentage = totalAmount > 0 ? (categoryTotal / totalAmount * 100) : 0.0;
      return CategoryStats(
        category: entry.key,
        total: categoryTotal,
        count: entry.value.length,
        percentage: percentage,
        transactions: entry.value,
      );
    }).toList();

    // 금액 내림차순 정렬
    stats.sort((a, b) => b.total.compareTo(a.total));
    return stats;
  }

  /// 일별로 그룹화하여 집계
  static List<DailyStats> calculateDailyStats(
    List<Transaction> transactions,
    TransactionType type,
    DateTime month,
  ) {
    final filtered = filterByType(transactions, type).where((tx) {
      return tx.date.year == month.year && tx.date.month == month.month;
    }).toList();

    final grouped = <DateTime, List<Transaction>>{};

    for (final tx in filtered) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(date, () => []).add(tx);
    }

    final stats = grouped.entries.map((entry) {
      return DailyStats(
        date: entry.key,
        total: calculateTotal(entry.value),
        transactions: entry.value,
      );
    }).toList();

    // 날짜 순서대로 정렬
    stats.sort((a, b) => a.date.compareTo(b.date));
    return stats;
  }

  /// 카테고리 목록 추출
  static List<String> extractCategories(
    List<Transaction> transactions,
    TransactionType type,
  ) {
    final categories = <String>{};
    for (final tx in filterByType(transactions, type)) {
      final category = tx.mainCategory.isEmpty
          ? Transaction.defaultMainCategory
          : tx.mainCategory;
      categories.add(category);
    }
    return categories.toList()..sort();
  }

  /// 지정된 개월 수의 거래 필터링
  static List<Transaction> filterByMonths(
    List<Transaction> transactions,
    DateTime anchor,
    int months,
  ) {
    final start = DateTime(anchor.year, anchor.month - months + 1);
    final end = DateTime(anchor.year, anchor.month + 1, 0); // 해당 월 마지막 날

    return transactions.where((tx) {
      return tx.date.isAfter(start.subtract(const Duration(days: 1))) &&
          tx.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
}
