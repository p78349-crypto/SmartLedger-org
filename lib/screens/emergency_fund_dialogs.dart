import 'package:flutter/material.dart';

import '../models/emergency_transaction.dart';
import '../utils/utils.dart';

enum EmergencyDeleteMode { justDelete, adjustCashAsset }

class EmergencyDeleteDecision {
  final EmergencyDeleteMode mode;
  final String memo;

  const EmergencyDeleteDecision({required this.mode, required this.memo});
}

class EmergencyDeleteDecisionDialog extends StatefulWidget {
  const EmergencyDeleteDecisionDialog({super.key});

  @override
  State<EmergencyDeleteDecisionDialog> createState() =>
      _EmergencyDeleteDecisionDialogState();
}

class _EmergencyDeleteDecisionDialogState
    extends State<EmergencyDeleteDecisionDialog> {
  EmergencyDeleteMode _mode = EmergencyDeleteMode.justDelete;
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
          SegmentedButton<EmergencyDeleteMode>(
            segments: const [
              ButtonSegment(
                value: EmergencyDeleteMode.justDelete,
                label: Text('단순 삭제'),
              ),
              ButtonSegment(
                value: EmergencyDeleteMode.adjustCashAsset,
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
            _mode == EmergencyDeleteMode.justDelete
                ? '오기입/기록만 제거합니다.'
                : '삭제 금액을 현금 자산에 반영합니다.',
          ),
          if (_mode == EmergencyDeleteMode.adjustCashAsset) ...[
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
              EmergencyDeleteDecision(
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

class EmergencyTransactionDialog extends StatefulWidget {
  final EmergencyTransaction? transaction;
  const EmergencyTransactionDialog({super.key, this.transaction});

  @override
  State<EmergencyTransactionDialog> createState() =>
      _EmergencyTransactionDialogState();
}

class _EmergencyTransactionDialogState
    extends State<EmergencyTransactionDialog> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  bool _isDeposit = true;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.transaction?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.transaction != null
          ? CurrencyFormatter.format(
              widget.transaction!.amount.abs(),
              showUnit: false,
            )
          : '',
    );
    _isDeposit = widget.transaction == null || widget.transaction!.amount > 0;
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
      title: Text(widget.transaction == null ? '입출금 추가' : '입출금 수정'),
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
              hintText: '예: 비상금 적립',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '금액',
              hintText: '0',
              border: OutlineInputBorder(),
              suffixText: '원',
            ),
          ),
        ],
      ),
      actions: [
        if (widget.transaction != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop('DELETE');
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = _parseAmount(_amountController.text);
            if (amount != null && _descriptionController.text.isNotEmpty) {
              final transaction = EmergencyTransaction(
                id:
                    widget.transaction?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                description: _descriptionController.text,
                amount: _isDeposit ? amount : -amount,
                date: widget.transaction?.date ?? DateTime.now(),
              );
              Navigator.of(context).pop(transaction);
            }
          },
          child: const Text('저장'),
        ),
      ],
    );
  }

  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll(' ', '').trim();
    return double.tryParse(cleaned);
  }
}
