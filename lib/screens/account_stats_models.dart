import '../models/transaction.dart';

/// 통계 화면 뷰 모드.
enum StatsView {
  month,
  quarter,
  halfYear,
  year,
  decade,
  chart,
  expenseDetail,
  incomeDetail,
  savingsDetail,
}

/// 월별 요약 데이터.
class MonthlySummary {
  const MonthlySummary({
    required this.month,
    required this.total,
    required this.count,
  });

  final DateTime month;
  final double total;
  final int count;
}

/// 연도별 요약 데이터.
class YearSummary {
  const YearSummary({
    required this.year,
    required this.total,
    required this.count,
  });

  final int year;
  final double total;
  final int count;
}

/// 차트용 데이터 포인트.
class ChartPoint {
  const ChartPoint({required this.month, required this.total});

  final DateTime month;
  final double total;
}

/// 요약 합계 (수입/지출/저축/고정비/순수익).
class SummaryTotals {
  const SummaryTotals({
    required this.income,
    required this.expense,
    required this.savings,
    required this.fixedCost,
    required this.expenseDisplay,
    required this.net,
    required this.expenseTitle,
    required this.fixedCostTitle,
  });

  final double income;
  final double expense;
  final double savings;
  final double fixedCost;
  final double expenseDisplay;
  final double net;
  final String expenseTitle;
  final String fixedCostTitle;
}

/// 매장/상품 누적기.
class StoreProductAcc {
  String name;
  int count = 0;
  double total = 0;

  StoreProductAcc({required this.name});
}

/// 매장/상품 통계.
class StoreProductStat {
  final String name;
  final int count;
  final double total;

  const StoreProductStat({
    required this.name,
    required this.count,
    required this.total,
  });
}

/// 검색 결과 항목.
class StatsSearchResult {
  const StatsSearchResult({
    required this.accountName,
    required this.transaction,
  });

  final String accountName;
  final Transaction transaction;
}
