import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'icon_catalog.dart';

/// 통계 화면 뷰 타입
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
  refundDetail,
}

/// 통계 화면 상태 관리 유틸리티
class StatsViewUtils {
  StatsViewUtils._();

  /// 그래프/뷰 메타데이터 (아이콘/라벨/ID)
  static const Map<StatsView, StatsViewMeta> _meta = {
    StatsView.month: StatsViewMeta(
      id: 'stats_month',
      label: 'Month',
      icon: IconCatalog.calendarToday,
    ),
    StatsView.quarter: StatsViewMeta(
      id: 'stats_quarter',
      label: 'Quarter',
      icon: IconCatalog.timeline,
    ),
    StatsView.halfYear: StatsViewMeta(
      id: 'stats_half_year',
      label: 'Half-year',
      icon: IconCatalog.calendarViewMonth,
    ),
    StatsView.year: StatsViewMeta(
      id: 'stats_year',
      label: 'Year',
      icon: IconCatalog.dateRange,
    ),
    StatsView.decade: StatsViewMeta(
      id: 'stats_decade',
      label: 'Decade',
      icon: IconCatalog.autoGraph,
    ),
    StatsView.chart: StatsViewMeta(
      id: 'stats_chart',
      label: 'Chart',
      icon: IconCatalog.showChart,
    ),
    StatsView.expenseDetail: StatsViewMeta(
      id: 'stats_expense_detail',
      label: 'Expense detail',
      icon: IconCatalog.receiptLong,
    ),
    StatsView.incomeDetail: StatsViewMeta(
      id: 'stats_income_detail',
      label: 'Income detail',
      icon: IconCatalog.receiptLongOutlined,
    ),
    StatsView.savingsDetail: StatsViewMeta(
      id: 'stats_savings_detail',
      label: 'Savings detail',
      icon: IconCatalog.savingsOutlined,
    ),
    StatsView.refundDetail: StatsViewMeta(
      id: 'stats_refund_detail',
      label: 'Refund detail',
      icon: IconCatalog.refund,
    ),
  };

  /// 뷰가 상세 뷰인지 확인
  static bool isDetailView(String view) {
    return view.contains('Detail');
  }

  /// 뷰가 차트 뷰인지 확인
  static bool isChartView(String view) {
    return view == 'chart';
  }

  /// 뷰가 범위 뷰인지 확인
  static bool isRangeView(String view) {
    return ['month', 'quarter', 'halfYear', 'year', 'decade'].contains(view);
  }

  /// 다음 뷰로 전환
  static String toggleView(String currentView, String targetView) {
    return currentView == targetView ? 'month' : targetView;
  }

