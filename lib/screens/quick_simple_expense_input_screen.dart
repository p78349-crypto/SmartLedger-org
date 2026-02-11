import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../navigation/app_routes.dart';
import '../services/quick_simple_expense_input_history_service.dart';
import '../services/transaction_service.dart';
import '../services/voice_input_bridge.dart';
import '../services/aicore_gemini_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/icon_catalog.dart';

part 'quick_simple_expense_input_screen_parsing.dart';
part 'quick_simple_expense_input_screen_ui.dart';

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
    ({
      String id,
      String description,
      double amount,
      String payment,
      String store,
    })
  >
  _displayedItems = [];

  int? _editingIndex;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      bottomNavigationBar: _buildBottomNavigationBar(theme),
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
          _buildNumberButtons(),
          const SizedBox(height: 8),
          if (_displayedItems.isNotEmpty)
            Expanded(child: _buildItemsList(theme)),
        ],
      ),
    );
  }
}
