import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/chart_colors.dart';
import '../utils/date_formats.dart';
import '../utils/stats_calculator.dart';
import '../utils/utils.dart';
import '../widgets/background_widget.dart';
import '../widgets/category_pie_chart.dart';
import '../utils/period_utils.dart' as period;

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

  Widget _buildPeriodSelector(ThemeData theme, period.DateTimeRange range) {
    String label = '';
    final df = DateFormats.monthDayLabel;
    final mf = DateFormats.yMLabel;

    switch (widget.periodType) {
      case period.PeriodType.week:
        label = '${df.format(range.start)} ~ ${df.format(range.end)}';
        break;
      case period.PeriodType.month:
        label = mf.format(_anchorDate);
        break;
      case period.PeriodType.quarter:
        final quarter = ((_anchorDate.month - 1) ~/ 3) + 1;
        label = '${_anchorDate.year}년 $quarter분기';
        break;
      case period.PeriodType.halfYear:
        final half = _anchorDate.month <= 6 ? '상반기' : '하반기';
        label = '${_anchorDate.year}년 $half';
        break;
      case period.PeriodType.year:
        label = '${_anchorDate.year}년';
        break;
      case period.PeriodType.decade:
        final startYear = (_anchorDate.year ~/ 10) * 10;
        label = '$startYear ~ ${startYear + 9}';
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changePeriod(-1),
          ),
          Text(label, style: theme.textTheme.titleLarge),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changePeriod(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('지출'),
                  icon: Icon(Icons.trending_down),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('수입'),
                  icon: Icon(Icons.trending_up),
                ),
                ButtonSegment(
                  value: TransactionType.savings,
                  label: Text('예금'),
                  icon: Icon(Icons.savings),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<TransactionType> selected) {
                if (selected.isNotEmpty) {
                  _changeType(selected.first);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '카테고리가 없습니다',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    List<CategoryStats> categoryStats,
    ThemeData theme,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categoryStats.length,
      itemBuilder: (context, index) {
        final stats = categoryStats[index];
        final color = ChartColors.getColorForIndex(index, theme);

        if (isLandscape) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(
                      _getIconForCategory(stats.category),
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: Text(
                      stats.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${stats.count}건',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      CurrencyFormatter.format(stats.total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stats.percentage.toStringAsFixed(1)}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(
                    _getIconForCategory(stats.category),
                    color: color,
                    size: 20,
                  ),
                ),
                title: Text(
                  stats.category,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('${stats.count}건'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(stats.total),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '${stats.percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // 퍼센트 바
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.percentage / 100,
                    minHeight: 8,
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForCategory(String category) {
    // 카테고리별 아이콘 매핑 (간단한 버전)
    final iconMap = {
      '식비': Icons.restaurant,
      '교통': Icons.directions_car,
      '쇼핑': Icons.shopping_cart,
      '문화': Icons.movie,
      '의료': Icons.local_hospital,
      '교육': Icons.school,
      '주거': Icons.home,
      '통신': Icons.phone,
      '기타': Icons.more_horiz,
    };
    return iconMap[category] ?? Icons.category;
  }
}
