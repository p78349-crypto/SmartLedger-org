library monthly_stats_screen;

import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/stats_calculator.dart';
import 'category_stats_screen.dart';
import '../utils/date_formats.dart';
import '../utils/date_formatter.dart';
import '../utils/currency_formatter.dart';
import '../utils/refund_utils.dart';

part 'monthly_stats_screen_builders.dart';

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
      floatingActionButton: Transform.translate(
        // Moved down slightly as requested
        offset: const Offset(0, 5),
        child: SizedBox(
          width: 160,
          height: 120,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Positioned(
                right: 0,
                bottom: 0,
                child: FloatingActionButton(
                  heroTag: 'monthly_stats_trend',
                  // Changed shape to Rounded Rectangle with border
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CategoryStatsScreen(
                          accountName: widget.accountName,
                          initialDate: _currentMonth,
                        ),
                      ),
                    );
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: Icon(
                    Icons.trending_up,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Positioned(
                right: 72,
                bottom: 0,
                child: FloatingActionButton(
                  heroTag: 'monthly_stats_bar',
                  // Changed shape to Rounded Rectangle with border
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CategoryStatsScreen(
                          accountName: widget.accountName,
                          isSubCategory: true,
                          initialDate: _currentMonth,
                        ),
                      ),
                    );
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: Icon(
                    Icons.bar_chart,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

