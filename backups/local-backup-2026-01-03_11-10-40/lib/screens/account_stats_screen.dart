import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ledger/models/fixed_cost.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/screens/transaction_add_screen.dart';
import 'package:smart_ledger/services/fixed_cost_service.dart';
import 'package:smart_ledger/services/'
    'monthly_agg_cache_service.dart';
import 'package:smart_ledger/services/'
    'quick_simple_expense_input_history_service.dart';
import 'package:smart_ledger/services/store_alias_service.dart';
import 'package:smart_ledger/services/'
    'transaction_benefit_monthly_agg_service.dart';
import 'package:smart_ledger/services/'
    'transaction_fts_index_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/benefit_memo_utils.dart';
import 'package:smart_ledger/utils/chart_utils.dart';
import 'package:smart_ledger/utils/date_formatter.dart';
import 'package:smart_ledger/utils/localization.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/product_name_utils.dart';
import 'package:smart_ledger/utils/store_memo_utils.dart';

enum _StatsView {
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

// Use shared ChartDisplayType from utils/chart_utils.dart

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

  _StatsView _selectedView = _StatsView.month;
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
  DateTime? _selectedDate; // 선택된 날짜 (null이면 전체 월)

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

  _StatsView _parseRangeOrChartView(String key) {
    switch (key) {
      case 'month':
        return _StatsView.month;
      case 'quarter':
        return _StatsView.quarter;
      case 'halfYear':
        return _StatsView.halfYear;
      case 'year':
        return _StatsView.year;
      case 'decade':
        return _StatsView.decade;
      case 'chart':
        return _StatsView.chart;
      default:
        return _StatsView.month;
    }
  }

  Widget _buildChartForDisplay(
    List<_ChartPoint> points,
    ThemeData theme,
    double maxValue,
    TransactionType type,
  ) {
    switch (_chartDisplay) {
      case ChartDisplayType.bar:
        return _buildBarChart(points, theme, maxValue, type);
      case ChartDisplayType.line:
        return _buildLineChart(points, theme, maxValue, type);
      case ChartDisplayType.pie:
        return _buildPieChart(points, theme, type);
      case ChartDisplayType.all:
        return _buildAllCharts(points, theme, maxValue, type);
    }
  }

  Widget _buildAllCharts(
    List<_ChartPoint> points,
    ThemeData theme,
    double maxValue,
    TransactionType type,
  ) {
    return Column(
      children: [
        // 1. 원형 차트
        _buildPieChart(points, theme, type),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        // 2. 막대형 차트
        _buildBarChart(points, theme, maxValue, type),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        // 3. 선형 차트
        _buildLineChart(points, theme, maxValue, type),
      ],
    );
  }

