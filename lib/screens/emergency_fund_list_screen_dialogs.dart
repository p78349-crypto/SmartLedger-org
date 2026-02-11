part of 'emergency_fund_list_screen.dart';

/// 비상금 거래 수정 다이얼로그
class _EmergencyTransactionEditDialog extends StatefulWidget {
  final EmergencyTransaction transaction;

  const _EmergencyTransactionEditDialog({required this.transaction});

  @override
  State<_EmergencyTransactionEditDialog> createState() =>
      _EmergencyTransactionEditDialogState();
}

class _EmergencyTransactionEditDialogState
    extends State<_EmergencyTransactionEditDialog> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late bool _isDeposit;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.transaction.description,
    );
    _amountController = TextEditingController(
      text: CurrencyFormatter.format(
        widget.transaction.amount.abs(),
        showUnit: false,
      ),
    );
    _isDeposit = widget.transaction.amount >= 0;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('거래 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('입금'),
                icon: Icon(Icons.add),
              ),
              ButtonSegment(
                value: false,
                label: Text('출금'),
                icon: Icon(Icons.remove),
              ),
            ],
            selected: {_isDeposit},
            onSelectionChanged: (Set<bool> selected) {
              setState(() {
                _isDeposit = selected.first;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '설명',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '금액',
              border: OutlineInputBorder(),
              suffixText: '원',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final amount = CurrencyFormatter.parse(_amountController.text);
            final description = _descriptionController.text.trim();
            if (amount == null || amount <= 0 || description.isEmpty) {
              return;
            }

            Navigator.of(context).pop(
              widget.transaction.copyWith(
                description: description,
                amount: _isDeposit ? amount : -amount,
              ),
            );
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}

enum _EmergencyDeleteMode { justDelete, adjustCashAsset }

class _EmergencyDeleteDecision {
  final _EmergencyDeleteMode mode;
  final String memo;

  const _EmergencyDeleteDecision({required this.mode, required this.memo});
}

/// 삭제 결정 다이얼로그
class _EmergencyDeleteDecisionDialog extends StatefulWidget {
  final int count;

  const _EmergencyDeleteDecisionDialog({required this.count});

  @override
  State<_EmergencyDeleteDecisionDialog> createState() =>
      _EmergencyDeleteDecisionDialogState();
}

class _EmergencyDeleteDecisionDialogState
    extends State<_EmergencyDeleteDecisionDialog> {
  _EmergencyDeleteMode _mode = _EmergencyDeleteMode.justDelete;

  late final TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: '비상금 거래 삭제(환불/취소) 반영');
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('삭제 처리 선택'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('선택한 ${widget.count}개 거래를 삭제합니다.'),
          const SizedBox(height: 12),
          SegmentedButton<_EmergencyDeleteMode>(
            segments: const [
              ButtonSegment(
                value: _EmergencyDeleteMode.justDelete,
                label: Text('단순 삭제'),
              ),
              ButtonSegment(
                value: _EmergencyDeleteMode.adjustCashAsset,
                label: Text('자산 순환'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selected) {
              setState(() {
                _mode = selected.first;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            _mode == _EmergencyDeleteMode.justDelete
                ? '오기입/기록만 제거합니다.'
                : '삭제 금액을 현금 자산에 반영합니다.',
          ),
          if (_mode == _EmergencyDeleteMode.adjustCashAsset) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모(자산 이동 기록)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _EmergencyDeleteDecision(
                mode: _mode,
                memo: _memoController.text.trim().isEmpty
                    ? '비상금 거래 삭제(환불/취소) 반영'
                    : _memoController.text.trim(),
              ),
            );
          },
          child: const Text('계속'),
        ),
      ],
    );
  }
}
