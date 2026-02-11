import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fixed_cost.dart';
import '../models/transaction.dart';
import '../services/fixed_cost_service.dart';
import '../services/transaction_service.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formats.dart';
import '../utils/refund_utils.dart';
import '../utils/stats_labels.dart';

part 'chart_detail_screen_build.dart';
part 'chart_detail_screen_charts.dart';

enum ChartType { bar, line, pie }

class ChartDetailScreen extends StatefulWidget {
  final String accountName;
  final TransactionType transactionType;

  const ChartDetailScreen({
    super.key,
    required this.accountName,
    required this.transactionType,
  });

  @override
  State<ChartDetailScreen> createState() => _ChartDetailScreenState();
}

class _ChartDetailScreenState extends State<ChartDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormats.currency;
  final NumberFormat _compactNumberFormat = NumberFormats.currencyCompactKo;
  final DateFormat _rangeMonthFormat = DateFormatter.rangeMonth;

  ChartType _chartType = ChartType.bar;
  DateTime _anchorMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;
  List<FixedCost> _fixedCosts = const [];
  bool _includeFixedCosts = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await TransactionService().loadTransactions();
    await FixedCostService().loadFixedCosts();
    final costs = FixedCostService().getFixedCosts(widget.accountName);
    if (!mounted) return;
    setState(() {
      _fixedCosts = costs;
      _isLoading = false;
    });
  }

  String get _typeLabel {
    switch (widget.transactionType) {
      case TransactionType.expense:
        return '지출';
      case TransactionType.income:
        return '수입';
      case TransactionType.savings:
        return '예금';
      case TransactionType.refund:
        return '반품';
    }
  }

  Color _getTypeColor(ThemeData theme) {
    switch (widget.transactionType) {
      case TransactionType.expense:
        return theme.colorScheme.error;
      case TransactionType.income:
        return theme.colorScheme.primary;
      case TransactionType.savings:
        return Colors.amber[800]!;
      case TransactionType.refund:
        return RefundUtils.color;
    }
  }

  List<DateTime> _getChartMonths() {
    final service = TransactionService();
    final transactions = service.getTransactions(widget.accountName);

    if (transactions.isNotEmpty) {
      final sortedTransactions = transactions.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final firstTransactionDate = sortedTransactions.first.date;
      final firstMonth = DateTime(
        firstTransactionDate.year,
        firstTransactionDate.month,
      );

      final currentMonth = _anchorMonth;

      final monthsDiff =
          (currentMonth.year - firstMonth.year) * 12 +
          (currentMonth.month - firstMonth.month) +
          1;

      final displayMonths = monthsDiff > 12 ? 12 : monthsDiff;

      return List.generate(displayMonths, (index) {
        final offset = displayMonths - 1 - index;
        return DateTime(currentMonth.year, currentMonth.month - offset);
      });
    }

    return List.generate(12, (index) {
      final offset = 11 - index;
      return DateTime(_anchorMonth.year, _anchorMonth.month - offset);
    });
  }

  List<MapEntry<DateTime, double>> _getChartData() {
    final months = _getChartMonths();
    final service = TransactionService();
    final transactions = service.getTransactions(widget.accountName);

    return months.map((month) {
      final monthTransactions = transactions.where(
        (tx) =>
            tx.type == widget.transactionType &&
            tx.date.year == month.year &&
            tx.date.month == month.month,
      );

      var total = monthTransactions.fold<double>(
        0.0,
        (sum, tx) => sum + tx.amount,
      );

      if (_includeFixedCosts &&
          _fixedCosts.isNotEmpty &&
          widget.transactionType == TransactionType.expense) {
        final monthlyCost = _fixedCosts.fold<double>(
          0.0,
          (sum, fc) => sum + fc.amount,
        );
        total += monthlyCost;
      }

      return MapEntry(month, total);
    }).toList();
  }

  void _previousPeriod() {
    setState(() {
      _anchorMonth = DateTime(_anchorMonth.year, _anchorMonth.month - 1);
    });
  }

  void _nextPeriod() {
    setState(() {
      _anchorMonth = DateTime(_anchorMonth.year, _anchorMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) => _buildContent(context);
}
