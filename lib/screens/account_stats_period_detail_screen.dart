import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/date_formatter.dart';
import '../utils/debounce_utils.dart';
import '../utils/number_formats.dart';
import 'account_stats_models.dart';
import 'account_stats_utils.dart';

part 'account_stats_period_detail_build.dart';

/// 기간별 거래 내역 상세 화면.
class AccountStatsPeriodDetailScreen extends StatefulWidget {
  const AccountStatsPeriodDetailScreen({
    super.key,
    required this.accountName,
    required this.view,
  });

  final String accountName;
  final StatsView view;

  @override
  State<AccountStatsPeriodDetailScreen> createState() =>
      _AccountStatsPeriodDetailScreenState();
}

class _AccountStatsPeriodDetailScreenState
    extends State<AccountStatsPeriodDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 180),
  );
  final NumberFormat _currencyFormat = NumberFormats.currency;
  final DateFormat _dateFormat = DateFormatter.defaultDate;
  final DateFormat _monthLabelFormat = DateFormatter.monthLabel;

  late DateTime _currentMonth;
  late int _currentYear;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _currentYear = now.year;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.view) {
      case StatsView.month:
        return '1달 통계';
      case StatsView.quarter:
        return '3개월 통계';
      case StatsView.halfYear:
        return '6개월 통계';
      case StatsView.year:
        return '1년 통계';
      case StatsView.decade:
        return '10년 통계';
      default:
        return '기간 통계';
    }
  }

  DateTimeRange _rangeForView() {
    switch (widget.view) {
      case StatsView.month:
        final start = DateTime(_currentMonth.year, _currentMonth.month);
        final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
        return DateTimeRange(start: start, end: end);
      case StatsView.quarter:
        final start = DateTime(_currentMonth.year, _currentMonth.month - 2);
        final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
        return DateTimeRange(start: start, end: end);
      case StatsView.halfYear:
        final start = DateTime(_currentMonth.year, _currentMonth.month - 5);
        final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
        return DateTimeRange(start: start, end: end);
      case StatsView.year:
        final start = DateTime(_currentYear);
        final end = DateTime(_currentYear, 12, 31);
        return DateTimeRange(start: start, end: end);
      case StatsView.decade:
        final startYear = _currentYear - 9;
        final start = DateTime(startYear);
        final end = DateTime(_currentYear, 12, 31);
        return DateTimeRange(start: start, end: end);
      default:
        final now = DateTime.now();
        final start = DateTime(now.year, now.month);
        final end = DateTime(now.year, now.month + 1, 0);
        return DateTimeRange(start: start, end: end);
    }
  }

  List<Transaction> _filterByRangeAndQuery(
    List<Transaction> all,
    DateTimeRange range,
  ) {
    final lower = _query.toLowerCase();
    return all.where((tx) {
      final inRange =
          !tx.date.isBefore(range.start) && !tx.date.isAfter(range.end);
      if (!inRange) return false;
      if (lower.isEmpty) return true;
      return tx.description.toLowerCase().contains(lower) ||
          tx.memo.toLowerCase().contains(lower) ||
          tx.paymentMethod.toLowerCase().contains(lower);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  String _formatSignedAmount(Transaction tx) =>
      '${tx.type.sign}${_currencyFormat.format(tx.amount)}원';

  void _goPrev() {
    setState(() {
      switch (widget.view) {
        case StatsView.month:
        case StatsView.quarter:
        case StatsView.halfYear:
          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
          _currentYear = _currentMonth.year;
          break;
        case StatsView.year:
        case StatsView.decade:
          _currentYear -= 1;
          _currentMonth = DateTime(_currentYear, _currentMonth.month);
          break;
        default:
          break;
      }
    });
  }

  void _goNext() {
    setState(() {
      switch (widget.view) {
        case StatsView.month:
        case StatsView.quarter:
        case StatsView.halfYear:
          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
          _currentYear = _currentMonth.year;
          break;
        case StatsView.year:
        case StatsView.decade:
          _currentYear += 1;
          _currentMonth = DateTime(_currentYear, _currentMonth.month);
          break;
        default:
          break;
      }
    });
  }

  String _rangeLabel(DateTimeRange range) {
    final df = DateFormatter.defaultDate;
    return '${df.format(range.start)} ~ ${df.format(range.end)}';
  }

  String _referencePeriodLabel() {
    if (widget.view == StatsView.year || widget.view == StatsView.decade) {
      return '기준 연도: $_currentYear년';
    }
    final monthLabel = _monthLabelFormat.format(_currentMonth);
    return '기준 월: $monthLabel';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final service = TransactionService();
    final all = service.getTransactions(widget.accountName);
    final range = _rangeForView();
    final filtered = _filterByRangeAndQuery(all, range);
    final referenceLabel = _referencePeriodLabel();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: Column(
          children: [
            _buildSearchAndNav(theme, range, referenceLabel),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        '해당 기간에 표시할 거래가 없습니다.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : _buildTransactionList(theme, filtered, isLandscape),
            ),
          ],
        ),
      ),
    );
  }
}
