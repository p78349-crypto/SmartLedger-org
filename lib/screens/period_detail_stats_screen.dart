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

  String get _periodLabel {
    return period.PeriodUtils.getPeriodLabel(widget.periodType);
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
        return '환급';
    }
  }

  int get _monthsInPeriod {
    switch (widget.periodType) {
      case period.PeriodType.week:
        return 0; // 주간은 월 단위 이동이 아님
      case period.PeriodType.month:
        return 1;
      case period.PeriodType.quarter:
        return 3;
      case period.PeriodType.halfYear:
        return 6;
      case period.PeriodType.year:
        return 12;
      case period.PeriodType.decade:
        return 120;
    }
  }

  bool _shouldAggregateForType(Transaction tx, TransactionType type) {
    final isSavingsAsExpense =
        tx.type == TransactionType.savings &&
        tx.savingsAllocation == SavingsAllocation.expense;

    switch (type) {
      case TransactionType.expense:
        return tx.type == TransactionType.expense || isSavingsAsExpense;
      case TransactionType.income:
        return tx.type == TransactionType.income;
      case TransactionType.savings:
        return tx.type == TransactionType.savings && !isSavingsAsExpense;
      case TransactionType.refund:
        return tx.type == TransactionType.refund;
    }
  }

  List<Transaction> _getFilteredTransactions() {
    final allTransactions = TransactionService().getTransactions(
      widget.accountName,
    );
    final months = _monthsInPeriod;

    DateTime startDate;
    DateTime endDate;

    if (widget.periodType == period.PeriodType.decade) {
      final startYear = (_currentYear ~/ 10) * 10;
      startDate = DateTime(startYear);
      endDate = DateTime(startYear + 10, 12, 31);
    } else {
      startDate = DateTime(
        _currentMonth.year,
        _currentMonth.month - months + 1,
      );
      endDate = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    }

    return allTransactions.where((tx) {
      if (tx.date.isBefore(startDate) || tx.date.isAfter(endDate)) {
        return false;
      }
      return _shouldAggregateForType(tx, widget.transactionType);
    }).toList();
  }

  double _calculateTotal(List<Transaction> transactions) {
    double total = transactions.fold(0.0, (sum, tx) => sum + tx.amount);

    if (_includeFixedCosts &&
        _fixedCosts.isNotEmpty &&
        widget.transactionType == TransactionType.expense) {
      final months = _monthsInPeriod;
      final monthlyCost = _fixedCosts.fold(0.0, (sum, fc) => sum + fc.amount);
      total += monthlyCost * months;
    }

    return total;
  }

  void _previousPeriod() {
    setState(() {
      if (widget.periodType == period.PeriodType.decade) {
        _currentYear -= 10;
        return;
      }
      if (widget.periodType == period.PeriodType.week) {
        _currentMonth = _currentMonth.subtract(const Duration(days: 7));
        return;
      }
      final stepMonths = _monthsInPeriod;
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month - stepMonths,
      );
    });
  }

  void _nextPeriod() {
    setState(() {
      if (widget.periodType == period.PeriodType.decade) {
        _currentYear += 10;
        return;
      }
      if (widget.periodType == period.PeriodType.week) {
        _currentMonth = _currentMonth.add(const Duration(days: 7));
        return;
      }
      final stepMonths = _monthsInPeriod;
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + stepMonths,
      );
    });
  }

  String _getCurrentPeriodLabel(BuildContext context) {
    switch (widget.periodType) {
      case period.PeriodType.week:
        final start = _currentMonth.subtract(const Duration(days: 6));
        final startLabel = LocalizedDateFormatter.yMd(context, start);
        final endLabel = LocalizedDateFormatter.yMd(context, _currentMonth);
        return '$startLabel ~ $endLabel';
      case period.PeriodType.month:
        // 월간은 DAY 없이 연-월만.
        return LocalizedDateFormatter.yM(context, _currentMonth);
      case period.PeriodType.quarter:
      case period.PeriodType.halfYear:
      case period.PeriodType.year:
        final startMonth = DateTime(
          _currentMonth.year,
          _currentMonth.month - (_monthsInPeriod - 1),
        );
        final startLabel = LocalizedDateFormatter.yM(context, startMonth);
        final endLabel = LocalizedDateFormatter.yM(context, _currentMonth);
        return '$startLabel ~ $endLabel';
      case period.PeriodType.decade:
        final startYear = _currentYear - 9;
        final startLabel = LocalizedDateFormatter.y(context, startYear);
        final endLabel = LocalizedDateFormatter.y(context, _currentYear);
        return '$startLabel ~ $endLabel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('$_periodLabel $_typeLabel 상세')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final transactions = _getFilteredTransactions();
    final txTotal = transactions.fold<double>(
      0.0,
      (sum, tx) => sum + tx.amount,
    );
    final total = _calculateTotal(transactions);
    // Average should reflect actual transactions;
    // total can include fixed costs.
    final average = transactions.isEmpty ? 0.0 : txTotal / transactions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('$_periodLabel $_typeLabel 상세'),
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
          // 기간 네비게이터
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousPeriod,
                ),
                Text(
                  _getCurrentPeriodLabel(context),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextPeriod,
                ),
              ],
            ),
          ),

          // 요약 카드
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('총 $_typeLabel', style: theme.textTheme.titleMedium),
                    Text(
                      '${_currencyFormat.format(total)}원',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('거래 건수', style: theme.textTheme.bodyMedium),
                    Text(
                      '${transactions.length}건',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (transactions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('평균 금액', style: theme.textTheme.bodyMedium),
                      Text(
                        '${_currencyFormat.format(average)}원',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 거래 목록
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text(
                      '이 기간에 $_typeLabel 거래가 없습니다.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : (isLandscape
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '날짜',
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
                                    flex: 4,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: transactions.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final tx = transactions[index];
                                  final color = _getColorForType(
                                    widget.transactionType,
                                    theme,
                                  );
                                  final amountLabel =
                                      '${_currencyFormat.format(tx.amount)}원';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getIconForType(
                                            widget.transactionType,
                                          ),
                                          size: 18,
                                          color: color,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            _dateFormat.format(tx.date),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 7,
                                          child: Text(
                                            tx.description,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            amountLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.end,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: color,
                                                ),
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
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: transactions.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final amountLabel =
                                '${_currencyFormat.format(tx.amount)}원';
                            return ListTile(
                              leading: Icon(
                                _getIconForType(widget.transactionType),
                                color: _getColorForType(
                                  widget.transactionType,
                                  theme,
                                ),
                              ),
                              title: Text(tx.description),
                              subtitle: Text(_dateFormat.format(tx.date)),
                              trailing: Text(
                                amountLabel,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _getColorForType(
                                    widget.transactionType,
                                    theme,
                                  ),
                                ),
                              ),
                            );
                          },
                        )),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return Icons.remove_circle_outline;
      case TransactionType.income:
        return Icons.add_circle_outline;
      case TransactionType.savings:
        return Icons.savings_outlined;
      case TransactionType.refund:
        return RefundUtils.icon;
    }
  }

  Color _getColorForType(TransactionType type, ThemeData theme) {
    switch (type) {
      case TransactionType.expense:
        return theme.colorScheme.error;
      case TransactionType.income:
        return theme.colorScheme.primary;
      case TransactionType.savings:
        return theme.colorScheme.tertiary;
      case TransactionType.refund:
        return RefundUtils.color;
    }
  }
}
