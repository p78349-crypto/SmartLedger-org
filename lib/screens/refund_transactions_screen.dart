import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'transaction_add_screen.dart';
import '../services/transaction_service.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/number_formats.dart';
import '../utils/refund_utils.dart';
import '../widgets/smart_input_field.dart';

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
  final NumberFormat _numberFormat = NumberFormats.custom('#,###');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
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
      // required: 날짜 / 상품명 / 메모 / 가격 / 구매자(판매자일 경우)
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
      // keep useful fields too
      tx.mainCategory,
      sub,
      tx.paymentMethod,
      (tx.cardChargedAmount ?? '').toString(),
      if (cardWon != null) cardWon,
      if (cardWon != null) '$cardWon원',
    ].join(' ').toLowerCase();

    return haystack.contains(q);
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SmartInputField(
        hint: '반품 검색 (날짜/상품명/메모/가격/구매자·거래처)',
        controller: _searchController,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.trim().isEmpty
            ? null
            : IconButton(
                tooltip: '지우기',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
        onChanged: (v) {
          setState(() {
            _searchQuery = v;
          });
        },
      ),
    );
  }

  String _categoryText(Transaction tx) {
    final sub = tx.subCategory?.trim();
    return (sub == null || sub.isEmpty)
        ? tx.mainCategory
        : '${tx.mainCategory} · $sub';
  }

  Widget _buildRefundTile(
    ThemeData theme,
    Transaction tx, {
    required bool showDate,
  }) {
    const txColor = RefundUtils.color;
    final memoText = tx.memo.trim();
    final storeText = tx.store?.trim() ?? '';
    final dateText = DateFormat('yyyy-MM-dd').format(tx.date);
    final qty = tx.quantity;
    final unit = tx.unitPrice;
    final cardCharged = tx.cardChargedAmount;

    final subtitleLines = <String>[
      if (showDate) '일자: $dateText',
      '카테고리: ${_categoryText(tx)}',
      '결제: ${tx.paymentMethod}',
      if (storeText.isNotEmpty) '구매자/거래처: $storeText',
      if (qty != 0 || unit != 0)
        '수량/단가: ${_numberFormat.format(qty)} × ${_numberFormat.format(unit)}원',
      if (cardCharged != null) '카드금액: ${_numberFormat.format(cardCharged)}원',
      if (memoText.isNotEmpty) '메모: $memoText',
    ];

    final titleText = tx.description.trim().isEmpty ? '(미입력)' : tx.description;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: txColor.withValues(alpha: 0.2),
        child: const Icon(Icons.replay, color: RefundUtils.color),
      ),
      title: Text(
        titleText,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitleLines.join('\n'),
        style: theme.textTheme.bodySmall,
      ),
      isThreeLine: subtitleLines.length >= 2,
      trailing: Text(
        '⊕${_numberFormat.format(tx.amount)}원',
        style: const TextStyle(
          color: RefundUtils.color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: () => _showTransactionActionSheet(tx),
    );
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
            title: const Text('반품 삭제'),
            content: const Text('이 반품 내역을 삭제하시겠습니까?'),
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
    if (!queryActive) {
      transactions = dayTransactions;
    } else {
      final all = <Transaction>[];
      for (final list in _events.values) {
        all.addAll(list);
      }
      transactions = all.where((t) => _matchesSearch(t, _searchQuery)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    final weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdayLabels[_selectedDay.weekday - 1];
    final monthDay = DateFormatter.formatMonthDay(_selectedDay);
    final formattedDate = '$monthDay ($weekday)';

    double totalRefund = 0;
    for (final t in transactions) {
      totalRefund += t.amount;
    }

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
          _buildSearchBar(theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: queryActive
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          '검색 결과: ${transactions.length}건',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (totalRefund > 0)
                        Text(
                          '⊕${_numberFormat.format(totalRefund)}원',
                          style: const TextStyle(
                            color: RefundUtils.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  )
                : Row(
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
                              if (totalRefund > 0) ...[
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
                              ] else ...[
                                Text(
                                  '0원',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
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
                  queryActive ? '검색 결과가 없습니다.' : '$formattedDate\n반품 내역이 없습니다.',
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
                        child: Row(
                          children: [
                            if (queryActive) ...[
                              const Expanded(flex: 2, child: Text('일자')),
                              const SizedBox(width: 10),
                            ],
                            const Expanded(flex: 4, child: Text('상품명')),
                            const SizedBox(width: 10),
                            const Expanded(flex: 3, child: Text('카테고리')),
                            const SizedBox(width: 10),
                            const Expanded(flex: 2, child: Text('결제')),
                            const SizedBox(width: 10),
                            const Expanded(flex: 2, child: Text('수량')),
                            const SizedBox(width: 10),
                            const Expanded(flex: 2, child: Text('단가')),
                            const SizedBox(width: 10),
                            const Expanded(flex: 4, child: Text('메모')),
                            const SizedBox(width: 10),
                            const Text('금액'),
                            const SizedBox(width: 10),
                            const Text('카드금액'),
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
                        if (!isLandscape) {
                          return _buildRefundTile(
                            theme,
                            tx,
                            showDate: queryActive,
                          );
                        }

                        final categoryText = _categoryText(tx);

                        final memoText = tx.memo.trim().isEmpty
                            ? '-'
                            : tx.memo.trim();

                        final storeText = tx.store?.trim() ?? '';
                        final memoColText = storeText.isEmpty
                            ? memoText
                            : (memoText == '-'
                                  ? storeText
                                  : '$storeText | $memoText');

                        final cardCharged = tx.cardChargedAmount;
                        final cardText = cardCharged == null
                            ? '-'
                            : '${_numberFormat.format(cardCharged)}원';

                        final dateText = DateFormat(
                          'yyyy-MM-dd',
                        ).format(tx.date);
                        final qtyText = _numberFormat.format(tx.quantity);
                        final unitText =
                            '${_numberFormat.format(tx.unitPrice)}원';

                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          title: Row(
                            children: [
                              if (queryActive) ...[
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    dateText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                flex: 4,
                                child: Text(
                                  tx.description.trim().isEmpty
                                      ? '(미입력)'
                                      : tx.description,
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
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tx.paymentMethod,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  qtyText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  unitText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  memoColText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '⊕${_numberFormat.format(tx.amount)}원',
                                style: const TextStyle(
                                  color: RefundUtils.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                cardText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: RefundUtils.color,
                                ),
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
}
