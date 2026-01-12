part of meal_cost_experiment_screen;

class _MealItemInput {
  final nameController = TextEditingController();
  final gramsController = TextEditingController();
  final priceController = TextEditingController();

  void dispose() {
    nameController.dispose();
    gramsController.dispose();
    priceController.dispose();
  }

  String get name => nameController.text;

  double get gramsValue {
    final raw = gramsController.text.trim();
    final value = double.tryParse(raw);
    return (value ?? 0.0).clamp(0.0, double.infinity);
  }

  String get gramsLabel {
    final grams = gramsValue;
    if (grams <= 0) return '';
    final isInt = grams == grams.toInt();
    return isInt ? '${grams.toInt()}g' : '${grams.toStringAsFixed(1)}g';
  }

  double get priceValue {
    final raw = priceController.text.trim().replaceAll(',', '');
    final value = double.tryParse(raw);
    return (value ?? 0.0).clamp(0.0, double.infinity);
  }
}

class _MealItemRow extends StatelessWidget {
  final _MealItemInput input;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _MealItemRow({
    required this.input,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: TextField(
              controller: input.nameController,
              decoration: const InputDecoration(
                labelText: '품목',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: input.gramsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'g',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: input.priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '원',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close),
              tooltip: '삭제',
            ),
          ],
        ],
      ),
    );
  }
}
