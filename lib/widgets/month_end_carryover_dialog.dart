import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/emergency_transaction.dart';
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../services/emergency_fund_service.dart';
import '../services/transaction_service.dart';

class MonthEndCarryoverDialog extends StatefulWidget {
  final Account account;
  final VoidCallback onSaved;

  const MonthEndCarryoverDialog({
    super.key,
    required this.account,
    required this.onSaved,
  });

  @override
  State<MonthEndCarryoverDialog> createState() =>
      _MonthEndCarryoverDialogState();
}

class _MonthEndCarryoverDialogState extends State<MonthEndCarryoverDialog> {
  late TextEditingController _remainingAmountController;
  late TextEditingController _overdraftController;
  late TextEditingController _customAmountController;
  String _selectedOption = 'carryover'; // 기본값: 다음달 예산으로 이월

  @override
  void initState() {
    super.initState();
    _remainingAmountController = TextEditingController(
      text: widget.account.carryoverAmount.toString(),
    );
    _overdraftController = TextEditingController(
      text: widget.account.overdraftAmount.toString(),
    );
    _customAmountController = TextEditingController(
      text: widget.account.carryoverAmount.toString(),
    );
  }

  @override
  void dispose() {
    _remainingAmountController.dispose();
    _overdraftController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('월말 정산'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.account.name} - 월말 정산 정보',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            // 남은 돈 입력
            TextField(
              controller: _remainingAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: '남은 돈',
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: '원',
              ),
            ),
            const SizedBox(height: 16),
            // 남은 돈 용도 선택
            Text(
              '남은 돈을 어디로 이동할까요?',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            _buildOption('carryover', '📅 다음달 예산으로 이월'),
            _buildOption('emergency', '🆘 비상금(Emergency Fund)으로 이동'),
            _buildOption('savings', '🏆 예금(Savings)으로 이동'),
            _buildOption('custom', '📝 기타 (수동 입력)'),
            if (_selectedOption == 'custom') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '기타용도 금액',
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: '원',
                ),
              ),
            ],
            const SizedBox(height: 16),
            // 예산 초과 입력
            TextField(
              controller: _overdraftController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: '예산 초과 금액 (미래에서 끌어온 돈)',
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: '원',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '다음달 예산 계산:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '기본 예산 + 이월된 남은 돈 - 예산 초과 금액',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(onPressed: _handleSave, child: const Text('저장')),
      ],
    );
  }

  Widget _buildOption(String value, String label) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSelected = _selectedOption == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOption = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? scheme.primaryContainer : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? scheme.primary : scheme.outline,
                  width: 2,
                ),
                color: isSelected ? scheme.primary : scheme.surface,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 12, color: scheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final rawRemaining =
        double.tryParse(_remainingAmountController.text.replaceAll(',', '')) ??
        0.0;
    final rawOverdraft =
        double.tryParse(_overdraftController.text.replaceAll(',', '')) ?? 0.0;

    final remainingAmount = rawRemaining.isFinite && rawRemaining > 0
        ? rawRemaining
        : 0.0;
    final overdraftAmount = rawOverdraft.isFinite && rawOverdraft > 0
        ? rawOverdraft
        : 0.0;

    double carryoverAmount = 0.0;
    if (_selectedOption == 'carryover') {
      carryoverAmount = remainingAmount;
    } else if (_selectedOption == 'custom') {
      final rawCustom =
          double.tryParse(_customAmountController.text.replaceAll(',', '')) ??
          0.0;
      final custom = rawCustom.isFinite && rawCustom > 0 ? rawCustom : 0.0;
      // Custom is treated as manual carryover into next month's budget.
      carryoverAmount = custom.clamp(0.0, remainingAmount).toDouble();
    }

    final now = DateTime.now();

    // Persist month-end budget adjustments first.
    await AccountService().updateMonthEndData(
      widget.account.name,
      carryoverAmount: carryoverAmount,
      overdraftAmount: overdraftAmount,
      completedAt: now,
    );

    // Apply optional destination side-effects.
    if (remainingAmount > 0) {
      if (_selectedOption == 'emergency') {
        await EmergencyFundService().addTransaction(
          widget.account.name,
          EmergencyTransaction(
            id: now.microsecondsSinceEpoch.toString(),
            description: '월말 정산 이월(비상금)',
            amount: remainingAmount,
            date: now,
          ),
        );
      } else if (_selectedOption == 'savings') {
        await TransactionService().addTransaction(
          widget.account.name,
          Transaction(
            id: now.microsecondsSinceEpoch.toString(),
            type: TransactionType.savings,
            description: '월말 정산 이월(예금)',
            amount: remainingAmount,
            date: now,
            savingsAllocation: SavingsAllocation.assetIncrease,
            memo: '월말 정산에서 예금으로 이동',
          ),
        );
      }
    }

    if (!mounted) return;
    widget.onSaved();
    Navigator.pop(context);
  }
}
