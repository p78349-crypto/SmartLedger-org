import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/date_formats.dart';
import '../utils/refund_utils.dart';
import '../utils/stats_calculator.dart';
import '../utils/utils.dart';

/// 월별 통계 화면 (단순화된 버전)
///
/// AccountStatsScreen에서 분리한 월별 통계 기능
class MonthlyStatsScreen extends StatefulWidget {
  final String accountName;

  const MonthlyStatsScreen({super.key, required this.accountName});

  @override
  State<MonthlyStatsScreen> createState() => _MonthlyStatsScreenState();
}

class _MonthlyStatsScreenState extends State<MonthlyStatsScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  TransactionType _selectedType = TransactionType.expense;
  List<Transaction> _allTransactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('월별 통계')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final monthTransactions = StatsCalculator.filterByMonth(
      _allTransactions,
      _currentMonth,
    );
    final typeTransactions = StatsCalculator.filterByType(
      monthTransactions,
      _selectedType,
    );
    final total = StatsCalculator.calculateTotal(typeTransactions);
    final dailyStats = StatsCalculator.calculateDailyStats(
      _allTransactions,
      _selectedType,
      _currentMonth,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('월별 통계'),
        actions: [
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
          // 요약
          _buildSummary(theme, total, typeTransactions.length),
          const Divider(),
          // 일별 목록
          Expanded(
            child: dailyStats.isEmpty
                ? _buildEmptyState(theme)
                : _buildDailyList(dailyStats, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
                ButtonSegment(
                  value: TransactionType.refund,
                  label: Text('환급'),
                  icon: Icon(RefundUtils.icon),
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

  Widget _buildSummary(ThemeData theme, double total, int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            CurrencyFormatter.format(total),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getTypeColor(_selectedType, theme),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count건의 거래',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
            Icons.insert_chart_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '거래 내역이 없습니다',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyList(List<DailyStats> dailyStats, ThemeData theme) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final typeColor = _getTypeColor(_selectedType, theme);

    if (!isLandscape) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dailyStats.length,
        itemBuilder: (context, index) {
          final stats = dailyStats[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: typeColor.withValues(alpha: 0.2),
                child: Text(
                  '${stats.date.day}',
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                DateFormatter.formatMonthDay(stats.date),
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text('${stats.transactions.length}건'),
              trailing: Text(
                CurrencyFormatter.format(stats.total),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
            ),
          );
        },
      );
    }

    Widget headerCell(String text, {required int flex, TextAlign? align}) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    Widget rowCell(
      String text, {
      required int flex,
      TextAlign? align,
      TextStyle? style,
    }) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: style,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              headerCell('일자', flex: 4),
              headerCell('건수', flex: 2, align: TextAlign.end),
              headerCell('합계', flex: 4, align: TextAlign.end),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: dailyStats.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final stats = dailyStats[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    rowCell(
                      DateFormatter.formatMonthDay(stats.date),
                      flex: 4,
                      style: theme.textTheme.bodyMedium,
                    ),
                    rowCell(
                      '${stats.transactions.length}건',
                      flex: 2,
                      align: TextAlign.end,
                      style: theme.textTheme.bodyMedium,
                    ),
                    rowCell(
                      CurrencyFormatter.format(stats.total),
                      flex: 4,
                      align: TextAlign.end,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(TransactionType type, ThemeData theme) {
    switch (type) {
      case TransactionType.expense:
        return theme.colorScheme.error;
      case TransactionType.income:
        return Colors.green;
      case TransactionType.savings:
        return Colors.blue;
      case TransactionType.refund:
        return RefundUtils.color;
    }
  }
}