  Widget _buildBarChart(
    List<_ChartPoint> points,
    ThemeData theme,
    double maxValue,
    TransactionType type,
  ) {
    final groups = points
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.total,
                color: _typeColorFor(type, theme),
                borderRadius: BorderRadius.circular(4),
                width: 14,
              ),
            ],
          ),
        )
        .toList();

    final chartMax = maxValue == 0 ? 1.0 : maxValue * 1.2;
    final labelStyle = theme.textTheme.bodySmall;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: chartMax,
        barGroups: groups,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _shortMonthFormat.format(points[index].month),
                    style: labelStyle,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(_formatAxisLabel(value), style: labelStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(
    List<_ChartPoint> points,
    ThemeData theme,
    double maxValue,
    TransactionType type,
  ) {
    final spots = points
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.total))
        .toList();
    final chartMax = maxValue == 0 ? 1.0 : maxValue * 1.2;
    final labelStyle = theme.textTheme.bodySmall;
    final color = _typeColorFor(type, theme);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: chartMax,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _shortMonthFormat.format(points[index].month),
                    style: labelStyle,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(_formatAxisLabel(value), style: labelStyle),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: _colorWithOpacity(color, 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(
    List<_ChartPoint> points,
    ThemeData theme,
    TransactionType type,
  ) {
    return _buildPieChartForType(points, theme, type);
  }

  Widget _buildPieChartForType(
    List<_ChartPoint> points,
    ThemeData theme,
    TransactionType type,
  ) {
    final nonZeroPoints = points.where((point) => point.total > 0).toList();
    final total = nonZeroPoints.fold<double>(
      0,
      (sum, point) => sum + point.total,
    );
    if (nonZeroPoints.isEmpty || total == 0) {
      return _buildNoChartData(theme);
    }

    final color = _typeColorFor(type, theme);

    final sections = nonZeroPoints.asMap().entries.map((entry) {
      final ratio = entry.value.total / total;
      final percent = (ratio * 100).toStringAsFixed(ratio >= 0.1 ? 0 : 1);
      final sliceColor = _sliceColor(color, entry.key, nonZeroPoints.length);
      return PieChartSectionData(
        value: entry.value.total,
        color: sliceColor,
        title: '$percent%\n${_shortMonthFormat.format(entry.value.month)}',
        radius: 70,
        titleStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 1,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: nonZeroPoints.asMap().entries.map((entry) {
            final sliceColor = _sliceColor(
              color,
              entry.key,
              nonZeroPoints.length,
            );
            return Chip(
              label: Text(
                '${_shortMonthFormat.format(entry.value.month)} · '
                '${_formatCurrency(entry.value.total)}',
              ),
              backgroundColor: _colorWithOpacity(sliceColor, 0.2),
              avatar: CircleAvatar(backgroundColor: sliceColor, radius: 6),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoChartData(ThemeData theme) {
    return Center(
      child: Text('표시할 데이터가 없습니다.', style: theme.textTheme.bodyMedium),
    );
  }

  String _chartDisplayLabel(ChartDisplayType display) {
    switch (display) {
      case ChartDisplayType.bar:
        return '막대형';
      case ChartDisplayType.line:
        return '선형';
      case ChartDisplayType.pie:
        return '원형';
      case ChartDisplayType.all:
        return '전체';
    }
  }

  String _formatAxisLabel(double value) {
    final abs = value.abs();
    if (abs >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(1)}억';
    }
    if (abs >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}만';
    }
    if (abs >= 1000) {
      return _compactNumberFormat.format(value);
    }
    return value.toStringAsFixed(0);
  }

  Color _sliceColor(Color base, int index, int totalSlices) {
    final hsl = HSLColor.fromColor(base);
    final step = totalSlices <= 1 ? 0 : index / (totalSlices - 1);
    final lightness = (0.65 - step * 0.35).clamp(0.25, 0.75).toDouble();
    return hsl.withLightness(lightness).toColor();
  }

  Color _colorWithOpacity(Color color, double opacity) {
    var alpha = (opacity * 255).round();
    if (alpha < 0) {
      alpha = 0;
    } else if (alpha > 255) {
      alpha = 255;
    }
    return color.withAlpha(alpha);
  }

  TransactionType get _currentType => _typeOrder[_typeIndex];

  String _typeLabel([TransactionType? type]) {
    final target = type ?? _currentType;
    return target.label;
  }

  Color _typeColor(ThemeData theme) =>
      _colorForTransaction(_currentType, theme);

  Color _typeColorFor(TransactionType type, ThemeData theme) =>
      _colorForTransaction(type, theme);

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

  Future<void> _initialize() async {
    await TransactionService().loadTransactions();
    await FixedCostService().loadFixedCosts();
    if (!mounted) {
      return;
    }

    final service = TransactionService();
    final transactions = List<Transaction>.from(
      service.getTransactions(widget.accountName),
    );
    final fixedCosts = List<FixedCost>.from(
      FixedCostService().getFixedCosts(widget.accountName),
    );

    final monthlyAggCache = await MonthlyAggCacheService().ensureBuilt(
      accountName: widget.accountName,
      transactions: transactions,
      // AccountStats does not depend on quick input; keep it off to avoid
      // unnecessary work on this screen.
      includeQuickInput: false,
      maxMonths: MonthlyAggCacheService.defaultMaxMonths,
    );
    if (!mounted) return;

    final quickEntries = await QuickSimpleExpenseInputHistoryService()
        .loadEntries(widget.accountName);
    final storeAliasMap = await StoreAliasService.loadMap(widget.accountName);
    final defaultStore = _pickDefaultStore(transactions, storeAliasMap);
    if (!mounted) return;

    DateTime fallbackDate = DateTime.now();
    if (transactions.isNotEmpty) {
      final latest = transactions.reduce(
        (prev, next) => prev.date.isAfter(next.date) ? prev : next,
      );
      fallbackDate = latest.date;
    }

    setState(() {
      _currentMonth = DateTime(fallbackDate.year, fallbackDate.month);
      _currentYear = fallbackDate.year;
      _chartAnchorMonth = DateTime(fallbackDate.year, fallbackDate.month);
      _isInitializing = false;
      _fixedCosts = fixedCosts;
      _monthlyAggCache = monthlyAggCache;
      _quickEntries = quickEntries;
      _storeAliasMap = storeAliasMap;
      _defaultStore = defaultStore;
    });
  }

  String? _pickDefaultStore(
    List<Transaction> txs,
    Map<String, String> aliasMap,
  ) {
    final now = DateTime.now();
    final scanStart = now.subtract(const Duration(days: 183));

    final ordered = List<Transaction>.from(txs)
      ..sort((a, b) => b.date.compareTo(a.date));
    final limited = ordered.take(1500);

    final counts = <String, int>{};
    for (final t in limited) {
      if (t.date.isBefore(scanStart)) continue;
      final raw = _storeKeyOf(t);
      if (raw == null) continue;
      final canonical = StoreAliasService.resolve(raw, aliasMap);
      counts[canonical] = (counts[canonical] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final ranked = counts.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    return ranked.first.key;
  }

  String? _storeKeyOf(Transaction t) {
    final store = t.store?.trim();
    if (store != null && store.isNotEmpty) return store;
    return StoreMemoUtils.extractStoreKey(t.memo);
  }

  _SummaryTotals? _tryCalculateRangeSummaryFromMonthlyAgg(
    DateTimeRange range,
    int months,
  ) {
    final cache = _monthlyAggCache;
    if (cache == null || cache.months.isEmpty) return null;

    double income = 0;
    double expenseOnly = 0;
    double savings = 0;

    for (var i = 0; i < months; i++) {
      final monthDate = DateTime(range.end.year, range.end.month - i, 1);
      final ym = MonthlyAggCacheService.yearMonthOf(monthDate);
      final bucket = cache.months[ym];
      if (bucket == null) continue;
      income += bucket.incomeAmount;
      expenseOnly += bucket.expenseAggAmount;
      savings += bucket.savingsTotalAmount;
    }

    final monthlyFixed = _fixedCostTotalForMonth(_currentMonth);
    final fixedCostTotal = _fixedCosts.isEmpty ? 0.0 : monthlyFixed * months;

    final hasFixedCosts = _fixedCosts.isNotEmpty;
    final includeFixed = hasFixedCosts && _includeFixedCosts;
    final expenseDisplay = expenseOnly + (includeFixed ? fixedCostTotal : 0.0);
    final net = income - expenseDisplay;
    final baseFixedTitle = _fixedCostTitleForMonths(months);
    final fixedCostTitle = hasFixedCosts && !_includeFixedCosts
        ? '$baseFixedTitle(미포함)'
        : baseFixedTitle;
    final expenseTitle = includeFixed ? '지출(고정비 포함)' : '지출';

    return _SummaryTotals(
      income: income,
      expense: expenseOnly,
      savings: savings,
      fixedCost: fixedCostTotal,
      expenseDisplay: expenseDisplay,
      net: net,
      expenseTitle: expenseTitle,
      fixedCostTitle: fixedCostTitle,
    );
  }

  double _sumAmounts(Iterable<Transaction> transactions) {
    return transactions.fold<double>(0, (sum, tx) => sum + tx.amount);
  }

  String _formatCurrency(double value, {bool includeSign = false}) {
    final formatted = _currencyFormat.format(value.abs());
    if (!includeSign) {
      return '$formatted원';
    }
    if (value > 0) {
      return '+$formatted원';
    }
    if (value < 0) {
      return '-$formatted원';
    }
    return '$formatted원';
  }

  String _formatAmountByType(double value, TransactionType type) {
    final formatted = _currencyFormat.format(value.abs());
    final prefix = type.sign;
    return '$prefix$formatted원';
  }

  String _formatSignedAmount(Transaction tx) {
    final prefix = tx.type.sign;
    return '$prefix${_currencyFormat.format(tx.amount)}원';
  }

  String _formatDailyAverage(double total, int daysInMonth) {
    final average = (total / daysInMonth).round().toDouble();
    return _formatCurrency(average);
  }

  Future<void> _showTransactionActionDialog(
    Transaction tx,
    TransactionType type,
    ThemeData theme,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 핸들
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 거래 정보
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_dateFormat.format(tx.date)} · '
                    '${_currencyFormat.format(tx.amount.abs())}원',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.edit, color: theme.colorScheme.primary),
              title: const Text('거래 편집'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            if (type == TransactionType.expense)
              ListTile(
                leading: const Icon(Icons.replay, color: Colors.green),
                title: const Text('반품 처리'),
                subtitle: const Text('환불 금액을 예산에 반영'),
                onTap: () => Navigator.pop(context, 'refund'),
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('거래 삭제'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    switch (action) {
      case 'edit':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionAddScreen(
              accountName: widget.accountName,
              initialTransaction: tx,
            ),
          ),
        );
        if (mounted) {
          setState(() {});
        }
        break;
      case 'refund':
        await _showRefundDialog(tx, theme);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
            title: const Text('거래 삭제'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('정말로 이 거래를 삭제하시겠습니까?'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withAlpha(64),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withAlpha(128),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_currencyFormat.format(tx.amount.abs())}원',
                              style: TextStyle(
                                color: _typeColorFor(type, theme),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('삭제'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await TransactionService().deleteTransaction(
            widget.accountName,
            tx.id,
          );
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('거래가 삭제되었습니다'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
        break;
    }
  }

  Future<void> _showRefundDialog(
    Transaction originalTx,
    ThemeData theme,
  ) async {
    final refundAmountController = TextEditingController(
      text: originalTx.amount.abs().toString(),
    );
    DateTime selectedDate = DateTime.now();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            icon: const Icon(Icons.replay, size: 48, color: Colors.green),
            title: const Text('반품 처리'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 원본 거래 정보
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '원본 거래',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          originalTx.description,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currencyFormat.format(originalTx.amount.abs())}원',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 환불 금액 입력
                  TextField(
                    controller: refundAmountController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: '환불 금액',
                      helperText: '택배비 등을 제외한 실제 환불 금액',
                      suffixText: '원',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(128),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 16),
                  // 환불 날짜
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('ko', 'KR'),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withAlpha(128),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '환불 날짜',
                                  style: theme.textTheme.labelSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dateFormat.format(selectedDate),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 안내 메시지
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withAlpha(64)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '환불 금액이 수입으로 기록되어\n예산에 다시 반영됩니다.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('반품 처리'),
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;

      if (confirmed == true) {
        final refundAmount = double.tryParse(
          refundAmountController.text.replaceAll(',', '').trim(),
        );

        if (refundAmount == null || refundAmount <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('올바른 환불 금액을 입력하세요')));
          }
          return;
        }

        await TransactionService().createRefundTransaction(
          widget.accountName,
          originalTx,
          refundDate: selectedDate,
          refundAmount: refundAmount,
        );

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '반품 처리 완료 (환불: ${_currencyFormat.format(refundAmount)}원)',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } finally {
      refundAmountController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isInitializing) {
      const loader = Center(child: CircularProgressIndicator());
      if (widget.embed) {
        return loader;
      }
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: null,
          toolbarHeight: 40,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: loader,
      );
    }

    final service = TransactionService();
    final transactions = service.getTransactions(widget.accountName);

    final contentBody = _buildView(transactions, theme);

    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: null,
          toolbarHeight: 40,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: content,
      ),
    );
  }

  Widget _buildView(List<Transaction> transactions, ThemeData theme) {
    switch (_selectedView) {
      case _StatsView.month:
        return _buildMonthlyView(transactions, theme);
      case _StatsView.quarter:
        return _buildMultiMonthView(transactions, theme, 3);
      case _StatsView.halfYear:
        return _buildMultiMonthView(transactions, theme, 6);
      case _StatsView.year:
        return _buildYearView(transactions, theme);
      case _StatsView.decade:
        return _buildDecadeView(transactions, theme);
      case _StatsView.chart:
        return _buildChartView(transactions, theme);
      case _StatsView.expenseDetail:
        return _buildTypeDetailView(
          transactions,
          theme,
          TransactionType.expense,
        );
      case _StatsView.incomeDetail:
        return _buildTypeDetailView(
          transactions,
          theme,
          TransactionType.income,
        );
      case _StatsView.savingsDetail:
        return _buildTypeDetailView(
          transactions,
          theme,
          TransactionType.savings,
        );
    }
  }

  _SummaryTotals _calculateMonthlySummary(
    List<Transaction> monthlyTransactions,
    DateTime month,
  ) {
    double income = 0;
    double expenseOnly = 0; // 순수 지출만
    double savings = 0; // 모든 예금 (expense 포함)

    for (final tx in monthlyTransactions) {
      switch (tx.type) {
        case TransactionType.income:
        case TransactionType.refund:
          income += tx.amount;
          break;
        case TransactionType.expense:
          expenseOnly += tx.amount;
          break;
        case TransactionType.savings:
          savings += tx.amount; // 모든 savings를 포함
          if (_isSavingsCountedAsExpense(tx)) {
            // expense로 분류된 것도 지출에 포함
            expenseOnly += tx.amount;
          }
          break;
      }
    }

    final fixedCost = _fixedCostTotalForMonth(month);
    final hasFixedCosts = _fixedCosts.isNotEmpty;
    final includeFixed = hasFixedCosts && _includeFixedCosts;
    final expenseDisplay = expenseOnly + (includeFixed ? fixedCost : 0.0);
    final net = income - expenseDisplay;
    final expenseTitle = includeFixed ? '지출(고정비 포함)' : '지출';
    final fixedCostTitle = hasFixedCosts && !_includeFixedCosts
        ? '고정비용(미포함)'
        : '고정비용';

    return _SummaryTotals(
      income: income,
      expense: expenseOnly,
      savings: savings,
      fixedCost: fixedCost,
      expenseDisplay: expenseDisplay,
      net: net,
      expenseTitle: expenseTitle,
      fixedCostTitle: fixedCostTitle,
    );
  }

  _SummaryTotals _calculateYearlySummary(
    List<Transaction> yearlyTransactions,
    int year,
  ) {
    double income = 0;
    double expenseOnly = 0; // 순수 지출만
    double savings = 0; // 모든 예금 (expense 포함)

    for (final tx in yearlyTransactions) {
      switch (tx.type) {
        case TransactionType.income:
        case TransactionType.refund:
          income += tx.amount;
          break;
        case TransactionType.expense:
          expenseOnly += tx.amount;
          break;
        case TransactionType.savings:
          savings += tx.amount; // 모든 savings를 포함
          if (_isSavingsCountedAsExpense(tx)) {
            // expense로 분류된 것도 지출에 포함
            expenseOnly += tx.amount;
          }
          break;
      }
    }

    final fixedCostMonthly = _fixedCostTotalForMonth(DateTime(year, 1));
    final fixedCostYearly = _fixedCosts.isEmpty ? 0.0 : fixedCostMonthly * 12;

    final hasFixedCosts = _fixedCosts.isNotEmpty;
    final includeFixed = hasFixedCosts && _includeFixedCosts;
    final expenseDisplay = expenseOnly + (includeFixed ? fixedCostYearly : 0.0);
    final net = income - expenseDisplay;
    final expenseTitle = includeFixed ? '지출(고정비 포함)' : '지출';
    final fixedCostTitle = hasFixedCosts && !_includeFixedCosts
        ? '연간 고정비용(미포함)'
        : '연간 고정비용';

    return _SummaryTotals(
      income: income,
      expense: expenseOnly,
      savings: savings,
      fixedCost: fixedCostYearly,
      expenseDisplay: expenseDisplay,
      net: net,
      expenseTitle: expenseTitle,
      fixedCostTitle: fixedCostTitle,
    );
  }

  _SummaryTotals _calculateRangeSummary(
    List<Transaction> rangeTransactions,
    int months,
  ) {
    double income = 0;
    double expenseOnly = 0; // 순수 지출만
    double savings = 0; // 모든 예금 (expense 포함)

    for (final tx in rangeTransactions) {
      switch (tx.type) {
        case TransactionType.income:
        case TransactionType.refund:
          income += tx.amount;
          break;
        case TransactionType.expense:
          expenseOnly += tx.amount;
          break;
        case TransactionType.savings:
          savings += tx.amount; // 모든 savings를 포함
          if (_isSavingsCountedAsExpense(tx)) {
            // expense로 분류된 것도 지출에 포함
            expenseOnly += tx.amount;
          }
          break;
      }
    }

    final monthlyFixed = _fixedCostTotalForMonth(_currentMonth);
    final fixedCostTotal = _fixedCosts.isEmpty ? 0.0 : monthlyFixed * months;

    final hasFixedCosts = _fixedCosts.isNotEmpty;
    final includeFixed = hasFixedCosts && _includeFixedCosts;
    final expenseDisplay = expenseOnly + (includeFixed ? fixedCostTotal : 0.0);
    final net = income - expenseDisplay;
    final baseFixedTitle = _fixedCostTitleForMonths(months);
    final fixedCostTitle = hasFixedCosts && !_includeFixedCosts
        ? '$baseFixedTitle(미포함)'
        : baseFixedTitle;
    final expenseTitle = includeFixed ? '지출(고정비 포함)' : '지출';

    return _SummaryTotals(
      income: income,
      expense: expenseOnly,
      savings: savings,
      fixedCost: fixedCostTotal,
      expenseDisplay: expenseDisplay,
      net: net,
      expenseTitle: expenseTitle,
      fixedCostTitle: fixedCostTitle,
    );
  }

  List<Transaction> _transactionsForMonth(
    List<Transaction> transactions,
    DateTime month,
  ) {
    return transactions
        .where(
          (tx) => tx.date.year == month.year && tx.date.month == month.month,
        )
        .toList();
  }

  DateTimeRange _rangeForMonths(int months) {
    final start = DateTime(
      _currentMonth.year,
      _currentMonth.month - (months - 1),
      1,
    );
    final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    return DateTimeRange(start: start, end: end);
  }

  String _formatRangeLabel(DateTime start, DateTime end) {
    final startLabel = _dateFormat.format(start);
    final endLabel = _dateFormat.format(end);
    return '$startLabel ~ $endLabel';
  }

  int _monthsInYearWithinRange(
    int year,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    var count = 0;
    for (var month = 1; month <= 12; month++) {
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0);
      final overlaps =
          !monthEnd.isBefore(rangeStart) && !monthStart.isAfter(rangeEnd);
      if (overlaps) {
        count += 1;
      }
    }
    return count;
  }

  String _fixedCostTitleForMonths(int months) {
    switch (months) {
      case 1:
        return '고정비용';
      case 3:
        return '3개월 고정비용';
      case 6:
        return '6개월 고정비용';
      case 12:
        return '연간 고정비용';
      case 120:
        return '10년 고정비용';
      default:
        return '고정비용';
    }
  }

  List<_SummaryCard> _buildSummaryCards(
    _SummaryTotals summary,
    ThemeData theme,
  ) {
    final cards = <_SummaryCard>[
      // 1. 수입
      _SummaryCard(
        icon: Icons.trending_up,
        title: '수입',
        value: _formatCurrency(summary.income),
        valueColor: theme.colorScheme.primary,
      ),
      // 2. 예금
      _SummaryCard(
        icon: Icons.savings,
        title: AppStrings.transactionTypeSavings,
        value: _formatAmountByType(summary.savings, TransactionType.savings),
        valueColor: Colors.amber[800],
      ),
      // 3. 지출
      _SummaryCard(
        icon: Icons.trending_down,
        title: summary.expenseTitle,
        value: _formatAmountByType(
          summary.expenseDisplay,
          TransactionType.expense,
        ),
        valueColor: theme.colorScheme.error,
      ),
    ];

    if (_fixedCosts.isNotEmpty) {
      cards.add(
        _SummaryCard(
          icon: Icons.receipt_long,
          title: summary.fixedCostTitle,
          value: _formatAmountByType(
            summary.fixedCost,
            TransactionType.expense,
          ),
          valueColor: theme.colorScheme.secondary,
        ),
      );
    }

    // 여유자금은 항상 표시 (수입 - 지출)
    final remainingBudget = summary.income - summary.expenseDisplay;
    cards.add(
      _SummaryCard(
        icon: Icons.savings_outlined,
        title: '여유자금',
        value: _formatCurrency(remainingBudget, includeSign: true),
        valueColor: remainingBudget >= 0 ? Colors.green : Colors.red,
      ),
    );

    return cards;
  }

  Widget _buildMonthlyView(List<Transaction> transactions, ThemeData theme) {
    final summary = _calculateMonthlySummary(transactions, _currentMonth);
    final monthlyTransactions = _transactionsForMonth(
      transactions,
      _currentMonth,
    );

    final typeTransactions =
        monthlyTransactions
            .where((tx) => _shouldAggregateForType(tx, _currentType))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final dayGroups = <DateTime, List<Transaction>>{};
    for (final tx in typeTransactions) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      dayGroups.putIfAbsent(day, () => <Transaction>[]).add(tx);
    }
    final orderedDays = dayGroups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthNavigator(theme),
        const SizedBox(height: 16),
        _SummaryGrid(children: _buildSummaryCards(summary, theme)),
        const SizedBox(height: 24),
        Text('일별 ${_typeLabel()}', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (orderedDays.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('이 달에 ${_typeLabel()} 거래가 없습니다.'),
            ),
          )
        else
          Column(
            children: orderedDays
                .map((day) => _buildDailyTile(day, dayGroups[day]!, theme))
                .toList(),
          ),
        if (_fixedCosts.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildFixedCostSection(theme),
        ],

        const SizedBox(height: 24),
        Text('간편 지출(1줄)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildQuickInputInline(theme),

        const SizedBox(height: 24),
        Text('마트별 제품', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildStoreProductsInline(theme, transactions),
      ],
    );
  }

  DateTime _monthStart(DateTime month) => DateTime(month.year, month.month, 1);

  DateTime _monthEndExclusive(DateTime month) =>
      DateTime(month.year, month.month + 1, 1);

  String _formatWon(double value) => '${_currencyFormat.format(value)}원';

  Widget _buildQuickInputInline(ThemeData theme) {
    if (_quickEntries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '저장된 1줄 입력이 없습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final start = _monthStart(_currentMonth);
    final endEx = _monthEndExclusive(_currentMonth);
    final inMonth = _quickEntries
        .where((e) {
          return !e.createdAt.isBefore(start) && e.createdAt.isBefore(endEx);
        })
        .toList(growable: false);

    var total = 0.0;
    for (final e in inMonth) {
      total += e.amount;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이번달 총액', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              _formatWon(total),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '(1달) · ${inMonth.length}건',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreProductsInline(ThemeData theme, List<Transaction> txs) {
    final store = _defaultStore;
    if (store == null || store.trim().isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '마트명이 기록된 거래가 없습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final start = _monthStart(_currentMonth);
    final endEx = _monthEndExclusive(_currentMonth);

    var thisMonthTotal = 0.0;
    var thisMonthCount = 0;

    final byKey = <String, _StoreProductAcc>{};

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;

      final raw = _storeKeyOf(t);
      if (raw == null) continue;
      final canonical = StoreAliasService.resolve(raw, _storeAliasMap);
      if (canonical != store) continue;

      if (t.date.isBefore(start) || !t.date.isBefore(endEx)) continue;

      thisMonthCount += 1;
      thisMonthTotal += t.amount;

      final key = ProductNameUtils.normalizeKey(t.description);
      if (key.isEmpty) continue;
      final acc = byKey.putIfAbsent(
        key,
        () => _StoreProductAcc(name: t.description.trim()),
      );
      acc.count += 1;
      acc.total += t.amount;

      final name = t.description.trim();
      if (name.isNotEmpty && acc.name.length < name.length) {
        acc.name = name;
      }
    }

    final items =
        byKey.values
            .map(
              (a) => _StoreProductStat(
                name: a.name,
                count: a.count,
                total: a.total,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.total.compareTo(a.total));

    final top = items.take(20).toList(growable: false);
    final maxAmount = top.fold<double>(0, (m, e) => e.total > m ? e.total : m);
    final denom = maxAmount <= 0 ? 1.0 : maxAmount;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('기본 마트: $store', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              '이번달 총액: ${_formatWon(thisMonthTotal)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '(1달) · $thisMonthCount건',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (top.isEmpty)
              Text(
                '이번달 제품 데이터가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...top.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final item = entry.value;
                final pct = (item.total / denom).clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$rank. ${item.name}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: rank <= 20
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatWon(item.total),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: pct,
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.count}건',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiMonthView(
    List<Transaction> transactions,
    ThemeData theme,
    int months,
  ) {
    final range = _rangeForMonths(months);

    final aggSummary = _tryCalculateRangeSummaryFromMonthlyAgg(range, months);
    final canUseAgg = aggSummary != null && _monthlyAggCache != null;

    final summary =
        aggSummary ??
        (() {
          final rangeTransactions = transactions
              .where(
                (tx) =>
                    !tx.date.isBefore(range.start) &&
                    !tx.date.isAfter(range.end),
              )
              .toList();
          return _calculateRangeSummary(rangeTransactions, months);
        })();

    final monthSummaries = canUseAgg
        ? List.generate(months, (index) {
            final monthDate = DateTime(
              _currentMonth.year,
              _currentMonth.month - index,
              1,
            );
            final ym = MonthlyAggCacheService.yearMonthOf(monthDate);
            final bucket = _monthlyAggCache!.months[ym];
            final baseTotal = bucket?.amountForType(_currentType) ?? 0.0;
            final baseCount = bucket?.countForType(_currentType) ?? 0;

            var total = baseTotal;
            if (_includeFixedCosts &&
                _fixedCosts.isNotEmpty &&
                _currentType == TransactionType.expense) {
              total += _fixedCostTotalForMonth(monthDate);
            }
            return _MonthlySummary(
              month: DateTime(monthDate.year, monthDate.month),
              total: total,
              count: baseCount,
            );
          }).reversed.toList()
        : () {
            final rangeTransactions = transactions
                .where(
                  (tx) =>
                      !tx.date.isBefore(range.start) &&
                      !tx.date.isAfter(range.end),
                )
                .toList();
            return List.generate(months, (index) {
              final monthDate = DateTime(
                _currentMonth.year,
                _currentMonth.month - index,
              );
              final monthTransactions = rangeTransactions.where(
                (tx) =>
                    tx.date.year == monthDate.year &&
                    tx.date.month == monthDate.month &&
                    _shouldAggregateForType(tx, _currentType),
              );
              var total = _sumAmounts(monthTransactions);
              if (_includeFixedCosts &&
                  _fixedCosts.isNotEmpty &&
                  _currentType == TransactionType.expense) {
                total += _fixedCostTotalForMonth(monthDate);
              }
              return _MonthlySummary(
                month: DateTime(monthDate.year, monthDate.month),
                total: total,
                count: monthTransactions.length,
              );
            }).reversed.toList();
          }();

    final rangeLabel = _formatRangeLabel(range.start, range.end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthNavigator(theme),
        const SizedBox(height: 8),
        Center(
          child: Text(
            rangeLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SummaryGrid(children: _buildSummaryCards(summary, theme)),
        const SizedBox(height: 24),
        Text('월별 ${_typeLabel()}', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: monthSummaries
                  .map(
                    (summary) => ListTile(
                      title: Text(_shortMonthFormat.format(summary.month)),
                      subtitle: Text('${summary.count}건'),
                      trailing: Text(
                        _formatAmountByType(summary.total, _currentType),
                        style: TextStyle(color: _typeColor(theme)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (_fixedCosts.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildFixedCostSection(theme),
        ],
      ],
    );
  }

  Widget _buildDailyTile(
    DateTime day,
    List<Transaction> transactions,
    ThemeData theme,
  ) {
    final total = _sumAmounts(transactions);
    return Card(
      child: ExpansionTile(
        title: Text(_dayLabelFormat.format(day)),
        subtitle: Text(
          '합계 ${_formatAmountByType(total, _currentType)}',
          style: TextStyle(color: _typeColor(theme)),
        ),
        children: transactions
            .map(
              (tx) => ListTile(
                dense: true,
                leading: Icon(
                  _iconForType(tx.type),
                  color: _colorForTransaction(tx.type, theme),
                ),
                title: Text(tx.description),
                subtitle: Text(_dateFormat.format(tx.date)),
                trailing: Text(_formatSignedAmount(tx)),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildYearView(List<Transaction> transactions, ThemeData theme) {
    final cache = _monthlyAggCache;
    final canUseAgg = cache != null && cache.months.isNotEmpty;

    final summary = canUseAgg
        ? () {
            double income = 0;
            double expenseOnly = 0;
            double savings = 0;
            for (var month = 1; month <= 12; month++) {
              final ym = MonthlyAggCacheService.yearMonthOf(
                DateTime(_currentYear, month, 1),
              );
              final bucket = cache.months[ym];
              if (bucket == null) continue;
              income += bucket.incomeAmount;
              expenseOnly += bucket.expenseAggAmount;
              savings += bucket.savingsTotalAmount;
            }

            final fixedCostMonthly = _fixedCostTotalForMonth(
              DateTime(_currentYear, 1),
            );
            final fixedCostYearly = _fixedCosts.isEmpty
                ? 0.0
                : fixedCostMonthly * 12;

            final hasFixedCosts = _fixedCosts.isNotEmpty;
            final includeFixed = hasFixedCosts && _includeFixedCosts;
            final expenseDisplay =
                expenseOnly + (includeFixed ? fixedCostYearly : 0.0);
            final net = income - expenseDisplay;
            final expenseTitle = includeFixed ? '지출(고정비 포함)' : '지출';
            final fixedCostTitle = hasFixedCosts && !_includeFixedCosts
                ? '연간 고정비용(미포함)'
                : '연간 고정비용';

            return _SummaryTotals(
              income: income,
              expense: expenseOnly,
              savings: savings,
              fixedCost: fixedCostYearly,
              expenseDisplay: expenseDisplay,
              net: net,
              expenseTitle: expenseTitle,
              fixedCostTitle: fixedCostTitle,
            );
          }()
        : _calculateYearlySummary(transactions, _currentYear);

    final fixedCostMonthlyTotal = _fixedCostTotalForMonth(
      DateTime(_currentYear, 1),
    );

    final monthSummaries = List.generate(12, (index) {
      final month = index + 1;
      if (canUseAgg) {
        final ym = MonthlyAggCacheService.yearMonthOf(
          DateTime(_currentYear, month, 1),
        );
        final bucket = cache.months[ym];
        final baseTotal = bucket?.amountForType(_currentType) ?? 0.0;
        final addFixed =
            _includeFixedCosts &&
            _fixedCosts.isNotEmpty &&
            _currentType == TransactionType.expense;
        final total = baseTotal + (addFixed ? fixedCostMonthlyTotal : 0.0);
        final count = bucket?.countForType(_currentType) ?? 0;
        return _MonthlySummary(
          month: DateTime(_currentYear, month),
          total: total,
          count: count,
        );
      }

      final yearlyTransactions = transactions.where(
        (tx) => tx.date.year == _currentYear,
      );

      final monthTransactions = yearlyTransactions.where(
        (tx) =>
            _shouldAggregateForType(tx, _currentType) && tx.date.month == month,
      );
      var total = _sumAmounts(monthTransactions);
      if (_includeFixedCosts &&
          _fixedCosts.isNotEmpty &&
          _currentType == TransactionType.expense) {
        total += fixedCostMonthlyTotal;
      }
      final count = monthTransactions.length;
      return _MonthlySummary(
        month: DateTime(_currentYear, month),
        total: total,
        count: count,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildYearNavigator(theme),
        const SizedBox(height: 16),
        _SummaryGrid(children: _buildSummaryCards(summary, theme)),
        const SizedBox(height: 24),
        Text('월별 ${_typeLabel()}', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: monthSummaries
                  .map(
                    (summary) => ListTile(
                      title: Text(_shortMonthFormat.format(summary.month)),
                      subtitle: Text('${summary.count}건'),
                      trailing: Text(
                        _formatAmountByType(summary.total, _currentType),
                        style: TextStyle(color: _typeColor(theme)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (_fixedCosts.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildFixedCostSection(theme, annual: true),
        ],
      ],
    );
  }

  Widget _buildDecadeView(List<Transaction> transactions, ThemeData theme) {
    const totalMonths = 120;
    final range = _rangeForMonths(totalMonths);
    final aggSummary = _tryCalculateRangeSummaryFromMonthlyAgg(
      range,
      totalMonths,
    );
    final canUseAgg = aggSummary != null && _monthlyAggCache != null;

    final rangeTransactions = canUseAgg
        ? const <Transaction>[]
        : transactions
              .where(
                (tx) =>
                    !tx.date.isBefore(range.start) &&
                    !tx.date.isAfter(range.end),
              )
              .toList();

    final summary =
        aggSummary ??
        (() {
          return _calculateRangeSummary(rangeTransactions, totalMonths);
        })();
    final startYear = range.start.year;
    final endYear = range.end.year;

    final yearSummaries = <_YearSummary>[];
    for (var year = startYear; year <= endYear; year++) {
      if (canUseAgg) {
        double total = 0.0;
        int count = 0;
        for (var month = 1; month <= 12; month++) {
          final dt = DateTime(year, month, 1);
          if (dt.isBefore(range.start) || dt.isAfter(range.end)) continue;
          final ym = MonthlyAggCacheService.yearMonthOf(dt);
          final bucket = _monthlyAggCache!.months[ym];
          if (bucket == null) continue;
          total += bucket.amountForType(_currentType);
          count += bucket.countForType(_currentType);
        }

        if (_includeFixedCosts &&
            _fixedCosts.isNotEmpty &&
            _currentType == TransactionType.expense) {
          final monthsCovered = _monthsInYearWithinRange(
            year,
            range.start,
            range.end,
          );
          total += _fixedCostTotalForMonth(DateTime(year, 1)) * monthsCovered;
        }
        yearSummaries.add(_YearSummary(year: year, total: total, count: count));
        continue;
      }
      final yearTransactions = rangeTransactions.where(
        (tx) =>
            tx.date.year == year && _shouldAggregateForType(tx, _currentType),
      );
      var total = _sumAmounts(yearTransactions);
      if (_includeFixedCosts &&
          _fixedCosts.isNotEmpty &&
          _currentType == TransactionType.expense) {
        final monthsCovered = _monthsInYearWithinRange(
          year,
          range.start,
          range.end,
        );
        total += _fixedCostTotalForMonth(DateTime(year, 1)) * monthsCovered;
      }
      yearSummaries.add(
        _YearSummary(year: year, total: total, count: yearTransactions.length),
      );
    }

    final filteredSummaries = _showEmptyYears
        ? yearSummaries
        : yearSummaries
              .where((summary) => summary.total != 0 || summary.count != 0)
              .toList();
    final infoMessage = _showEmptyYears
        ? '모든 연도를 표시하는 중입니다.'
        : '거래가 있는 연도만 표시합니다.';

    final rangeLabel = _formatRangeLabel(range.start, range.end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildYearNavigator(theme, label: '$startYear년 ~ $endYear년'),
        const SizedBox(height: 8),
        Center(
          child: Text(
            rangeLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SummaryGrid(children: _buildSummaryCards(summary, theme)),
        const SizedBox(height: 24),
        Text('연도별 ${_typeLabel()}', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                infoMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _showEmptyYears = !_showEmptyYears);
              },
              child: Text(_showEmptyYears ? '기록 없는 연도 숨기기' : '기록 없는 연도 표시'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filteredSummaries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '표시할 연도가 없습니다. 기록 없는 연도를 표시하려면 버튼을 눌러주세요.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: filteredSummaries
                    .map(
                      (summary) => ListTile(
                        title: Text('${summary.year}년'),
                        subtitle: Text('${summary.count}건'),
                        trailing: Text(
                          _formatAmountByType(summary.total, _currentType),
                          style: TextStyle(color: _typeColor(theme)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        if (_fixedCosts.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildFixedCostSection(theme),
        ],
      ],
    );
  }

  List<DateTime> _chartMonths() {
    return List.generate(12, (index) {
      final offset = 11 - index;
      return DateTime(_chartAnchorMonth.year, _chartAnchorMonth.month - offset);
    });
  }

  List<_ChartPoint> _chartPointsForType(
    List<Transaction> transactions,
    TransactionType type,
    List<DateTime> months,
  ) {
    return months.map((month) {
      final monthTransactions = transactions.where(
        (tx) =>
            tx.type == type &&
            tx.date.year == month.year &&
            tx.date.month == month.month,
      );
      var total = _sumAmounts(monthTransactions);
      if (_includeFixedCosts &&
          _fixedCosts.isNotEmpty &&
          type == TransactionType.expense) {
        total += _fixedCostTotalForMonth(month);
      }
      return _ChartPoint(month: month, total: total);
    }).toList();
  }

  Widget _buildChartView(List<Transaction> transactions, ThemeData theme) {
    final months = _chartMonths();
    final points = _chartPointsForType(transactions, _currentType, months);

    final maxValue = points.fold<double>(
      0,
      (previousValue, point) =>
          point.total > previousValue ? point.total : previousValue,
    );
    final hasData = points.any((point) => point.total > 0);
    final safeMax = maxValue == 0 ? 1.0 : maxValue;

    final rangeStart = months.first;
    final rangeEnd = months.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartNavigator(theme, rangeStart, rangeEnd),
        const SizedBox(height: 16),
        _buildChartDisplaySelector(),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 260,
              child: hasData
                  ? _buildChartForDisplay(points, theme, safeMax, _currentType)
                  : _buildNoChartData(theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartDisplaySelector() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: ChartDisplayType.values
          .map(
            (display) => ChoiceChip(
              label: Text(_chartDisplayLabel(display)),
              selected: _chartDisplay == display,
              onSelected: (selected) {
                if (!selected) {
                  return;
                }
                setState(() => _chartDisplay = display);
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildTypeDetailView(
    List<Transaction> transactions,
    ThemeData theme,
    TransactionType type,
  ) {
    // 선택한 타입의 거래만 필터링
    final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final endOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final filtered = transactions.where((tx) {
      // 날짜 범위 필터
      bool inRange;
      if (_selectedDate != null) {
        // 특정 날짜 선택 시
        inRange =
            tx.date.year == _selectedDate!.year &&
            tx.date.month == _selectedDate!.month &&
            tx.date.day == _selectedDate!.day;
      } else {
        // 전체 월 표시
        inRange =
            tx.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            tx.date.isBefore(endOfMonth.add(const Duration(days: 1)));
      }
      return inRange && _shouldAggregateForType(tx, type);
    }).toList();

    // 카테고리별 집계
    final Map<String, double> categoryTotals = {};
    final Map<String, List<Transaction>> categoryTransactions = {};

    for (final tx in filtered) {
      final category = tx.memo.isEmpty ? '미분류' : tx.memo;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + tx.amount.abs();
      categoryTransactions.putIfAbsent(category, () => []).add(tx);
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = filtered.fold<double>(0, (sum, tx) => sum + tx.amount.abs());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 뒤로가기 버튼
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedView = _StatsView.month;
                });
              },
            ),
            Text(
              '${_typeLabel(type)} 상세',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 월 이동 네비게이션
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(
                    _currentMonth.year,
                    _currentMonth.month - 1,
                  );
                  _selectedDate = null; // 월 변경 시 날짜 필터 해제
                });
              },
            ),
            Text(
              _monthLabelFormat.format(_currentMonth),
              style: theme.textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(
                    _currentMonth.year,
                    _currentMonth.month + 1,
                  );
                  _selectedDate = null; // 월 변경 시 날짜 필터 해제
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 날짜 선택 버튼
        Center(
          child: Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? _currentMonth,
                  firstDate: DateTime(
                    _currentMonth.year,
                    _currentMonth.month,
                    1,
                  ),
                  lastDate: DateTime(
                    _currentMonth.year,
                    _currentMonth.month + 1,
                    0,
                  ),
                  locale: const Locale('ko', 'KR'),
                  builder: (context, child) {
                    return Theme(
                      data: theme.copyWith(
                        colorScheme: theme.colorScheme.copyWith(
                          primary: _typeColorFor(type, theme),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (!mounted) return;
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedDate != null
                          ? Icons.event
                          : Icons.calendar_today,
                      size: 20,
                      color: _typeColorFor(type, theme),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDate != null
                          ? _dayLabelFormat.format(_selectedDate!)
                          : '날짜 선택',
                      style: TextStyle(
                        color: _typeColorFor(type, theme),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 16,
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(64),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: '전체 보기',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 총액 카드
        Card(
          color: _typeColorFor(type, theme).withAlpha(25),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  _selectedDate != null
                      ? '${_dayLabelFormat.format(_selectedDate!)} '
                            '${_typeLabel(type)}'
                      : '총 ${_typeLabel(type)}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(total),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: _typeColorFor(type, theme),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${filtered.length}건의 거래',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (filtered.isNotEmpty && _selectedDate == null) ...[
                  const Divider(height: 24),
                  Text(
                    '일일 평균',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDailyAverage(total, endOfMonth.day),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: _typeColorFor(type, theme),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 카테고리별 목록
        if (sortedCategories.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                '${_typeLabel(type)} 거래가 없습니다.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...sortedCategories.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
            final txList = categoryTransactions[entry.key] ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _typeColorFor(
                    type,
                    theme,
                  ).withValues(alpha: 0.2),
                  child: Icon(
                    type == TransactionType.expense
                        ? Icons.remove_circle_outline
                        : (type == TransactionType.income
                              ? Icons.add_circle_outline
                              : Icons.savings_outlined),
                    color: _typeColorFor(type, theme),
                  ),
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: _typeColorFor(type, theme),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${percentage.toStringAsFixed(1)}%'),
                  ],
                ),
                trailing: Text(
                  '${_currencyFormat.format(entry.value)}원',
                  style: TextStyle(
                    color: _typeColorFor(type, theme),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                children: txList.map((tx) {
                  // 이 거래의 반품 내역 조회
                  final refunds = TransactionService().getRefundsForTransaction(
                    widget.accountName,
                    tx.id,
                  );
                  final totalRefunded = refunds.fold<double>(
                    0.0,
                    (sum, refund) => sum + refund.amount.abs(),
                  );
                  final hasRefund = refunds.isNotEmpty;

                  return ListTile(
                    dense: true,
                    leading: tx.isRefund
                        ? const Icon(
                            Icons.replay,
                            size: 16,
                            color: Colors.green,
                          )
                        : null,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_dateFormat.format(tx.date)} ${tx.description}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: hasRefund
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (hasRefund)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(51),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '반품',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green[700],
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: hasRefund
                        ? Text(
                            '환불: ${_currencyFormat.format(totalRefunded)}원',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green[700],
                              fontSize: 11,
                            ),
                          )
                        : null,
                    trailing: Text(
                      '${_currencyFormat.format(tx.amount.abs())}원',
                      style: TextStyle(
                        color: _typeColorFor(type, theme),
                        decoration: hasRefund
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    onTap: !tx.isRefund
                        ? () => _showTransactionActionDialog(tx, type, theme)
                        : null,
                  );
                }).toList(),
              ),
            );
          }),
      ],
    );
  }

  double _fixedCostTotalForMonth(DateTime _) {
    if (_fixedCosts.isEmpty) {
      return 0.0;
    }
    return _fixedCosts.fold<double>(
      0.0,
      (previousValue, cost) => previousValue + cost.amount,
    );
  }

  List<FixedCost> _sortedFixedCosts() {
    final list = List<FixedCost>.from(_fixedCosts);
    list.sort((a, b) {
      final dayA = a.dueDay ?? 0;
      final dayB = b.dueDay ?? 0;
      if (dayA != dayB) {
        return dayA.compareTo(dayB);
      }
      return a.name.compareTo(b.name);
    });
    return list;
  }

  Widget _buildFixedCostSection(ThemeData theme, {bool annual = false}) {
    final costs = _sortedFixedCosts();
    final referenceMonth = annual ? DateTime(_currentYear, 1) : _currentMonth;
    final monthlyTotal = _fixedCostTotalForMonth(referenceMonth);
    final total = annual ? monthlyTotal * 12 : monthlyTotal;
    final titlePrefix = annual ? '연간' : '등록된';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$titlePrefix 고정비용 '
          '(${_formatAmountByType(total, TransactionType.expense)})',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: costs
                .map(
                  (cost) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.receipt_long),
                    title: Text(cost.name),
                    subtitle: Text(_fixedCostSubtitle(cost)),
                    trailing: Text(
                      _formatAmountByType(cost.amount, TransactionType.expense),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  String _fixedCostSubtitle(FixedCost cost) {
    final parts = <String>[];
    if (cost.paymentMethod.isNotEmpty) {
      parts.add(cost.paymentMethod);
    }
    if (cost.vendor != null && cost.vendor!.trim().isNotEmpty) {
      parts.add(cost.vendor!.trim());
    }
    if (cost.dueDay != null) {
      parts.add('매월 ${cost.dueDay}일');
    }
    if (cost.memo != null && cost.memo!.trim().isNotEmpty) {
      parts.add(cost.memo!.trim());
    }
    if (parts.isEmpty) {
      return '추가 정보 없음';
    }
    return parts.join(' · ');
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

  Color _colorForTransaction(TransactionType type, ThemeData theme) {
    switch (type) {
      case TransactionType.income:
      case TransactionType.refund:
        return theme.colorScheme.primary;
      case TransactionType.savings:
        return Colors.amber[700] ?? theme.colorScheme.secondary;
      case TransactionType.expense:
        return theme.colorScheme.error;
    }
  }

  Widget _buildMonthNavigator(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month - 1,
              );
            });
          },
        ),
        Text(
          _monthLabelFormat.format(_currentMonth),
          style: theme.textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month + 1,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildYearNavigator(ThemeData theme, {String? label}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _currentYear -= 1;
              if (_selectedView == _StatsView.decade) {
                _currentMonth = DateTime(_currentYear, _currentMonth.month);
              }
            });
          },
        ),
        Text(label ?? '$_currentYear년', style: theme.textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _currentYear += 1;
              if (_selectedView == _StatsView.decade) {
                _currentMonth = DateTime(_currentYear, _currentMonth.month);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildChartNavigator(ThemeData theme, DateTime start, DateTime end) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _chartAnchorMonth = DateTime(
                _chartAnchorMonth.year,
                _chartAnchorMonth.month - 12,
              );
            });
          },
        ),
        Text(
          '${_rangeMonthFormat.format(start)} ~ '
          '${_rangeMonthFormat.format(end)}',
          style: theme.textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _chartAnchorMonth = DateTime(
                _chartAnchorMonth.year,
                _chartAnchorMonth.month + 12,
              );
            });
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class AccountStatsSearchScreen extends StatefulWidget {
  const AccountStatsSearchScreen({
    super.key,
    required this.accountName,
    this.memoOnly = false,
  });

  final String accountName;
  final bool memoOnly;

  @override
  State<AccountStatsSearchScreen> createState() =>
      _AccountStatsSearchScreenState();
}

class _TxSearchPlan {
  final String ftsQuery;
  final _TxSearchFilters filters;

  const _TxSearchPlan({required this.ftsQuery, required this.filters});
}

class _TxSearchFilters {
  final Set<TransactionType> types = <TransactionType>{};
  final List<String> paymentContains = <String>[];
  final List<String> storeContains = <String>[];
  final List<String> categoryContains = <String>[];
  final List<String> descriptionContains = <String>[];
  final List<String> memoContains = <String>[];

  double? minAmountAbs;
  double? maxAmountAbs;
  DateTime? startDate;
  DateTime? endDate;

  bool benefitOnly = false;
  bool pointsOnly = false;
  double? minBenefit;
  double? maxBenefit;

  // For simulation display only (does not affect matching).
  double? annualRatePercent;

  bool get hasAny {
    return types.isNotEmpty ||
        paymentContains.isNotEmpty ||
        storeContains.isNotEmpty ||
        categoryContains.isNotEmpty ||
        descriptionContains.isNotEmpty ||
        memoContains.isNotEmpty ||
        minAmountAbs != null ||
        maxAmountAbs != null ||
        startDate != null ||
        endDate != null ||
        benefitOnly ||
        pointsOnly ||
        minBenefit != null ||
        maxBenefit != null ||
        annualRatePercent != null;
  }
}

_TxSearchPlan _parseTxSearchPlan(String raw) {
  final input = raw.trim();
  final filters = _TxSearchFilters();
  if (input.isEmpty) {
    return _TxSearchPlan(ftsQuery: '', filters: filters);
  }

  double? parseAnnualRatePercent(String s) {
    final cleaned = s.trim().replaceAll('%', '');
    final v = double.tryParse(cleaned);
    if (v == null) return null;
    if (v < 0 || v > 100) return null;
    return v;
  }

  DateTime? parseYmd(String s) {
    final t = s.trim();
    final m = RegExp(r'^(\d{4})-(\d{1,2})(?:-(\d{1,2}))?$').firstMatch(t);
    if (m == null) return null;
    final y = int.tryParse(m.group(1) ?? '');
    final mo = int.tryParse(m.group(2) ?? '');
    final dRaw = m.group(3);
    final d = dRaw == null ? 1 : int.tryParse(dRaw);
    if (y == null || mo == null) return null;
    final day = d ?? 1;
    return DateTime(y, mo, day);
  }

  DateTime endOfMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0);
  }

  void applyAmount(String op, double value) {
    final v = value.abs();
    switch (op) {
      case '>=':
      case '>':
        filters.minAmountAbs = (filters.minAmountAbs == null)
            ? v
            : (filters.minAmountAbs! > v ? filters.minAmountAbs : v);
        break;
      case '<=':
      case '<':
        filters.maxAmountAbs = (filters.maxAmountAbs == null)
            ? v
            : (filters.maxAmountAbs! < v ? filters.maxAmountAbs : v);
        break;
      case '=':
        filters.minAmountAbs = v;
        filters.maxAmountAbs = v;
        break;
    }
  }

  void applyBenefitAmount(String op, double value) {
    final v = value.abs();
    switch (op) {
      case '>=':
      case '>':
        filters.minBenefit = (filters.minBenefit == null)
            ? v
            : (filters.minBenefit! > v ? filters.minBenefit : v);
        break;
      case '<=':
      case '<':
        filters.maxBenefit = (filters.maxBenefit == null)
            ? v
            : (filters.maxBenefit! < v ? filters.maxBenefit : v);
        break;
      case '=':
        filters.minBenefit = v;
        filters.maxBenefit = v;
        break;
    }
  }

  final freeTokens = <String>[];
  final tokens = input
      .split(RegExp(r'\s+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList(growable: false);

  for (final token in tokens) {
    // Type filters.
    if (token == '지출') {
      filters.types.add(TransactionType.expense);
      continue;
    }
    if (token == '수입') {
      filters.types.add(TransactionType.income);
      continue;
    }
    if (token == '예금' || token == '저축') {
      filters.types.add(TransactionType.savings);
      continue;
    }
    if (token == '반품' || token == '환불') {
      filters.types.add(TransactionType.refund);
      continue;
    }

    // Benefit / points filters.
    if (token == '혜택' || token == '혜택만') {
      filters.benefitOnly = true;
      continue;
    }
    if (token == '포인트' || token == '적립') {
      filters.pointsOnly = true;
      continue;
    }

    // Simulation mode shortcuts.
    if (token == '보수') {
      filters.annualRatePercent = 0;
      continue;
    }
    if (token == '공격') {
      filters.annualRatePercent = 5;
      continue;
    }

    // Prefix filters: key:value
    final kv = token.split(':');
    if (kv.length == 2) {
      final key = kv[0].trim();
      final value = kv[1].trim();
      if (value.isEmpty) {
        continue;
      }

      switch (key) {
        case '이자':
        case '금리':
        case 'rate':
        case 'r':
          final rate = parseAnnualRatePercent(value);
          if (rate != null) {
            filters.annualRatePercent = rate;
            continue;
          }
          break;
        case '카드':
        case '결제':
          filters.paymentContains.add(value);
          continue;
        case '마트':
        case '편의점':
        case '온라인':
        case '쇼핑몰':
        case '출처':
        case '매장':
          filters.storeContains.add(value);
          continue;
        case '카테고리':
        case '분류':
          filters.categoryContains.add(value);
          continue;
        case '항목':
        case '내용':
          filters.descriptionContains.add(value);
          continue;
        case '메모':
          filters.memoContains.add(value);
          continue;
        case '기간':
        case '날짜':
          // 기간:YYYY-MM-DD..YYYY-MM-DD  OR  기간:YYYY-MM..YYYY-MM
          final parts = value.split('..');
          if (parts.length == 2) {
            final start = parseYmd(parts[0]);
            final endRaw = parseYmd(parts[1]);
            if (start != null && endRaw != null) {
              final end = (parts[1].trim().length == 7)
                  ? endOfMonth(endRaw)
                  : endRaw;
              filters.startDate = start;
              filters.endDate = end;
              continue;
            }
          }
          // If parsing fails, keep it as free text.
          break;
        case '혜택':
          // 혜택:>=1000  (benefit total)
          final m = RegExp(r'^(>=|<=|>|<|=)(\d[\d,]*)$').firstMatch(value);
          if (m != null) {
            final op = m.group(1) ?? '';
            final numText = (m.group(2) ?? '').replaceAll(',', '');
            final amount = double.tryParse(numText);
            if (amount != null) {
              filters.benefitOnly = true;
              applyBenefitAmount(op, amount);
              continue;
            }
          }
          break;
      }
    }

    // Amount operators: >=10000, <=12000원
    final amountMatch = RegExp(
      r'^(>=|<=|>|<|=)(\d[\d,]*)(?:원)?$',
      unicode: true,
    ).firstMatch(token);
    if (amountMatch != null) {
      final op = amountMatch.group(1) ?? '';
      final numText = (amountMatch.group(2) ?? '').replaceAll(',', '');
      final amount = double.tryParse(numText);
      if (amount != null) {
        applyAmount(op, amount);
        continue;
      }
    }

    freeTokens.add(token);
  }

  return _TxSearchPlan(ftsQuery: freeTokens.join(' '), filters: filters);
}

Map<String, double> _benefitByTypeForSearch(Transaction tx) {
  final fromJson = tx.benefitByType;
  if (fromJson.isNotEmpty) {
    return fromJson;
  }
  return BenefitMemoUtils.parseBenefitByType(tx.memo);
}

bool _matchesAllContains(String haystack, List<String> needles) {
  final lower = haystack.toLowerCase();
  for (final n in needles) {
    if (!lower.contains(n.toLowerCase().trim())) {
      return false;
    }
  }
  return true;
}

bool _matchesTxFilters(Transaction tx, _TxSearchFilters f) {
  if (f.types.isNotEmpty && !f.types.contains(tx.type)) {
    return false;
  }

  if (f.minAmountAbs != null || f.maxAmountAbs != null) {
    final v = tx.amount.abs();
    if (f.minAmountAbs != null && v < f.minAmountAbs!) return false;
    if (f.maxAmountAbs != null && v > f.maxAmountAbs!) return false;
  }

  if (f.startDate != null || f.endDate != null) {
    final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
    if (f.startDate != null) {
      final s = DateTime(
        f.startDate!.year,
        f.startDate!.month,
        f.startDate!.day,
      );
      if (day.isBefore(s)) return false;
    }
    if (f.endDate != null) {
      final e = DateTime(f.endDate!.year, f.endDate!.month, f.endDate!.day);
      if (day.isAfter(e)) return false;
    }
  }

  if (f.paymentContains.isNotEmpty &&
      !_matchesAllContains(tx.paymentMethod, f.paymentContains)) {
    return false;
  }

  if (f.storeContains.isNotEmpty) {
    final storeText = '${tx.store ?? ''} ${tx.memo}';
    if (!_matchesAllContains(storeText, f.storeContains)) {
      return false;
    }
  }

  if (f.categoryContains.isNotEmpty) {
    final catText = '${tx.mainCategory} ${tx.subCategory ?? ''}';
    if (!_matchesAllContains(catText, f.categoryContains)) {
      return false;
    }
  }

  if (f.descriptionContains.isNotEmpty &&
      !_matchesAllContains(tx.description, f.descriptionContains)) {
    return false;
  }

  if (f.memoContains.isNotEmpty &&
      !_matchesAllContains(tx.memo, f.memoContains)) {
    return false;
  }

  if (f.benefitOnly ||
      f.pointsOnly ||
      f.minBenefit != null ||
      f.maxBenefit != null) {
    final byType = _benefitByTypeForSearch(tx);
    final total = byType.values.fold<double>(0, (a, b) => a + b);
    if (f.benefitOnly && total <= 0) return false;
    if (f.pointsOnly) {
      final hasPoints = byType.keys.any((k) {
        final key = k.toLowerCase();
        return key.contains('포인트') ||
            key.contains('적립') ||
            key.contains('point');
      });
      if (!hasPoints) return false;
    }
    if (f.minBenefit != null && total < f.minBenefit!) return false;
    if (f.maxBenefit != null && total > f.maxBenefit!) return false;
  }

  return true;
}

class _AccountStatsSearchScreenState extends State<AccountStatsSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = true;
  int _searchSeq = 0;
  List<_SearchResult> _results = const <_SearchResult>[];
  _TxSearchPlan? _lastPlan;

  static const int _fallbackScanMax = 2000;

  bool _tenYearAggLoading = false;
  double? _tenYearAggTotal;

  static const double _defaultAnnualRatePercent = 3.0;
  bool _pointProjectionLoading = false;
  double? _pointProjectionMonthlyBase;
  double? _pointProjectionFiveYear;
  double? _pointProjectionTenYear;
  double? _pointProjectionMonthlyBase3mAvg;
  double? _pointProjectionFiveYear3mAvg;
  double? _pointProjectionTenYear3mAvg;
  double? _pointProjectionMonthlyBase6mAvg;
  double? _pointProjectionFiveYear6mAvg;
  double? _pointProjectionTenYear6mAvg;
  double _pointProjectionAnnualRateUsed = _defaultAnnualRatePercent;

  final NumberFormat _currencyFormat = NumberFormats.currency;
  final DateFormat _dateFormat = DateFormatter.defaultDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await TransactionService().loadTransactions();
    await TransactionFtsIndexService().ensureIndexedFromPrefs();
    await TransactionBenefitMonthlyAggService().ensureAggregatedFromPrefs();
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _runSearch(TransactionService service, String rawQuery) {
    final seq = ++_searchSeq;
    final query = rawQuery.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const <_SearchResult>[];
        _lastPlan = null;
        _tenYearAggTotal = null;
        _tenYearAggLoading = false;
        _pointProjectionLoading = false;
        _pointProjectionMonthlyBase = null;
        _pointProjectionFiveYear = null;
        _pointProjectionTenYear = null;
        _pointProjectionMonthlyBase3mAvg = null;
        _pointProjectionFiveYear3mAvg = null;
        _pointProjectionTenYear3mAvg = null;
        _pointProjectionMonthlyBase6mAvg = null;
        _pointProjectionFiveYear6mAvg = null;
        _pointProjectionTenYear6mAvg = null;
        _pointProjectionAnnualRateUsed = _defaultAnnualRatePercent;
      });
      return;
    }

    final plan = _parseTxSearchPlan(query);
    setState(() => _lastPlan = plan);

    _maybeLoadTenYearAgg(seq, plan);
    _maybeLoadPointProjection(seq, plan);

    () async {
      final txs = service.getTransactions(widget.accountName);
      final byId = <String, Transaction>{for (final tx in txs) tx.id: tx};

      final matched = <_SearchResult>[];

      if (plan.ftsQuery.trim().isNotEmpty) {
        final hits = await TransactionFtsIndexService().search(
          accountName: widget.accountName,
          query: plan.ftsQuery,
          memoOnly: widget.memoOnly,
          limit: 500,
        );
        if (!mounted || seq != _searchSeq) return;

        for (final h in hits) {
          final tx = byId[h.transactionId];
          if (tx == null) continue;
          if (!_matchesTxFilters(tx, plan.filters)) continue;
          matched.add(
            _SearchResult(accountName: widget.accountName, transaction: tx),
          );
        }
      } else {
        // Filter-only query (e.g., ">=10000", "카드:신용카드")
        final sorted = List<Transaction>.from(txs)
          ..sort((a, b) => b.date.compareTo(a.date));
        final limited = sorted.length > _fallbackScanMax
            ? sorted.sublist(0, _fallbackScanMax)
            : sorted;

        for (final tx in limited) {
          if (!_matchesTxFilters(tx, plan.filters)) continue;
          matched.add(
            _SearchResult(accountName: widget.accountName, transaction: tx),
          );
        }
      }

      matched.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
      setState(() => _results = matched);
    }();
  }

  String _ym(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  bool _isBenefitQuery(_TxSearchPlan plan) {
    final f = plan.filters;
    return f.benefitOnly ||
        f.pointsOnly ||
        f.minBenefit != null ||
        f.maxBenefit != null;
  }

  double _effectiveAnnualRatePercent(_TxSearchPlan plan) {
    final v = plan.filters.annualRatePercent;
    if (v == null) return _defaultAnnualRatePercent;
    if (v < 0) return 0;
    return v;
  }

  double _futureValueMonthlyContribution(
    double monthlyContribution,
    double annualRatePercent,
    int months,
  ) {
    if (monthlyContribution <= 0) return 0;
    final annualRate = annualRatePercent / 100.0;
    final i = annualRate / 12.0;
    if (i == 0) {
      return monthlyContribution * months;
    }
    final factor = (math.pow(1 + i, months) - 1) / i;
    return monthlyContribution * factor.toDouble();
  }

  void _maybeLoadPointProjection(int seq, _TxSearchPlan plan) {
    if (widget.memoOnly || !plan.filters.pointsOnly) {
      setState(() {
        _pointProjectionLoading = false;
        _pointProjectionMonthlyBase = null;
        _pointProjectionFiveYear = null;
        _pointProjectionTenYear = null;
        _pointProjectionMonthlyBase3mAvg = null;
        _pointProjectionFiveYear3mAvg = null;
        _pointProjectionTenYear3mAvg = null;
        _pointProjectionMonthlyBase6mAvg = null;
        _pointProjectionFiveYear6mAvg = null;
        _pointProjectionTenYear6mAvg = null;
        _pointProjectionAnnualRateUsed = _defaultAnnualRatePercent;
      });
      return;
    }

    setState(() {
      _pointProjectionLoading = true;
      _pointProjectionMonthlyBase = null;
      _pointProjectionFiveYear = null;
      _pointProjectionTenYear = null;
      _pointProjectionMonthlyBase3mAvg = null;
      _pointProjectionFiveYear3mAvg = null;
      _pointProjectionTenYear3mAvg = null;
      _pointProjectionMonthlyBase6mAvg = null;
      _pointProjectionFiveYear6mAvg = null;
      _pointProjectionTenYear6mAvg = null;
      _pointProjectionAnnualRateUsed = _effectiveAnnualRatePercent(plan);
    });

    () async {
      final now = DateTime.now();
      final ym = _ym(now);

      final start3m = DateTime(now.year, now.month - 2, 1);
      final start3mYm = _ym(start3m);

      final start6m = DateTime(now.year, now.month - 5, 1);
      final start6mYm = _ym(start6m);

      await TransactionBenefitMonthlyAggService().ensureAggregatedFromPrefs();

      final a = await TransactionBenefitMonthlyAggService().sumTotal(
        accountName: widget.accountName,
        benefitTypeContains: '포인트',
        startYm: ym,
        endYm: ym,
      );
      final b = await TransactionBenefitMonthlyAggService().sumTotal(
        accountName: widget.accountName,
        benefitTypeContains: '적립',
        startYm: ym,
        endYm: ym,
      );
      final c = await TransactionBenefitMonthlyAggService().sumTotal(
        accountName: widget.accountName,
        benefitTypeContains: 'point',
        startYm: ym,
        endYm: ym,
      );
      final monthlyBase = a + b + c;

      final a3 = await TransactionBenefitMonthlyAggService().sumTotal(
        accountName: widget.accountName,
        benefitTypeContains: '포인트',
        startYm: start3mYm,
        endYm: ym,
      );
      final b3 = await TransactionBenefitMonthlyAggService().sumTotal(
        accountName: widget.accountName,
        benefitTypeContains: '적립',
        startYm: start3mYm,
        endYm: ym,
      );
      final c3 = await TransactionBenefitMonthlyAggService().sumTotal(
        accountName: widget.accountName,
        benefitTypeContains: 'point',
        startYm: start3mYm,
        endYm: ym,
      );
      final threeMonthAvg = (a3 + b3 + c3) / 3.0;

      final a6 = await TransactionBenefitMonthlyAggService().sumTotal(
        accountName: widget.accountName,
        benefitTypeContains: '포인트',
        startYm: start6mYm,
        endYm: ym,
      );
      final b6 = await TransactionBenefitMonthlyAggService().sumTotal(
        accountName: widget.accountName,
        benefitTypeContains: '적립',
        startYm: start6mYm,
        endYm: ym,
      );
      final c6 = await TransactionBenefitMonthlyAggService().sumTotal(
        accountName: widget.accountName,
        benefitTypeContains: 'point',
        startYm: start6mYm,
        endYm: ym,
      );
      final sixMonthAvg = (a6 + b6 + c6) / 6.0;

      final rate = _effectiveAnnualRatePercent(plan);
      final fiveYear = _futureValueMonthlyContribution(
        monthlyBase,
        rate,
        12 * 5,
      );
      final tenYear = _futureValueMonthlyContribution(
        monthlyBase,
        rate,
        12 * 10,
      );

      final fiveYear3 = _futureValueMonthlyContribution(
        threeMonthAvg,
        rate,
        12 * 5,
      );
      final tenYear3 = _futureValueMonthlyContribution(
        threeMonthAvg,
        rate,
        12 * 10,
      );

      final fiveYear6 = _futureValueMonthlyContribution(
        sixMonthAvg,
        rate,
        12 * 5,
      );
      final tenYear6 = _futureValueMonthlyContribution(
        sixMonthAvg,
        rate,
        12 * 10,
      );

      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _pointProjectionLoading = false;
        _pointProjectionMonthlyBase = monthlyBase;
        _pointProjectionFiveYear = fiveYear;
        _pointProjectionTenYear = tenYear;
        _pointProjectionMonthlyBase3mAvg = threeMonthAvg;
        _pointProjectionFiveYear3mAvg = fiveYear3;
        _pointProjectionTenYear3mAvg = tenYear3;
        _pointProjectionMonthlyBase6mAvg = sixMonthAvg;
        _pointProjectionFiveYear6mAvg = fiveYear6;
        _pointProjectionTenYear6mAvg = tenYear6;
        _pointProjectionAnnualRateUsed = rate;
      });
    }();
  }

  void _maybeLoadTenYearAgg(int seq, _TxSearchPlan plan) {
    if (widget.memoOnly) {
      setState(() {
        _tenYearAggTotal = null;
        _tenYearAggLoading = false;
      });
      return;
    }

    if (!_isBenefitQuery(plan)) {
      setState(() {
        _tenYearAggTotal = null;
        _tenYearAggLoading = false;
      });
      return;
    }

    setState(() {
      _tenYearAggLoading = true;
    });

    () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month - 119, 1);
      final startYm = _ym(start);
      final endYm = _ym(now);

      await TransactionBenefitMonthlyAggService().ensureAggregatedFromPrefs();

      double total;
      if (plan.filters.pointsOnly) {
        final a = await TransactionBenefitMonthlyAggService().sumTotal(
          accountName: widget.accountName,
          benefitTypeContains: '포인트',
          startYm: startYm,
          endYm: endYm,
        );
        final b = await TransactionBenefitMonthlyAggService().sumTotal(
          accountName: widget.accountName,
          benefitTypeContains: '적립',
          startYm: startYm,
          endYm: endYm,
        );
        final c = await TransactionBenefitMonthlyAggService().sumTotal(
          accountName: widget.accountName,
          benefitTypeContains: 'point',
          startYm: startYm,
          endYm: endYm,
        );
        total = a + b + c;
      } else {
        total = await TransactionBenefitMonthlyAggService().sumTotal(
          accountName: widget.accountName,
          startYm: startYm,
          endYm: endYm,
        );
      }

      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _tenYearAggTotal = total;
        _tenYearAggLoading = false;
      });
    }();
  }

  Widget _buildBenefitSummary(
    ThemeData theme, {
    required String query,
    required List<_SearchResult> results,
  }) {
    final plan = _lastPlan;
    if (plan == null) return const SizedBox.shrink();
    if (widget.memoOnly) return const SizedBox.shrink();
    if (query.isEmpty) return const SizedBox.shrink();

    final f = plan.filters;
    final isBenefitQuery = _isBenefitQuery(plan);
    if (!isBenefitQuery) return const SizedBox.shrink();

    var total = 0.0;
    var count = 0;

    bool isPointsKey(String key) {
      final k = key.toLowerCase();
      return k.contains('포인트') || k.contains('적립') || k.contains('point');
    }

    for (final r in results) {
      final tx = r.transaction;
      final byType = _benefitByTypeForSearch(tx);

      double sum;
      if (f.pointsOnly) {
        sum = byType.entries
            .where((e) => isPointsKey(e.key))
            .fold<double>(0, (a, e) => a + e.value);
      } else {
        sum = byType.values.fold<double>(0, (a, b) => a + b);
      }

      if (sum <= 0) continue;
      count += 1;
      total += sum;
    }

    final avg = count == 0 ? 0.0 : (total / count);
    final label = f.pointsOnly ? '포인트' : '혜택';
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final subStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final readableSubStyle = subStyle?.copyWith(height: 1.25);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$label 합계: ${_currencyFormat.format(total)}원',
                    style: valueStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text('건수: $count', style: subStyle),
                const SizedBox(width: 12),
                Text('평균: ${_currencyFormat.format(avg)}원', style: subStyle),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _tenYearAggLoading
                  ? '최근 10년 누적(계정 전체): 계산 중…'
                  : '최근 10년 누적(계정 전체): '
                        '${_currencyFormat.format(_tenYearAggTotal ?? 0)}원',
              style: subStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (f.pointsOnly) ...[
              const SizedBox(height: 6),
              Text(
                _buildPointProjectionHeadline(),
                style: readableSubStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!_pointProjectionLoading) ...[
                const SizedBox(height: 4),
                Text(
                  '현재(이번달) 선택이 미래를 만듭니다',
                  style: readableSubStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (!_pointProjectionLoading &&
                  (_pointProjectionMonthlyBase3mAvg ?? 0) > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _buildPointProjectionAverageLabel(
                    periodLabel: '최근 3개월',
                    base: _pointProjectionMonthlyBase3mAvg,
                    fiveYear: _pointProjectionFiveYear3mAvg,
                    tenYear: _pointProjectionTenYear3mAvg,
                  ),
                  style: readableSubStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (!_pointProjectionLoading &&
                  (_pointProjectionMonthlyBase6mAvg ?? 0) > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _buildPointProjectionAverageLabel(
                    periodLabel: '최근 6개월',
                    base: _pointProjectionMonthlyBase6mAvg,
                    fiveYear: _pointProjectionFiveYear6mAvg,
                    tenYear: _pointProjectionTenYear6mAvg,
                  ),
                  style: readableSubStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _buildPointProjectionHeadline() {
    final annualRate = _pointProjectionAnnualRateUsed.toStringAsFixed(0);
    if (_pointProjectionLoading) {
      return '이번달(최우선) 포인트 기반 5/10년 예상(연 '
          '$annualRate%): 계산 중…';
    }

    final base = _pointProjectionMonthlyBase ?? 0;
    if (base <= 0) {
      return '이번달(최우선) 포인트 기반 5/10년 예상(연 '
          '$annualRate%): 0원';
    }

    final monthlyLabel = '${_currencyFormat.format(base)}원';
    final fiveYearLabel =
        '${_currencyFormat.format(_pointProjectionFiveYear ?? 0)}원';
    final tenYearLabel =
        '${_currencyFormat.format(_pointProjectionTenYear ?? 0)}원';

    return '이번달(최우선) 포인트 $monthlyLabel → 5년(연 '
        '$annualRate%): $fiveYearLabel · 10년: $tenYearLabel';
  }

  String _buildPointProjectionAverageLabel({
    required String periodLabel,
    required double? base,
    required double? fiveYear,
    required double? tenYear,
  }) {
    final baseLabel = '${_currencyFormat.format(base ?? 0)}원';
    final fiveYearLabel = '${_currencyFormat.format(fiveYear ?? 0)}원';
    final tenYearLabel = '${_currencyFormat.format(tenYear ?? 0)}원';

    return '참고(과거) $periodLabel 평균 $baseLabel → '
        '5년: $fiveYearLabel · 10년: $tenYearLabel';
  }

  String _formatSignedAmount(Transaction tx) {
    return '${tx.type.sign}${_currencyFormat.format(tx.amount)}원';
  }

  String _searchResultSubtitle(_SearchResult result) {
    final formattedDate = _dateFormat.format(result.transaction.date);
    return '${result.accountName} · $formattedDate';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final service = TransactionService();
    final query = _searchController.text.trim();
    final results = _isLoading ? const <_SearchResult>[] : _results;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.memoOnly ? '메모 검색' : '거래 검색')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 26),
                    hintText: widget.memoOnly
                        ? '현재 계정 메모에서 검색'
                        : '예: 카드:신용카드 마트:대형마트 카테고리:식비 >=10000'
                              ' 기간:2025-12..2025-12',
                    border: const OutlineInputBorder(),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _runSearch(service, '');
                            },
                          ),
                  ),
                  onChanged: (value) => _runSearch(service, value),
                ),
                const SizedBox(height: 8),
                _buildBenefitSummary(theme, query: query, results: results),
                if (!_isLoading && query.isNotEmpty) const SizedBox(height: 8),
                if (!widget.memoOnly) const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : query.isEmpty
                      ? const Center(child: Text('검색어를 입력하세요.'))
                      : results.isEmpty
                      ? const Center(child: Text('검색 결과가 없습니다.'))
                      : ListView.separated(
                          itemCount: results.length > 50 ? 50 : results.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final result = results[index];
                            final tx = result.transaction;
                            final subtitle = _searchResultSubtitle(result);
                            final subtitleStyle = theme.textTheme.bodySmall
                                ?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                );
                            if (!isLandscape) {
                              return ListTile(
                                leading: Icon(
                                  _iconForType(tx.type),
                                  color: _colorForType(tx.type, theme),
                                ),
                                title: Text(tx.description),
                                subtitle: Text(subtitle, style: subtitleStyle),
                                trailing: Text(_formatSignedAmount(tx)),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _iconForType(tx.type),
                                    size: 18,
                                    color: _colorForType(tx.type, theme),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      tx.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 7,
                                    child: Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: subtitleStyle,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      _formatSignedAmount(tx),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Color _colorForType(TransactionType type, ThemeData theme) {
    switch (type) {
      case TransactionType.income:
      case TransactionType.refund:
        return theme.colorScheme.primary;
      case TransactionType.savings:
        return Colors.amber[700] ?? theme.colorScheme.secondary;
      case TransactionType.expense:
        return theme.colorScheme.error;
    }
  }
}

class _MonthlySummary {
  const _MonthlySummary({
    required this.month,
    required this.total,
    required this.count,
  });

  final DateTime month;
  final double total;
  final int count;
}

class _YearSummary {
  const _YearSummary({
    required this.year,
    required this.total,
    required this.count,
  });

  final int year;
  final double total;
  final int count;
}

class _ChartPoint {
  const _ChartPoint({required this.month, required this.total});

  final DateTime month;
  final double total;
}

class _SummaryTotals {
  const _SummaryTotals({
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

class _StoreProductAcc {
  String name;
  int count = 0;
  double total = 0;

  _StoreProductAcc({required this.name});
}

class _StoreProductStat {
  final String name;
  final int count;
  final double total;

  const _StoreProductStat({
    required this.name,
    required this.count,
    required this.total,
  });
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.children});

  final List<_SummaryCard> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children
          .map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: card,
            ),
          )
          .toList(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: valueColor ?? theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: valueColor ?? theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResult {
  const _SearchResult({required this.accountName, required this.transaction});

  final String accountName;
  final Transaction transaction;
}

class _PeriodDetailScreen extends StatefulWidget {
  const _PeriodDetailScreen({required this.accountName, required this.view});

  final String accountName;
  final _StatsView view;

  @override
  State<_PeriodDetailScreen> createState() => _PeriodDetailScreenState();
}

class _PeriodDetailScreenState extends State<_PeriodDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormats.currency;
  final DateFormat _dateFormat = DateFormatter.defaultDate;
  final DateFormat _monthLabelFormat = DateFormatter.monthLabel;

  late DateTime _currentMonth;
  late int _currentYear;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _currentYear = now.year;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.view) {
      case _StatsView.month:
        return '1달 통계';
      case _StatsView.quarter:
        return '3개월 통계';
      case _StatsView.halfYear:
        return '6개월 통계';
      case _StatsView.year:
        return '1년 통계';
      case _StatsView.decade:
        return '10년 통계';
      default:
        return '기간 통계';
    }
  }

  DateTimeRange _rangeForView() {
    switch (widget.view) {
      case _StatsView.month:
        final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
        final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
        return DateTimeRange(start: start, end: end);
      case _StatsView.quarter:
        final start = DateTime(_currentMonth.year, _currentMonth.month - 2, 1);
        final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
        return DateTimeRange(start: start, end: end);
      case _StatsView.halfYear:
        final start = DateTime(_currentMonth.year, _currentMonth.month - 5, 1);
        final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
        return DateTimeRange(start: start, end: end);
      case _StatsView.year:
        final start = DateTime(_currentYear, 1, 1);
        final end = DateTime(_currentYear, 12, 31);
        return DateTimeRange(start: start, end: end);
      case _StatsView.decade:
        final startYear = _currentYear - 9;
        final start = DateTime(startYear, 1, 1);
        final end = DateTime(_currentYear, 12, 31);
        return DateTimeRange(start: start, end: end);
      default:
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return DateTimeRange(start: start, end: end);
    }
  }

  List<Transaction> _filterByRangeAndQuery(
    List<Transaction> all,
    DateTimeRange range,
  ) {
    final lower = _query.toLowerCase();
    return all.where((tx) {
      final inRange =
          !tx.date.isBefore(range.start) && !tx.date.isAfter(range.end);

      if (!inRange) return false;

      if (lower.isEmpty) return true;

      return tx.description.toLowerCase().contains(lower) ||
          tx.memo.toLowerCase().contains(lower) ||
          tx.paymentMethod.toLowerCase().contains(lower);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  String _formatSignedAmount(Transaction tx) {
    return '${tx.type.sign}${_currencyFormat.format(tx.amount)}원';
  }

  void _goPrev() {
    setState(() {
      switch (widget.view) {
        case _StatsView.month:
        case _StatsView.quarter:
        case _StatsView.halfYear:
          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
          _currentYear = _currentMonth.year;
          break;
        case _StatsView.year:
        case _StatsView.decade:
          _currentYear -= 1;
          _currentMonth = DateTime(_currentYear, _currentMonth.month);
          break;
        default:
          break;
      }
    });
  }

  void _goNext() {
    setState(() {
      switch (widget.view) {
        case _StatsView.month:
        case _StatsView.quarter:
        case _StatsView.halfYear:
          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
          _currentYear = _currentMonth.year;
          break;
        case _StatsView.year:
        case _StatsView.decade:
          _currentYear += 1;
          _currentMonth = DateTime(_currentYear, _currentMonth.month);
          break;
        default:
          break;
      }
    });
  }

  String _rangeLabel(DateTimeRange range) {
    final df = DateFormatter.defaultDate;
    return '${df.format(range.start)} ~ ${df.format(range.end)}';
  }

  String _referencePeriodLabel() {
    if (widget.view == _StatsView.year || widget.view == _StatsView.decade) {
      return '기준 연도: $_currentYear년';
    }
    final monthLabel = _monthLabelFormat.format(_currentMonth);
    return '기준 월: $monthLabel';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final service = TransactionService();
    final all = service.getTransactions(widget.accountName);
    final range = _rangeForView();
    final filtered = _filterByRangeAndQuery(all, range);
    final referenceLabel = _referencePeriodLabel();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '거래 검색 (내용/메모/결제수단)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _goPrev,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _rangeLabel(range),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          referenceLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _goNext,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        '해당 기간에 표시할 거래가 없습니다.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : (isLandscape
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        '내용',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 7,
                                      child: Text(
                                        '날짜 · 메모',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '금액',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final tx = filtered[index];
                                    final icon =
                                        tx.type == TransactionType.income
                                        ? Icons.trending_up
                                        : tx.type == TransactionType.expense
                                        ? Icons.trending_down
                                        : Icons.savings;
                                    final color =
                                        tx.type == TransactionType.income
                                        ? theme.colorScheme.primary
                                        : tx.type == TransactionType.expense
                                        ? theme.colorScheme.error
                                        : (Colors.amber[700] ??
                                              theme.colorScheme.secondary);
                                    final subtitleStyle = theme
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        );
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(icon, size: 18, color: color),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 5,
                                            child: Text(
                                              tx.description,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 7,
                                            child: Text(
                                              '${_dateFormat.format(tx.date)} '
                                              '· '
                                              '${tx.memo}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: subtitleStyle,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              _formatSignedAmount(tx),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end,
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final tx = filtered[index];
                              return ListTile(
                                leading: Icon(
                                  tx.type == TransactionType.income
                                      ? Icons.trending_up
                                      : tx.type == TransactionType.expense
                                      ? Icons.trending_down
                                      : Icons.savings,
                                  color: tx.type == TransactionType.income
                                      ? theme.colorScheme.primary
                                      : tx.type == TransactionType.expense
                                      ? theme.colorScheme.error
                                      : Colors.amber[700],
                                ),
                                title: Text(tx.description),
                                subtitle: Text(
                                  '${_dateFormat.format(tx.date)} · '
                                  '${tx.memo}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Text(_formatSignedAmount(tx)),
                              );
                            },
                          )),
            ),
          ],
        ),
      ),
    );
  }
}
