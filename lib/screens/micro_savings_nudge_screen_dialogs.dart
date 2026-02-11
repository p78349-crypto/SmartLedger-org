part of 'micro_savings_nudge_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _DialogsExt on _MicroSavingsNudgeScreenState {
  Future<void> _openQuickRecordDialog({
    required String title,
    required String description,
    required String memoTag,
  }) async {
    final amountController = TextEditingController();
    final memoController = TextEditingController();
    final amountFocusNode = FocusNode();
    final memoFocusNode = FocusNode();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!amountFocusNode.hasFocus) {
            amountFocusNode.requestFocus();
          }
          final text = amountController.text;
          amountController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: text.length,
          );
        });

        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                focusNode: amountFocusNode,
                decoration: const InputDecoration(
                  labelText: '금액',
                  hintText: '예: 5000',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autofocus: true,
                onSubmitted: (_) => memoFocusNode.requestFocus(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: memoController,
                focusNode: memoFocusNode,
                decoration: const InputDecoration(labelText: '메모(선택)'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('기록'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      amountController.dispose();
      memoController.dispose();
      amountFocusNode.dispose();
      memoFocusNode.dispose();
      return;
    }

    final parsed = CurrencyFormatter.parse(amountController.text.trim());
    final memo = memoController.text.trim();

    amountController.dispose();
    memoController.dispose();
    amountFocusNode.dispose();
    memoFocusNode.dispose();

    final amount = (parsed ?? 0).toDouble();
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('금액을 확인해주세요.')));
      return;
    }

    final tx = Transaction(
      id: 'micro_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.savings,
      description: title,
      amount: amount,
      date: DateTime.now(),
      memo: memo.isEmpty ? memoTag : '$memoTag $memo',
      savingsAllocation: SavingsAllocation.assetIncrease,
    );

    await TransactionService().addTransaction(widget.accountName, tx);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title ${CurrencyFormatter.format(amount)} 저장 완료'),
      ),
    );

    await _load();
  }

  Future<void> _openRoundUpDialog() async {
    final amountController = TextEditingController();
    final amountFocusNode = FocusNode();

    var unit = 1000.0;
    double? computed;

    double computeRoundUp(double base) {
      if (base <= 0) return 0;
      if (unit <= 0) return 0;
      final rounded = (base / unit).ceil() * unit;
      final diff = rounded - base;
      return diff > 0 ? diff : 0;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!amountFocusNode.hasFocus) {
            amountFocusNode.requestFocus();
          }
          final text = amountController.text;
          amountController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: text.length,
          );
        });

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final parsed = CurrencyFormatter.parse(
              amountController.text.trim(),
            );
            final base = (parsed ?? 0).toDouble();
            computed = computeRoundUp(base);

            return AlertDialog(
              title: const Text('잔돈 모으기(반올림)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    focusNode: amountFocusNode,
                    decoration: const InputDecoration(
                      labelText: '결제 금액',
                      hintText: '예: 9900',
                    ),
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<double>(
                    key: ValueKey<double>(unit),
                    initialValue: unit,
                    decoration: const InputDecoration(labelText: '반올림 단위'),
                    items: const [
                      DropdownMenuItem(value: 1000, child: Text('1,000원')),
                      DropdownMenuItem(value: 10000, child: Text('10,000원')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() => unit = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '저축 금액(잔돈): ${CurrencyFormatter.format(computed ?? 0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '이 기록은 1억 프로젝트의 "혜택/절약"에 포함됩니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('저축 기록'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) {
      amountController.dispose();
      amountFocusNode.dispose();
      return;
    }

    final parsed = CurrencyFormatter.parse(amountController.text.trim());
    amountController.dispose();
    amountFocusNode.dispose();

    final base = (parsed ?? 0).toDouble();
    final diff = computeRoundUp(base);
    if (base <= 0 || diff <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('반올림할 금액이 없습니다.')));
      return;
    }

    final rounded = (base / unit).ceil() * unit;
    final memo =
        '${BenefitAggregationUtils.roundUpMemoTag} '
        '${CurrencyFormatter.format(base)}→'
        '${CurrencyFormatter.format(rounded)}';

    final tx = Transaction(
      id: 'roundup_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.savings,
      description: '잔돈 모으기',
      amount: diff,
      date: DateTime.now(),
      memo: memo,
      savingsAllocation: SavingsAllocation.assetIncrease,
    );

    await TransactionService().addTransaction(widget.accountName, tx);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('잔돈 ${CurrencyFormatter.format(diff)} 저축 저장 완료'),
      ),
    );

    await _load();
  }
}
