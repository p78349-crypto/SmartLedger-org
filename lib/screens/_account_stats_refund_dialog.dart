// ignore_for_file: invalid_use_of_protected_member
part of 'account_stats_screen.dart';

/// 반품(환불) 처리 다이얼로그.
extension AccountStatsRefundDialog on _AccountStatsScreenState {
  Future<void> _showRefundDialog(Transaction originalTx, ThemeData theme) async {
    final refundAmountController = TextEditingController(
      text: originalTx.amount.abs().toString(),
    );
    DateTime selectedDate = DateTime.now();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            icon: const Icon(Icons.replay, size: 48, color: Colors.green),
            title: const Text('반품 처리'),
            content: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('원본 거래', style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Text(originalTx.description,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${_currencyFormat.format(originalTx.amount.abs())}원',
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: refundAmountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: '환불 금액',
                    helperText: '택배비 등을 제외한 실제 환불 금액',
                    suffixText: '원',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withAlpha(128),
                  ),
                ),
                const SizedBox(height: 24),
                _buildRefundDatePicker(theme, selectedDate, (picked) {
                  setDialogState(() => selectedDate = picked);
                }),
                const SizedBox(height: 16),
                _buildRefundInfoBanner(theme),
              ],
            )),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소')),
              FilledButton.icon(
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('반품 처리'),
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      if (confirmed == true) {
        final refundAmount = double.tryParse(
          refundAmountController.text.replaceAll(',', '').trim());
        if (refundAmount == null || refundAmount <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('올바른 환불 금액을 입력하세요')));
          }
          return;
        }
        await TransactionService().createRefundTransaction(
          widget.accountName, originalTx,
          refundDate: selectedDate, refundAmount: refundAmount);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '반품 처리 완료 (환불: ${_currencyFormat.format(refundAmount)}원)'),
            backgroundColor: Colors.green,
          ));
        }
      }
    } finally {
      refundAmountController.dispose();
    }
  }

  Widget _buildRefundDatePicker(
    ThemeData theme, DateTime selectedDate,
    void Function(DateTime) onPicked,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate, firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('ko', 'KR'),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
              color: theme.colorScheme.outline.withAlpha(128)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('환불 날짜', style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(_dateFormat.format(selectedDate),
                style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600)),
            ],
          )),
          const Icon(Icons.chevron_right),
        ]),
      ),
    );
  }

  Widget _buildRefundInfoBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withAlpha(64)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: Colors.green, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text('환불 금액이 수입으로 기록되어\n예산에 다시 반영됩니다.',
          style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green[800]))),
      ]),
    );
  }
}
