import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../navigation/app_routes.dart';
import '../services/quick_simple_expense_input_history_service.dart';
import '../services/transaction_service.dart';
import '../services/voice_input_bridge.dart';
import '../services/aicore_gemini_service.dart';
import '../utils/icon_catalog.dart';
import 'quick_expense_choseong_refiner.dart';
import 'quick_simple_expense_history_screen.dart';
import 'quick_simple_expense_input_widgets.dart';
import 'quick_simple_expense_parser.dart';

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
  final bool autoSubmitOnStart;

  @override
  State<QuickSimpleExpenseInputScreen> createState() =>
      _QuickSimpleExpenseInputScreenState();
}

class _QuickSimpleExpenseInputScreenState
    extends State<QuickSimpleExpenseInputScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<QuickExpenseDisplayedItem> _displayedItems = [];
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    final prefill = widget.initialLine?.trim() ?? '';
    if (prefill.isNotEmpty) _controller.text = prefill;
    if (widget.autoSubmitOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _goNext();
      });
    }
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

  void _onEdit(int index) {
    final item = _displayedItems[index];
    setState(() {
      _editingIndex = index;
      _controller.text = '${item.description} ${item.amount.toInt()}';
      if (item.payment != '미지정') _controller.text += ' ${item.payment}';
      if (item.store != '미지정') _controller.text += ' ${item.store}';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  void _onVoiceInputReceived() {
    final text = VoiceInputBridge.instance.pendingInput.value;
    if (text != null && mounted) _processVoiceInputWithNano(text);
  }

  /// Gemini Nano를 사용하여 음성 입력을 "품목 금액" 형식으로 정규화
  Future<void> _processVoiceInputWithNano(String text) async {
    _setControllerText(text);
    try {
      final aicore = AICoreGeminiService();
      if (!await aicore.isAvailable()) return;
      final result = await aicore.processVoiceInput(text);
      if (!result.containsKey('items')) return;
      final items = result['items'] as List;
      if (items.isEmpty || !mounted) return;
      final first = items[0] as Map<String, dynamic>;
      final name = first['name'];
      final total = first['total'];
      if (name != null && total != null) _setControllerText('$name $total');
    } catch (e) {
      debugPrint('[Nano] 간편지출 파싱 오류: $e');
    }
  }

  void _setControllerText(String v) {
    setState(() {
      _controller.text = v;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: v.length),
      );
    });
  }

  void _onVoiceSubmitRequested() {
    if (VoiceInputBridge.instance.requestSubmit.value && mounted) {
      _goNext();
      VoiceInputBridge.instance.clear();
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> _openHistory() async => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => QuickSimpleExpenseHistoryScreen(
        accountName: widget.accountName,
      ),
    ),
  );

  Future<void> _openTop20ExpenseStats() async =>
      Navigator.of(context).pushNamed(
        AppRoutes.periodStatsMonth,
        arguments: AccountArgs(accountName: widget.accountName),
      );

  Future<void> _goNext() async {
    final isUpdating = _editingIndex != null;
    final refinedText = QuickExpenseChoseongRefiner.refineInput(_controller.text);
    final parsed = parseExpenseLine(refinedText);
    if (parsed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '금액이 필요합니다. 예: 커피 1잔 3000원 신용카드 프랜차이즈 카페 (결제/매장은 선택)',
          ),
        ),
      );
      return;
    }

    final rawLine = refinedText.trim();
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

    final String txId = _editingIndex != null
        ? _displayedItems[_editingIndex!].id
        : 'tx_${DateTime.now().microsecondsSinceEpoch}';

    final tx = Transaction(
      id: txId,
      type: TransactionType.expense,
      description: parsed.description,
      amount: parsed.amount,
      cardChargedAmount:
          parsed.payment.contains('카드') ? parsed.amount : null,
      date: _dateOnly(widget.initialDate),
      quantity: qty,
      unitPrice: unit,
      paymentMethod: parsed.payment,
      store: parsed.store == '미지정' ? null : parsed.store,
      memo: memo,
      mainCategory: Transaction.defaultMainCategory,
    );

    if (_editingIndex != null) {
      await TransactionService().updateTransaction(widget.accountName, tx);
    } else {
      await TransactionService().addTransaction(widget.accountName, tx);
    }

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
    setState(() {
      if (_editingIndex != null) {
        _displayedItems[_editingIndex!] = (
          id: txId,
          description: parsed.description,
          amount: parsed.amount,
          payment: parsed.payment,
          store: parsed.store,
        );
        _editingIndex = null;
      } else {
        _displayedItems.add((
          id: txId,
          description: parsed.description,
          amount: parsed.amount,
          payment: parsed.payment,
          store: parsed.store,
        ));
      }
      _controller.clear();
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isUpdating ? '수정되었습니다' : '저장되었습니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      bottomNavigationBar: QuickExpenseBottomBar(
        onOpenHistory: _openHistory,
        onOpenTop20: _openTop20ExpenseStats,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _editingIndex != null ? '기존 항목 수정 중' : '내용',
                hintText: '예: 커피 1잔 3000원 신용카드 프랜차이즈 카페',
                suffixIcon: _editingIndex != null
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _editingIndex = null;
                          _controller.clear();
                        }),
                      )
                    : null,
              ),
              onSubmitted: (_) => _goNext(),
            ),
          ),
          QuickExpenseNumPad(controller: _controller),
          const SizedBox(height: 8),
          if (_displayedItems.isNotEmpty)
            Expanded(
              child: QuickExpenseItemList(
                items: _displayedItems,
                editingIndex: _editingIndex,
                onEdit: _onEdit,
              ),
            ),
        ],
      ),
    );
  }
}
