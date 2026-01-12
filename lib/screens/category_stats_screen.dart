library category_stats_screen;

import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/stats_calculator.dart';
import '../widgets/background_widget.dart';
import '../widgets/category_pie_chart.dart';
import '../utils/period_utils.dart' as period;
import '../utils/date_formats.dart';
import '../utils/currency_formatter.dart';
import '../utils/chart_colors.dart';

part 'category_stats_screen_builders.dart';

/// 카테고리별 분석 화면
///
/// AccountStatsScreen에서 분리한 카테고리 통계 기능
class CategoryStatsScreen extends StatefulWidget {
  final String accountName;
  final bool isSubCategory;
  final DateTime? initialDate;
  final period.PeriodType periodType;

  const CategoryStatsScreen({
    super.key,
    required this.accountName,
    this.isSubCategory = false,
    this.initialDate,
    this.periodType = period.PeriodType.month,
  });

  @override
  State<CategoryStatsScreen> createState() => _CategoryStatsScreenState();
}

class _CategoryStatsScreenState extends State<CategoryStatsScreen> {
  late DateTime _anchorDate;
  TransactionType _selectedType = TransactionType.expense;
  List<Transaction> _allTransactions = [];
  bool _loading = true;
  late bool _isSubCategory;

  @override
  void initState() {
    super.initState();
    _anchorDate = widget.initialDate ?? DateTime.now();
    _isSubCategory = widget.isSubCategory;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await TransactionService().loadTransactions();
    final transactions = TransactionService().getTransactions(
      widget.accountName,
    );
    if (!mounted) return;
    setState(() {
      _allTransactions = transactions;
      _loading = false;
    });
  }

  void _changePeriod(int delta) {
    setState(() {
      switch (widget.periodType) {
        case period.PeriodType.week:
          _anchorDate = _anchorDate.add(Duration(days: 7 * delta));
          break;
        case period.PeriodType.month:
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + delta);
          break;
        case period.PeriodType.quarter:
          _anchorDate = DateTime(
            _anchorDate.year,
            _anchorDate.month + (3 * delta),
          );
          break;
        case period.PeriodType.halfYear:
          _anchorDate = DateTime(
            _anchorDate.year,
            _anchorDate.month + (6 * delta),
          );
          break;
        case period.PeriodType.year:
          _anchorDate = DateTime(_anchorDate.year + delta, _anchorDate.month);
          break;
        case period.PeriodType.decade:
          _anchorDate = DateTime(
            _anchorDate.year + (10 * delta),
            _anchorDate.month,
          );
          break;
      }
    });
  }

  void _changeType(TransactionType type) {
    setState(() => _selectedType = type);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<Color>(
      valueListenable: BackgroundHelper.colorNotifier,
      builder: (context, bgColor, _) {
        if (_loading) {
          return Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(title: const Text('카테고리 분석')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final range = period.PeriodUtils.getPeriodRange(
          widget.periodType,
          baseDate: _anchorDate,
        );
        final filteredTransactions = StatsCalculator.filterByRange(
          _allTransactions,
          range.start,
          range.end,
        );
        final categoryStats = _isSubCategory
            ? StatsCalculator.calculateSubCategoryStats(
                filteredTransactions,
                _selectedType,
              )
            : StatsCalculator.calculateCategoryStats(
                filteredTransactions,
                _selectedType,
              );

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(_isSubCategory ? '소분류 분석' : '대분류 분석'),
            actions: [
              IconButton(
                icon: Icon(
                  _isSubCategory ? Icons.category : Icons.account_tree,
                ),
                onPressed: () {
                  setState(() {
                    _isSubCategory = !_isSubCategory;
                  });
                },
                tooltip: _isSubCategory ? '대분류로 전환' : '소분류로 전환',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: '새로고침',
              ),
            ],
          ),
          body: Column(
            children: [
              // 기간 선택기
              _buildPeriodSelector(theme, range),
              // 타입 선택기
              _buildTypeSelector(theme),
              const SizedBox(height: 16),
              // 차트
              if (categoryStats.isNotEmpty)
                CategoryPieChart(categoryStats: categoryStats),
              const Divider(),
              // 카테고리 목록
              Expanded(
                child: categoryStats.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildCategoryList(categoryStats, theme),
              ),
            ],
          ),
        );
      },
    );
  }
}

