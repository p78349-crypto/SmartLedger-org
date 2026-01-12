part of deep_link_handler;

mixin _DeepLinkHandlerOpenRouteQuickExpense on _DeepLinkHandlerBase {
  @override
  bool _handleOpenRouteQuickExpense({
    required NavigatorState navigator,
    required OpenRouteAction action,
    required AssistantRouteSpec spec,
    required Map<String, String> filteredParams,
    required String? accountName,
  }) {
    if (action.routeName != AppRoutes.quickSimpleExpenseInput) {
      return false;
    }
    if (action.intent != 'quick_expense_add') return false;

    final p = filteredParams;

    final rawLine = (p['line'] ?? p['raw'] ?? '').toString().trim();
    final description = (p['description'] ?? '').toString().trim();
    final amountStr = (p['amount'] ?? '').toString().trim();
    final payment = (p['payment'] ?? '').toString().trim();
    final store = (p['store'] ?? '').toString().trim();

    final amount = double.tryParse(amountStr.replaceAll(',', ''));

    String composeLine() {
      if (rawLine.isNotEmpty) return rawLine;

      final parts = <String>[];
      if (description.isNotEmpty) parts.add(description);
      if (amount != null) {
        final a = amount == amount.roundToDouble()
            ? amount.toStringAsFixed(0)
            : amount.toString();
        parts.add('$a원');
      }
      if (payment.isNotEmpty) parts.add(payment);
      if (store.isNotEmpty) parts.add(store);
      return parts.join(' ').trim();
    }

    final line = composeLine();

    void openScreen({required bool autoSubmit}) {
      navigator.pushNamed(
        spec.routeName,
        arguments: QuickSimpleExpenseInputArgs(
          accountName: _accountNameOrDefault(accountName),
          initialDate: DateTime.now(),
          initialLine: line.isEmpty ? null : line,
          autoSubmit: autoSubmit,
        ),
      );
    }

    bool hasAmountInLine(String text) {
      final t = text.trim();
      if (t.isEmpty) return false;
      return RegExp(r'(\d[\d,]*)\s*원').hasMatch(t) ||
          RegExp(r'\d[\d,]*\s*$').hasMatch(t);
    }

    if (action.autoSubmit) {
      final missingForAuto = !hasAmountInLine(line);
      if (missingForAuto) {
        _showSimpleInfoDialog(
          navigator,
          title: '자동 저장 불가',
          message:
              '자동 저장을 위해서는 금액이 필요합니다.\n'
              '예: 커피 3000원\n'
              '화면을 열어 입력을 계속 진행하세요.',
        );
        openScreen(autoSubmit: false);
        return true;
      }

      if (!action.confirmed) {
        final previewText = line.isNotEmpty
            ? line
            : (description.isNotEmpty ? description : '간편 지출(1줄)');
        final amountText = amount != null
            ? (amount == amount.roundToDouble()
                  ? amount.toStringAsFixed(0)
                  : amount.toString())
            : '';

        showDialog<bool>(
          context: navigator.context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('저장 전에 확인'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('입력: $previewText'),
                  if (amountText.isNotEmpty) Text('금액: $amountText'),
                  const SizedBox(height: 8),
                  const Text('이대로 저장할까요?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        ).then((confirmed) {
          if (confirmed == true) {
            openScreen(autoSubmit: true);
          }
        });
        return true;
      }

      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: action.routeName,
        intent: action.intent ?? 'quick_expense_add',
        success: true,
      );

      openScreen(autoSubmit: true);
      return true;
    }

    VoiceAssistantAnalytics.logCommand(
      assistant: _detectAssistant(action.params),
      route: action.routeName,
      intent: action.intent ?? 'quick_expense_add',
      success: true,
    );

    openScreen(autoSubmit: false);
    return true;
  }
}
