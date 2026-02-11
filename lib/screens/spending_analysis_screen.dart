import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/chart_colors.dart';
import '../utils/number_formats.dart';
import '../utils/period_utils.dart' as period;
import '../utils/saving_tips_utils.dart';
import '../utils/spending_analysis_utils.dart';
import '../widgets/background_widget.dart';

part 'spending_analysis_screen_period_common.dart';
part 'spending_analysis_screen_top_spending.dart';
part 'spending_analysis_screen_recurring.dart';
part 'spending_analysis_screen_tips.dart';

/// 지출 분석 + 절약 팁 화면
///
/// TOP 5 지출 항목, 반복 지출 패턴, 맞춤형 절약 팁을 제공합니다.
class SpendingAnalysisScreen extends StatefulWidget {
  final String accountName;
  final DateTime? initialDate;

  const SpendingAnalysisScreen({
    super.key,
    required this.accountName,
    this.initialDate,
  });

  @override
  State<SpendingAnalysisScreen> createState() => _SpendingAnalysisScreenState();
}

class _SpendingAnalysisScreenState extends State<SpendingAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _anchorDate;
  List<Transaction> _allTransactions = [];
  bool _loading = true;
  period.PeriodType _periodType = period.PeriodType.month;

  final NumberFormat _currencyFormat = NumberFormats.currency;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _anchorDate = widget.initialDate ?? DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      switch (_periodType) {
        case period.PeriodType.week:
          _anchorDate = _anchorDate.add(Duration(days: 7 * delta));
          break;
        case period.PeriodType.month:
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + delta);
          break;
        case period.PeriodType.quarter:
        case period.PeriodType.halfYear:
        case period.PeriodType.year:
        case period.PeriodType.decade:
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + delta);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<Color>(
      valueListenable: BackgroundHelper.colorNotifier,
      builder: (context, bgColor, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text('지출 분석 & 절약 팁'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.bar_chart), text: 'TOP 지출'),
                Tab(icon: Icon(Icons.repeat), text: '반복 패턴'),
                Tab(icon: Icon(Icons.lightbulb), text: '절약 팁'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: '새로고침',
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    buildPeriodSelector(theme),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          buildTopSpendingTab(theme),
                          buildRecurringPatternTab(theme),
                          buildSavingTipsTab(theme),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
