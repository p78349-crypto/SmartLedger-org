import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
// import 'package:smart_ledger/screens/quick_simple_expense_input_screen.dart';
// // disabled: connection removed
import 'package:smart_ledger/screens/transaction_add_screen.dart';
// import 'package:smart_ledger/screens/nutrition_report_screen.dart';
// // disabled: feature connections removed
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/theme/app_colors.dart';
import 'package:smart_ledger/utils/date_formatter.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/refund_utils.dart';

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

      final wantsPoints = widget.showShoppingPointsInputCta;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wantsPoints
                ? '저장 완료: $count건 · 포인트도 기록해두세요'
                : '저장 완료: $count건 · 할인/절약도 기록해두세요',
          ),
          action: SnackBarAction(
            label: wantsPoints ? '포인트 입력' : '기록',
            onPressed: () {
              final route = wantsPoints
                  ? AppRoutes.shoppingPointsInput
                  : AppRoutes.microSavings;
              Navigator.of(context).pushNamed(
                route,
                arguments: AccountArgs(accountName: widget.accountName),
              );
            },
          ),
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

  Future<void> _showTransactionActionSheet(Transaction tx) async {
    final theme = Theme.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(IconCatalog.edit, color: theme.colorScheme.primary),
              title: const Text('편집'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(IconCatalog.delete, color: Colors.red),
              title: const Text('삭제'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    switch (action) {
      case 'edit':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionAddScreen(
              accountName: widget.accountName,
              initialTransaction: tx,
            ),
          ),
        );
        await _loadData();
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('거래 삭제'),
            content: const Text('이 거래를 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('삭제'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await TransactionService().deleteTransaction(
            widget.accountName,
            tx.id,
          );
          await _loadData();
        }
        break;
    }
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

    final int currentIndex = _eventDays.indexWhere((d) => d == _selectedDay);
    final bool hasPrev = currentIndex > 0;
    final bool hasNext =
        currentIndex >= 0 && currentIndex < _eventDays.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('일일 거래'),
        actions: const [
          // Quick Simple Expense Input connection removed
          // (feature disabled per request).
          // Nutrition report action removed
          // (feature disabled per request).
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: hasPrev
                      ? () => _changeDay(_eventDays[currentIndex - 1])
                      : null,
                  icon: const Icon(IconCatalog.chevronLeft),
                ),
                Column(
                  children: [
                    Text(
                      formattedDate,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (totalIncome > 0) ...[
                          const Text(
                            '수입 ',
                            style: TextStyle(
                              color: AppColors.income,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '+${_numberFormat.format(totalIncome)}원',
                            style: const TextStyle(
                              color: AppColors.income,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (totalExpense > 0) ...[
                          const Text(
                            '지출 ',
                            style: TextStyle(
                              color: AppColors.expense,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '-${_numberFormat.format(totalExpense)}원',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.expense,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (totalSavings > 0) ...[
                          const Text(
                            '예금 ',
                            style: TextStyle(
                              color: AppColors.savings,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '⊕${_numberFormat.format(totalSavings)}원',
                            style: const TextStyle(
                              color: AppColors.savings,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (totalRefund > 0) ...[
                          const SizedBox(width: 12),
                          const Text(
                            '환급 ',
                            style: TextStyle(
                              color: RefundUtils.color,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '⊕${_numberFormat.format(totalRefund)}원',
                            style: const TextStyle(
                              color: RefundUtils.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (paymentSummary != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '결제: $paymentSummary',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  onPressed: hasNext
                      ? () => _changeDay(_eventDays[currentIndex + 1])
                      : null,
                  icon: const Icon(IconCatalog.chevronRight),
                ),
              ],
            ),
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
                        Color txColor;
                        String prefix;
                        switch (tx.type) {
                          case TransactionType.income:
                            txColor = AppColors.income;
                            prefix = '+';
                            break;
                          case TransactionType.expense:
                            txColor = AppColors.expense;
                            prefix = '-';
                            break;
                          case TransactionType.savings:
                            txColor = AppColors.savings;
                            prefix = '⊕';
                            break;
                          case TransactionType.refund:
                            txColor = RefundUtils.color;
                            prefix = '⊕';
                            break;
                        }

                        if (!isLandscape) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: txColor.withValues(alpha: 0.2),
                              child: Icon(Icons.receipt_long, color: txColor),
                            ),
                            title: Text(
                              tx.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: tx.memo.isNotEmpty ? Text(tx.memo) : null,
                            trailing: Text(
                              '$prefix${_numberFormat.format(tx.amount)}원',
                              style: TextStyle(
                                color: txColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () => _showTransactionActionSheet(tx),
                          );
                        }

                        final sub = tx.subCategory?.trim();
                        final categoryText = (sub == null || sub.isEmpty)
                            ? tx.mainCategory
                            : '${tx.mainCategory} · $sub';

                        final memoText = tx.memo.trim().isEmpty
                            ? '-'
                            : tx.memo.trim();

                        final cardCharged = tx.cardChargedAmount;
                        final cardText = cardCharged == null
                            ? '-'
                            : '${_numberFormat.format(cardCharged)}원';
                        final baseAbs = tx.amount.abs();
                        final hasMismatch =
                            cardCharged != null &&
                            (cardCharged - baseAbs).abs() >= 1;

                        final discountAmount =
                            (cardCharged != null &&
                                tx.type == TransactionType.expense &&
                                cardCharged < baseAbs)
                            ? (baseAbs - cardCharged)
                            : null;

                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  tx.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  categoryText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tx.paymentMethod,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  memoText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$prefix${_numberFormat.format(tx.amount)}원',
                                style: TextStyle(
                                  color: txColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    cardText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: hasMismatch
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.onSurfaceVariant,
                                      fontWeight: hasMismatch
                                          ? FontWeight.w600
                                          : null,
                                    ),
                                  ),
                                  if (discountAmount != null)
                                    Text(
                                      _formatDiscountLabel(discountAmount),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _showTransactionActionSheet(tx),
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

  String _formatDiscountLabel(num amount) {
    final formatted = _numberFormat.format(amount);
    return '할인 $formatted원';
  }

  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
