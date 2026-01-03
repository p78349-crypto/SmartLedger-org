import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/date_formats.dart';
import 'package:smart_ledger/utils/stats_calculator.dart';
import 'package:smart_ledger/utils/utils.dart';
import 'package:smart_ledger/widgets/background_widget.dart';

/// 카테고리별 분석 화면
///
/// AccountStatsScreen에서 분리한 카테고리 통계 기능
class CategoryStatsScreen extends StatefulWidget {
  final String accountName;
  final bool isSubCategory;
  final DateTime? initialMonth;

  const CategoryStatsScreen({
    super.key,
    required this.accountName,
    this.isSubCategory = false,
    this.initialMonth,
  });

  @override
  State<CategoryStatsScreen> createState() => _CategoryStatsScreenState();
}

class _CategoryStatsScreenState extends State<CategoryStatsScreen> {
  late DateTime _currentMonth;
  TransactionType _selectedType = TransactionType.expense;
  List<Transaction> _allTransactions = [];
  bool _loading = true;
  late bool _isSubCategory;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth ??
        DateTime(DateTime.now().year, DateTime.now().month);
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

  void _changeMonth(int months) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + months,
      );
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

        final monthTransactions = StatsCalculator.filterByMonth(
          _allTransactions,
          _currentMonth,
        );
        final categoryStats = _isSubCategory
            ? StatsCalculator.calculateSubCategoryStats(
                monthTransactions,
                _selectedType,
              )
            : StatsCalculator.calculateCategoryStats(
                monthTransactions,
                _selectedType,
              );

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(_isSubCategory ? '소분류 분석' : '대분류 분석'),
            actions: [
              IconButton(
                icon: Icon(_isSubCategory ? Icons.category : Icons.account_tree),
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
              // 월 선택기
              _buildMonthSelector(theme),
              // 타입 선택기
              _buildTypeSelector(theme),
              const SizedBox(height: 16),
              // 차트
              if (categoryStats.isNotEmpty) _buildChart(categoryStats, theme),
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

  Widget _buildChart(List<CategoryStats> categoryStats, ThemeData theme) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: categoryStats.asMap().entries.map((entry) {
            final index = entry.key;
            final stats = entry.value;
            const fontSize = 12.0;
            const radius = 50.0;

            return PieChartSectionData(
              color: _getColorForIndex(index, theme),
              value: stats.total,
              title: stats.percentage > 5
                  ? '${stats.percentage.toStringAsFixed(0)}%'
                  : '',
              radius: radius,
              titleStyle: const TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormats.yMLabel.format(_currentMonth),
            style: theme.textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
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
        final color = _getColorForIndex(index, theme);

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

  Color _getColorForIndex(int index, ThemeData theme) {
    final scheme = theme.colorScheme;

    // 상위 10/20/21 색상 구분
    if (index < 10) {
      // 상위 1-10: 강조색 (Primary 계열)
      final colors = [
        scheme.primary,
        Colors.blue,
        Colors.indigo,
        Colors.cyan,
        Colors.teal,
        Colors.green,
        Colors.lightGreen,
        Colors.lime,
        Colors.yellow,
        Colors.amber,
      ];
      return colors[index % colors.length];
    } else if (index < 20) {
      // 상위 11-20: 보조색 (Secondary 계열)
      final colors = [
        scheme.secondary,
        Colors.orange,
        Colors.deepOrange,
        Colors.red,
        Colors.pink,
        Colors.purple,
        Colors.deepPurple,
        Colors.brown,
        Colors.blueGrey,
        Colors.grey,
      ];
      return colors[(index - 10) % colors.length];
    } else {
      // 21위 이상: 기타색 (Tertiary 계열)
      final colors = [
        scheme.tertiary,
        scheme.outline,
        scheme.onSurfaceVariant,
      ];
      return colors[(index - 20) % colors.length];
    }
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
