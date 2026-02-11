import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fixed_cost.dart';
import '../models/transaction.dart';
import '../services/fixed_cost_service.dart';
import '../services/monthly_agg_cache_service.dart';
import '../services/quick_simple_expense_input_history_service.dart';
import '../services/smart_consuming_service.dart';
import '../services/store_alias_service.dart';
import '../services/transaction_service.dart';
import '../utils/chart_utils.dart' hide ChartPoint;
import '../utils/date_formatter.dart';
import '../utils/localization.dart';
import '../utils/number_formats.dart';
import '../utils/product_name_utils.dart';
import '../utils/store_memo_utils.dart';
import 'account_stats_models.dart';
import 'account_stats_summary_widgets.dart';
import 'account_stats_utils.dart';
import 'transaction_add_screen.dart';

part '_account_stats_charts.dart';
part '_account_stats_init.dart';
part '_account_stats_action_dialog.dart';
part '_account_stats_refund_dialog.dart';
part '_account_stats_summary.dart';
part '_account_stats_monthly_view.dart';
part '_account_stats_store_products.dart';
part '_account_stats_weekly.dart';
part '_account_stats_multi_month.dart';
part '_account_stats_year_view.dart';
part '_account_stats_decade_chart.dart';
part '_account_stats_type_detail.dart';
part '_account_stats_type_detail_list.dart';
part '_account_stats_fixed_cost_nav.dart';

class AccountStatsScreen extends StatefulWidget {
  final String accountName;
  final bool embed;
  final String? initialView;
  final String? initialRangeView;
  const AccountStatsScreen({
    super.key,
    required this.accountName,
    this.embed = false,
    this.initialView,
    this.initialRangeView,
  });

  @override
  State<AccountStatsScreen> createState() => _AccountStatsScreenState();
}

class _AccountStatsScreenState extends State<AccountStatsScreen> {
  final NumberFormat _currencyFormat = NumberFormats.currency;
  final NumberFormat _compactNumberFormat = NumberFormat.compact(locale: 'ko');
  final DateFormat _dateFormat = DateFormatter.defaultDate;
  final DateFormat _monthLabelFormat = DateFormatter.monthLabel;
  final DateFormat _rangeMonthFormat = DateFormatter.rangeMonth;
  final DateFormat _shortMonthFormat = DateFormatter.shortMonth;
  final DateFormat _dayLabelFormat = DateFormatter.monthDay;

  StatsView _selectedView = StatsView.month;
  ChartDisplayType _chartDisplay = ChartDisplayType.bar;
  static const List<TransactionType> _typeOrder = <TransactionType>[
    TransactionType.expense,
    TransactionType.income,
    TransactionType.savings,
  ];
  final int _typeIndex = 0;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _currentYear = DateTime.now().year;
  DateTime _chartAnchorMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  bool _isInitializing = true;
  List<FixedCost> _fixedCosts = const [];
  final bool _includeFixedCosts = true;
  bool _showEmptyYears = false;
  DateTime? _selectedDate;

  MonthlyAggCache? _monthlyAggCache;
  List<QuickSimpleExpenseInputEntry> _quickEntries =
      const <QuickSimpleExpenseInputEntry>[];
  Map<String, String> _storeAliasMap = const <String, String>{};
  String? _defaultStore;

  @override
  void initState() {
    super.initState();
    if (widget.initialView != null) {
      _selectedView = _parseRangeOrChartView(widget.initialView!);
    } else if (widget.initialRangeView != null) {
      _selectedView = _parseRangeOrChartView(widget.initialRangeView!);
    }
    _initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  StatsView _parseRangeOrChartView(String key) {
    switch (key) {
      case 'month':
        return StatsView.month;
      case 'quarter':
        return StatsView.quarter;
      case 'halfYear':
        return StatsView.halfYear;
      case 'year':
        return StatsView.year;
      case 'decade':
        return StatsView.decade;
      case 'chart':
        return StatsView.chart;
      default:
        return StatsView.month;
    }
  }

  TransactionType get _currentType => _typeOrder[_typeIndex];

  String _typeLabel([TransactionType? type]) =>
      (type ?? _currentType).label;

  Color _typeColor(ThemeData theme) =>
      statsColorForType(_currentType, theme);

  Color _typeColorFor(TransactionType type, ThemeData theme) =>
      statsColorForType(type, theme);

  Color _colorForTransaction(TransactionType type, ThemeData theme) =>
      statsColorForType(type, theme);

  SavingsAllocation _allocationFor(Transaction tx) =>
      tx.savingsAllocation ?? SavingsAllocation.assetIncrease;

  bool _isSavingsCountedAsExpense(Transaction tx) =>
      tx.type == TransactionType.savings &&
      _allocationFor(tx) == SavingsAllocation.expense;

  bool _shouldAggregateForType(Transaction tx, TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return tx.type == TransactionType.expense ||
            _isSavingsCountedAsExpense(tx);
      case TransactionType.income:
        return tx.type == TransactionType.income ||
            tx.type == TransactionType.refund;
      case TransactionType.refund:
        return tx.type == TransactionType.refund;
      case TransactionType.savings:
        return tx.type == TransactionType.savings &&
            !_isSavingsCountedAsExpense(tx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isInitializing) {
      const loader = Center(child: CircularProgressIndicator());
      if (widget.embed) return loader;
      return Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
        body: loader,
      );
    }
    final service = TransactionService();
    final transactions = service.getTransactions(widget.accountName);
    final contentBody = _buildView(transactions, theme);
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [contentBody],
      ),
    );
    if (widget.embed) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: content,
      );
    }
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
        body: content,
      ),
    );
  }

  Widget _buildView(List<Transaction> transactions, ThemeData theme) {
    switch (_selectedView) {
      case StatsView.month:
        return _buildMonthlyView(transactions, theme);
      case StatsView.quarter:
        return _buildMultiMonthView(transactions, theme, 3);
      case StatsView.halfYear:
        return _buildMultiMonthView(transactions, theme, 6);
      case StatsView.year:
        return _buildYearView(transactions, theme);
      case StatsView.decade:
        return _buildDecadeView(transactions, theme);
      case StatsView.chart:
        return _buildChartView(transactions, theme);
      case StatsView.expenseDetail:
        return _buildTypeDetailView(
          transactions, theme, TransactionType.expense);
      case StatsView.incomeDetail:
        return _buildTypeDetailView(
          transactions, theme, TransactionType.income);
      case StatsView.savingsDetail:
        return _buildTypeDetailView(
          transactions, theme, TransactionType.savings);
    }
  }

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
      case TransactionType.refund:
        return Icons.trending_up;
      case TransactionType.savings:
        return Icons.savings;
      case TransactionType.expense:
        return Icons.trending_down;
    }
  }
}