  /// 트랜잭션 타입에 따른 상세 뷰 반환
  static StatsView detailViewForTransaction(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return StatsView.expenseDetail;
      case TransactionType.income:
        return StatsView.incomeDetail;
      case TransactionType.savings:
        return StatsView.savingsDetail;
      case TransactionType.refund:
        return StatsView.refundDetail;
    }
  }

  /// 메타 조회: 아이콘/라벨/ID를 한 곳에서 사용
  static StatsViewMeta meta(StatsView view) => _meta[view]!;

  /// 등록된 모든 뷰 메타 리스트
  static List<StatsViewMeta> allMetas() => StatsView.values
      .where((v) => _meta.containsKey(v))
      .map((v) => _meta[v]!)
      .toList(growable: false);

  // ---- Range presets (chips: 1/3/6/12 months + 10 years) ----
  static const List<StatsRangePreset> rangePresets = [
    StatsRangePreset(id: 'range_1m', label: '1m', icon: IconCatalog.looksOne),
    StatsRangePreset(id: 'range_3m', label: '3m', icon: IconCatalog.looks3),
    StatsRangePreset(id: 'range_6m', label: '6m', icon: IconCatalog.looks6),
    StatsRangePreset(
      id: 'range_12m',
      label: '12m',
      icon: IconCatalog.calendarViewMonth,
    ),
    StatsRangePreset(
      id: 'range_10y',
      label: '10y',
      icon: IconCatalog.autoGraph,
    ),
  ];

  // ---- Quick toggles (chips: transactions, decade view, fixed cost) ----
  static const List<StatsQuickToggle> quickToggles = [
    StatsQuickToggle(
      id: 'toggle_transactions',
      label: 'Transactions',
      icon: IconCatalog.receiptLong,
    ),
    StatsQuickToggle(
      id: 'toggle_decade',
      label: 'Decade',
      icon: IconCatalog.autoGraph,
    ),
    StatsQuickToggle(
      id: 'toggle_fixed_cost',
      label: 'Fixed cost',
      icon: IconCatalog.receiptLongOutlined,
    ),
  ];

  // ---- Category analysis chips (expense / income / savings) ----
  static const List<CategoryFilterChip> categoryFilters = [
    CategoryFilterChip(
      id: 'category_expense',
      label: 'Expense',
      icon: IconCatalog.trendingDown,
    ),
    CategoryFilterChip(
      id: 'category_income',
      label: 'Income',
      icon: IconCatalog.trendingUp,
    ),
    CategoryFilterChip(
      id: 'category_savings',
      label: 'Savings',
      icon: IconCatalog.savings,
    ),
  ];

  // ---- Decade analysis filters
  // (Year / Quarter / Category 10y trend / Monthly avg) ----
  static const List<DecadeAnalysisFilter> decadeAnalysisFilters = [
    DecadeAnalysisFilter(
      id: 'decade_year_compare',
      label: 'Year compare',
      icon: IconCatalog.compareArrows,
    ),
    DecadeAnalysisFilter(
      id: 'decade_quarter_trend',
      label: 'Quarter trend',
      icon: IconCatalog.trendingUp,
    ),
    DecadeAnalysisFilter(
      id: 'decade_category_10y',
      label: 'Category 10y',
      icon: IconCatalog.categoryOutlined,
    ),
    DecadeAnalysisFilter(
      id: 'decade_monthly_avg',
      label: 'Monthly avg',
      icon: IconCatalog.moving,
    ),
  ];

  // ---- Chart extension options
  // (Fullscreen / Export / Detail / Comparison / Zoom) ----
  static const List<ChartExtensionOption> chartExtensionOptions = [
    ChartExtensionOption(
      id: 'chart_fullscreen',
      label: 'Fullscreen',
      icon: IconCatalog.fullscreen,
    ),
    ChartExtensionOption(
      id: 'chart_export',
      label: 'Export',
      icon: IconCatalog.download,
    ),
    ChartExtensionOption(
      id: 'chart_detail',
      label: 'Detail',
      icon: IconCatalog.tune,
    ),
    ChartExtensionOption(
      id: 'chart_comparison',
      label: 'Comparison',
      icon: IconCatalog.compareArrows,
    ),
    ChartExtensionOption(
      id: 'chart_zoom',
      label: 'Zoom',
      icon: IconCatalog.zoomIn,
    ),
    ChartExtensionOption(
      id: 'chart_refresh',
      label: 'Refresh',
      icon: IconCatalog.refresh,
    ),
  ];
}

/// 카테고리 분석 토글(지출/수입/예금) 메타 정보
class CategoryFilterChip {
  final String id;
  final String label;
  final IconData icon;

  const CategoryFilterChip({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// 연대통계 분석 필터 메타 정보 (연도비교/분기추세/카테고리10년/월평균)
class DecadeAnalysisFilter {
  final String id;
  final String label;
  final IconData icon;

  const DecadeAnalysisFilter({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// 차트 확장 옵션 메타 정보 (전체화면/내보내기/상세/비교/확대)
class ChartExtensionOption {
  final String id;
  final String label;
  final IconData icon;

  const ChartExtensionOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// 그래프/뷰 메타 정보
class StatsViewMeta {
  final String id;
  final String label;
  final IconData icon;

  const StatsViewMeta({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// 범위 프리셋 메타 정보
class StatsRangePreset {
  final String id;
  final String label;
  final IconData icon;

  const StatsRangePreset({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// 빠른 토글 메타 정보 (거래/10년/고정비 등)
class StatsQuickToggle {
  final String id;
  final String label;
  final IconData icon;

  const StatsQuickToggle({
    required this.id,
    required this.label,
    required this.icon,
  });
}
