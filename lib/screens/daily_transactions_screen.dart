import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../navigation/app_routes.dart';
import 'transaction_add_screen.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../models/shopping_cart_item.dart';

// ignore_for_file: avoid_redundant_argument_values
import '../utils/number_formats.dart';
import '../utils/refund_utils.dart';

part 'daily_transactions_screen_actions.dart';
part 'daily_transactions_screen_header.dart';
part 'daily_transactions_screen_ui.dart';

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
    loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final count = widget.savedCount;
      if (_didShowSavedSnack) return;
      if (count == null || count <= 0) return;
      _didShowSavedSnack = true;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();

      final wantsPoints = widget.showShoppingPointsInputCta;
      messenger.showSnackBar(
        SnackBar(
          content: Text('저장 완료: $count건'),
          action: wantsPoints
              ? SnackBarAction(
                  label: '포인트 입력',
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    Navigator.of(context).pushNamed(
                      AppRoutes.shoppingPointsInput,
                      arguments: ShoppingPointsInputArgs(
                        accountName: widget.accountName,
                      ),
                    );
                  },
                )
              : null,
        ),
      );
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

    final summary = _computeSummary(transactions);
    final int currentIndex = _eventDays.indexWhere(
      (d) => d == _selectedDay,
    );
    final bool hasPrev = currentIndex > 0;
    final bool hasNext =
        currentIndex >= 0 && currentIndex < _eventDays.length - 1;

    return Scaffold(
      appBar: AppBar(title: const Text('일일 거래')),
      bottomNavigationBar: buildBottomActionBar(theme),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDateHeader(
            theme: theme,
            formattedDate: formattedDate,
            summary: summary,
            hasPrev: hasPrev,
            hasNext: hasNext,
            currentIndex: currentIndex,
          ),
          const Divider(height: 1),
          if (transactions.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  '$formattedDate\n거래 내역이 없습니다.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  if (isLandscape) buildLandscapeHeader(theme),
                  if (isLandscape) const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: transactions.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final tx = transactions[index];
                        return isLandscape
                            ? buildLandscapeItem(theme, tx)
                            : buildPortraitItem(theme, tx);
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

  _DaySummary _computeSummary(List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    double totalSavings = 0;
    double totalRefund = 0;
    for (final t in transactions) {
      switch (t.type) {
        case TransactionType.income:
          totalIncome += t.amount;
          break;
        case TransactionType.expense:
          totalExpense += t.amount;
          break;
        case TransactionType.savings:
          totalSavings += t.amount;
          break;
        case TransactionType.refund:
          totalRefund += t.amount;
          break;
      }
    }

    final paymentTotals = <String, double>{};
    for (final t in transactions) {
      if (t.type != TransactionType.expense) continue;
      final method = t.paymentMethod.trim();
      if (method.isEmpty) continue;
      final amount = (t.cardChargedAmount ?? t.amount).abs();
      paymentTotals[method] = (paymentTotals[method] ?? 0) + amount;
    }

    String? paymentSummary;
    if (paymentTotals.isNotEmpty) {
      final sorted = paymentTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final parts = sorted.take(3).map((e) {
        final v = _numberFormat.format(e.value);
        return '${e.key} $v';
      }).toList();
      paymentSummary = parts.join(' · ');
    }

    return _DaySummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalSavings: totalSavings,
      totalRefund: totalRefund,
      paymentSummary: paymentSummary,
    );
  }

  void _changeDay(DateTime newDay) {
    setState(() {
      _selectedDay = _stripTime(newDay);
    });
  }

  String _formatDiscountLabel(num amount) {
    final formatted = _numberFormat.format(amount);
    return '할인 $formatted원';
  }

  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _DaySummary {
  final double totalIncome;
  final double totalExpense;
  final double totalSavings;
  final double totalRefund;
  final String? paymentSummary;

  const _DaySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalSavings,
    required this.totalRefund,
    this.paymentSummary,
  });
}
