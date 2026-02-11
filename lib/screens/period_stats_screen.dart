import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'category_stats_screen.dart';
import '../services/transaction_service.dart';
import '../utils/date_formatter.dart';
import '../utils/localized_date_formatter.dart';
import '../utils/number_formats.dart';
import '../widgets/background_widget.dart';
import '../utils/period_utils.dart' as period;
import '../utils/misc_spending_utils.dart';
import '../utils/icon_catalog.dart';

part 'period_stats_screen_widgets.dart';
part 'period_stats_screen_fabs.dart';

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
          _anchorDay = DateTime(_anchorDay.year, _anchorDay.month - 1);
          break;
        case period.PeriodType.quarter:
          _anchorDay = DateTime(_anchorDay.year, _anchorDay.month - 3);
          break;
        case period.PeriodType.halfYear:
          _anchorDay = DateTime(_anchorDay.year, _anchorDay.month - 6);
          break;
        case period.PeriodType.year:
          _anchorDay = DateTime(_anchorDay.year - 1, _anchorDay.month);
          break;
        case period.PeriodType.decade:
          _anchorDay = DateTime(_anchorDay.year - 10, _anchorDay.month);
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
          next = DateTime(_anchorDay.year, _anchorDay.month + 1);
          break;
        case period.PeriodType.quarter:
          next = DateTime(_anchorDay.year, _anchorDay.month + 3);
          break;
        case period.PeriodType.halfYear:
          next = DateTime(_anchorDay.year, _anchorDay.month + 6);
          break;
        case period.PeriodType.year:
          next = DateTime(_anchorDay.year + 1, _anchorDay.month);
          break;
        case period.PeriodType.decade:
          next = DateTime(_anchorDay.year + 10, _anchorDay.month);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final service = TransactionService();
    final all = service.getTransactions(widget.accountName);
    final range = _rangeForView();
    final filtered = _filterByRange(all, range);

    final body = Column(
      children: [
        _buildMiscSpendingSummary(theme, all),
        Expanded(child: _buildExpenseCategoryAggregation(theme, filtered)),
      ],
    );

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
        floatingActionButton: _buildFloatingButtons(theme),
      ),
    );
  }
}

class _InclusiveRange {
  const _InclusiveRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}
