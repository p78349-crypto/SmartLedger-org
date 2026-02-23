import 'package:flutter/material.dart';

/// 생활용품 항목 추가 다이얼로그
class HouseholdAddItemDialog extends StatefulWidget {
  const HouseholdAddItemDialog({super.key, required this.onAdd});

  final void Function(String name, String unit, double qty) onAdd;

  @override
  State<HouseholdAddItemDialog> createState() => _HouseholdAddItemDialogState();
}

class _HouseholdAddItemDialogState extends State<HouseholdAddItemDialog> {
  final _nameController = TextEditingController();
  final _unitController = TextEditingController(text: '');
  final _qtyController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('생활용품 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '상품명',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: const [
                          TextSpan(text: '단위'),
                          TextSpan(text: ' '),
                          TextSpan(
                            text: '(개수)',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  decoration: const InputDecoration(
                    labelText: '수량',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final unit = _unitController.text.trim();
            final qty = double.tryParse(_qtyController.text) ?? 1;
            if (name.isNotEmpty) {
              widget.onAdd(name, unit, qty);
              Navigator.pop(context);
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
