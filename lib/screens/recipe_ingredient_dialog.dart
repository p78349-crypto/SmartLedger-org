import 'package:flutter/material.dart';
import '../models/recipe.dart';

/// 재료 추가/편집 다이얼로그
class RecipeIngredientDialog extends StatefulWidget {
  const RecipeIngredientDialog({
    super.key,
    this.existing,
    required this.onSave,
  });

  final RecipeIngredient? existing;
  final void Function(RecipeIngredient) onSave;

  @override
  State<RecipeIngredientDialog> createState() => _RecipeIngredientDialogState();
}

class _RecipeIngredientDialogState extends State<RecipeIngredientDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late String _unit;

  static const _units = ['g', 'kg', 'ml', 'L', '개', '장', '줌', '큰술', '작은술', '컵'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.existing?.quantity.toString() ?? '',
    );
    _unit = widget.existing?.unit ?? 'g';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('재료 이름을 입력해주세요')));
      return;
    }
    if (quantity <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수량을 올바르게 입력해주세요')));
      return;
    }

    widget.onSave(
      RecipeIngredient(name: name, quantity: quantity, unit: _unit),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? '재료 추가' : '재료 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '재료 이름',
              hintText: '예: 돼지고기',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: '수량',
                    hintText: '예: 200',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _unit,
                  decoration: const InputDecoration(labelText: '단위'),
                  items: _units
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _unit = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _save, child: const Text('확인')),
      ],
    );
  }
}
