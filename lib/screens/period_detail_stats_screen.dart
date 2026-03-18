import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fixed_cost.dart';
import '../models/transaction.dart';
import '../services/fixed_cost_service.dart';
import '../services/transaction_service.dart';
import '../utils/date_formatter.dart';
import '../utils/localized_date_formatter.dart';
import '../utils/number_formats.dart';
import '../utils/period_utils.dart' as period;
import '../utils/refund_utils.dart';
import '../utils/stats_labels.dart';
import '../utils/transaction_aggregation_utils.dart';

part 'period_detail_stats_screen_data.dart';
part 'period_detail_stats_screen_ui.dart';

class PeriodDetailStatsScreen extends StatefulWidget {
  final String accountName;
  final period.PeriodType periodType;
  final TransactionType transactionType;

  const PeriodDetailStatsScreen({
    super.key,
    required this.accountName,
    required this.periodType,
    required this.transactionType,
  });

  @override
  State<PeriodDetailStatsScreen> createState() =>
      _PeriodDetailStatsScreenState();
}

class _PeriodDetailStatsScreenState extends State<PeriodDetailStatsScreen> {
  final NumberFormat _currencyFormat = NumberFormats.currency;
  final DateFormat _dateFormat = DateFormatter.defaultDate;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _currentYear = DateTime.now().year;
  bool _isLoading = true;
  List<FixedCost> _fixedCosts = const [];
  bool _includeFixedCosts = true;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('$periodLabel $typeLabel 상세')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final transactions = getFilteredTransactions();
    final txTotal = transactions.fold<double>(
      0.0,
      (sum, tx) => sum + tx.amount,
    );
    final total = calculateTotal(transactions);
    final average = transactions.isEmpty ? 0.0 : txTotal / transactions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('$periodLabel $typeLabel 상세'),
        actions: [
          if (_fixedCosts.isNotEmpty &&
              widget.transactionType == TransactionType.expense)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text(
                  StatsLabels.fixedCostLabel,
                  style: TextStyle(fontSize: 12),
                ),
                showCheckmark: false,
                selected: _includeFixedCosts,
                onSelected: (selected) {
                  setState(() => _includeFixedCosts = selected);
                },
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          buildPeriodNavigator(context, theme),
          buildSummaryCard(theme, transactions, total, average),
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text(
                      '이 기간에 $typeLabel 거래가 없습니다.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : isLandscape
                ? buildTransactionListLandscape(theme, transactions)
                : buildTransactionListPortrait(theme, transactions),
          ),
        ],
      ),
    );
  }
}
