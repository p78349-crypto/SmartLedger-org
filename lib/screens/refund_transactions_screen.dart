import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'transaction_add_screen.dart';
import '../services/transaction_service.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/number_formats.dart';
import '../utils/refund_utils.dart';
import '../utils/debounce_utils.dart';
import '../widgets/smart_input_field.dart';

part 'refund_transactions_screen_tiles.dart';
part 'refund_transactions_screen_grouped.dart';
part 'refund_transactions_screen_body.dart';

class RefundTransactionsScreen extends StatefulWidget {
  const RefundTransactionsScreen({
    super.key,
    required this.accountName,
    required this.initialDay,
  });

  final String accountName;
  final DateTime initialDay;

  @override
  State<RefundTransactionsScreen> createState() =>
      _RefundTransactionsScreenState();
}

class _RefundTransactionsScreenState extends State<RefundTransactionsScreen> {
  late DateTime _selectedDay;
  List<DateTime> _eventDays = const <DateTime>[];
  Map<DateTime, List<Transaction>> _events = {};
  int? _rangeDays;
  bool _partialOnly = false;
  bool _groupByPayment = false;
  final NumberFormat _numberFormat = NumberFormats.custom('#,###');
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 200),
  );
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _stripTime(widget.initialDay);
    _loadData();
  }

  DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> _loadData() async {
    await TransactionService().loadTransactions();
    final transactions = TransactionService().getTransactions(
      widget.accountName,
    );

    final grouped = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      if (tx.type != TransactionType.refund) continue;
      final key = _stripTime(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final days = grouped.keys.toList()..sort();

    setState(() {
      _events = grouped;
      _eventDays = days;
      if (_eventDays.isNotEmpty && !_eventDays.contains(_selectedDay)) {
        _selectedDay = _eventDays.last;
      }
    });
  }

  void _changeDay(DateTime next) {
    setState(() => _selectedDay = next);
  }

  bool _matchesSearch(Transaction tx, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final dateYmd = DateFormat('yyyy-MM-dd').format(tx.date);
    final dateMd = DateFormat('MM-dd').format(tx.date);
    final dateMdySlash = DateFormat('M/d').format(tx.date);

    final amountWon = _numberFormat.format(tx.amount);
    final unitWon = _numberFormat.format(tx.unitPrice);
    final qtyText = _numberFormat.format(tx.quantity);
    final cardWon = tx.cardChargedAmount == null
        ? null
        : _numberFormat.format(tx.cardChargedAmount);

    final sub = tx.subCategory?.trim() ?? '';
    final memo = tx.memo.trim();
    final store = tx.store?.trim() ?? '';
    final haystack = <String>[
      dateYmd,
      dateMd,
      dateMdySlash,
      tx.description,
      memo,
      store,
      tx.amount.toString(),
      '$amountWon원',
      amountWon,
      tx.unitPrice.toString(),
      '$unitWon원',
      unitWon,
      tx.quantity.toString(),
      qtyText,
      tx.mainCategory,
      sub,
      tx.paymentMethod,
      (tx.cardChargedAmount ?? '').toString(),
      if (cardWon != null) ...[
        cardWon,
        '$cardWon원',
      ],
    ].join(' ').toLowerCase();

    return haystack.contains(q);
  }

  String _categoryText(Transaction tx) {
    final sub = tx.subCategory?.trim();
    return (sub == null || sub.isEmpty)
        ? tx.mainCategory
        : '${tx.mainCategory} · $sub';
  }

  bool _isPartialRefund(Transaction tx) {
    if (!tx.isRefund) return false;
    final memo = tx.memo.toLowerCase();
    final desc = tx.description.toLowerCase();
    if (memo.contains('부분') || desc.contains('부분')) {
      return true;
    }
    final cardAmount = tx.cardChargedAmount?.abs();
    if (cardAmount != null && cardAmount != tx.amount.abs()) {
      return true;
    }
    if (tx.unitPrice > 0 && tx.quantity > 0) {
      final expected = (tx.unitPrice * tx.quantity).abs();
      if (expected > 0 && tx.amount.abs() < expected) {
        return true;
      }
    }
    return false;
  }

  Transaction _buildRefundTemplate() {
    return Transaction(
      id: 'template_refund',
      type: TransactionType.refund,
      description: '',
      amount: 0,
      date: _selectedDay,
      mainCategory: Transaction.defaultMainCategory,
      isRefund: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayTransactions = _events[_selectedDay] ?? const <Transaction>[];
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final queryActive = _searchQuery.trim().isNotEmpty;
    final List<Transaction> transactions;
    if (queryActive) {
      final all = _events.values.expand((list) => list).toList();
      transactions =
          all
              .where((t) => _matchesSearch(t, _searchQuery))
              .where((t) => !_partialOnly || _isPartialRefund(t))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
    } else if (_rangeDays != null && _rangeDays! > 0) {
      final now = DateTime.now();
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: _rangeDays! - 1));
      final filtered = <Transaction>[];
      _events.forEach((day, list) {
        if (!day.isBefore(start)) {
          filtered.addAll(list);
        }
      });
      transactions =
          filtered.where((t) => !_partialOnly || _isPartialRefund(t)).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
    } else {
      transactions =
          dayTransactions
              .where((t) => !_partialOnly || _isPartialRefund(t))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
    }

    final weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdayLabels[_selectedDay.weekday - 1];
    final monthDay = DateFormatter.formatMonthDay(_selectedDay);
    final formattedDate = '$monthDay ($weekday)';

    final totalRefund = transactions.fold<double>(0, (s, t) => s + t.amount);
    final int currentIndex = _eventDays.indexWhere((d) => d == _selectedDay);
    final bool hasPrev = currentIndex > 0;
    final bool hasNext =
        currentIndex >= 0 && currentIndex < _eventDays.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('반품'),
        actions: [
          IconButton(
            tooltip: '반품 추가',
            icon: const Icon(Icons.add),
            onPressed: () async {
              final saved = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionAddScreen(
                    accountName: widget.accountName,
                    initialTransaction: _buildRefundTemplate(),
                    treatAsNew: true,
                  ),
                ),
              );
              if (saved == true && mounted) {
                await _loadData();
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSearchBar(theme),
          buildHeaderSection(
            theme: theme,
            queryActive: queryActive,
            transactionCount: transactions.length,
            totalRefund: totalRefund,
            formattedDate: formattedDate,
            hasPrev: hasPrev,
            hasNext: hasNext,
            currentIndex: currentIndex,
          ),
          const Divider(height: 1),
          buildTransactionListExpanded(
            theme: theme,
            transactions: transactions,
            isLandscape: isLandscape,
            queryActive: queryActive,
            formattedDate: formattedDate,
          ),
          buildBottomFilterBar(theme),
        ],
      ),
    );
  }
}
