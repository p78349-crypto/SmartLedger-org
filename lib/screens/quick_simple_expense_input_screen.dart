import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../navigation/app_routes.dart';
import '../services/quick_simple_expense_input_history_service.dart';
import '../services/transaction_service.dart';
import '../services/voice_input_bridge.dart';
import '../utils/currency_formatter.dart';
import '../utils/icon_catalog.dart';

class QuickSimpleExpenseInputScreen extends StatefulWidget {
  const QuickSimpleExpenseInputScreen({
    super.key,
    required this.accountName,
    required this.initialDate,
    this.initialLine,
    this.autoSubmitOnStart = false,
  });

  final String accountName;
  final DateTime initialDate;
  final String? initialLine;

  /// If true, attempts to save automatically once opened.
  /// Safety gate must be enforced by DeepLinkHandler using confirmed flags.
  final bool autoSubmitOnStart;

  @override
  State<QuickSimpleExpenseInputScreen> createState() =>
      _QuickSimpleExpenseInputScreenState();
}

class _QuickSimpleExpenseInputScreenState
    extends State<QuickSimpleExpenseInputScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<
    ({String description, double amount, String payment, String store})
  >
  _displayedItems = [];

  @override
  void initState() {
    super.initState();

    final prefill = widget.initialLine?.trim() ?? '';
    if (prefill.isNotEmpty) {
      _controller.text = prefill;
    }

    if (widget.autoSubmitOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _goNext();
      });
    }

    // Listen for voice assistant input
    VoiceInputBridge.instance.pendingInput.addListener(_onVoiceInputReceived);
    VoiceInputBridge.instance.requestSubmit.addListener(
      _onVoiceSubmitRequested,
    );
  }

  @override
  void dispose() {
    VoiceInputBridge.instance.pendingInput.removeListener(
      _onVoiceInputReceived,
    );
    VoiceInputBridge.instance.requestSubmit.removeListener(
      _onVoiceSubmitRequested,
    );
    _controller.dispose();
    super.dispose();
  }

  void _onVoiceInputReceived() {
    final text = VoiceInputBridge.instance.pendingInput.value;
    if (text != null && mounted) {
      setState(() {
        _controller.text = text;
        // Optionally move cursor to end
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
    }
  }

  void _onVoiceSubmitRequested() {
    if (VoiceInputBridge.instance.requestSubmit.value && mounted) {
      _goNext();
      VoiceInputBridge.instance.clear();
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _QuickSimpleExpenseHistoryScreen(accountName: widget.accountName),
      ),
    );
  }

  Future<void> _openTop20ExpenseStats() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.periodStatsMonth,
      arguments: AccountArgs(accountName: widget.accountName),
    );
  }

  ({
    String description,
    int quantity,
    double amount,
    String payment,
    String store,
  })?
  _parseLine(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;

    // Normalize common separators.
    text = text.replaceAll('.', ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    // Optional parsing mode (no UI):
    // - "공격": infer more (e.g., bare quantity)
    // - "보수": infer less
    // Default is aggressive to avoid blocking saves.
    bool aggressive = true;
    final modeMatch = RegExp(r'(^|\s)(공격|보수)(\s|$)').firstMatch(text);
    if (modeMatch != null) {
      aggressive = (modeMatch.group(2) == '공격');
      text = text.replaceFirst(modeMatch.group(0)!, ' ').trim();
      text = text.replaceAll(RegExp(r'\s+'), ' ');
    }

    // Amount: prefer explicit "원" but allow bare numbers.
    Match? amountMatch = RegExp(r'(\d[\d,]*)\s*원').firstMatch(text);
    String? rawAmount;
    if (amountMatch != null) {
      rawAmount = (amountMatch.group(1) ?? '').replaceAll(',', '');
      text = text.replaceFirst(amountMatch.group(0)!, ' ').trim();
    } else {
      final allNums = RegExp(r'\d[\d,]*').allMatches(text).toList();
      if (allNums.isEmpty) return null;
      amountMatch = allNums.last;
      rawAmount = text
          .substring(amountMatch.start, amountMatch.end)
          .replaceAll(',', '');
      text =
          (text.substring(0, amountMatch.start) +
                  text.substring(amountMatch.end))
              .trim();
    }

    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) return null;

    // Normalize spaces after removing amount.
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    final tokens = text.split(' ').where((t) => t.trim().isNotEmpty).toList();

    // Payment token.
    String payment = '';
    int paymentIndex = -1;
    for (var i = tokens.length - 1; i >= 0; i--) {
      final t = tokens[i];
      if (t.contains('카드') ||
          t.contains('현금') ||
          t.contains('계좌') ||
          t.contains('이체') ||
          t.contains('페이')) {
        payment = t;
        paymentIndex = i;
        break;
      }
    }
    if (paymentIndex >= 0) {
      tokens.removeAt(paymentIndex);
    }

    payment = payment.trim();
    if (payment.isEmpty) payment = '미지정';

    // Quantity token: prefer explicit unit words to avoid mis-detecting.
    int quantity = 1;
    int qtyIndex = -1;
    final qtyMatchRe = RegExp(r'^(\d+)(개|잔|병|회|장|팩|봉|캔)$');
    for (var i = 0; i < tokens.length; i++) {
      final m = qtyMatchRe.firstMatch(tokens[i]);
      if (m != null) {
        quantity = int.tryParse(m.group(1) ?? '1') ?? 1;
        qtyIndex = i;
        break;
      }
    }
    if (qtyIndex >= 0) {
      tokens.removeAt(qtyIndex);
    }

    // Quantity inference (aggressive only):
    // - "x2" / "2x" / "×2" patterns
    // - bare trailing integer (e.g., "커피 2")
    if (aggressive && tokens.isNotEmpty && qtyIndex < 0) {
      int inferredQty = 1;
      int inferredIndex = -1;
      final xQtyRe1 = RegExp(r'^(?:x|X|\*|×)(\d+)$');
      final xQtyRe2 = RegExp(r'^(\d+)(?:x|X|\*|×)$');
      for (var i = tokens.length - 1; i >= 0; i--) {
        final t = tokens[i];
        final m1 = xQtyRe1.firstMatch(t);
        final m2 = xQtyRe2.firstMatch(t);
        if (m1 != null) {
          inferredQty = int.tryParse(m1.group(1) ?? '1') ?? 1;
          inferredIndex = i;
          break;
        }
        if (m2 != null) {
          inferredQty = int.tryParse(m2.group(1) ?? '1') ?? 1;
          inferredIndex = i;
          break;
        }
      }

      if (inferredIndex < 0 && tokens.length >= 2) {
        final last = tokens.last;
        if (RegExp(r'^\d+$').hasMatch(last)) {
          final v = int.tryParse(last) ?? 1;
          if (v >= 2 && v <= 99) {
            inferredQty = v;
            inferredIndex = tokens.length - 1;
          }
        }
      }

      if (inferredIndex >= 0) {
        quantity = inferredQty;
        tokens.removeAt(inferredIndex);
      }
    }

    // Store tag (aggressive only): "매장:OO" / "가게:OO" / "상호:OO"
    String taggedStore = '';
    if (aggressive && tokens.isNotEmpty) {
      for (var i = 0; i < tokens.length; i++) {
        final t = tokens[i];
        if (t.startsWith('매장:') || t.startsWith('가게:') || t.startsWith('상호:')) {
          taggedStore = t.split(':').skip(1).join(':').trim();
          tokens.removeAt(i);
          break;
        }
      }
    }

    // Store/description: be permissive.
    String store = taggedStore.isNotEmpty ? taggedStore : '미지정';
    String description = '';
    if (tokens.isEmpty) {
      description = '';
    } else if (tokens.length == 1) {
      description = tokens.first.trim();
    } else {
      if (taggedStore.isEmpty) {
        store = tokens.removeLast().trim();
      }
      description = tokens.join(' ').trim();
    }

    if (description.isEmpty) {
      description = '간편지출';
    }
    if (store.isEmpty) {
      store = '미지정';
    }

    return (
      description: description,
      quantity: quantity <= 0 ? 1 : quantity,
      amount: amount,
      payment: payment.trim(),
      store: store,
    );
  }

  Future<void> _goNext() async {
    final parsed = _parseLine(_controller.text);
    if (parsed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('금액이 필요합니다. 예: 커피 1잔 3000원 신용카드 프랜차이즈 카페 (결제/매장은 선택)'),
        ),
      );
      return;
    }

    final rawLine = _controller.text.trim();

    final qty = parsed.quantity;
    final unit = qty > 0 ? (parsed.amount / qty) : parsed.amount;

    final memoParts = <String>[
      '간편입력',
      rawLine,
      if (parsed.payment.isNotEmpty && parsed.payment != '미지정')
        '결제:${parsed.payment}',
      if (parsed.store.isNotEmpty && parsed.store != '미지정')
        '매장:${parsed.store}',
      if (parsed.quantity > 1) '수량:${parsed.quantity}',
    ];
    var memo = memoParts.join(' | ');
    const maxMemoLen = 200;
    if (memo.length > maxMemoLen) {
      memo = '${memo.substring(0, maxMemoLen - 3)}...';
    }

    final tx = Transaction(
      id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
      type: TransactionType.expense,
      description: parsed.description,
      amount: parsed.amount,
      cardChargedAmount: parsed.payment.contains('카드') ? parsed.amount : null,
      date: _dateOnly(widget.initialDate),
      quantity: qty,
      unitPrice: unit,
      paymentMethod: parsed.payment,
      store: parsed.store == '미지정' ? null : parsed.store,
      memo: memo,
      mainCategory: Transaction.defaultMainCategory,
    );

    await TransactionService().addTransaction(widget.accountName, tx);

    await QuickSimpleExpenseInputHistoryService().addEntry(
      widget.accountName,
      raw: rawLine,
      description: parsed.description,
      quantity: parsed.quantity,
      amount: parsed.amount,
      payment: parsed.payment,
      store: parsed.store,
    );
    if (!mounted) return;

    // 입력된 항목을 화면에 표시할 리스트에 추가
    setState(() {
      _displayedItems.add((
        description: parsed.description,
        amount: parsed.amount,
        payment: parsed.payment,
        store: parsed.store,
      ));
      _controller.clear();
    });

    // Give a clear "saved" feeling.
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('저장되었습니다')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bottomActionButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 8),
      minimumSize: const Size(0, 56),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('간편 지출 입력(1줄)'),
        actions: [
          IconButton(
            tooltip: '지우기',
            icon: const Icon(IconCatalog.clear),
            onPressed: () => setState(_controller.clear),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: theme.colorScheme.surface,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(height: 1, thickness: 1, color: theme.dividerColor),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: bottomActionButtonStyle,
                        onPressed: _openHistory,
                        child: const Text(
                          '최근 입력',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: bottomActionButtonStyle,
                        onPressed: _openTop20ExpenseStats,
                        child: const Text(
                          '지출 상위20',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '내용',
                hintText: '예: 커피 1잔 3000원 신용카드 프랜차이즈 카페',
              ),
              onSubmitted: (_) => _goNext(),
            ),
          ),
          // 숫자 보조 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _controller.text += '0',
                    child: const Text('0'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _controller.text += '00',
                    child: const Text('00'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _controller.text += '000',
                    child: const Text('000'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_displayedItems.isNotEmpty)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _displayedItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _displayedItems[index];
                  final amountLabel = CurrencyFormatter.format(item.amount);
                  final paymentLabel = item.payment != '미지정'
                      ? ' · ${item.payment}'
                      : '';
                  final storeLabel = item.store != '미지정'
                      ? ' · ${item.store}'
                      : '';
                  final itemText =
                      '${item.description} · $amountLabel'
                      '$paymentLabel$storeLabel';
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        itemText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickSimpleExpenseHistoryScreen extends StatelessWidget {
  const _QuickSimpleExpenseHistoryScreen({required this.accountName});
  final String accountName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('최근 입력 내역')),
      body: FutureBuilder<List<QuickSimpleExpenseInputEntry>>(
        future: QuickSimpleExpenseInputHistoryService().loadEntries(
          accountName,
        ),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <QuickSimpleExpenseInputEntry>[];
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items.isEmpty) {
            return const Center(child: Text('저장된 내역이 없습니다.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                SizedBox(key: ValueKey('sep-$index'), height: 8),
            itemBuilder: (context, i) {
              final e = items[i];
              return Card(
                child: ListTile(
                  title: Text(
                    '${e.description} · ${CurrencyFormatter.format(e.amount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${e.payment} · ${e.store}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
