import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/screens/category_stats_screen.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/date_formatter.dart';
import 'package:smart_ledger/utils/localized_date_formatter.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/widgets/background_widget.dart';
import 'package:smart_ledger/utils/period_utils.dart' as period;

class PeriodStatsScreen extends StatefulWidget {
  const PeriodStatsScreen({
    super.key,
    required this.accountName,
    required this.view,
  });

  final String accountName;
  final period.PeriodType view;

  @override
  State<PeriodStatsScreen> createState() => _PeriodStatsScreenState();
}

class _PeriodStatsScreenState extends State<PeriodStatsScreen> {
  final NumberFormat _currencyFormat = NumberFormats.currency;

  late DateTime _anchorDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchorDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    super.dispose();
  }

  String get _title {
    return period.PeriodUtils.getPeriodLabel(widget.view);
  }

  DateTime _todayDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  _InclusiveRange _rangeForView() {
    final range = period.PeriodUtils.getPeriodRange(
      widget.view,
      baseDate: _anchorDay,
    );
    return _InclusiveRange(start: range.start, end: range.end);
  }

  void _goPrev() {
    setState(() {
      switch (widget.view) {
        case period.PeriodType.week:
          _anchorDay = _anchorDay.subtract(const Duration(days: 7));
          break;
        case period.PeriodType.month:
          _anchorDay = DateTime(_anchorDay.year, _anchorDay.month - 1, 1);
          break;
        case period.PeriodType.quarter:
          _anchorDay = DateTime(_anchorDay.year, _anchorDay.month - 3, 1);
          break;
        case period.PeriodType.halfYear:
          _anchorDay = DateTime(_anchorDay.year, _anchorDay.month - 6, 1);
          break;
        case period.PeriodType.year:
          _anchorDay = DateTime(_anchorDay.year - 1, _anchorDay.month, 1);
          break;
        case period.PeriodType.decade:
          _anchorDay = DateTime(_anchorDay.year - 10, _anchorDay.month, 1);
          break;
      }
    });
  }

  void _goNext() {
    setState(() {
      final today = _todayDay();
      DateTime next;
      switch (widget.view) {
        case period.PeriodType.week:
          next = _anchorDay.add(const Duration(days: 7));
          break;
        case period.PeriodType.month:
          next = DateTime(_anchorDay.year, _anchorDay.month + 1, 1);
          break;
        case period.PeriodType.quarter:
          next = DateTime(_anchorDay.year, _anchorDay.month + 3, 1);
          break;
        case period.PeriodType.halfYear:
          next = DateTime(_anchorDay.year, _anchorDay.month + 6, 1);
          break;
        case period.PeriodType.year:
          next = DateTime(_anchorDay.year + 1, _anchorDay.month, 1);
          break;
        case period.PeriodType.decade:
          next = DateTime(_anchorDay.year + 10, _anchorDay.month, 1);
          break;
      }

      _anchorDay = next.isAfter(today) ? today : next;
    });
  }

  String _rangeLabel(BuildContext context, _InclusiveRange range) {
    switch (widget.view) {
      case period.PeriodType.month:
        return LocalizedDateFormatter.yM(context, range.start);
      case period.PeriodType.week:
        final startText = LocalizedDateFormatter.yMd(context, range.start);
        final endText = (range.start.year == range.end.year)
            ? LocalizedDateFormatter.md(context, range.end)
            : LocalizedDateFormatter.yMd(context, range.end);
        return '$startText ~ $endText';
      case period.PeriodType.quarter:
      case period.PeriodType.halfYear:
      case period.PeriodType.year:
      case period.PeriodType.decade:
        final startText = LocalizedDateFormatter.yMd(context, range.start);
        final endText = LocalizedDateFormatter.yMd(context, range.end);
        return '$startText ~ $endText';
    }
  }

  List<Transaction> _filterByRange(
    List<Transaction> all,
    _InclusiveRange range,
  ) {
    bool inRange(DateTime dt) {
      final day = DateTime(dt.year, dt.month, dt.day);
      return !day.isBefore(range.start) && !day.isAfter(range.end);
    }

    return all.where((tx) => inRange(tx.date)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Color _colorForCategoryRank(ThemeData theme, int index) {
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

  Widget _buildExpenseCategoryAggregation(
    ThemeData theme,
    List<Transaction> filtered,
  ) {
    final expenseTxs = filtered
        .where((tx) => tx.type == TransactionType.expense)
        .toList(growable: false);

    if (expenseTxs.isEmpty) {
      return Center(
        child: Text('해당 기간에 표시할 지출이 없습니다.', style: theme.textTheme.bodyMedium),
      );
    }

    final Map<String, double> totals = <String, double>{};
    final Map<String, int> counts = <String, int>{};
    for (final tx in expenseTxs) {
      final key = tx.mainCategory;
      totals[key] = (totals[key] ?? 0) + tx.amount.abs();
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(20).toList(growable: false);
    final totalExpense = expenseTxs.fold<double>(
      0,
      (sum, tx) => sum + tx.amount.abs(),
    );

    return ListView.separated(
      itemCount: top.length + 1,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == 0) {
          return ListTile(
            title: const Text('카테고리별 지출 (상위 20)'),
            trailing: Text(
              '총 ${_currencyFormat.format(totalExpense)}원',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        final index = i - 1;
        final entry = top[index];
        final category = entry.key;
        final amount = entry.value;
        final count = counts[category] ?? 0;
        final color = _colorForCategoryRank(theme, index);

        return ListTile(
          leading: CircleAvatar(radius: 10, backgroundColor: color),
          title: Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            '$count건',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Text(
            '${_currencyFormat.format(amount)}원',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final service = TransactionService();
    final all = service.getTransactions(widget.accountName);
    final range = _rangeForView();
    final filtered = _filterByRange(all, range);

    final body = _buildExpenseCategoryAggregation(theme, filtered);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: [
            IconButton(
              tooltip: '거래 보기',
              icon: const Icon(Icons.list_alt),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _PeriodTransactionsListScreen(
                      title: '거래 목록',
                      rangeLabel: _rangeLabel(context, range),
                      transactions: filtered,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
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
                          _rangeLabel(context, range),
                          style: theme.textTheme.bodyMedium,
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
            Expanded(child: body),
          ],
        ),
        floatingActionButton: Transform.translate(
          offset: const Offset(0, 45),
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
                    heroTag: 'period_stats_trend',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CategoryStatsScreen(
                            accountName: widget.accountName,
                            isSubCategory: false,
                            initialDate: _anchorDay,
                            periodType: widget.view,
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
                    heroTag: 'period_stats_bar',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CategoryStatsScreen(
                            accountName: widget.accountName,
                            isSubCategory: true,
                            initialDate: _anchorDay,
                            periodType: widget.view,
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
      ),
    );
  }
}

class _InclusiveRange {
  const _InclusiveRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class _PeriodTransactionsListScreen extends StatelessWidget {
  const _PeriodTransactionsListScreen({
    required this.title,
    required this.rangeLabel,
    required this.transactions,
  });

  final String title;
  final String rangeLabel;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormatter.defaultDate;
    final currencyFormat = NumberFormats.currency;

    return ValueListenableBuilder<Color>(
      valueListenable: BackgroundHelper.colorNotifier,
      builder: (context, bgColor, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(title: Text(title)),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rangeLabel, style: theme.textTheme.titleSmall),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Text(
                          '해당 기간에 표시할 거래가 없습니다.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        itemCount: transactions.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final icon = tx.type == TransactionType.income
                              ? Icons.trending_up
                              : tx.type == TransactionType.expense
                              ? Icons.trending_down
                              : Icons.savings;

                          final color = tx.type == TransactionType.income
                              ? theme.colorScheme.primary
                              : tx.type == TransactionType.expense
                              ? theme.colorScheme.error
                              : (Colors.amber[700] ??
                                    theme.colorScheme.secondary);

                          final amountText =
                              '${tx.sign}'
                              '${currencyFormat.format(tx.amount.abs())}원';

                          return ListTile(
                            leading: Icon(icon, color: color),
                            title: Text(tx.description),
                            subtitle: Text(
                              '${dateFormat.format(tx.date)} · ${tx.memo}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Text(amountText),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
