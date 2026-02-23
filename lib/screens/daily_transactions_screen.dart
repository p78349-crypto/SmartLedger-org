import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/date_formatter.dart';
import '../utils/number_formats.dart';
import 'daily_transactions_helpers.dart';
import 'daily_transactions_widgets.dart';

class DailyTransactionsScreen extends StatefulWidget {
  const DailyTransactionsScreen({
    super.key,
    required this.accountName,
    required this.initialDay,
    this.savedCount,
    this.showShoppingPointsInputCta = false,
  });

  final String accountName;
  final DateTime initialDay;
  final int? savedCount;
  final bool showShoppingPointsInputCta;

  @override
  State<DailyTransactionsScreen> createState() =>
      _DailyTransactionsScreenState();
}

class _DailyTransactionsScreenState extends State<DailyTransactionsScreen> {
  late DateTime _selectedDay;
  late List<DateTime> _eventDays;
  Map<DateTime, List<Transaction>> _events = {};
  final NumberFormat _numberFormat = NumberFormats.custom('#,###');

  bool _didShowSavedSnack = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _stripTime(widget.initialDay);
    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final count = widget.savedCount;
      if (_didShowSavedSnack) return;
      if (count == null || count <= 0) return;
      _didShowSavedSnack = true;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();

      messenger.showSnackBar(
        SnackBar(
          content: Text('저장 완료: $count건'),
        ),
      );
    });
  }

  Future<void> _loadData() async {
    await TransactionService().loadTransactions();
    final transactions = TransactionService().getTransactions(
      widget.accountName,
    );

    final grouped = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final key = _stripTime(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final days = grouped.keys.toList()..sort();

    setState(() {
      _events = grouped;
      _eventDays = days;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactions = _events[_selectedDay] ?? const <Transaction>[];
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdayLabels[_selectedDay.weekday - 1];
    final monthDay = DateFormatter.formatMonthDay(_selectedDay);
    final formattedDate = '$monthDay ($weekday)';

    final int currentIndex = _eventDays.indexWhere((d) => d == _selectedDay);
    final bool hasPrev = currentIndex > 0;
    final bool hasNext =
        currentIndex >= 0 && currentIndex < _eventDays.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('일일 거래'),
        actions: const [],
      ),
      bottomNavigationBar: DailyTransactionsBottomBar(
        accountName: widget.accountName,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DailyTransactionDateHeader(
            selectedDay: _selectedDay,
            transactions: transactions,
            hasPrev: hasPrev,
            hasNext: hasNext,
            onPrevDay: hasPrev
                ? () => _changeDay(_eventDays[currentIndex - 1])
                : null,
            onNextDay: hasNext
                ? () => _changeDay(_eventDays[currentIndex + 1])
                : null,
            numberFormat: _numberFormat,
          ),
          const Divider(height: 1),
          if (transactions.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  '$formattedDate\n'
                  '거래 내역이 없습니다.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  if (isLandscape)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: DefaultTextStyle(
                        style:
                            theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ) ??
                            const TextStyle(fontSize: 12),
                        child: const Row(
                          children: [
                            Expanded(flex: 4, child: Text('상품명')),
                            SizedBox(width: 10),
                            Expanded(flex: 3, child: Text('카테고리')),
                            SizedBox(width: 10),
                            Expanded(flex: 2, child: Text('결제')),
                            SizedBox(width: 10),
                            Expanded(flex: 4, child: Text('메모')),
                            SizedBox(width: 10),
                            Text('금액'),
                            SizedBox(width: 10),
                            Text('카드금액'),
                          ],
                        ),
                      ),
                    ),
                  if (isLandscape) const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return DailyTransactionTile(
                          tx: tx,
                          isLandscape: isLandscape,
                          numberFormat: _numberFormat,
                          onTap: () => showDailyTransactionActionSheet(
                            context: context,
                            tx: tx,
                            accountName: widget.accountName,
                            onReload: _loadData,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _changeDay(DateTime newDay) {
    setState(() {
      _selectedDay = _stripTime(newDay);
    });
  }

  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
