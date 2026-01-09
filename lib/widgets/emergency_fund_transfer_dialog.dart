import 'package:flutter/material.dart';
import '../utils/icon_catalog.dart';

class EmergencyFundTransferDialog extends StatefulWidget {
  final double currentBalance;
  final String accountName;

  const EmergencyFundTransferDialog({
    super.key,
    required this.currentBalance,
    required this.accountName,
  });

  @override
  State<EmergencyFundTransferDialog> createState() =>
      _EmergencyFundTransferDialogState();
}

class _EmergencyFundTransferDialogState
    extends State<EmergencyFundTransferDialog> {
  late TextEditingController _amountController;
  String _selectedTarget = 'savings'; // 기본값: 예금

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('비상금 이동'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.accountName} - 비상금 이동',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            // 현재 비상금 표시
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '현재 비상금:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    '₩${widget.currentBalance.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 이동할 금액 입력
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: '이동할 금액',
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: '원',
              ),
            ),
            const SizedBox(height: 16),
            // 이동 대상 선택
            Text(
              '이동 대상을 선택하세요',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            _buildTargetOption('savings', '🏆 예금(Savings)으로 투자'),
            _buildTargetOption('expense', '💸 지출(이번달 예산 초과분)'),
            _buildTargetOption('asset', '🏠 자산(Asset)으로 이동'),
            _buildTargetOption('custom', '📝 기타 용도'),
            const SizedBox(height: 16),
            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ 주의',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '비상금은 긴급 상황 대비 자금입니다.\n'
                    '신중하게 이동하시기 바랍니다.',
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
        ElevatedButton(onPressed: _handleTransfer, child: const Text('이동')),
      ],
    );
  }

  Widget _buildTargetOption(String value, String label) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSelected = _selectedTarget == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTarget = value;
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
                  ? Icon(IconCatalog.check, size: 12, color: scheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }

  void _handleTransfer() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('0 이상의 금액을 입력하세요.')));
      return;
    }

    if (amount > widget.currentBalance) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비상금 잔액을 초과할 수 없습니다.')));
      return;
    }

    Navigator.pop(context, {'amount': amount, 'target': _selectedTarget});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('비상금에서 ₩${amount.toStringAsFixed(0)}이 이동되었습니다.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
